-- lua/monitors.lua -- output configuration
--
-- Migrated from config.kdl `output { ... }` blocks.
--
-- This config is shared between two machines:
--   * desktop -- LG UltraGear+ OLED (DP-1), Dell U2412M portrait (DP-2)
--   * laptop  -- eDP-1 + an external over HDMI
-- The two sets are disjoint, so the explicit positions below never actually
-- collide even though eDP-1 and the LG both claim 0x0.
--
-- The desktop monitors are matched by `desc:` rather than connector, so the
-- layout follows the physical panel if a cable moves between DP ports. The
-- strings come from `hyprctl monitors all` (verified 2026-08-05):
--   DP-1  description: LG Electronics LG ULTRAGEAR+ 603NTSUN9974
--   DP-2  description: Dell Inc. DELL U2412M YPPY087K0J9U
-- Hyprland prefix-matches, so make+model is enough; append the serial if you
-- ever run two identical panels.

-- ---------------------------------------------------------------------------
-- Fallback -- applies to any output without an explicit rule below.
-- ---------------------------------------------------------------------------
hl.monitor({
  output   = "",
  mode     = "preferred",
  position = "auto",
  scale    = 1,
})

-- ---------------------------------------------------------------------------
-- Desktop
-- ---------------------------------------------------------------------------

-- LG UltraGear+ OLED (serial 603NTSUN9974), primary.
-- EDID: native 2560x1440@240, 10 bpc, BT.2020 + ST2084 PQ,
--       604 nits peak / 277 nits frame-average / ~0 nits min, FreeSync 48-240.
--       Measured primaries are essentially DCI-P3, NOT BT.2020:
--         R 0.677,0.321  G 0.249,0.685  B 0.146,0.057   (BT.2020 G is 0.170,0.797)
--
-- HDR strategy: the desktop stays SDR at 10 bpc, and `render.cm_auto_hdr`
-- (see lua/look.lua) flips the panel into real HDR only when a fullscreen
-- game/video asks for it. Verified via the KMS HDR_OUTPUT_METADATA blob.
--
-- Do NOT use cm = "auto" here. Hyprland resolves `auto` to "wide" whenever
-- bitdepth is 10, which tags the output BT2020_RGB. This panel only honours
-- BT.2020 colorimetry in HDR mode; in SDR it presents the BT.2020-encoded
-- values as-is, so all sRGB content renders at roughly 75% of its intended
-- saturation. That made the entire desktop look muted and dimmer than a
-- much older IPS panel. "srgb" matches how the content is actually authored.
-- 10 bpc is kept -- it reduces gradient banding and is unrelated to the gamut.
hl.monitor({
  output   = "desc:LG Electronics LG ULTRAGEAR+",
  mode     = "2560x1440@240",
  position = "0x0",
  scale    = 1,
  bitdepth = 10,
  cm       = "srgb", -- see note above; "auto" would silently become "wide"
  vrr      = 0,      -- OFF -- see "VRR" note at the bottom of this file

  -- The EDID already reports these correctly, so they're left commented.
  -- Uncomment to override if HDR tone mapping looks wrong:
  -- max_luminance     = 604,
  -- max_avg_luminance = 277,
  -- min_luminance     = 0,
})

-- Dell U2412M, rotated 90 degrees (portrait), to the right of the LG.
-- Rotated, its logical size is 1200x1920, so it occupies x 2560..3760.
hl.monitor({
  output    = "desc:Dell Inc. DELL U2412M",
  mode      = "1920x1200@59.95",
  position  = "2560x0",
  scale     = 1,
  transform = 1, -- 1 = 90 degrees CCW (niri: transform "90")
})

-- ---------------------------------------------------------------------------
-- Laptop
-- ---------------------------------------------------------------------------

hl.monitor({
  output   = "eDP-1",
  mode     = "1920x1080@144",
  position = "0x0",
  scale    = 1,
})

-- The niri config declared HDMI-A-2, but this machine's HDMI connector
-- enumerates as HDMI-A-1. Both are declared so it works either way; whichever
-- doesn't exist is simply ignored.
hl.monitor({
  output   = "HDMI-A-1",
  mode     = "1920x1200@59.95",
  position = "auto-right",
  scale    = 1,
})

hl.monitor({
  output   = "HDMI-A-2",
  mode     = "1920x1200@59.95",
  position = "auto-right",
  scale    = 1,
})

-- ---------------------------------------------------------------------------
-- Notes
-- ---------------------------------------------------------------------------
-- * Dropped from the niri config: `PNP(BNQ) BenQ EX2780Q H2N00612019`. That
--   monitor was replaced by the LG above, so the rule was dead config.
--
-- * The Zen picture-in-picture window rule in lua/rules.lua still targets the
--   connector name "DP-2" -- window rules take a monitor name or ID, not a
--   `desc:` selector. If you move the Dell to another port, update that rule
--   too.
--
-- * The laptop panel keeps its connector name: eDP-1 is stable by definition.
--
-- ---------------------------------------------------------------------------
-- VRR / Adaptive-Sync on DP-1
-- ---------------------------------------------------------------------------
-- Disabled (`vrr = 0`). Measured with scripts/display-probe.py, sampling the
-- DRM vblank counter on the CRTC:
--
--   vrr = 2 (on):   mean 202.39 Hz, min 187.20, max 238.68, stdev 11.08
--   vrr = 0 (off):  mean 239.93 Hz, min 239.93, max 239.93, stdev  0.00
--
-- With VRR on, the panel is re-clocked across a ~51 Hz range continuously.
-- OLED luminance depends slightly on refresh interval, so that shows up as
-- brightness flicker. LG's own OSD help text for Adaptive-Sync says: "Note
-- that the screen flickering may occur intermittently in a specific gaming
-- environment."
--
-- The cost of disabling it is small here: 240 Hz divides evenly by 60, 80 and
-- 120, so a capped framerate on any of those gives perfect frame cadence with
-- no tearing and no judder.
--
-- !! GOTCHA !! Changing `vrr` at runtime frequently does NOT take effect.
-- Hyprland calls setAdaptiveSync() and, if the atomic commit is rejected,
-- silently reverts it (DEBUG log only, and logs are off by default). Neither
-- `hyprctl reload` nor a DPMS cycle reliably forces it. What does work is a
-- full modeset -- e.g. toggling `cm` or `bitdepth` in the same rule.
--
-- Never trust `hyprctl monitors -> vrr`, the monitor's OSD indicator, or this
-- file to tell you what the hardware is doing. Verify with:
--
--     scripts/display-probe.py verify        # config vs kernel
--     scripts/display-probe.py watch -s 15   # measured refresh stability
