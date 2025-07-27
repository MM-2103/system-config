# Path
set -gx PATH "$HOME/.local/bin" "$HOME/go/bin" "$HOME/.composer/vendor/bin" "$HOME/.cargo/bin" "$HOME/.phpenv/bin" "$HOME/dotfiles/emacs/bin" $PATH

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
direnv hook fish | source

# Atuin
atuin init fish | source

# Starship
starship init fish | source
