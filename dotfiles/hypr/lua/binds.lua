-- lua/binds.lua -- keybinds
--
-- Migrated 1:1 from config.kdl `binds { ... }`. Where the old hyprland.conf
-- and the niri config disagreed, niri won. Hyprland-only additions (mouse
-- drag/resize, brightness keys) are marked as such.
--
-- Scrolling-layout messages are documented at
-- https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/#layout-messages

local mainMod = "SUPER" -- niri's "Mod"; Caps Lock is also Super via kb_options.

-- Per-monitor workspace blocks; owns the monitor -> id-block mapping used by
-- the numbered workspace binds further down.
local ws = require("workspaces")

local terminal = "ghostty"
local browser  = "zen-browser"

local QS_PATH = "/home/mm-2103/projects/personal/quickshell-bar"
local function qs(target, fn)
  return "qs -p " .. QS_PATH .. " ipc call " .. target .. " " .. fn
end

local SHOTS = "$HOME/Pictures/Screenshots"

-- ===========================================================================
-- Programs
-- ===========================================================================

hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal),
  { description = "Terminal" })
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(browser),
  { description = "Browser" })

-- quickshell-bar popups (same IPC as the niri session).
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd(qs("launcher", "open")),
  { description = "App launcher" })
hl.bind(mainMod .. " + semicolon", hl.dsp.exec_cmd(qs("launcher", "openEmoji")),
  { description = "Emoji picker" })
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd(qs("clipboard", "open")),
  { description = "Clipboard history" })

-- Addition: quickshell-bar exposes a settings panel over IPC that the niri
-- config never bound. Mod+S is unused in the niri keymap, so it is free.
hl.bind(mainMod .. " + S", hl.dsp.exec_cmd(qs("settings", "toggle")),
  { description = "Settings panel" })

-- ===========================================================================
-- Session
-- ===========================================================================

hl.bind(mainMod .. " + SHIFT + C", hl.dsp.window.close(),
  { description = "Close window" })

hl.bind(mainMod .. " + SHIFT + X", hl.dsp.exec_cmd(qs("lock", "open")),
  { description = "Lock session" })

-- niri: `quit`. This session is uwsm-managed, and the wiki is explicit that
-- uwsm users must NOT use hl.dsp.exit() -- it yanks the compositor out from
-- under its clients and breaks the ordered shutdown. `uwsm stop` brings the
-- graphical session down cleanly.
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exec_cmd("uwsm stop"),
  { description = "Quit Hyprland" })
hl.bind("CTRL + ALT + Delete", hl.dsp.exec_cmd("uwsm stop"),
  { description = "Quit Hyprland" })

-- niri: `power-off-monitors`.
--
-- The screens only come back because `misc.key_press_enables_dpms` and
-- `misc.mouse_move_enables_dpms` are set in lua/look.lua. Both default to
-- false, and with them off this bind is a one-way door -- see the note there.
--
-- That is also why the dispatch is deferred: the SUPER+SHIFT release is
-- itself a key event, so firing dpms off immediately means the release wakes
-- the panels a few milliseconds later. One second is enough slack for a
-- deliberate press; 500ms was not.
hl.bind(mainMod .. " + SHIFT + P", function()
  hl.timer(function()
    hl.dispatch(hl.dsp.dpms({ action = "off" }))
  end, { timeout = 1000, type = "oneshot" })
end, { description = "Power off monitors" })

-- niri: `toggle-keyboard-shortcuts-inhibit`. Hyprland has no such action, so
-- this is the documented equivalent: an empty submap that swallows everything
-- except the key that leaves it. `dont_inhibit` guarantees the escape hatch
-- works even if an app is inhibiting shortcuts.
hl.bind(mainMod .. " + Escape", hl.dsp.submap("passthrough"),
  { dont_inhibit = true, description = "Toggle shortcut passthrough" })
hl.define_submap("passthrough", function()
  hl.bind(mainMod .. " + Escape", hl.dsp.submap("reset"),
    { dont_inhibit = true, description = "Leave shortcut passthrough" })
end)

