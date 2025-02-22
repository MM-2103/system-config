# -------------------------------------------------------------------
# Switch php and unlink the "default" version.
# -------------------------------------------------------------------
function switchphp() {
       # Custom Linux Aliases
       if [[ -f /usr/bin/php ]]; then
            sudo rm -rf /usr/bin/php
            sudo rm -rf /etc/php
            sudo rm -rf /usr/lib/modules/php
       fi
       sudo ln -s /usr/bin/php$1 /usr/bin/php
       sudo ln -s /etc/php$1 /etc/php
       sudo ln -s /usr/lib/modules/php$1 /usr/lib/modules/php
}

# -------------------------------------------------------------------
# Checks if phpunit is installed in vendor folder or if we should use global one.
# -------------------------------------------------------------------
function get_phpunit_install() {
    if [[ -f vendor/bin/pest ]]; then
        echo './vendor/bin/pest'
    elif [[ -f vendor/bin/paratest ]]; then
        echo './vendor/bin/paratest'
    elif [[ -f vendor/bin/phpunit ]]; then
        echo './vendor/bin/phpunit'
    else
        echo 'phpunit'
    fi
}

# -------------------------------------------------------------------
# Checks if phpstan is installed in vendor folder or if we should use global one.
# -------------------------------------------------------------------
function get_stan_install() {
    if [[ -f vendor/bin/phpstan ]]; then
        echo './vendor/bin/phpstan'    
    else
        echo 'phpstan'
    fi
}
