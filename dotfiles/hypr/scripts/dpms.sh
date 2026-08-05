#!/usr/bin/env bash
# Turn the monitors off/on, whichever compositor is running.
#
# ~/.config/hypr/hypridle.conf is shared by the niri and Hyprland sessions
# (both spawn hypridle, and both read this same directory), so it cannot
# hardcode `niri msg` or `hyprctl`. This script picks the right one.
#
# Usage: dpms.sh on|off

set -euo pipefail

action="${1:-}"
case "$action" in
    on|off) ;;
    *)
        printf 'usage: %s on|off\n' "${0##*/}" >&2
        exit 2
        ;;
esac

if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    exec hyprctl dispatch "hl.dsp.dpms({ action = \"${action}\" })"
elif [[ -n "${NIRI_SOCKET:-}" ]]; then
    exec niri msg action "power-${action}-monitors"
else
    printf '%s: no supported compositor detected\n' "${0##*/}" >&2
    exit 1
fi
