# mise
if (( $+commands[mise] )); then
    eval "$(mise activate zsh)"
fi

# Starship
if (( $+commands[starship] )); then
    eval "$(starship init zsh)"
fi