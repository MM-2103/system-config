#!/bin/bash
sleep 3
autorandr -c &
dunst -config ~/.config/dunst/dunstrc &
picom --config ~/.config/picom/picom.conf &
/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
sleep 1
nitrogen --restore &
dbus-update-activation-environment --all &
