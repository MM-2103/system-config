function update
    # Check for the standard /etc/os-release file
    if not test -f /etc/os-release
        echo "Error: /etc/os-release not found. Cannot determine distribution." >&2
        return 1
    end

    # Parse the ID from the file. This is the correct, shell-agnostic way.
    # - grep '^ID=' finds the line starting with "ID="
    # - cut -d'=' -f2 splits the line by '=' and takes the second field
    set distro_id (grep '^ID=' /etc/os-release | cut -d'=' -f2)

    # The value might have quotes, so let's remove them.
    set distro_id (string trim -c '"' $distro_id)

    switch $distro_id
        case fedora
            sudo dnf update
        case arch
            paru
        case ubuntu debian
            sudo apt update && sudo apt upgrade -y
        case '*'
            # Get the pretty name for a better error message
            set pretty_name (grep '^PRETTY_NAME=' /etc/os-release | cut -d'=' -f2 | string trim -c '"')
            echo "Distribution '$pretty_name' (ID='$distro_id') is not configured in the update function." >&2
            return 1
    end
end