-- ===========================================================================
-- Focus -- columns and windows
-- ===========================================================================
-- In the scrolling layout, left/right moves between columns on the tape and
-- up/down moves between windows stacked inside the focused column. This is
-- exactly niri's model.
--
-- `layout("focus l/r")` is used rather than `focus({direction})` because it is
-- the scrolling-layout-aware version: it scrolls the tape and, per
-- `scrolling.wrap_focus = false`, stops at the ends instead of jumping to a
-- neighbouring monitor.

for _, k in ipairs({ { "left", "l" }, { "right", "r" } }) do
  hl.bind(mainMod .. " + " .. k[1], hl.dsp.layout("focus " .. k[2]))
end
hl.bind(mainMod .. " + H", hl.dsp.layout("focus l"), { description = "Focus column left" })
hl.bind(mainMod .. " + L", hl.dsp.layout("focus r"), { description = "Focus column right" })

hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "d" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "d" }), { description = "Focus window down" })
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "u" }), { description = "Focus window up" })

-- ===========================================================================
-- Move -- columns and windows
-- ===========================================================================
-- niri: Mod+Ctrl+<dir>. Left/right swaps whole columns along the tape;
-- up/down reorders windows within the focused column.

hl.bind(mainMod .. " + CTRL + left", hl.dsp.layout("swapcol l"))
hl.bind(mainMod .. " + CTRL + right", hl.dsp.layout("swapcol r"))
hl.bind(mainMod .. " + CTRL + H", hl.dsp.layout("swapcol l"), { description = "Move column left" })
hl.bind(mainMod .. " + CTRL + L", hl.dsp.layout("swapcol r"), { description = "Move column right" })

hl.bind(mainMod .. " + CTRL + down", hl.dsp.window.move({ direction = "d" }))
hl.bind(mainMod .. " + CTRL + up", hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + CTRL + J", hl.dsp.window.move({ direction = "d" }), { description = "Move window down" })
hl.bind(mainMod .. " + CTRL + K", hl.dsp.window.move({ direction = "u" }), { description = "Move window up" })

-- ===========================================================================
-- Column composition -- consume / expel
-- ===========================================================================

hl.bind(mainMod .. " + bracketleft", hl.dsp.layout("consume_or_expel prev"),
  { description = "Consume or expel window left" })
hl.bind(mainMod .. " + bracketright", hl.dsp.layout("consume_or_expel next"),
  { description = "Consume or expel window right" })

hl.bind(mainMod .. " + comma", hl.dsp.layout("consume"),
  { description = "Consume window into column" })
hl.bind(mainMod .. " + period", hl.dsp.layout("expel"),
  { description = "Expel window from column" })

-- ===========================================================================
-- Sizing
-- ===========================================================================

-- niri: `switch-preset-column-width`. Cycles scrolling.explicit_column_widths.
hl.bind(mainMod .. " + R", hl.dsp.layout("colresize +conf"),
  { description = "Cycle preset column widths" })

-- niri: `set-column-width "-10%" / "+10%"`.
hl.bind(mainMod .. " + minus", hl.dsp.layout("colresize -0.1"),
  { description = "Narrow column" })
hl.bind(mainMod .. " + equal", hl.dsp.layout("colresize +0.1"),
  { description = "Widen column" })

-- niri: `set-window-height "-10%" / "+10%"`. Hyprland's resize dispatcher
-- takes logical pixels here, so this is a fixed 50px rather than a
-- proportional step. Close enough in practice.
hl.bind(mainMod .. " + SHIFT + minus", hl.dsp.window.resize({ x = 0, y = -50, relative = true }),
  { description = "Shrink window height" })
hl.bind(mainMod .. " + SHIFT + equal", hl.dsp.window.resize({ x = 0, y = 50, relative = true }),
  { description = "Grow window height" })

-- niri: `maximize-column` / `fullscreen-window`.
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "maximized" }),
  { description = "Maximize column" })
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }),
  { description = "Fullscreen window" })

-- niri: `expand-column-to-available-width`.
hl.bind(mainMod .. " + CTRL + F", hl.dsp.layout("fit expand"),
  { description = "Expand column to available width" })

