#!/usr/bin/env bash

set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
apt_package_list="$repo_dir/manifests/apt-packages.txt"
brewfile="$repo_dir/manifests/Brewfile"
platform=""
distribution=""
privilege=()
total_stages=5

die() {
    printf 'install.sh: %s\n' "$*" >&2
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

check_os() {
    if (( EUID == 0 )) && [[ -n "${SUDO_USER:-}" ]]; then
        die 'Run install.sh as your user without sudo. The apt steps request sudo when needed, while mise should use your user home.'
    fi

    case "$(uname -s)" in
        Darwin)
            platform="macos"
            command -v brew >/dev/null 2>&1 || die 'Homebrew is required on macOS. Install it first, then rerun this script.'
            ;;
        Linux)
            [[ -r /etc/os-release ]] || die 'Cannot identify this Linux distribution.'
            # shellcheck disable=SC1091
            . /etc/os-release
            case "${ID:-}" in
                debian|ubuntu) distribution="$ID" ;;
                *) die "Unsupported Linux distribution: ${ID:-unknown}. Supported distributions are Debian and Ubuntu." ;;
            esac
            platform="linux"
            command -v apt-get >/dev/null 2>&1 || die 'apt-get is required on Debian/Ubuntu.'
            if (( EUID != 0 )); then
                command -v sudo >/dev/null 2>&1 || die 'Run as root or install sudo first.'
                privilege=(sudo)
            fi
            ;;
        *)
            die "Unsupported operating system: $(uname -s)."
            ;;
    esac

    if [[ "$platform" == macos ]]; then
        printf '  Detected macOS.\n'
    else
        printf '  Detected %s Linux.\n' "$distribution"
    fi
}

apt_has_candidate() {
    apt-cache policy "$1" 2>/dev/null | awk '$1 == "Candidate:" && $2 != "(none)" { found = 1 } END { exit !found }'
}

install_apt_packages() {
    local package

    printf '  Refreshing apt package lists.\n'
    "${privilege[@]}" apt-get update

    # mise is distributed through its own apt repository on Debian/Ubuntu.
    if ! apt_has_candidate mise; then
        printf "  Installing extrepo, Debian's apt repository helper, to add the mise repository.\n"
        "${privilege[@]}" apt-get install -y extrepo
        "${privilege[@]}" extrepo enable mise
        "${privilege[@]}" apt-get update
    fi

    while IFS= read -r package || [[ -n "$package" ]]; do
        [[ -z "$package" ]] && continue
        if ! apt_has_candidate "$package"; then
            die "Package '$package' is not available from the configured apt repositories."
        fi
    done < "$apt_package_list"

    printf '  Installing packages from the apt package list.\n'
    "${privilege[@]}" xargs -r -a "$apt_package_list" apt-get install -y
}

install_shell() {
    case "$platform" in
        macos)
            printf '  Installing packages from the Homebrew Brewfile.\n'
            brew bundle --file="$brewfile"
            ;;
        linux)
            install_apt_packages
            ;;
    esac
}

setup_ssh() (
    ssh_dir="$HOME/.ssh"
    tmp_dir=""

    umask 077
    mkdir -p -- "$ssh_dir"
    trap 'if [[ -n "$tmp_dir" ]]; then rm -rf -- "$tmp_dir"; fi' EXIT

    for key_name in id_ed25519_auth id_ed25519_sign; do
        private_key="$ssh_dir/$key_name"
        public_key="$private_key.pub"

        for key_file in "$private_key" "$public_key"; do
            if [[ ( -e "$key_file" || -L "$key_file" ) && ! -f "$key_file" ]]; then
                die "Not a regular SSH key file: $key_file"
            fi
        done
        if [[ -f "$private_key" && -f "$public_key" ]]; then
            continue
        fi

        command -v ssh-keygen >/dev/null 2>&1 || die 'ssh-keygen is required to set up SSH keys.'
        if [[ -z "$tmp_dir" ]]; then
            tmp_dir="$(mktemp -d "$ssh_dir/.install-keys.XXXXXXXX")"
        fi
        tmp_key="$tmp_dir/$key_name"

        if [[ -f "$private_key" ]]; then
            printf '  Restoring public key %s.\n' "$public_key"
            ssh-keygen -y -f "$private_key" > "$tmp_key.pub" || die "Could not read SSH private key: $private_key"
        else
            printf '  Creating %s. Choose a passphrase when prompted.\n' "$private_key"
            ssh-keygen -t ed25519 -f "$tmp_key" || die "Could not generate SSH key: $private_key"
            mv -f -- "$tmp_key" "$private_key"
        fi
        mv -f -- "$tmp_key.pub" "$public_key"
    done
)

import_config() {
    command -v mise >/dev/null 2>&1 || die 'mise was not installed.'
    printf '  Trusting the mise config and applying dotfiles from this checkout.\n'
    mise trust "$repo_dir/mise.toml"
    mise -C "$repo_dir" dot apply
}

install_runtime() {
    command -v mise >/dev/null 2>&1 || die 'mise was not installed.'
    command -v zsh >/dev/null 2>&1 || die 'zsh was not installed.'

    printf '  Starting zsh with the configured XDG paths before mise runs.\n'
    XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}" \
    XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}" \
    XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}" \
    XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}" \
        zsh -c 'mise bootstrap --only packages,services,tools'
}

main() {
    run_stage 1 'Checking OS and prerequisites' check_os
    run_stage 2 'Installing shell and bootstrap packages' install_shell
    run_stage 3 'Setting up SSH authentication and signing keys' setup_ssh
    run_stage 4 'Applying configuration with mise' import_config
    run_stage 5 'Bootstrapping selected module packages, services and runtimes with mise' install_runtime
    printf '\nAll setup stages completed. Start zsh to use the installed shell configuration.\n'
}

main "$@"
