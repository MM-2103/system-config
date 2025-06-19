function rmrf
    if not set -q argv[1]
        echo "Usage: rmrf <path> [path...]"
        return 1
    end

    # Safety check for dangerous paths
    for path in $argv
        set -l resolved_path (realpath "$path" 2>/dev/null || echo "$path")
        if string match -q "/" "$resolved_path" || string match -q "$HOME" "$resolved_path"
            echo "Error: Refusing to delete critical path '$path'"
            return 1
        end
    end

    for path in $argv
        if test -e "$path"
            read -P "Delete '$path'? (y/n): " -l response
            if test (string lower $response) = y
                rm -rf "$path"
                echo "Deleted '$path'"
            else
                echo "Skipped '$path'"
            end
        else
            echo "Error: '$path' does not exist"
        end
    end
end
