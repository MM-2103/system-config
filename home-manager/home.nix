{ config, lib, pkgs, ... }:

{
  nixGL = {
    vulkan.enable = true;
    packages = pkgs.nixgl;
    defaultWrapper = "mesa";
    offloadWrapper = "nvidiaPrime";  
    installScripts = [ "mesa" "nvidiaPrime" ];
  };

  nixpkgs.config.allowUnfree = true;

  home.username = "mm-2103";
  home.homeDirectory = "/home/mm-2103";
  home.stateVersion = "25.05";

  home.packages = with pkgs; [
    lazygit
    lazydocker
    ansible-language-server
    antares
    eza
    protonvpn-gui
    sesh
    television
    umu-launcher
    evil-helix
    dysk
    thunderbird
    intelephense
    gimp3
    mako
    protonup-qt
    pandoc
    atuin
    texliveSmall
    sqlite
    typora
    dust
    tealdeer
    fish
    zoxide
    metasploit

    # Install Iosevka font
    # (nerdfonts.override { fonts = [ "Iosevka" ]; })

    # Packages that need OpenGL/Vulkan - wrapped automatically
    # (config.lib.nixGL.wrap zed-editor-fhs)

  ];

  home.file = {
    # ~/.config/ destinations
    # ".config/alacritty".source = ../dotfiles/alacritty;
    #    ".config/atuin".source = ../dotfiles/atuin;
   #".config/awesome".source = ../dotfiles/awesome;
   #".config/bspwm".source = ../dotfiles/bspwm;
   #".config/dunst".source = ../dotfiles/dunst;
   #".config/emacs".source = ../dotfiles/emacs;
   #".config/eza".source = ../dotfiles/eza;
   #".config/fastfetch".source = ../dotfiles/fastfetch;
   #".config/fish".source = ../dotfiles/fish;
   #".config/foot".source = ../dotfiles/foot;
   #".config/fuzzel".source = ../dotfiles/fuzzel;
   #".config/ghostty".source = ../dotfiles/ghostty;
   #".config/helix".source = ../dotfiles/helix;
   #".config/hypr".source = ../dotfiles/hypr;
   #".config/i3".source = ../dotfiles/i3;
   #".config/kitty".source = ../dotfiles/kitty;
   #".config/lazygit".source = ../dotfiles/lazygit;
   #".config/mako".source = ../dotfiles/mako;
   #".config/niri".source = ../dotfiles/niri;
   #".config/nix".source = ../dotfiles/nix;
   #".config/nushell".source = ../dotfiles/nushell;
   #".config/nvim".source = ../dotfiles/nvim;
   #".config/picom".source = ../dotfiles/picom;
   #".config/quickshell".source = ../dotfiles/quickshell;
   #".config/river".source = ../dotfiles/river;
   #".config/rofi".source = ../dotfiles/rofi;
   #".config/sesh".source = ../dotfiles/sesh;
   #".config/starship".source = ../dotfiles/starship;
   #".config/swaylock".source = ../dotfiles/swaylock;
   #".config/tmux".source = ../dotfiles/tmux;
   #".config/uwsm".source = ../dotfiles/uwsm;
   #".config/waybar".source = ../dotfiles/waybar;
   #".config/wayfire".source = ../dotfiles/wayfire;
   #".config/wezterm".source = ../dotfiles/wezterm;
   #".config/wireplumber".source = ../dotfiles/wireplumber;
   #".config/xmonad".source = ../dotfiles/xmonad;
   #".config/zsh".source = ../dotfiles/zsh;

    # ~/ destinations (traditional locations)
    #".tmux.conf".source = ../dotfiles/tmate/tmate.conf;  # If you want tmate config as tmux
    
    # Scripts and other files
    # ".local/bin/dwm-autostart".source = ../dotfiles/dwm/autostart.sh;
    # ".local/bin/gnome-startup".source = ../dotfiles/gnome/startup.sh;
    # ".local/bin/plasma-autostart".source = ../dotfiles/plasma/autostart.sh;
    # ".local/bin/i3-autostart".source = ../dotfiles/i3/autostart.sh;

    # Distrobox images (if you want them accessible)
    # ".local/share/distrobox-images".source = ../dotfiles/distrobox-images;
  };

  home.sessionVariables = {
    EDITOR = "nvim";
  };

  programs = {
    home-manager.enable = true;

    git = {
      enable = true;
      userName = "mm-2103";
      userEmail = "mohsen.menem@protonmail.com";
    };

    starship.enable = true;

    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };

  fonts.fontconfig = {
    enable = true;
    defaultFonts = {
      monospace = [ "Iosevka Nerd Font Mono" ];
    };
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common = {
      default = [ "gtk" ];
      "org.freedesktop.impl.portal.Secret" = [ "kwalletd6" ];
    };
  };
}