-- niri: `center-column`. Nearest scrolling-layout equivalent -- it scrolls the
-- tape so the focused column sits fully in view. Not a true centre.
hl.bind(mainMod .. " + C", hl.dsp.layout("fit_into_view"),
  { description = "Fit column into view" })

-- ===========================================================================
-- Floating and tabs
-- ===========================================================================

hl.bind(mainMod .. " + T", hl.dsp.window.float({ action = "toggle" }),
  { description = "Toggle floating" })

-- niri: `switch-focus-between-floating-and-tiling`. Hyprland has no toggle,
-- so branch on the focused window's current state.
hl.bind(mainMod .. " + SHIFT + T", function()
  local w = hl.get_active_window()
  if w ~= nil and w.floating then
    hl.dispatch(hl.dsp.focus({ window = "tiled" }))
  else
    hl.dispatch(hl.dsp.focus({ window = "floating" }))
  end
end, { description = "Switch focus between floating and tiling" })

-- niri: `toggle-column-tabbed-display`. Hyprland groups are tabbed
-- containers; `group.groupbar.stacked` (lua/layout.lua) renders them as a
-- vertical tab strip. With `binds.movefocus_cycles_groupfirst`, Mod+J/K walks
-- the tabs first, matching niri.
hl.bind(mainMod .. " + W", hl.dsp.group.toggle(),
  { description = "Toggle tabbed column" })

-- ===========================================================================
-- Monitors
-- ===========================================================================

for _, k in ipairs({
  { "left", "l" }, { "right", "r" }, { "up", "u" }, { "down", "d" },
  { "H", "l" }, { "L", "r" }, { "K", "u" }, { "J", "d" },
}) do
  hl.bind(mainMod .. " + SHIFT + " .. k[1], hl.dsp.focus({ monitor = k[2] }))
  hl.bind(mainMod .. " + SHIFT + CTRL + " .. k[1],
    hl.dsp.window.move({ monitor = k[2], follow = true }))
end

-- ===========================================================================
-- Workspaces
-- ===========================================================================
-- niri's workspaces are dynamic, per-monitor and stacked vertically;
-- Hyprland's are a flat numbered set. `r+1` / `r-1` walk to the next/previous
-- workspace on the current monitor including empty ones, which is the closest
-- behavioural match to niri's up/down.

hl.bind(mainMod .. " + Page_Down", hl.dsp.focus({ workspace = "r+1" }))
hl.bind(mainMod .. " + Page_Up", hl.dsp.focus({ workspace = "r-1" }))
hl.bind(mainMod .. " + U", hl.dsp.focus({ workspace = "r+1" }), { description = "Focus workspace down" })
hl.bind(mainMod .. " + I", hl.dsp.focus({ workspace = "r-1" }), { description = "Focus workspace up" })

hl.bind(mainMod .. " + CTRL + Page_Down", hl.dsp.window.move({ workspace = "r+1", follow = true }))
hl.bind(mainMod .. " + CTRL + Page_Up", hl.dsp.window.move({ workspace = "r-1", follow = true }))
hl.bind(mainMod .. " + CTRL + U", hl.dsp.window.move({ workspace = "r+1", follow = true }),
  { description = "Move window to workspace down" })
hl.bind(mainMod .. " + CTRL + I", hl.dsp.window.move({ workspace = "r-1", follow = true }),
  { description = "Move window to workspace up" })

-- niri: Mod+1..9 focus, Mod+Ctrl+1..9 move. Note it is CTRL, not SHIFT --
-- the stock Hyprland example uses SHIFT, but niri wins.
--
-- These resolve against the *focused monitor* (lua/workspaces.lua), so Mod+3 is
-- workspace 3 on DP-1 but workspace 13 on DP-2: each screen keeps its own
-- independent set, as in niri. A plain `hl.dsp.focus({ workspace = i })` uses
-- the global id instead and would drag focus across to the other monitor.
--
-- The slot has to be resolved inside the callback, not when the bind is
-- registered, because the focused monitor is only known at press time.
for i = 1, ws.count do
  hl.bind(mainMod .. " + " .. i, function()
    hl.dispatch(hl.dsp.focus({ workspace = ws.slot(i) }))
  end)
  hl.bind(mainMod .. " + CTRL + " .. i, function()
    hl.dispatch(hl.dsp.window.move({ workspace = ws.slot(i) }))
  end)
