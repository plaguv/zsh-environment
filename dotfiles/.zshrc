# Interactive configuration only; keep non-interactive shells lightweight.
[[ -o interactive ]] || return

source "$XDG_CONFIG_HOME/zsh/tools.zsh"
source "$XDG_CONFIG_HOME/zsh/completion.zsh"
source "$XDG_CONFIG_HOME/zsh/history.zsh"
source "$XDG_CONFIG_HOME/zsh/keybind.zsh"
source "$XDG_CONFIG_HOME/zsh/aliases.zsh"

# Automatic system wide keychain agent for ssh- and gpg keys
if (( $+commands[keychain] )); then
    if [[ $(keychain --version 2>&1) == *"3."* ]]; then
        eval "$(keychain add --eval --quiet)"
    else
        eval "$(keychain --eval --quiet)"
    fi
fi
