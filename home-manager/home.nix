{ config, lib, pkgs, ... }:

{
  # -------- Tell Home-Manager we are NOT on NixOS --------------------
  targets.genericLinux.enable = true;

  # -------- Basic user metadata -------------------------------------
  home.username      = "mm-2103";
  home.homeDirectory = "/home/mm-2103";
  home.stateVersion  = "25.05";

  # If you want unfree software from Nixpkgs
  nixpkgs.config.allowUnfree = true;

  # ------------------------------------------------------------------
  # Packages (formerly both environment.systemPackages + home.packages)
  # ------------------------------------------------------------------
  home.packages = with pkgs; [
    lazygit
    lazydocker
    ansible-language-server
    eza
    protonvpn-gui
    sesh
    umu-launcher
    evil-helix
    dysk
    thunderbird
    intelephense
    gimp3
    protonup-qt
    pandoc
    atuin
    texliveSmall
    sqlite
    dust
    tealdeer
    zoxide
    metasploit
    jq
    yq
    rustup
    cliphist
    go
    php
    php84Packages.composer
    bun
    htop
    pamixer
    zellij
    btop
    cmake
    prettierd
    ruby
    git-crypt
    zig
    ly
    tmux
    fzf
    networkmanagerapplet
    nwg-look
    mangohud
    protonup
    git-extras
    delta
    keepassxc
    adw-gtk3
    libsForQt5.qt5ct
    gnome-themes-extra
    sgdboop
    fastfetch
    bat
    rubyPackages.solargraph
    typescript-language-server
    omnisharp-roslyn
    libreoffice-qt6-fresh
    gh
    ripgrep
    git-lfs
    pavucontrol
    tor-browser
    librewolf
    calibre
    rocmPackages.llvm.clang-tools
    unzip
    ibm-plex
  ];

  # ------------------------------------------------------------------
  # Session-wide environment
  # ------------------------------------------------------------------
  home.sessionVariables = {
    GTK_THEME            = "adw-gtk3-dark";
    QT_STYLE_OVERRIDE    = "breeze";
    XDG_CURRENT_DESKTOP  = "gnome";
    EDITOR               = "nvim";
  };

  # ------------------------------------------------------------------
  # Theming
  # ------------------------------------------------------------------
  gtk = {
    enable = true;
    theme = {
      name    = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };
    iconTheme = {
      name    = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };
  };

  qt = {
    enable = true;
    style.name = "breeze";
  };

  # ------------------------------------------------------------------
  # MIME defaults
  # ------------------------------------------------------------------
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "application/pdf"        = "org.kde.okular.desktop";
      "image/jpeg"             = "org.kde.gwenview.desktop";
      "image/png"              = "org.kde.gwenview.desktop";
      "inode/directory"        = "org.kde.dolphin.desktop";
      "video/mp4"              = "mpv.desktop";
      "video/x-matroska"       = "mpv.desktop";
      "x-scheme-handler/http"  = "zen.desktop";
      "x-scheme-handler/https" = "zen.desktop";
    };
    associations.added = {
      "application/pdf" = [ "org.kde.okular.desktop" ];
    };
  };

  # ------------------------------------------------------------------
  # Dot-files (uncomment what you actually want to deploy)
  # ------------------------------------------------------------------
  home.file = {
    # ".config/alacritty".source = ../dotfiles/alacritty;
  };

  # ------------------------------------------------------------------
  # User-level programs
  # ------------------------------------------------------------------
  programs = {
    # git = {
    #   enable      = true;
    #   userName    = "mm-2103";
    #   userEmail   = "mohsen.menem@protonmail.com";
    # };

    starship.enable = true;

    direnv = {
      enable           = true;
      nix-direnv.enable = true;
    };

   home-manager = {
     enable = true;
   };

    emacs.enable   = true;
    #fish.enable    = true;
    #tmux.enable    = true;
    fuzzel.enable  = true;
    waybar.enable  = true;
  };

  # ------------------------------------------------------------------
  # User services
  # ------------------------------------------------------------------
  services = {
    cliphist = {
      enable       = true;
      allowImages  = true;
    };
    # polkit-gnome.enable = true;
    # wlsunset = {
    #   enable   = true;
    #   sunrise  = "7:00";
    #   sunset   = "23:00";
    # };
  };

  # ------------------------------------------------------------------
  # Fonts
  # ------------------------------------------------------------------
  fonts.fontconfig = {
    enable = true;
    defaultFonts = {
      monospace = [ "Iosevka Nerd Font Mono" ];
      sansSerif = [ "IBM Plex Sans" "Noto Sans" ];
      serif     = [ "IBM Plex Serif" "Noto Serif" ];
    };
  };

}
