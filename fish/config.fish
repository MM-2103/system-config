if status is-interactive

# Functions
	
## Make all dots into cd ../
function multicd
    echo cd (string repeat -n (math (string length -- $argv[1]) - 1) ../)
end

function take
    mkdir -p $argv && cd $argv
end

# Function to extract files
function extract
    echo Extracting $argv ...
    if test -f $argv[1]
        switch $argv[1]
            case '*.tar.bz2'
                tar xjf $argv[1]
            case '*.tar.gz'
                tar xzf $argv[1]
            case '*.bz2'
                bunzip2 $argv[1]
            case '*.rar'
                tar xzf $argv[1]
            case '*.gz'
                gunzip $argv[1]
            case '*.tar'
                tar xf $argv[1]
            case '*.tbz2'
                tar xjf $argv[1]
            case '*.tgz'
                tar xzf $argv[1]
            case '*.zip'
                unzip $argv[1]
            case '*.Z'
                uncompress $argv[1]
            case '*.7z'
                7z x $argv[1]
            case '*'
                echo "'$argv[1]' cannot be extracted via extract()"
        end
    else
        echo "'$argv[1]' is not a valid file"
    end
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

alias vim="nvim"
alias vi="nvim"

alias ll="eza -l"
alias l="eza -l"
alias ls="eza"

alias cat="bat"

alias dotfiles="cd ~/dotfiles && vim"


alias t='sesh connect $(sesh list -c | fzf --height 40% --border)'
end

# pnpm
set -gx PNPM_HOME "/home/mm-2103/.local/share/pnpm"
if not string match -q -- $PNPM_HOME $PATH
  set -gx PATH "$PNPM_HOME" $PATH
end
# pnpm end

set -gx PATH "/home/mm-2103/.local/bin" "/home/mm-2103/go/bin" $PATH

# Zoxide
zoxide init fish | source

# fnm
fnm env --use-on-cd --shell fish | source

# Starship
starship init fish | source
