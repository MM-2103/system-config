#!/usr/bin/env bash
# Open the clipboard history picker.
#
# Kept as a thin wrapper for parity with dotfiles/niri/scripts/cliphist.sh and
# for invoking from outside a keybind. The Mod+V bind in lua/binds.lua calls
# this IPC directly, so this script is not on the hot path.
#
# The old implementation piped `cliphist list` through hyprlauncher --dmenu;
# quickshell-bar's clipboard popup replaced that (it reads cliphist itself).

exec qs -p /home/mm-2103/projects/personal/quickshell-bar ipc call clipboard open
