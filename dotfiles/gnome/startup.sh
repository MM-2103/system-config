!#/usr/bin/env bash

# Disable Gnome default Super+p keyboard shortcut
gsettings set org.gnome.mutter.keybindings switch-monitor "['XF86Display']"
