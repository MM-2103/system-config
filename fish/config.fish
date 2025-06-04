# Path
set -gx PATH "$HOME/.local/bin" "$HOME/go/bin" "$HOME/.composer/vendor/bin" "$HOME/.cargo/bin" "$HOME/.phpenv/bin" "$HOME/dotfiles/emacs/bin" "/nix/store/g7yc135wzgh6abfwh074gd0bz6i5xzkh-nix-3.6.1/bin" $PATH

# Zoxide
zoxide init fish | source

# fnm
# fnm env --use-on-cd --shell fish | source

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

if test -f ~/dotfiles/fish/conf.d/env.fish
    source ~/dotfiles/fish/conf.d/env.fish
end

# Direnv
direnv hook fish | source

# Starship
starship init fish | source
