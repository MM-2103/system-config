-- lua/look.lua -- general appearance, decoration, blur, animations, cursor
--
-- Migrated from config.kdl `layout { ... }`, `blur { ... }`, `cursor { ... }`,
-- `animations { ... }` and `clipboard { ... }`.

hl.config({
  general = {
    -- niri: `layout { gaps 5 }`.
    -- Hyprland applies gaps_in per window *side*, so two adjacent windows get
    -- 2 * gaps_in between them. gaps_in = 2 gives ~4-5px between windows,
    -- matching niri's 5. gaps_out is measured once against the screen edge,
    -- so it maps 1:1.
    gaps_in          = 2,
    gaps_out         = 5,

    -- niri: `border { width 2; active-color "#ffc87f"; inactive-color "#505050" }`
    -- with `focus-ring { off }`. The old hyprland.conf's cyan/green gradient
    -- is intentionally dropped -- niri is the source of truth.
    --
    -- Both colours are dimmed from niri's values for the OLED on DP-1. The
    -- active border is a persistent lit element: thin, but it traces the same
    -- window edges for hours. niri's #ffc87f sits at 64% relative luminance;
    -- #d1a05f is 39.5%, a 38% cut, and deliberately matches the 39.2% of the
    -- bar's accent so both focus indicators carry the same weight.
    --
    -- The inactive border is dimmed alongside it purely to preserve the
    -- affordance -- what makes focus readable is the RATIO between the two,
    -- not the absolute brightness of the active one:
    --
    --   niri      #ffc87f / #505050  -> 5.31:1
    --   here      #d1a05f / #343434  -> 5.28:1
    --
    -- See ~/.config/quickshell-bar/themes/oled-guard.jsonc for the matching
    -- bar palette and the reasoning behind the luminance targets.
    border_size      = 2,
    col              = {
      active_border   = "rgb(d1a05f)",
      inactive_border = "rgb(343434)",
    },

    resize_on_border = false,
    allow_tearing    = false,
  },

  decoration = {
    -- niri's `geometry-corner-radius` rule is commented out, and the old
    -- hyprland.conf used rounding = 0. Square corners it is.
    rounding         = 0,

    active_opacity   = 1.0,
    inactive_opacity = 1.0,

    -- niri's `shadow { }` block has `on` commented out, i.e. shadows are OFF.
    -- (The stock Hyprland example enables them; this deliberately does not.)
    shadow           = {
      enabled = false,
    },

    -- niri: `blur { passes 3; offset 3; noise 0.02; saturation 1.5 }`.
    -- `offset` is niri's blur radius -> Hyprland's `size`.
    -- No equivalent for niri's `saturation`; Hyprland offers vibrancy /
    -- brightness / contrast instead.
    blur             = {
      enabled  = true,
      size     = 3,
      passes   = 3,
      noise    = 0.02,
      vibrancy = 0.1696,
    },
  },

  animations = {
    enabled = true,
  },

  misc = {
    disable_hyprland_logo   = true,
    disable_splash_rendering = true,
    force_default_wallpaper = 0,

    -- niri: `clipboard { disable-primary }`
    middle_click_paste      = false,

    -- niri: `variable-refresh-rate on-demand=true` plus per-window VRR rules.
    -- 2 = enable VRR only for fullscreen windows.
    vrr                     = 2,
  },

  cursor = {
    -- niri: `cursor { hide-when-typing; hide-after-inactive-ms 10000 }`
    hide_on_key_press = true,
    inactive_timeout  = 10,
  },

  render = {
    -- Colour management pipeline. Required for HDR; default is already true,
    -- stated explicitly because the OLED on DP-1 is the whole point.
    cm_enabled   = true,

    -- 1 = automatically switch the output to HDR when a fullscreen window
    -- needs it, then switch back. Pairs with `cm = "auto"` in lua/monitors.lua.
    -- NOTE: for mpv > v0.40.0 you also need --target-colorspace-hint-mode=source
    cm_auto_hdr  = 1,

    -- 2 = auto (on for content type 'game'). Reduces latency for fullscreen
    -- games on the OLED.
    direct_scanout = 2,
  },

  binds = {
    -- niri used `cooldown-ms=150` on its workspace wheel binds.
    scroll_event_delay          = 150,

    -- Inside a tabbed column (Mod+W), Mod+J/K should walk the tabs before
    -- leaving the group -- this is how niri's tabbed columns behave.
    movefocus_cycles_groupfirst = true,

    -- niri stops at the monitor edge rather than hopping to the next output;
    -- monitor movement has its own binds (Mod+Shift+<dir>).
    window_direction_monitor_fallback = false,
  },

  xwayland = {
    -- Hyprland has XWayland built in; niri needed xwayland-satellite.
    enabled = true,
  },
})

-- ---------------------------------------------------------------------------
-- Animation curves
-- ---------------------------------------------------------------------------
-- Kept as Hyprland 0.56's stock set. niri's `animations { slowdown 0.5 }` has
-- no clean translation -- Hyprland's `speed` is a duration in deciseconds, not
-- a multiplier, and the two compositors' animation sets don't correspond.
-- If these feel too slow, halve the `speed` values below.

hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })

hl.curve("easy", { type = "spring", mass = 1, stiffness = 238.1191, dampening = 24.21279333 })

hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows", enabled = true, speed = 4.79, spring = "easy" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.1, spring = "easy", style = "popin 87%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.49, bezier = "linear", style = "popin 87%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade", enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers", enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "linear", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "zoomFactor", enabled = true, speed = 7, bezier = "quick" })
