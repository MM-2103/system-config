-- lua/rules.lua -- window and layer rules
--
-- Migrated from config.kdl `window-rule { ... }` blocks, plus the
-- Hyprland-specific rules that had no niri counterpart.
--
-- Hyprland matches with RE2 in *partial* mode, so niri's unanchored patterns
-- (`zen$`, `steam$`, ...) carry over as-is. Remember Lua needs `\\` for a
-- literal backslash.
--
-- Rule order matters: named rules are evaluated before anonymous ones, then
-- top to bottom, last match wins.

-- ---------------------------------------------------------------------------
-- Hyprland housekeeping (no niri counterpart)
-- ---------------------------------------------------------------------------

-- Ignore client-initiated maximize requests. This does not interfere with the
-- config-driven `maximize = true` rules further down.
hl.window_rule({
  name           = "suppress-maximize-events",
  match          = { class = ".*" },
  suppress_event = "maximize",
})

-- Fix dragging issues with XWayland.
hl.window_rule({
  name     = "fix-xwayland-drags",
  match    = {
    class      = "^$",
    title      = "^$",
    xwayland   = true,
    float      = true,
    fullscreen = false,
    pin        = false,
  },
  no_focus = true,
})

-- ---------------------------------------------------------------------------
-- Floating windows
-- ---------------------------------------------------------------------------

-- niri: `match app-id=r#"Pinentry-gtk$"# { open-floating true }`
-- `stay_focused` is the wiki's recommended fix for pinentry losing focus.
hl.window_rule({
  name         = "float-pinentry",
  match        = { class = "Pinentry-gtk$" },
  float        = true,
  stay_focused = true,
})

-- niri: `match app-id=r#"xdg-desktop-portal-gtk"# { open-floating true }`
hl.window_rule({
  name  = "float-portal-gtk",
  match = { class = "xdg-desktop-portal-gtk" },
  float = true,
})

-- ---------------------------------------------------------------------------
-- Picture-in-Picture
-- ---------------------------------------------------------------------------
-- niri:
--   match app-id=r#"zen$"# title="^Picture-in-Picture$"
--   open-on-output "DP-2"; open-fullscreen true; open-floating true
-- Matches both host Zen ("zen") and Flatpak Zen ("app.zen_browser.zen").
--
-- Do NOT add `pin = true` here. `binds.allow_pin_fullscreen` is false by
-- default, so pinning silently cancels the fullscreen: the window ends up
-- floating at its client-requested size, straddling the monitor boundary.
-- Verified: unpinning the live window immediately snapped it to
-- at=[2560,0] size=[1200x1920], i.e. exactly filling the rotated Dell.
--
-- niri opened this floating, but do NOT restore `float = true` here either.
-- Hyprland has two fullscreen handlers, and floating windows always get the
-- `default` one, which un-fullscreens the window as soon as focus leaves it --
-- so a PiP would cover the Dell and could not be looked away from without
-- being closed. Tiled windows on a scrolling workspace instead get the
-- `scrolling` handler, whose whole purpose is to let you scroll away from a
-- fullscreen window without dropping its fullscreen state. That is what makes
-- it possible to glance at the terminal next to the video and scroll back.
--
-- The handler is not selectable from a window rule: `layout_aware` exists only
-- as an argument to the fullscreen *dispatchers*. It follows from the window
-- being tiled, which is why this rule simply omits `float`.
--
-- Check which handler a window ended up with via `fullscreenHandler` in
-- `hyprctl clients -j`.
hl.window_rule({
  name       = "zen-pip",
  match      = { class = "zen$", title = "^Picture-in-Picture$" },
  fullscreen = true,
  monitor    = "DP-2",
})

-- ---------------------------------------------------------------------------
-- Games / launchers -- open maximized
-- ---------------------------------------------------------------------------
-- niri set `variable-refresh-rate true` on each of these. Hyprland handles
-- that globally via `misc.vrr = 2` (VRR for fullscreen windows), so there is
-- nothing per-window to set here.

-- niri: `match app-id=r#"steam$"# { open-maximized true }`
hl.window_rule({
  name     = "steam-maximized",
  match    = { class = "steam$" },
  maximize = true,
})

-- niri: `match app-id=r#"heroic$"# { open-maximized true }`
hl.window_rule({
  name     = "heroic-maximized",
  match    = { class = "heroic$" },
  maximize = true,
})

-- niri: `match app-id=r#"\.exe$"# { open-maximized true }`
-- Wine/Proton windows.
hl.window_rule({
  name     = "wine-maximized",
  match    = { class = "\\.exe$" },
  maximize = true,
})

-- Tag Steam games as 'game' content. This lets `render.direct_scanout = 2`
-- and `cursor.no_break_fs_vrr = 2` (both "auto, on for game content") kick in,
-- which matters for latency and VRR stability on the OLED.
hl.window_rule({
  name    = "steam-games-content-type",
  match   = { class = "^steam_app_\\d+$" },
  content = "game",
})

