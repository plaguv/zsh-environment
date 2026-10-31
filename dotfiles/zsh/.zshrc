# Environment
[[ -f "$HOME/.local/bin/env" ]] && source "$HOME/.local/bin/env"

# History
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000

setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt INC_APPEND_HISTORY

# Options
setopt INTERACTIVE_COMMENTS

# Completion
autoload -Uz compinit
compinit

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Za-z}'

# Aliases
alias ls='ls --color=auto --group-directories-first'
alias cat='batcat'

# Sdkman
# export SDKMAN_DIR="${SDKMAN_DIR:-$HOME/.sdkman}"
# sdk() {
#    unfunction sdk
#    source "$SDKMAN_DIR/bin/sdkman-init.sh"
#    sdk "$@"
#}

# Prompt
eval "$(starship init zsh)"

