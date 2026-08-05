-- lua/autostart.lua -- session startup
--
-- Migrated from config.kdl `spawn-at-startup` lines.
--
-- Under uwsm, XDG autostart (~/.config/autostart) is already handled for you,
-- so only put things here that genuinely need the compositor to exist first.

local QS_PATH = "/home/mm-2103/projects/personal/quickshell-bar"

hl.on("hyprland.start", function()
  -- Wallet daemon (kwallet is used by the KDE portal / QT_QPA_PLATFORMTHEME=kde).
  hl.exec_cmd("kwalletd6")

  -- quickshell-bar: status bar, launcher, clipboard, wallpaper, session lock.
  -- It auto-detects Hyprland via HYPRLAND_INSTANCE_SIGNATURE and loads its
  -- BackendHyprland, so no flags differ from the niri session.
  hl.exec_cmd("qs -p " .. QS_PATH .. " -d")

  -- Polkit authentication agent.
  hl.exec_cmd("/usr/lib/hyprpolkitagent/hyprpolkitagent")

  -- Automount removable media.
  hl.exec_cmd("udiskie")

  hl.exec_cmd("protonvpn-app")

  -- Clipboard history, consumed by quickshell-bar's clipboard popup.
  hl.exec_cmd("wl-paste --watch cliphist store")

  -- Idle -> lock -> DPMS. See ../hypridle.conf.
  hl.exec_cmd("hypridle")
end)

-- ---------------------------------------------------------------------------
-- Dropped from the niri config
-- ---------------------------------------------------------------------------
-- * `waypaper --restore` -- waypaper is not installed, and quickshell-bar
--   renders the wallpaper itself (wallpaper/WallpaperService.qml +
--   WallpaperLayer.qml). It replaced swaybg/waypaper entirely.
-- * `xwayland-satellite` -- niri needed it; Hyprland has XWayland built in.
-- * `hyprpaper` -- not installed, superseded by the above.
