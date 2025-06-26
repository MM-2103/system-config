alias cat="bat"

alias reload="exec fish"

alias dotfiles="cd ~/dotfiles && vim"

alias t="sesh connect (sesh list | fzf-tmux -p 55%,60% \
    --no-sort --border-label ' sesh ' --prompt '⚡  ' \
    --header '  ^a all ^t tmux ^g configs ^x zoxide ^d tmux kill ^f find' \
    --bind 'tab:down,btab:up' \
    --bind 'ctrl-a:change-prompt(⚡  )+reload(sesh list)' \
    --bind 'ctrl-t:change-prompt(🪟  )+reload(sesh list -t)' \
    --bind 'ctrl-g:change-prompt(⚙️  )+reload(sesh list -c)' \
    --bind 'ctrl-x:change-prompt(📁  )+reload(sesh list -z)' \
    --bind 'ctrl-f:change-prompt(🔎  )+reload(fd -H -d 2 -t d -E .Trash . ~)' \
    --bind 'ctrl-d:execute(tmux kill-session -t {})+change-prompt(⚡  )+reload(sesh list)')"

alias ll="eza -lah --icons --group-directories-first --git"
alias l="eza -l --icons"
alias ls="eza --icons --group-directories-first"
alias lt="eza --tree --icons"

alias vim="nvim"
alias vi="nvim"
alias nedit="nvim ~/dotfiles/nvim/"
alias code="nvim"
alias edit="nvim"

alias protontricks="flatpak run com.github.Matoking.protontricks"
alias protontricks-launch="flatpak run --command=protontricks-launch com.github.Matoking.protontricks"

alias nvidia-status="cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status"

alias zzz="systemctl suspend"

# Yt-dlp
alias ytv="yt-dlp -P "~/Videos/YT" -f bestvideo --add-metadata -o '%(title)s.%(ext)s'"
alias ytm="yt-dlp -P "~/Music" --throttled-rate 100K -f bestaudio --extract-audio --audio-format mp3 --embed-thumbnail --add-metadata -o '%(title)s.%(ext)s'"

# Nix
alias nixenv="echo 'use nix' > .envrc && direnv allow"
alias hm-switch="home-manager switch --flake ~/.config/home-manager#mm-2103"
