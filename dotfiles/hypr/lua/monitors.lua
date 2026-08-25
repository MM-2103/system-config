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
  vrr      = 3,      -- fullscreen AND content-type game/video -- see note at bottom

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
-- Set to 3: VRR only for fullscreen windows whose content type is `game` or
-- `video`. Mode 2 ("any fullscreen window") caused severe OLED flicker.
--
-- WHY. This panel's brightness shifts slightly with the refresh interval, so
-- flicker tracks how much the refresh MOVES, not whether VRR is on. LG's own
-- OSD help text says: "Note that the screen flickering may occur
-- intermittently in a specific gaming environment."
--
-- All figures below are measured, via the DRM vblank counter on the CRTC
-- (scripts/display-probe.py). Fullscreen YouTube in Zen:
--
--   vrr = 2   mean 172.27 Hz   range 128.5 Hz   stdev 28.49   <- flickers badly
--   vrr = 3   mean 239.84 Hz   range   7.5 Hz   stdev  0.75   <- flat, no flicker
--
-- Mode 2 is a problem because Hyprland presents ON DAMAGE. A composited
-- fullscreen browser repaints erratically (video frames, page repaints, UI),
-- so the presentation rate swings wildly and VRR follows it.
--
-- KWin, for reference, uses the SAME policy -- `Window::wantsAdaptiveSync()`
-- is literally `isFullScreen()` -- yet does not flicker, because it composites
-- at the output's fixed refresh rate. Measured under Plasma on the same video:
-- VRR_ENABLED=1, stdev 1.30. So the difference is presentation cadence, not
-- VRR policy. Hyprland's vrr=3 ends up marginally steadier than Plasma here.
--
-- BENCHMARK vs KWin (scripts/vrr-bench.py, 6 clips x 15s, identical files,
-- constant average picture level so the panel's ABL cannot contaminate it,
-- measured from true per-vblank timestamps -- not averaged):
--
--                      d_mean    d_p99     hz_sd
--   hyprland            8.69     139.6      22.6
--   hyprland (no bar)   4.88      90.1      16.2
--   plasma (KWin)       1.92       7.4       1.4
--   idle floor          0.09       0.7       0.09
--
-- d_mean = mean |change in refresh between consecutive frames|, i.e. the
-- quantity an OLED turns into visible brightness change. KWin won all six
-- clips; Hyprland is ~4.5x less stable, ~2.5x even with the bar killed.
--
-- WHY -- and note the frame multiplication is NOT the compositor's doing.
--
-- LFC is implemented in the KERNEL as AMD "BTR" (Below The Range):
--   drivers/gpu/drm/amd/display/modules/freesync/freesync.c
--     :: apply_below_the_range()
--   enabled unconditionally via `config.btr = true` in amdgpu_dm.c
-- KWin has NO such code and an explicit `// TODO` saying so
-- (src/core/renderloop.cpp). Its maintainer: "we do not have driver APIs yet
-- to implement that". So BTR runs under Hyprland too -- Hyprland's erratic
-- presentation simply defeats it before it can settle.
--
-- BTR does not pick "the smallest multiple above the VRR floor". It picks the
-- multiplier whose frame duration lands nearest the MIDPOINT of the VRR range
-- (btr.mid_point_in_us). For 48-240 Hz that midpoint is 80.0 Hz.
--
-- Verified by falsification test (scripts/vrr-bench.py, KWin, 15s per clip).
-- Three clips where the two models disagree, plus two controls:
--
--   clip   measured   BTR model   "smallest multiple above floor"
--   20fps    80.01     80.0 (4x)      60.0     <- BTR correct
--   25fps    75.00     75.0 (3x)      50.0     <- BTR correct
--   26fps    78.01     78.0 (3x)      52.0     <- BTR correct
--   40fps    80.02     80.0 (2x)      80.0     control, both agree
--   55fps    55.01     55.0 (1x)      55.0     control, BTR inactive
--
-- and it reproduces the original six to <=0.04 Hz:
--   24 -> 72.01 (3x)   30 -> 90.01 (3x)   48 ->  96.02 (2x)
--   60 -> 60.01 (1x)   90 -> 90.03 (1x)  120 -> 120.04 (1x)
--
-- !! BTR HYSTERESIS -- THIS IS THE PRACTICALLY IMPORTANT BIT !!
--   engages  when frame time > 19583 us  (below ~51.1 fps)
--   releases when frame time < 17083 us  (above ~58.5 fps)
-- Crossing that boundary changes the refresh by a factor of 2-3x INSTANTLY.
-- Those are not jitter, they are step changes, and they are almost certainly
-- what the d_p99 = 115-170 Hz outliers in the Hyprland runs actually are.
--
-- So 51-58 fps is the WORST band to sit in. For any capped game either:
--   * keep the floor above ~52 fps  -> BTR never engages, or
--   * cap at 48 fps                 -> BTR always on, stable 2x = 96 Hz
--     (measured on KWin: 96.02 Hz, sd 1.66 -- the panel runs at 96, not 48)
-- Do NOT cap at 60: that sits directly on the release threshold.
--
-- The quickshell bar accounts for roughly 44% of Hyprland's instability
-- (8.69 -> 4.88 with it killed), so it is a contributor but not the cause.
--
-- PERCEPTUAL NOTE: none of these clips flickered visibly, on either
-- compositor. So d_mean ~8.7 with flat mid-grey content is below the
-- perception threshold here. The known-flickering case (fullscreen YouTube
-- under vrr=2) has not yet been measured with this instrument, so there is
-- no calibrated threshold -- only a confirmed "not visible at 8.7".
--
-- THINGS THAT DID NOT WORK (all measured, ~18s each, same video):
--   baseline (ds=2, no_break_fs_vrr=2)   stdev 23.71
--   render.direct_scanout      = 1       stdev 22.58
--   cursor.no_break_fs_vrr     = 1       stdev 24.21
--   both                       = 1       stdev 24.04
-- direct_scanout=1 does clear the CONTENT blocker, but `CANDIDATE` remains:
-- the browser's surface simply is not scanout-eligible, so it stays
-- composited no matter what. Don't re-litigate this.
--
-- CONSEQUENCE. Most wine/Proton games report contentType 'none', so they get
-- NO VRR under mode 3 unless explicitly tagged. That is deliberate -- an
-- opt-in whitelist. See the `content = "game"` rules in lua/rules.lua.
--
-- Tagged games still need a frame cap to stay flicker-free, because VRR then
-- tracks their frame rate. Rule of thumb: cap at the largest divisor of 240
-- (240/120/80/60/48) that sits below your 1% low, and use
-- `display-probe.py watch` to confirm the resulting stdev is near zero.
--
-- !! GOTCHA !! Changing `vrr` at runtime frequently does NOT take effect.
-- Hyprland calls setAdaptiveSync() and, if the atomic commit is rejected,
-- silently reverts it (DEBUG log only, and logs are off by default). Neither
-- `hyprctl reload` nor a DPMS cycle reliably forces it. What DOES work is a
-- full modeset -- e.g. toggling `cm` or `bitdepth` in the same rule.
--
-- Never trust `hyprctl monitors -> vrr`, the monitor's OSD indicator, or this
-- file to tell you what the hardware is doing. Verify with:
--
--     scripts/display-probe.py verify        # config vs kernel
--     scripts/display-probe.py watch -s 15   # measured refresh stability
