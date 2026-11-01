# History
HISTFILE="$XDG_STATE_HOME/zsh/history"
[[ -d "${HISTFILE:h}" ]] || command mkdir -p "${HISTFILE:h}"
HISTSIZE=50000
SAVEHIST=50000

setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt INC_APPEND_HISTORY

# Allow comments in interactive commands.
setopt INTERACTIVE_COMMENTS
