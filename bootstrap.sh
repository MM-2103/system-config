#!/usr/bin/env bash
# bootstrap.sh

set -e # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Detect distribution
detect_distro() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        DISTRO=$ID
    else
        error "Cannot detect distribution"
    fi

    case $DISTRO in
    fedora)
        PACKAGE_MANAGER="dnf"
        ;;
    arch)
        PACKAGE_MANAGER="pacman"
        ;;
    *)
        error "Unsupported distribution: $DISTRO"
        ;;
    esac

    log "Detected: $DISTRO using $PACKAGE_MANAGER"
}

# Install Paru on Arch if not present
install_paru() {
    if command -v paru &>/dev/null; then
        log "Paru already installed"
        return
    fi

    log "Installing Paru AUR helper..."
    sudo pacman -S --needed --noconfirm base-devel git

    cd /tmp
    git clone https://aur.archlinux.org/paru.git
    cd paru
    makepkg -si --noconfirm
    cd ~
    rm -rf /tmp/paru

    log "Paru installed successfully"
}

# Install Ansible
install_ansible() {
    if command -v ansible-playbook &>/dev/null; then
        log "Ansible already installed"
        return
    fi

    log "Installing Ansible..."
    case $DISTRO in
    fedora)
        sudo dnf install -y ansible
        ;;
    arch)
        if command -v paru &>/dev/null; then
            paru -S --noconfirm ansible
        else
            sudo pacman -S --noconfirm ansible
        fi
        ;;
    esac

    log "Ansible installed successfully"
}

# Install Nix
install_nix() {
    if command -v nix &>/dev/null; then
        log "Nix already installed"
        return
    fi

    log "Installing Nix..."
    sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --daemon

    # Source nix for current session
    if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
        source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    fi

    log "Nix installed successfully"
}

# Setup system config repo
setup_repo() {
    REPO_DIR="$HOME/system-config"

    if [[ -d "$REPO_DIR" ]]; then
        log "System config repo already exists, pulling latest..."
        cd "$REPO_DIR"
        git pull
    else
        log "Cloning system config repo..."
        git clone https://github.com/MM-2103/dotfiles "$REPO_DIR"
    fi

    cd "$REPO_DIR"
}

# Install home-manager
install_home_manager() {
    log "Setting up home-manager..."

    # Enable flakes
    mkdir -p ~/.config/nix
    echo "experimental-features = nix-command flakes" >~/.config/nix/nix.conf

    # Bootstrap home-manager
    nix run home-manager/master -- switch --flake ~/.config/home-manager#mm-2103 || {
        warn "Home-manager bootstrap failed, will try after ansible setup"
    }
}

# Main execution
main() {
    log "🚀 Starting system bootstrap..."

    # Basic setup
    detect_distro

    # Install core tools
    if [[ $DISTRO == "arch" ]]; then
        install_paru
    fi

    install_ansible
    install_nix

    # Setup repo
    setup_repo

    # Run Ansible system setup
    log "🔧 Running system setup with Ansible..."
    ansible-playbook ansible/playbooks/system.yml --ask-become-pass

    # Run Ansible dotfiles setup
    log "🏠 Setting up dotfiles with Ansible..."
    ansible-playbook ansible/playbooks/dotfiles.yml

    # Setup home-manager
    install_home_manager

    # Final home-manager setup
    log "🏠 Finalizing home-manager setup..."
    home-manager switch --flake ~/.config/home-manager#mm-2103

    log "✅ Bootstrap complete!"
    log "Please restart your shell or run: source ~/.bashrc"
}

# Run main function
main "$@"
