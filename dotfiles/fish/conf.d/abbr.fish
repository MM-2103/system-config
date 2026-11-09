abbr --add dcrm 'docker rm $(docker ps -a -q)'
abbr --add dcirm 'docker rmi $(docker images -q)'

abbr --add dotdot --regex '^\.\.+$' --function multicd
abbr --add :q exit
abbr --add nixupdate "sudo nixos-rebuild switch --flake /etc/nixos#default"
abbr --add nixedit "sudoe nvim /etc/nixos/configuration.nix"

abbr --add weather "curl wttr.in"

abbr --add home-mosh 'mosh -p 60000:60010 mm-2103-pc -- tmux new -A -s work'

# PHP
# abbr --add art "php artisan"
# abbr --add arts "php artisan serve"
# abbr --add artg "php artisan | grep"
# abbr --add artt "php artisan test"

