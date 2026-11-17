#!/usr/bin/env bash

set -euo pipefail
umask 077

ssh_dir="$HOME/.ssh"
work_dir=""
names=(id_ed25519 id_ed25519_signing)
replace_pairs=()
public_values=()
total_stages=6

die() {
    printf 'refresh-ssh-keys.sh: %s\n' "$*" >&2
    exit 1
}

run_stage() {
    local stage_number="$1"
    local description="$2"
    shift 2

    printf '\n[%s/%s] - %s\n' "$stage_number" "$total_stages" "$description"
    "$@"
    printf '[%s/%s] - Complete\n' "$stage_number" "$total_stages"
}

cleanup() {
    [[ -z "$work_dir" ]] || rm -rf -- "$work_dir"
}

check_prerequisites() {
    local tool

    for tool in ssh-keygen ssh-agent ssh-add; do
        command -v "$tool" >/dev/null 2>&1 || die "$tool is required."
    done
}

prepare_workspace() {
    mkdir -p "$ssh_dir"
    chmod 700 "$ssh_dir"

    # Prepare both pairs before changing any existing key files.
    work_dir="$(mktemp -d "$ssh_dir/.refresh-keys.XXXXXXXX")"
    trap cleanup EXIT
}

prepare_key_pair() {
    local private_key public_file key replace existing answer source_key
    local public_key key_type key_data existing_type existing_data

    local name="$1"
    local purpose="$2"
    private_key="$ssh_dir/$name"
    public_file="$private_key.pub"
    replace=false
    existing=false
    for key in "$private_key" "$public_file"; do
        if [[ -e "$key" || -L "$key" ]]; then
            [[ -f "$key" && ! -L "$key" ]] || die "Refusing to replace non-regular file or symlink: $key"
            existing=true
        fi
    done
    if "$existing"; then
        printf 'Existing %s key files found. Replacement requires registering the new public key with your services.\n' "$purpose"
        printf 'Overwrite ~/.ssh/%s and its public key? [y/N] ' "$name"
        answer=''
        read -r answer || true
        case "$answer" in y|Y|yes|YES) replace=true ;; esac
    fi
    # Capture the old identity before replacement, even if its public file is missing.
    if "$replace"; then
        if [[ -e "$private_key" ]]; then
            ssh-keygen -y -f "$private_key" > "$work_dir/$name.old.pub" || die "Could not identify the old $purpose key."
        elif [[ -e "$public_file" ]]; then
            cp -- "$public_file" "$work_dir/$name.old.pub"
        fi
    fi
    if "$replace" || [[ ! -e "$private_key" ]]; then
        if "$existing" && ! "$replace"; then
            die "$public_file exists without its private key. Restore it or approve replacement (including for the old shared signing public key)."
        fi
        printf 'Creating an independent Ed25519 %s key. Choose a passphrase when prompted.\n' "$purpose"
        ssh-keygen -t ed25519 -f "$work_dir/$name" -C "$purpose"
        source_key="$work_dir/$name"
    else
        printf 'Reusing the existing %s private key.\n' "$purpose"
        source_key="$private_key"
    fi
    public_key="$(ssh-keygen -y -f "$source_key")" || die "Could not derive the $purpose public key."
    read -r key_type key_data _ <<< "$public_key"
    [[ "$key_type" == ssh-ed25519 ]] || die "Expected an Ed25519 $purpose key."
    public_values+=("$key_type $key_data")
    if ! "$replace" && [[ -e "$public_file" ]]; then
        read -r existing_type existing_data _ < "$public_file" || die "Cannot read $public_file"
        [[ "$existing_type $existing_data" == "$key_type $key_data" ]] || die "$public_file does not match the private key; files were preserved."
    fi
    printf '%s %s %s\n' "$key_type" "$key_data" "$purpose" > "$work_dir/$name.pub"
    chmod 644 "$work_dir/$name.pub"
    replace_pairs+=("$replace")
}

prepare_key_pairs() {
    # Validate both pairs before changing existing files.
    prepare_key_pair id_ed25519 authentication
    prepare_key_pair id_ed25519_signing signing
    [[ "${public_values[0]}" != "${public_values[1]}" ]] || die 'Authentication and signing keys are identical. Approve replacement of at least one pair.'
}

agent_available() {
    local status=0
    ssh-add -l >/dev/null 2>&1 || status=$?
    # ssh-add returns 1 for a reachable agent with no keys, 2 for no agent.
    [[ "$status" == 0 || "$status" == 1 ]]
}

connect_agent() {
    if ! agent_available; then
        export SSH_AUTH_SOCK="$ssh_dir/agent.sock"
        unset SSH_AGENT_PID
        if ! agent_available; then
            # Remove only a stale socket, never an arbitrary file at this path.
            if [[ -S "$SSH_AUTH_SOCK" ]]; then rm -- "$SSH_AUTH_SOCK"; fi
            [[ ! -e "$SSH_AUTH_SOCK" && ! -L "$SSH_AUTH_SOCK" ]] || die "Agent socket path is occupied: $SSH_AUTH_SOCK"
            eval "$(ssh-agent -a "$SSH_AUTH_SOCK" -s)"
        fi
        printf 'For this terminal, run: export SSH_AUTH_SOCK=%q\n' "$SSH_AUTH_SOCK"
    fi
}

list_agent_identities() {
    local destination="$1"
    local status=0
    ssh-add -L > "$destination" || status=$?
    [[ "$status" == 0 || "$status" == 1 ]] || die 'Could not list agent identities; key files were preserved.'
}

remove_replaced_identities() {
    local agent_keys name old_public old_type old_data

    # Remove only identities being replaced that are actually loaded in this agent.
    agent_keys="$work_dir/agent-keys"
    list_agent_identities "$agent_keys"
    for name in "${names[@]}"; do
        old_public="$work_dir/$name.old.pub"
        [[ -e "$old_public" ]] || continue
        read -r old_type old_data _ < "$old_public" || die "Cannot read old identity for $name."
        if awk -v type="$old_type" -v data="$old_data" '$1 == type && $2 == data { found = 1 } END { exit !found }' "$agent_keys"; then
            ssh-add -d "$old_public" || die "Could not remove the old $name identity; key files were preserved."
            # Refresh after removal: the legacy shared-key setup can identify the same key twice.
            list_agent_identities "$agent_keys"
        fi
    done
}

install_key_pairs() {
    local index name private_key

    for index in 0 1; do
        name="${names[$index]}"
        private_key="$ssh_dir/$name"
        if [[ -e "$work_dir/$name" ]]; then mv -f -- "$work_dir/$name" "$private_key"; fi
        chmod 600 "$private_key"
        if "${replace_pairs[$index]}" || [[ ! -e "$private_key.pub" ]]; then
            mv -f -- "$work_dir/$name.pub" "$private_key.pub"
        fi
    done
}

load_key_pairs() {
    ssh-add "$ssh_dir/id_ed25519" "$ssh_dir/id_ed25519_signing"
}

main() {
    check_prerequisites
    run_stage 1 'Preparing SSH workspace' prepare_workspace
    run_stage 2 'Preparing authentication and signing key pairs' prepare_key_pairs
    run_stage 3 'Connecting to an SSH agent' connect_agent
    run_stage 4 'Removing replaced identities from the agent' remove_replaced_identities
    run_stage 5 'Installing key pairs' install_key_pairs
    run_stage 6 'Loading private keys into the agent' load_key_pairs
    printf '\nIndependent authentication and signing key pairs are ready; both private keys are loaded in ssh-agent.\n'
}

main "$@"
