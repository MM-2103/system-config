def t [] {
    sesh connect (sesh list | fzf-tmux -p 55%,60%
    --no-sort --border-label ' sesh ' --prompt '⚡  '
    --header '  ^a all ^t tmux ^g configs ^x zoxide ^d tmux kill ^f find'
    --bind 'tab:down,btab:up'
    --bind 'ctrl-a:change-prompt(⚡  )+reload(sesh list)'
    --bind 'ctrl-t:change-prompt(🪟  )+reload(sesh list -t)'
    --bind 'ctrl-g:change-prompt(⚙️  )+reload(sesh list -c)'
    --bind 'ctrl-x:change-prompt(📁  )+reload(sesh list -z)'
    --bind 'ctrl-f:change-prompt(🔎  )+reload(fd -H -d 2 -t d -E .Trash . ~)'
    --bind 'ctrl-d:execute(tmux kill-session -t {})+change-prompt(⚡  )+reload(sesh list)')
}


def extract [file: string] {
    print $"Extracting ($file) ..."
    if ($file | path exists) and ($file | path type) == 'file' {
        let extension = ($file | str downcase | path parse | get extension)
        match $extension {
            'tar.bz2' => { tar xjf $file },
            'tar.gz' => { tar xzf $file },
            'bz2' => { bunzip2 $file },
            'rar' => { tar xzf $file },
            'gz' => { gunzip $file },
            'tar' => { tar xf $file },
            'tbz2' => { tar xjf $file },
            'tgz' => { tar xzf $file },
            'zip' => { unzip $file },
            'z' => { uncompress $file },
            '7z' => { 7z x $file },
            'lz4' => { lz4 -dc $file | tar -xv },
            _ => { print $"'($file)' cannot be extracted via extract()" }
        }
    } else {
        print $"'($file)' is not a valid file"
    }
}

def --env new_project [] {
    let name = (input "Enter project name: " | str trim)
    if ($name | is-empty) {
        print "Error: Project name cannot be empty"
        return
    }
    let dir = $"($env.HOME)/projects/personal/($name)"
    print $"Creating directory: ($dir)"
    mkdir $dir
    if not ($dir | path exists) {
        print $"Error: Failed to create directory ($dir)"
        return
    }
    print $"Changing to directory: ($dir)"
    cd $dir
}

# Check current directory asset building dependencies, install and build them
def build [
    --help(-h)      # Show help text
    --fresh(-f)     # Fresh install (remove dependencies)
    --install(-i)   # Install without building
    --production(-p) # Production mode (implies fresh)
    --composer(-c)  # Only composer dependencies
    --npm(-a)       # Only npm packages
] {
    let usage = $"
    (ansi yellow)Usage:(ansi reset) build [flags]

    (ansi yellow)Options:(ansi reset)
        (ansi green)-h, --help(ansi reset)    Show this help text.
        (ansi green)-f, --fresh(ansi reset)   Fresh install: Remove vendor/node_modules/target
        (ansi green)-i, --install(ansi reset) Install dependencies without building
        (ansi green)-p, --production(ansi reset) Production mode (fresh install + production settings)
        (ansi green)-c, --composer(ansi reset) Only install composer dependencies
        (ansi green)-a, --npm(ansi reset)     Only install npm packages
    "

    if $help {
        print $usage
        return
    }

    # Initialize state variables
    mut composer_install = true
    mut cargo_install = true
    mut package_install = true
    mut package_build = true
    mut production = false
    mut refresh = false

    # Process flags
    if $fresh { $refresh = true }
    if $install { $package_build = false }
    if $production {
        $refresh = true
        $production = true
    }
    if $composer {
        $package_install = false
        $package_build = false
    }
    if $npm {
        $composer_install = false
        $package_install = false
    }

    # Set build arguments
    mut composer_args = []
    mut cargo_args = []
    mut package_args = "dev"

    if $production {
        $composer_args = ["--no-dev"]
        $package_args = "prod"
        $cargo_args = ["--release"]
        print "Running as on production"
    }

    # Fresh install cleanup
    if $refresh {
        if $composer_install and ("vendor" | path exists) {
            rm -rf vendor
            print "Removed 'vendor' directory"
        }
        
        if $package_build and ("node_modules" | path exists) {
            rm -rf node_modules
            print "Removed 'node_modules' directory"
        }
        
        if $cargo_install and ("target" | path exists) {
            rm -rf target
            print "Removed 'target' directory"
        }
    }

    # Composer installation
    if ("composer.json" | path exists) and $composer_install {
        run-external composer "install" ...$composer_args
    }

    # NPM/Yarn installation and build
    if ("package.json" | path exists) and $package_build {
        let package_manager = if ("yarn.lock" | path exists) { "yarn" } else { "npm" }
        
        if $package_install or $refresh {
            run-external $package_manager "install"
        }
        
        print $"Building with: ($package_manager)"
        run-external $package_manager "run" $package_args
    }

    # Cargo build
    if ("Cargo.toml" | path exists) and $cargo_install {
        run-external cargo "build" ...$cargo_args
    }
}

# Watch project assets
def watch-project-assets [] {
    if ("package.json" | path exists) {
        let package_manager = if (which bun | is-empty) {
            if ("yarn.lock" | path exists) { "yarn" } else { "npm" }
        } else {
            "bun"
        }
        
        run-external $package_manager "run" "watch"
    }
}