end

-- ===========================================================================
-- Mouse
-- ===========================================================================

-- Wheel. Rate-limited by `binds.scroll_event_delay = 150` (lua/look.lua),
-- which is niri's `cooldown-ms=150`.
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "r+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "r-1" }))
hl.bind(mainMod .. " + CTRL + mouse_down", hl.dsp.window.move({ workspace = "r+1", follow = true }))
hl.bind(mainMod .. " + CTRL + mouse_up", hl.dsp.window.move({ workspace = "r-1", follow = true }))

-- Horizontal wheel -> move along the tape.
hl.bind(mainMod .. " + mouse_right", hl.dsp.layout("focus r"))
hl.bind(mainMod .. " + mouse_left", hl.dsp.layout("focus l"))
hl.bind(mainMod .. " + CTRL + mouse_right", hl.dsp.layout("swapcol r"))
hl.bind(mainMod .. " + CTRL + mouse_left", hl.dsp.layout("swapcol l"))

-- Shift + vertical wheel -> horizontal, mirroring how apps behave.
hl.bind(mainMod .. " + SHIFT + mouse_down", hl.dsp.layout("focus r"))
hl.bind(mainMod .. " + SHIFT + mouse_up", hl.dsp.layout("focus l"))
hl.bind(mainMod .. " + CTRL + SHIFT + mouse_down", hl.dsp.layout("swapcol r"))
hl.bind(mainMod .. " + CTRL + SHIFT + mouse_up", hl.dsp.layout("swapcol l"))

-- Hyprland-only (from the old hyprland.conf): drag/resize floating windows.
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- ===========================================================================
-- Screenshots
-- ===========================================================================
-- niri had these built in; Hyprland delegates to hyprshot.
-- Filenames mirror niri's `screenshot-path` format.

local function shot(mode, extra)
  return hl.dsp.exec_cmd(
    "hyprshot -m " .. mode .. " " .. (extra or "") ..
    " -o '" .. SHOTS .. "'" ..
    " -f \"Screenshot from $(date '+%Y-%m-%d %H-%M-%S').png\""
  )
end

hl.bind("Print", shot("region", "--freeze"), { description = "Screenshot region" })
hl.bind("CTRL + Print", shot("output"), { description = "Screenshot screen" })
hl.bind("ALT + Print", shot("window"), { description = "Screenshot window" })

-- ===========================================================================
-- Media and brightness
-- ===========================================================================
-- niri used pamixer for sink volume and wpctl for the mic; kept verbatim.
-- `locked = true` is niri's `allow-when-locked=true`.

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("pamixer -i 5"),
  { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("pamixer -d 5"),
  { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("pamixer -t"),
  { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
  { locked = true })

hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })

-- Hyprland-only (from the old hyprland.conf) -- niri never bound these.
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),
  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),
  { locked = true, repeating = true })

-- ===========================================================================
-- niri binds with no Hyprland equivalent (deliberately not bound)
-- ===========================================================================
-- Mod+Shift+Slash  show-hotkey-overlay
--     No overlay exists. `hyprctl binds` lists them in a terminal; every bind
--     above carries a `description` so that output is readable.
-- Mod+Shift+W      toggle-overview
--     No native overview. The hyprexpo plugin (via hyprpm) is the closest,
--     but it must be recompiled on every Hyprland update. Key left free.
-- Mod+Shift+U / Mod+Shift+I / Mod+Shift+Page_Up|Down   move-workspace-up/down
--     Hyprland workspaces are a flat numbered set and cannot be reordered.
-- Mod+Home / Mod+End / Mod+Ctrl+Home / Mod+Ctrl+End
--     focus-column-first/last, move-column-to-first/last. The scrolling layout
--     has no message for jumping to either end of the tape.
-- Mod+Shift+R      switch-preset-window-height
-- Mod+Ctrl+R       reset-window-height
--     No vertical preset system; only column widths have presets.
