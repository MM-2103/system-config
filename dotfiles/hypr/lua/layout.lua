-- lua/layout.lua -- tiling layout
--
-- `scrolling` is Hyprland's native niri-alike: windows live in columns on an
-- infinitely growing horizontal tape. This is what makes the migration from
-- niri feel like the same WM rather than a different one.
--
-- Docs: https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/

hl.config({
  general = {
    layout = "scrolling",
  },

  scrolling = {
    -- niri: `default-column-width { proportion 0.5; }`
    column_width             = 0.5,

    -- niri: `preset-column-widths { proportion 0.33333 / 0.5 / 0.66667 }`.
    -- Cycled by `hl.dsp.layout("colresize +conf")` (Mod+R).
    explicit_column_widths   = "0.33333, 0.5, 0.66667",

    -- niri: `center-focused-column "never"`.
    -- 0 = center the focused column, 1 = just fit it into view.
    focus_fit_method         = 1,

    -- Scroll the tape to keep the focused window visible, like niri.
    follow_focus             = true,
    follow_min_visible       = 0.4,

    -- niri does NOT wrap around at the ends of the scroll; it stops.
    wrap_focus               = false,
    wrap_swapcol             = false,

    -- A lone column fills the screen, like niri with a single column.
    fullscreen_on_one_column = true,

    -- New windows appear to the right and the tape scrolls right, as in niri.
    direction                = "right",
  },

  -- Groups are Hyprland's tabbed containers. Mod+W (niri's
  -- `toggle-column-tabbed-display`) toggles one. `stacked = true` renders the
  -- group bar as a vertical tab strip, which is what niri's tabbed column
  -- looks like.
  group = {
    groupbar = {
      enabled       = true,
      stacked       = true,
      render_titles = true,
      font_size     = 11,
      height        = 18,
      indicator_height = 2,
      col           = {
        active   = "rgb(ffc87f)",
        inactive = "rgb(505050)",
      },
      text_color          = "rgb(1e1e1e)",
      text_color_inactive = "rgb(cccccc)",
    },
  },

  -- Kept configured so per-workspace overrides below (or ad-hoc ones) work.
  dwindle = {
    preserve_split = true,
  },

  master = {
    new_status = "master",
  },
})

-- ---------------------------------------------------------------------------
-- Workspace rules
-- ---------------------------------------------------------------------------
-- niri has dynamic, per-monitor, vertically-stacked workspaces. Hyprland's are
-- numbered 1..N and global. lua/workspaces.lua closes that gap by giving each
-- monitor its own block of ids, and owns the rules that pin them; the rules
-- below are only for per-workspace *layout* tweaks.
--
-- Per-workspace layout overrides go here if you want them, e.g.:
--   hl.workspace_rule({ workspace = "9", layout = "dwindle" })
--
-- Per-workspace scroll direction is also possible:
--   hl.workspace_rule({ workspace = "2", layout_opts = { direction = "down" } })
