function switchphp
        if test -f /usr/bin/php
            sudo rm /usr/bin/php
            sudo rm -rf /etc/php
            sudo rm -rf /usr/lib/php/modules
        end

        sudo ln -s /usr/bin/php$argv[1] /usr/bin/php
        sudo ln -s /etc/php$argv[1] /etc/php
        sudo ln -s /usr/lib/php$argv[1] /usr/lib/php
end


