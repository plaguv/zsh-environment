if (( $+commands[eza] )); then
    alias lz='eza --long --all --icons --group-directories-first'
fi

if (( $+commands[fdfind] && ! $+commands[fd] )); then
    alias fd=fdfind
fi

if (( $+commands[batcat] && ! $+commands[bat] )); then
    alias bat=batcat
fi
