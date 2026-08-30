# Path
set -gx PATH "$HOME/.local/bin" "$HOME/go/bin" "$HOME/.config/composer/vendor/bin" "$HOME/.cargo/bin" "$HOME/.phpenv/bin" $PATH

# Zoxide
zoxide init fish | source

# Vi mode
fish_vi_key_bindings

# Neovim as manpager
set -x MANPAGER "nvim +Man!"

# Default Editor
set EDITOR "nvim"                               # $EDITOR use Emacs in terminal

# Machine-local env vars and API keys.
# Kept outside ~/.config/fish because that path is a symlink into the
# system-config git repo, so anything stored there would get committed.
# The file is optional and does not exist yet.
if test -f ~/.config/fish-local.fish
    source ~/.config/fish-local.fish
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

