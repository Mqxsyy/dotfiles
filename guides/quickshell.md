# Quickshell

- Simple overview of quickshell
- Short & concise
- Keep up to date

## Overview

Config lives in `quickshell/` (symlinked to `~/.config/quickshell`). `shell.qml` lists the windows. Shared state and services are singletons (`pragma Singleton`), used by name from any file.

### Windows

All windows are `ShellWindow`s (`ShellWindow.qml`): transparent, over other windows, and named `qs-<name>` — or `qs-blur-<name>` with Glass on, which the `quickshell-glass` layer rule in `hypr/hyprland.lua` blurs.

- `Bar.qml` — slides down from the top edge of each screen when the pointer touches it: a floating now-playing card top-left (only while something plays), a clock tab hanging from the top-center (click for the calendar), a floating dnd / wifi / volume / battery card top-right (hover for hints).
- `Launcher.qml` — app launcher + calculator, `qs ipc call launcher toggle` (`SUPER + R`). Search in `fuzzy.js`, math in `calc.js`, units in `units.js`. `>` lists commands from `Commands.qml`.
- `Toasts.qml` — notification toasts, top-right. Draws what `Notifications.qml` holds.
- `Osd.qml` — volume / brightness tab sliding out of the right edge on change.
- `SettingsPage.qml` — `> settings` or `qs ipc call settings toggle`.

### Services (singletons)

- `Theme.qml` — colors, sizes, fonts. Colors from `~/.local/state/quickshell/colors.json` (written by matugen from `matugen/templates/quickshell-colors.json`); roundness and opacity from `Settings`.
- `Settings.qml` — user settings, saved to `~/.local/state/quickshell/settings.json`. Color settings are also read by `scripts/generate-colors.sh`; changing one regenerates the colors.
- `Notifications.qml` — notification server (notify-send etc.), Claude toasts (`qs ipc call claude notify "<title>" "<body>"`), do not disturb.
- `Audio.qml` (Pipewire), `Brightness.qml` (brightnessctl, `qs ipc call brightness up|down`), `Battery.qml` (UPower, low battery toasts at 15% / 5%), `Network.qml` (NetworkManager), `Media.qml` (MPRIS player to show).
- `Wallpaper.qml` — runs `scripts/randomize-wallpaper.sh` (new wallpaper + colors) and `scripts/generate-colors.sh` (new colors from the current wallpaper).
- `Commands.qml` — launcher `>` commands. Add an entry with `name`, `description`, `run`.
- `FocusedScreen.qml` — screen of the focused monitor, where popups open.

### Building blocks

- `Card.qml` — themed rounded surface; `EdgeShape.qml` — themed tab attached to the top or right screen edge; `Shadow.qml` — shared shadow.
- `BarButton.qml` — icon/label item used in the bar; `Calendar.qml`; `SettingSlider.qml`, `SettingChoice.qml`, `SettingToggle.qml`.
- `icons.js` — Nerd Font glyphs (`Theme.iconFont`).
