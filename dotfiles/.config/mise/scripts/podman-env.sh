#!/usr/bin/env bash

# Configures Podman's Docker-compatible API socket for tools such as k3d.
# - On Linux, enables the rootless Podman systemd socket.
# - On macOS, discovers the host-side socket exposed by Podman Machine.
# Sourced by mise to provide a consistent Docker API environment across both OSes.

podman_socket_linux() {
    [[ -n "${XDG_RUNTIME_DIR:-}" ]] || return 1
    command -v systemctl >/dev/null 2>&1 || return 1

    # Enable and start the rootless Podman socket via systemd.
    systemctl --user enable --now podman.socket >/dev/null 2>&1 || return 1

    printf '%s\n' "${XDG_RUNTIME_DIR}/podman/podman.sock"
}

podman_socket_darwin() {
    # Discover the host-side socket exposed by Podman Machine.
    podman machine inspect \
        --format '{{.ConnectionInfo.PodmanSocket.Path}}' \
        2>/dev/null
}

unset DOCKER_HOST DOCKER_SOCK

if command -v podman >/dev/null 2>&1; then
    case "$(uname -s)" in
        Linux)
            socket="$(podman_socket_linux)" || socket=""
            ;;
        Darwin)
            socket="$(podman_socket_darwin)" || socket=""
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

unset -f podman_socket_linux podman_socket_darwin
