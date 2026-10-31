# Completion behavior
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Za-z}'

autoload -Uz compinit
compinit
