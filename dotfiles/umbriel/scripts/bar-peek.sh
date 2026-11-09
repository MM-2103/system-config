#!/bin/sh
# Peek the Noctalia bar on the focused monitor, like the taskbar in Plasma or
# Windows. Bound to a bare Super tap in keybinds.toml.
#
# Umbriel keeps top-layer surfaces under fullscreen windows, so the first tap
# lifts the bar to the overlay layer and pauses its auto-hide, which would
# otherwise hide it as soon as the pointer leaves. The second tap restores
# both. "smart" and "top" mirror dotfiles/noctalia/config.toml.
#
# Noctalia doesn't report per-monitor bar state, so a file in
# $XDG_RUNTIME_DIR remembers which monitors are peeked. If Noctalia restarts
# mid-peek, the next tap only restores and the one after peeks again.

output=$(umbriel outputs --json | jq -r '.[] | select(.focused) | .name')
[ -n "$output" ] || exit 1

state="${XDG_RUNTIME_DIR:-/tmp}/umbriel-bar-peek-$output"

if [ -e "$state" ]; then
  rm -f "$state"
  noctalia msg bar-auto-hide-set smart "$output"
  noctalia msg bar-layer-set top "$output"
else
  touch "$state"
  noctalia msg bar-layer-set overlay "$output"
  noctalia msg bar-auto-hide-set off "$output"
fi
