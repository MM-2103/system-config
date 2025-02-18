function build -d "Install and build project dependencies"
    set -l usage (printf "\033[33mUsage:\033[0m build [-h] [-f] [-i] [-p] [-c] [-a]\n\n\033[33mOptions:\033[0m\n    \033[92m-h\033[0m  Show this help text.\n    \033[92m-f\033[0m  Fresh install, remove vendor/node_modules/target and install everything.\n    \033[92m-i\033[0m  Install everything.\n    \033[92m-p\033[0m  Install everything as on production.\n    \033[92m-c\033[0m  Install only composer dependencies.\n    \033[92m-a\033[0m  Install only npm packages.\n")

    set -l options h f i p c a
    if not argparse -n (status function) $options -- $argv 2>/dev/null
        echo -e $usage
        return 1
    end

    if set -q _flag_h
        echo -e $usage
        return 1
    end

    # Initialize state variables
    set -l refresh   false
    set -l production false
    set -l package_build    true
    set -l composer_install true
    set -l cargo_install    true
    set -l package_install  true

    # Process flags
    if set -q _flag_p
        set refresh   true
        set production true
    end

    if set -q _flag_f
        set refresh true
    end

    if set -q _flag_i
        set package_build false
    end

    if set -q _flag_c
        set package_install false
        set package_build   false
    end

    if set -q _flag_a
        set composer_install false
        set package_install  false
    end

    # Configure build arguments
    set -l package_arguments dev
    set -l composer_arguments
    set -l cargo_arguments

    if test "$production" = true
        set composer_arguments --no-dev
        set package_arguments prod
        set cargo_arguments    --release
        echo "Running as on production"
    end

    # Clean existing dependencies if refreshing
    if test "$refresh" = true
        # Composer vendor directory
        if test -d "$PWD/vendor" -a "$composer_install" = true
            rm -rf "$PWD/vendor"
            echo "Removed 'vendor' directory"
        end

        # Node modules directory
        if test -d "$PWD/node_modules" -a "$package_build" = true
            rm -rf "$PWD/node_modules"
            echo "Removed 'node_modules' directory"
        end

        # Cargo target directory
        if test -d "$PWD/target" -a "$cargo_install" = true
            rm -rf "$PWD/target"
            echo "Removed 'target' directory"
        end
    end

    # Composer installation
    if test -f composer.json -a "$composer_install" = true
        composer install $composer_arguments
    end

    # Frontend package management
    if test -f package.json -a "$package_build" = true
        set -l package_manager npm
        if test -f yarn.lock
            set package_manager yarn
        end

        if test "$package_install" = true -o "$refresh" = true
            $package_manager install
        end

        echo "Building with: $package_manager"
        $package_manager run $package_arguments
    end

    # Cargo build
    if test -f Cargo.toml -a "$cargo_install" = true
        cargo build $cargo_arguments
    end
end

function watch_project_assets -d "Watch and rebuild project assets"
    if test -f package.json
        set -l package_manager npm

        # Prefer Bun if available
        if command -q bun
            set package_manager bun
        else if test -f yarn.lock
            set package_manager yarn
        end

        $package_manager run watch
    end
end