-- ---------------------------------------------------------------------------
-- Games that do NOT self-report their content type
-- ---------------------------------------------------------------------------
-- Wayland clients are supposed to declare a content type; plenty of games
-- (especially under wine/Proton) never do, and arrive as 'none'. Hyprland's
-- "auto" modes then treat them as ordinary windows:
--
--   render.direct_scanout   = 2  -> auto, only for content type 'game'
--   cursor.no_break_fs_vrr  = 2  -> auto, only for content type 'game'
--
-- With scanout blocked, the compositor composites every frame and presents at
-- its OWN rate rather than the game's. Measured on FFXIV in Limsa: the game
-- reported 49-70 fps while the panel was re-clocked at a median of 90 Hz,
-- peaking at 199 -- i.e. roughly double, driven by the compositor.
--
-- With VRR that is a direct cause of OLED flicker, and it means an in-game
-- frame cap cannot stabilise the refresh: the game is not what is driving it.
--
-- `content` is a STATIC rule, applied when the window opens, so the game must
-- be restarted for it to take effect.
--
-- Verify with:  scripts/display-probe.py snapshot   (directScanoutBlockedBy)
--
-- !! CAVEAT for FFXIV specifically !!
-- Tagging it `game` also opts it INTO VRR (monitors.lua uses vrr = 3, which
-- gates on content type). Measured frame rate in crowded Limsa is 49-70 fps,
-- which straddles the kernel BTR hysteresis band (engages below ~51.1 fps,
-- releases above ~58.5 fps). Crossing that boundary steps the refresh by
-- 2-3x, which is a far bigger flicker event than ordinary VRR modulation.
--
-- So if FFXIV flickers, pick one:
--   a) drop this rule       -> no VRR for FFXIV, panel stays at a flat 240 Hz
--   b) cap the game at 48   -> BTR always on, stable 96 Hz (2x)
--   c) lower settings so the floor stays above ~52 fps -> BTR never engages
-- Do NOT cap at 60 -- that sits directly on the BTR release threshold.
-- See the VRR note in lua/monitors.lua for the measurements.
hl.window_rule({
  name    = "ffxiv-content-type",
  match   = { class = "^ffxiv_dx11\\.exe$" },
  content = "game",
})

-- Run fullscreen games through gamescope:
--
--     gamescope -f -W 2560 -H 1440 -r 240 -- %command%
--
-- Launched plain, a fullscreen game blanks the screen for about a second
-- every time anything draws over it (volume OSD, alt-tab) and again when that
-- thing leaves. Direct scanout hands the plane the game's 8 bpc buffer while
-- the compositor's own is 10 bpc, and changing the plane's pixel format needs
-- a modeset, so the link retrains. Not fixable from this config: amdgpu
-- rejects the format change without ALLOW_MODESET.
--
-- gamescope hands over XBGR2101010 instead. The format still flips, but 10 bpc
-- to 10 bpc leaves the link alone, so it is a short flicker rather than a
-- blackout.
--
-- The window arrives as class `gamescope`, which misses the steam_app rule
-- above, so tag it here or it gets neither scanout nor VRR.
hl.window_rule({
  name    = "gamescope-content-type",
  match   = { class = "^gamescope$" },
  content = "game",
})

-- If you ever want tearing for competitive games, set
-- `general.allow_tearing = true` in lua/look.lua and uncomment this:
-- hl.window_rule({
--   name      = "steam-games-tearing",
--   match     = { class = "^steam_app_\\d+$" },
--   immediate = true,
-- })

-- ---------------------------------------------------------------------------
-- Privacy -- hide from screen capture
-- ---------------------------------------------------------------------------
-- niri combined both matches into a single rule (OR semantics); Hyprland needs
-- one rule per match.
--   niri: block-out-from "screen-capture"

hl.window_rule({
  name            = "blockout-keepassxc",
  match           = { class = "^org\\.keepassxc\\.KeePassXC$" },
  no_screen_share = true,
})

hl.window_rule({
  name            = "blockout-gnome-secrets",
  match           = { class = "^org\\.gnome\\.World\\.Secrets$" },
  no_screen_share = true,
})

-- ---------------------------------------------------------------------------
-- Layer rules
-- ---------------------------------------------------------------------------

-- The quickshell-bar wallpaper layer must never animate or blur -- it is the
-- backdrop everything else composites against.
hl.layer_rule({
  name    = "wallpaper-no-anim",
  match   = { namespace = "^quickshell-wallpaper$" },
  no_anim = true,
})

-- ---------------------------------------------------------------------------
-- Dropped from the niri config
-- ---------------------------------------------------------------------------
-- * WezTerm `default-column-width {}` -- a workaround for a WezTerm initial
--   configure bug. You use ghostty, and Hyprland has no "let the client pick"
--   column width anyway (only the fixed `scrolling_width` rule).
-- * `move-hyprland-run` from the stock example -- hyprlauncher is unused; the
--   quickshell-bar launcher handles this.
