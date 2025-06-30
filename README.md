
# My Dotfiles

This repository contains my personal dotfiles, managed with [Nix Flakes](https://nixos.wiki/wiki/Flakes) and [Home Manager](https://nix-community.github.io/home-manager/).

## About

This setup allows me to have a reproducible and declarative configuration for my user environment. It includes:

-   Package management
-   Dotfile symlinking
-   Environment variables
-   And more!

## Usage

To apply the configuration, run the following command from the `home-manager` directory:

```bash
home-manager switch --flake .
```

To check for errors, run:

```bash
nix flake check
```
