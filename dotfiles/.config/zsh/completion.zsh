# Completion behavior
export ZSH_COMPDUMP="$XDG_CACHE_HOME/zsh/zcompdump"
[[ -d "${ZSH_COMPDUMP:h}" ]] || command mkdir -p "${ZSH_COMPDUMP:h}"

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Za-z}'

autoload -Uz compinit
compinit -d "$ZSH_COMPDUMP"
