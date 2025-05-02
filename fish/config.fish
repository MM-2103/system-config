# Path
set -gx PATH "$HOME/.local/bin" "$HOME/go/bin" "$HOME/.composer/vendor/bin" "$HOME/.cargo/bin" "$HOME/.phpenv/bin" "$HOME/dotfiles/emacs/bin" $PATH

# Zoxide
zoxide init fish | source

# fnm
fnm env --use-on-cd --shell fish | source

# Phpenv
# status --is-interactive; and source (phpenv init -|psub)

### "nvim" as manpager
set -x MANPAGER "nvim +Man!"

### EXPORT ###
#set TERM "xterm-256color"                         # Sets the terminal type
set EDITOR "nvim''"                               # $EDITOR use Emacs in terminal

set -gx OPENROUTER_API_KEY "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"

if status is-interactive
    colorscript random
end

# Starship
starship init fish | source

