#!/usr/bin/env bash
xfce4-clipman &
nm-applet &
/usr/lib/polkit-kde-authentication-agent-1 &
kdeconnectd &
kdeconnect-indicator &
xss-lock -n /usr/lib/xsecurelock/dimmer -l -- xsecurelock &
xfce4-power-manager &
sleep 1
autorandr -c
feh --bg-scale ~/Pictures/Wallpaper/wallpaper-02-Ys--The-Oath-in-Felghana-2560x1440.jpg
picom --config ~/.config/picom/picom.conf &
