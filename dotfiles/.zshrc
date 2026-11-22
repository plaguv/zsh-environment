# Interactive configuration only; keep non-interactive shells lightweight.
[[ -o interactive ]] || return

source "$XDG_CONFIG_HOME/zsh/tools.zsh"
source "$XDG_CONFIG_HOME/zsh/completion.zsh"
source "$XDG_CONFIG_HOME/zsh/history.zsh"
source "$XDG_CONFIG_HOME/zsh/keybind.zsh"
source "$XDG_CONFIG_HOME/zsh/aliases.zsh"

# Automatic system wide keychain agent for ssh- and gpg keys
if (( $+commands[keychain] )); then
    eval "$(keychain --eval --quiet --absolute --dir "$XDG_STATE_HOME/keychain")"
fi
