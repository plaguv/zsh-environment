#!/usr/bin/env bash

set -o pipefail

# Configures Podman's Docker-compatible API socket for tools such as k3d.
# - On Linux, uses the rootless Podman socket under XDG_RUNTIME_DIR.
# - On macOS, discovers the host-side socket exposed by Podman Machine.
# Sourced by mise to provide a consistent Docker API environment across both OSes.

unset DOCKER_HOST DOCKER_SOCK

if command -v podman >/dev/null 2>&1; then
    case "$(uname -s)" in
        Linux)
            if [[ -n "${XDG_RUNTIME_DIR:-}" ]]; then
                socket="${XDG_RUNTIME_DIR}/podman/podman.sock"
            else
                socket=""
            fi
            ;;

        Darwin)
            socket="$(podman machine inspect \
                --format '{{.ConnectionInfo.PodmanSocket.Path}}' \
                2>/dev/null)" || socket=""
            ;;

        *)
            socket=""
            ;;
    esac

    if [[ -n "$socket" && -S "$socket" ]]; then
        export DOCKER_HOST="unix://${socket}"
        export DOCKER_SOCK="$socket"
    fi

    unset socket
fi
