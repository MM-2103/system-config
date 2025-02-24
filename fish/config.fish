set -gx PATH "$HOME/.local/bin" "$HOME/go/bin" "$HOME/.composer/vendor/bin" "$HOME/.cargo/bin" $PATH

# Zoxide
zoxide init fish | source

# fnm
fnm env --use-on-cd --shell fish | source

# Starship
starship init fish | source
