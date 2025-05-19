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
