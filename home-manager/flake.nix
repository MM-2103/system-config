{
  description = "Home Manager configuration of mm-2103";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
          allowUnfreePredicate = (_: true);
        };
      };
    in
    {
      # Keyed as user@hostname on purpose. home-manager resolves a bare
      # `--flake .` by trying "$USER@$(hostname)" first and falling back to
      # "$USER", so this still works here but errors out on any other host
      # instead of silently applying laptop-only settings such as the
      # Fedora-specific hyprland-qtutils wrapper.
      homeConfigurations."mm-2103@MM-2103-Laptop" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [ ./home.nix ];
      };
    };
}
