-- lua/input.lua -- keyboard, pointer, touchpad, gestures
--
-- Migrated from config.kdl `input { ... }` and `gestures { ... }`.

hl.config({
  input = {
    kb_layout    = "us",
    kb_variant   = "",
    kb_model     = "",
    -- niri: `xkb { options "caps:super" }` -- Caps Lock acts as Super.
    kb_options   = "caps:super",
    kb_rules     = "",

    -- niri: `repeat-delay 300`, `repeat-rate 30`.
    -- (The old hyprland.conf used rate 25; niri wins.)
    repeat_delay = 300,
    repeat_rate  = 30,

    -- niri: `focus-follows-mouse max-scroll-amount="0%"`.
    -- Hyprland has no max-scroll-amount equivalent; 1 = focus follows mouse.
    follow_mouse = 1,

    sensitivity  = 0, -- -1.0 - 1.0, 0 means no modification.

    touchpad     = {
      -- niri: `touchpad { tap }`
      tap_to_click   = true,
      natural_scroll = false,
    },
  },

  cursor = {
    -- Sync the xcursor theme to gsettings so GTK CSD clients match.
    sync_gsettings_theme = true,
  },
})

-- ---------------------------------------------------------------------------
-- Gestures
-- ---------------------------------------------------------------------------
-- niri disables hot corners (`gestures { hot-corners { off } }`). Hyprland has
-- no hot corners at all, so there is nothing to disable.
--
-- The three-finger horizontal swipe for workspace switching is a Hyprland
-- nicety with no niri counterpart; kept from the stock example because it is
-- useful on the laptop.
hl.gesture({
  fingers   = 3,
  direction = "horizontal",
  action    = "workspace",
})

-- ---------------------------------------------------------------------------
-- Per-device overrides
-- ---------------------------------------------------------------------------
-- Check names with `hyprctl devices`.
-- Example (carried over from the old hyprland.conf):
--
-- hl.device({
--   name        = "epic-mouse-v1",
--   sensitivity = -0.5,
-- })
