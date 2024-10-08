if status is-interactive

# Functions
	
## Make all dots into cd ../
function multicd
	echo cd (string repeat -n (math (string length -- $argv[1]) - 1) ../)
end

## Change prompt color in SSH
if set -q SSH_TTY
  set -g fish_color_host brred
end

# Abbreviations
abbr --add dotdot --regex '^\.\.+$' --function multicd
abbr --add :q exit
abbr --add nixupdate "sudo nixos-rebuild switch --flake /etc/nixos#default"
abbr --add nixedit "sudoe nvim /etc/nixos/configuration.nix"

# PHP
abbr --add art "php artisan"
abbr --add arts "php artisan serve"
abbr --add artg "php artisan | grep"

# Aliases
alias sudo="sudo "
alias sudoe="sudo -E "

alias protontricks="flatpak run com.github.Matoking.protontricks"
alias protontricks-launch="flatpak run --command=protontricks-launch com.github.Matoking.protontricks"

alias nvidia-status="cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status"

alias suspend="systemctl suspend"

alias vim="nvim"
alias vi="nvim"

alias ll="eza -l"
alias l="eza -l"
alias ls="eza"

alias cat="bat"

end

# pnpm
set -gx PNPM_HOME "/home/mm-2103/.local/share/pnpm"
if not string match -q -- $PNPM_HOME $PATH
  set -gx PATH "$PNPM_HOME" $PATH
end
# pnpm end

set -gx PATH "/home/mm-2103/.local/bin" $PATH

# Zoxide
zoxide init fish | source

# fnm
fnm env --use-on-cd --shell fish | source

# Starship
starship init fish | source
