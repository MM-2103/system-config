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

if status is-interactive
    colorscript random
end

# Direnv
direnv hook fish | source

# Starship
starship init fish | source

