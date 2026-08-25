-- lua/workspaces.lua -- per-monitor workspace blocks
--
-- Hyprland's workspaces are a single flat, global, numbered set: workspace 2
-- lives on whichever monitor happens to own it, so Mod+2 can yank focus to the
-- other screen. niri and AwesomeWM instead give every output its own
-- independent set of workspaces. This module reproduces that behaviour.
--
-- Each monitor owns a contiguous block of ids, `stride` apart:
--
--   DP-1  (LG, main)      base  0  ->  workspaces  1..9
--   DP-2  (Dell, portrait) base 10  ->  workspaces 11..19
--
-- Mod+N resolves to `base(focused monitor) + N` -- see lua/binds.lua -- and the
-- workspace rules at the bottom pin each block to its monitor so a workspace
-- can never drift onto the wrong screen.
--
-- The relative binds (`r+1` / `r-1`: Mod+U/I, Mod+Page_Up/Down, Mod+scroll) are
-- already per-monitor in stock Hyprland and need nothing from this module.
--
-- Workspaces stay dynamic rather than `persistent`, matching niri: one exists
-- only once something is on it.
--
-- This is the same idea as the `split-monitor-workspaces` plugin, done in plain
-- Lua instead. Plugins are compiled against an exact Hyprland version and break
-- on every update; this does not.

local M = {}

-- Ids per monitor. Must exceed `count`, and stays a round number so the id
-- reads as "monitor digit + slot digit" (13 = DP-2's slot 3).
M.stride = 10

-- How many slots are bound per monitor (Mod+1..9). niri used 1..9, not 1..0.
M.count = 9

-- Monitor name -> block base. Names must match `hl.get_active_monitor().name`,
-- i.e. connector names, not the `desc:` strings used in lua/monitors.lua.
--
-- Monitors absent from this table fall back to block 0, so a single-screen
-- session (laptop, or DP-2 unplugged) behaves exactly like stock Hyprland.
M.base = {
  ["DP-1"] = 0,
  ["DP-2"] = 10,
}

--- Block base for the currently focused monitor, or 0 if it is unknown.
---@return integer
function M.current_base()
  local mon = hl.get_active_monitor()
  return (mon and M.base[mon.name]) or 0
end

--- Absolute workspace id for slot `n` on the currently focused monitor.
---@param n integer slot number, 1..M.count
---@return integer
function M.slot(n)
  return M.current_base() + n
end

-- ---------------------------------------------------------------------------
-- Pin each block to its monitor
-- ---------------------------------------------------------------------------
-- Without this the scheme leaks: nothing stops Hyprland opening workspace 13 on
-- DP-1, and the two sets stop being independent.
--
-- If a named monitor is not connected, Hyprland falls back to placing the
-- workspace on an available one -- which is the desired single-screen
-- behaviour, so the unplugged laptop outputs need no special handling.
--
-- Slot 1 of each block is marked `default`, which is what a monitor gets at
-- session start. Without it Hyprland has to invent one: it takes the lowest
-- id not pinned to some *other* monitor, and since this scheme pins 1..9 and
-- 11..19 while leaving `stride` itself (10) unowned, the second monitor came
-- up on workspace 10 every boot. That workspace belongs to no block, so:
--
--   * it sorted ahead of 11 in the bar, showing a stray "10" chip to the
--     left of "1";
--   * Mod+N could never return to it, because those resolve to base+1..base+9
--     and nothing maps to 10 -- only clicking the chip worked, since the bar
--     dispatches the raw id;
--   * emptying it made the problem vanish, workspaces being dynamic.
--
-- `(n == 1) or nil` leaves the key absent on the other slots rather than
-- passing an explicit false.

for name, base in pairs(M.base) do
  for n = 1, M.count do
    hl.workspace_rule({
      workspace = tostring(base + n),
      monitor   = name,
      default   = (n == 1) or nil,
    })
  end
end

-- DO NOT set `default_name` here to the per-monitor slot number (1..9) as a way
-- of feeding labels to a status bar. It parses and applies correctly, but
-- workspace names are a *global* namespace in Hyprland, and naming both DP-1's
-- workspace 1 and DP-2's workspace 11 "1" makes them indistinguishable to every
-- name-based consumer.
--
-- The legacy IPC events are name-based and become ambiguous:
--
--   focusedmon>>DP-2,1       <- which "1"? DP-1's or DP-2's?
--   focusedmonv2>>DP-2,11    <- the v2 events carry the id, so these are fine
--
-- Observed fallout: the bar re-parented DP-1's workspace onto DP-2, so the Dell
-- showed two chips labelled "1" and the LG showed none until it was refocused.
--
-- Bars therefore have to derive the per-monitor label from the id themselves.
-- quickshell-bar does that in compositor/BackendHyprland.qml, which keeps its
-- own copy of `stride` -- change M.stride above and that must change too.

return M
