{ config, lib, pkgs, ... }:

{
  # -------- Tell Home-Manager we are NOT on NixOS --------------------
  targets.genericLinux.enable = true;

  # -------- Basic user metadata -------------------------------------
  home.username      = "mm-2103";
  home.homeDirectory = "/home/mm-2103";
  home.stateVersion  = "25.11";

  # If you want unfree software from Nixpkgs
  nixpkgs.config.allowUnfree = true;

  # ------------------------------------------------------------------
  # Packages (formerly both environment.systemPackages + home.packages)
  # ------------------------------------------------------------------
 home.packages = with pkgs; [
     lazygit
    # lazydocker
     eza
    # protonvpn-gui
     sesh
    # evil-helix
     dysk
    # pandoc
     atuin
     dust
     tealdeer
     zoxide
     jq
     yq
     rustup
     bat
     fzf
     gh
     ripgrep
     git-lfs
     tmux
     lua51Packages.lua
     luajitPackages.luarocks_bootstrap
     go
     php
     php84Packages.composer
     nodejs_24
     python314
     gcc
     tree-sitter
     cliphist
     brightnessctl
     nerd-fonts.iosevka
     hypridle
     # Provides hyprland-dialog, which Hyprland shells out to for its error and
     # update popups. Kept here rather than as an RPM so it does not have to be
     # rebuilt against every Hyprland upgrade; Hyprland finds it because
     # ~/.nix-profile/bin is already on its PATH.
     #
     # QT_QUICK_BACKEND=software is required, not cosmetic. hyprland-dialog is
     # a Qt Quick app, and a nix-built GPU application cannot reach Fedora's
     # graphics drivers on a non-NixOS host -- the nixGL problem. Unwrapped it
     # dies instantly with SIGABRT inside
     # QSGRenderLoop::handleContextCreationFailure(), which surfaced as
     # "Service Crash" notifications. hypridle and cliphist are unaffected
     # because they never touch the GPU.
     #
     # The variable is set ONLY on these binaries. It must never go in
     # environment.d: quickshell-bar is also Qt Quick and has to keep hardware
     # rendering.
     (symlinkJoin {
       name = "hyprland-qtutils-wrapped";
       paths = [ hyprland-qtutils ];
       nativeBuildInputs = [ makeWrapper ];
       postBuild = ''
         for b in "$out"/bin/*; do
           wrapProgram "$b" --set QT_QUICK_BACKEND software
         done
       '';
     })
     pamixer
     fastfetch
     wpscan
     metasploit
   ];

  # ------------------------------------------------------------------
  # Session-wide environment
  # ------------------------------------------------------------------
  #home.sessionVariables = {
 #   GTK_THEME            = "adw-gtk3-dark";
  #  QT_STYLE_OVERRIDE    = "breeze";
   # XDG_CURRENT_DESKTOP  = "gnome";
    #EDITOR               = "nvim";
  #};

  # ------------------------------------------------------------------
  # Qt platform theme for D-Bus / systemd-user-activated apps
  # ------------------------------------------------------------------
  # xdg-desktop-portal-kde derives the freedesktop appearance color-scheme
  # value from its own QApplication palette. That palette is only built
  # from kdeglobals when KDEPlasmaPlatformTheme6.so is loaded, which only
  # happens when QT_QPA_PLATFORMTHEME=kde is in the process environment.
  #
  # Under niri, the systemd user manager (which D-Bus-activates the
  # portal) doesn't inherit Plasma's per-session env. Setting the var in
  # environment.d makes the user manager — and every service it spawns —
  # see it. Without this, the kde portal returns prefer-light regardless
  # of kdeglobals contents, breaking dark-mode in Helium/Zen/etc.
  xdg.configFile."environment.d/50-qt-kde-theme.conf".text = ''
    QT_QPA_PLATFORMTHEME=kde
    XCURSOR_THEME=breeze_cursors
    XCURSOR_SIZE=24
  '';

  # ------------------------------------------------------------------
  # Theming
  # ------------------------------------------------------------------
 # gtk = {
 #   enable = true;
 #   theme = {
 #     name    = "adw-gtk3-dark";
  #    package = pkgs.adw-gtk3;
   # };
    #iconTheme = {
     # name    = "Adwaita";
    #  package = pkgs.adwaita-icon-theme;
   # };
  #};

  #qt = {
    #enable = true;
   # style.name = "breeze";
  #};

  # ------------------------------------------------------------------
  # MIME defaults
  # ------------------------------------------------------------------
 # xdg.mimeApps = {
 #   enable = true;
 #   defaultApplications = {
 #     "application/pdf"        = "org.kde.okular.desktop";
 #     "image/jpeg"             = "org.kde.gwenview.desktop";
 #     "image/png"              = "org.kde.gwenview.desktop";
 #     "inode/directory"        = "org.kde.dolphin.desktop";
 #     "video/mp4"              = "mpv.desktop";
 #     "video/x-matroska"       = "mpv.desktop";
 #     "x-scheme-handler/http"  = "zen.desktop";
 #     "x-scheme-handler/https" = "zen.desktop";
 #   };
 #   associations.added = {
 #     "application/pdf" = [ "org.kde.okular.desktop" ];
 #   };
 # };

  # ------------------------------------------------------------------
  # Dot-files (uncomment what you actually want to deploy)
  # ------------------------------------------------------------------
 # home.file = {
    # ".config/alacritty".source = ../dotfiles/alacritty;
  #};

  # ------------------------------------------------------------------
  # User-level programs
  # ------------------------------------------------------------------
  programs = {
     # Git config is hand-managed in ~/.gitconfig and ~/.gitconfig-school,
     # not generated here. Re-enabling this module would recreate the
     # read-only symlink at ~/.config/git/config and shadow those files.
     # git = {
     #   enable      = true;
     #   userName    = "mm-2103";
     #   userEmail   = "mohsen.menem@protonmail.com";
     #   extraConfig = {
     #     pull.rebase = true;
     #   };
     # };

    starship.enable = true;

    direnv = {
      enable           = true;
      nix-direnv.enable = true;
    };

   home-manager = {
     enable = true;
   };

   # emacs.enable   = true;
    #fish.enable    = true;
    #tmux.enable    = true;
    #fuzzel.enable  = true;
   # waybar.enable  = true;
  };

  # ------------------------------------------------------------------
  # User services
  # ------------------------------------------------------------------
  #services = {
   # cliphist = {
  #    enable       = true;
 #     allowImages  = true;
#    };
    # polkit-gnome.enable = true;
    # wlsunset = {
    #   enable   = true;
    #   sunrise  = "7:00";
    #   sunset   = "23:00";
    # };
  #};

  # ------------------------------------------------------------------
  # Fonts
  # ------------------------------------------------------------------
  fonts.fontconfig = {
   enable = true;
   defaultFonts = {
     monospace = [ "Iosevka Nerd Font Mono" ];
    # sansSerif = [ "IBM Plex Sans" "Noto Sans" ];
    # serif     = [ "IBM Plex Serif" "Noto Serif" ];
   };
 };

}
