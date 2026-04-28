# Path
set -gx PATH "$HOME/.local/bin" "$HOME/go/bin" "$HOME/.config/composer/vendor/bin" "$HOME/.cargo/bin" "$HOME/.phpenv/bin" "$HOME/dotfiles/emacs/bin" $PATH

# Zoxide
zoxide init fish | source

# Vi mode
fish_vi_key_bindings

# Neovim as manpager
set -x MANPAGER "nvim +Man!"

# Default Editor
set EDITOR "nvim"                               # $EDITOR use Emacs in terminal

# Export env variables
if test -f ~/dotfiles/fish/conf.d/env.fish
    source ~/dotfiles/fish/conf.d/env.fish
end

# Direnv
# direnv hook fish | source

# Atuin
atuin init fish | sed 's/-k up/up/' | source

# Starship
starship init fish | source

# Added by LM Studio CLI (lms)
set -gx PATH $PATH /home/mm-2103/.lmstudio/bin
# End of LM Studio CLI section

