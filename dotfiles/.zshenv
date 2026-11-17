# XDG Base Directories
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
export XDG_BIN_HOME="${XDG_BIN_HOME:-$HOME/.local/bin}"
export XDG_OPT_HOME="${XDG_OPT_HOME:-$HOME/.local/opt}"

# System
export LESSHISTFILE="$XDG_STATE_HOME/less"

# Keep user-installed executables discoverable
typeset -U path
path=("$XDG_BIN_HOME" "$HOME/.local/bin" $path)
export PATH

# Reuse the agent started by refresh-ssh-keys.sh, preserving desktop/forwarded agents.
if [[ -z "${SSH_AUTH_SOCK:-}" && -S "$HOME/.ssh/agent.sock" ]]; then
    export SSH_AUTH_SOCK="$HOME/.ssh/agent.sock"
fi
