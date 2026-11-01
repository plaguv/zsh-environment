#!/usr/bin/env bash

set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
apt_manifest="$repo_dir/manifests/apt-manifest.json"
brewfile="$repo_dir/manifests/Brewfile"
platform=""
distribution=""
privilege=()
chezmoi_bin=""
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
            command -v python3 >/dev/null 2>&1 || die 'python3 is required to read manifests/apt-manifest.json.'

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
    local packages=()
    local apt_packages=()

    while IFS= read -r package; do
        [[ -n "$package" ]] && packages+=("$package")
    done < <(python3 -c 'import json, sys; print("\n".join(json.load(open(sys.argv[1]))["packages"]))' "$apt_manifest")

    printf '  Refreshing apt package lists.\n'
    "${privilege[@]}" apt-get update

    # mise is distributed through its own apt repository on Debian/Ubuntu.
    if ! apt_has_candidate mise; then
        printf '  Enabling the mise apt repository.\n'
        "${privilege[@]}" apt-get install -y extrepo
        "${privilege[@]}" extrepo enable mise
        "${privilege[@]}" apt-get update
    fi

    for package in "${packages[@]}"; do
        if apt_has_candidate "$package"; then
            apt_packages+=("$package")
        elif [[ "$package" == chezmoi ]]; then
            # Some stable Debian/Ubuntu releases do not package chezmoi.
            continue
        else
            die "Package '$package' is not available from the configured apt repositories."
        fi
    done

    printf '  Installing packages from the apt manifest.\n'
    "${privilege[@]}" apt-get install -y "${apt_packages[@]}"
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

install_chezmoi() {
    if command -v chezmoi >/dev/null 2>&1; then
        chezmoi_bin="$(command -v chezmoi)"
        printf '  Using chezmoi at %s.\n' "$chezmoi_bin"
    else
        command -v curl >/dev/null 2>&1 || die 'curl is required to install chezmoi.'
        printf '  Installing chezmoi with its official installer.\n'
        mkdir -p "$HOME/.local/bin"
        curl -fsLS https://get.chezmoi.io | sh -s -- -b "$HOME/.local/bin"
        chezmoi_bin="$HOME/.local/bin/chezmoi"
    fi
}

import_config() {
    printf '  Applying dotfiles from this checkout.\n'
    "$chezmoi_bin" --source "$repo_dir" init --apply
}

install_runtime() {
    command -v mise >/dev/null 2>&1 || die 'mise was not installed.'

    printf '  Installing runtimes declared in the mise config.\n'
    mise install
}

main() {
    run_stage 1 'Checking OS and prerequisites' check_os
    run_stage 2 'Installing shell and bootstrap packages' install_shell
    run_stage 3 'Ensuring chezmoi is installed' install_chezmoi
    run_stage 4 'Importing configuration with chezmoi' import_config
    run_stage 5 'Installing runtimes with mise' install_runtime
    printf '\nAll setup stages completed. Start zsh to use the installed shell configuration.\n'
}

main "$@"
