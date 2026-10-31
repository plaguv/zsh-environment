# Use eza when available, then the native macOS or GNU ls options.
if (( $+commands[eza] )); then
    alias ls='eza --group-directories-first'
elif [[ "$OSTYPE" == darwin* ]]; then
    alias ls='ls -G'
else
    alias ls='ls --color=auto --group-directories-first'
fi
