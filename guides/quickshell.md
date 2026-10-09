# Quickshell

- Simple overview of quickshell
- Short & concise
- Keep up to date

## Overview

Config lives in `quickshell/` (symlinked to `~/.config/quickshell`); the shell scripts it runs are in `quickshell/scripts/`. `shell.qml` lists the windows. Shared state and services are singletons (`pragma Singleton`), used by name from any file.

### Windows

All windows are `ShellWindow`s (`ShellWindow.qml`): transparent, over other windows, and named `qs-<name>` — or `qs-blur-<name>` with Glass on, which the `quickshell-glass` layer rule in `hypr/hyprland.lua` blurs.

- `Bar.qml` — slides down on each screen when the pointer reaches the top center, and stays until the pointer leaves the bar. Three parts grow into panels while hovered: the now-playing card top-left (`MediaView`), the clock card top-center (`DashboardView`: Overview tab with calendar, quick toggles, shortcuts; System tab with `SystemView`; Clean tab with `CleanView`), and the status card top-right (hover the bell → `NotificationsView`: history, do not disturb, clear; click it for do not disturb; hover wifi → `WifiView`, volume → `AudioView`, brightness → `BrightnessView`; click power → power menu). Stays while hovered, expanded, dragging or typing a password. A media key opens just the now-playing card for a moment. `> audio`, `> wifi`, `> media`, `> notifications` (or `qs ipc call bar open <part>`, `BarLayout.open`) show the bar with that part expanded.
- `Launcher.qml` — app launcher + calculator, `qs ipc call launcher toggle` (`SUPER + R`). Search in `fuzzy.js`, math in `calc.js`, units in `units.js`. `>` lists commands from `Commands.qml`. Apps launched often and recently rank higher (`~/.local/state/quickshell/launcher.json`).
- `RecordingCard.qml` — while recording: time, stop hotkey and stop button, fixed at the top center just below the bar (reaching it never reveals the bar), on the overlay layer so it's above fullscreen windows. One per screen.
- `Toasts.qml` — notification toasts, top-right, pushed under the bar while it shows (`BarLayout.qml`). Draws what `Notifications.qml` holds.
- `Osd.qml` — volume / brightness card sliding in at the right on change.
- `LockScreen.qml` — the lock screen (`WlSessionLock`), a `LockSurface.qml` per screen showing `LockView.qml`: blurred wallpaper, clock, date, password dots. Just type; Enter checks, Esc clears. `LockCover.qml` (overlay layer) fades the same view in over the desktop before the session locks and out after it unlocks, since Hyprland switches instantly. `SUPER + Escape`, `> lock`, power menu, `qs ipc call lock lock`, or after the idle minutes set on the settings page (Lock).
- `greeter.qml` — the login screen, a separate entry run by greetd (not part of `shell.qml`); see `guides/greeter.md`.
- `Background.qml` — the wallpaper, on the background layer of each screen (`WallpaperView.qml`: a new one grows in from the center or swipes in from the top-right corner, picked in settings).

### Panels

`Popup.qml` windows: open one at a time through `Popups.qml` (`qs ipc call popup toggle <name>`), close with Esc or a click outside.

- `ClipboardPanel.qml` (`clipboard`) — `SUPER + SHIFT + V` or `> clipboard`: history, filter, Enter to copy back.
- `CapturePanel.qml` (`screenshot`, `record`) — made twice: `> screenshot` (region / screen, Freeze: the screen holds still while picking a region, remembered in `Settings.screenshotFreeze` so `Super P` uses it too) and `> record` (region / screen, sound, Stop). While recording, `RecordingCard.qml` shows the time; click it to stop.
- `PowerMenu.qml` (`power`) — lock / log out / suspend (locks first) / restart / shut down, card at the right. Every action needs a second, confirming click.
- `WallpaperPicker.qml` (`wallpapers`) — `> wallpaper`; thumbnails of a folder, type to filter, click or Enter to set.
- `SettingsPage.qml` (`settings`) — `> settings` or `qs ipc call settings toggle`; categories Appearance / Wallpaper / Night light / Lock picked with `Tabs.qml` (also the dashboard's tabs).

### Services (singletons)

- `Theme.qml` — colors, sizes, fonts. Colors from `~/.local/state/quickshell/colors.json` (written by matugen from `matugen/templates/quickshell-colors.json`); roundness and opacity from `Settings`.
- `Settings.qml` — user settings, saved to `~/.local/state/quickshell/settings.json`. Color settings are also read by `quickshell/scripts/generate-colors.sh`; changing one regenerates the colors.
- `Notifications.qml` — notification server (notify-send etc.), Claude toasts (`qs ipc call claude notify "<title>" "<body>"`), do not disturb, and the history (`~/.local/state/quickshell/notifications.json`, also what came in during do not disturb).
- `NightLight.qml` — warmer colors through a Hyprland screen shader written to `~/.local/state/quickshell/night-light-<kelvin>.frag`; Quick settings tile, `> night`, `qs ipc call nightlight toggle`, warmth and on/off hours on the settings page. Screenshots get the tint too.
- `Lock.qml` — lock state, kept across config reloads (`PersistentProperties`) so saving a file doesn't unlock; checks the password with PAM `login`, like logging in (lockout after wrong tries); at boot it's the login screen (`guides/greeter.md`); idle lock (`IdleMonitor`, `Settings.lockAfter` minutes, 0 = never).
- `Audio.qml` (Pipewire), `Brightness.qml` (brightnessctl, `qs ipc call brightness up|down`), `Battery.qml` (UPower, low battery toasts at 15% / 5%), `Network.qml` (NetworkManager), `Media.qml` (MPRIS player to show; media keys via `qs ipc call media playPause|next|previous`).
- `Wallpaper.qml` — current wallpaper (the path in `~/.local/state/quickshell/wallpaper`) and the picker's image list; runs `quickshell/scripts/set-wallpaper.sh` (writes that path + new colors), `quickshell/scripts/randomize-wallpaper.sh` (random one, `> shuffle`) and `quickshell/scripts/generate-colors.sh` (new colors from the current wallpaper).
- `System.qml` — stats from `top`, `sensors`, `nvidia-smi`, `df`, `/proc/net/dev`.
- `Cleanup.qml` — what can be cleaned (trash, caches, AUR builds, old and unused packages, logs, crash reports), each with a size and a clean command. Click twice to clean; hover shows the command. System entries open kitty showing the command, sudo asks there. Add an entry to the list to add one.
- `Clipboard.qml` — history from `quickshell/scripts/clipboard-watch.sh` (`wl-paste --watch`), saved in `~/.cache/quickshell/clipboard/`. Password manager copies are skipped.
- `Recorder.qml` — `quickshell/scripts/screenshot.sh` (`/tmp/quickshell/screenshots`, toast with a preview), `quickshell/scripts/record.sh` (wf-recorder, `/tmp/quickshell/recordings`); not kept, paste to save, both picking regions with `quickshell/scripts/pick-region.sh`; hyprpicker; `qs ipc call recorder screenshot|record|toggle <region|screen>`, `stop`. Keys (hypr/hyprland.lua, shown as hints from `Recorder.keys`): `Super P` region screenshot (of the screen as it is: open panels and the bar stay, the bar holds still while picking), `Super [` record panel, `Super ]` stop (a toast says so when nothing records).
- `Commands.qml` — launcher `>` commands. Add an entry with `name`, `description`, `run`.
- `Popups.qml` — which panel is open.
- `FocusedScreen.qml` — screen of the focused monitor, where popups open.

### Building blocks

- `KeyHint.qml` — hotkey shown as key caps; `Card.qml` — themed floating surface (gradient, border, separate `RectangularShadow`; `glows: true` adds the `Backdrop.qml` glow circles). Everything is a floating card. Keep text out of layers (`layer.enabled`): it gets resampled and looks blurry.
- `ArtImage.qml` — album art trying `Media.artSources` best first (full YouTube thumbnails for browser players, which only give MPRIS 60px art); `Visualizer.qml` — live output level bars (Pipewire peak monitor); `Glow.qml` — accent light behind active elements; `Theme.accentGradient` — accent → second accent (matugen `tertiary`) fill for active elements.
- `BarButton.qml` — icon/label item used in the bar; `PanelButton.qml` — filled button; `ListRow.qml` — clickable list row; `PanelCard.qml` — padded card for panels; `SectionTitle.qml`; `Slider.qml`; `TextField.qml`; `Calendar.qml`; views shared by bar and panels: `MediaView.qml`, `WifiView.qml`, `AudioView.qml`, `BrightnessView.qml`, `SystemView.qml`, `CleanView.qml`, `DashboardView.qml`; `SettingSlider.qml`, `SettingChoice.qml`, `SettingToggle.qml`.
- `icons.js` — Nerd Font glyphs (`Theme.iconFont`).

### Gotchas

- No `options` or `status` variables in zsh scripts: zsh reserves them.
- Hyprland gives the pointer to a newly shown overlay (slurp) only after the pointer moves; `pick-region.sh` moves the cursor onto itself to hand it over.
- Commands run by quickshell get an open stdin pipe: give tools that read stdin when it isn't a terminal (slurp) `</dev/null`.
- If quickshell dies while locked, Hyprland keeps the session locked (with a warning screen). Get back in from a TTY (`Ctrl + Alt + F2`, log in): `hyprctl --instance 0 eval 'hl.config({ misc = { allow_session_lock_restore = true } })'`, then `WAYLAND_DISPLAY=wayland-1 qs -n -d` and `WAYLAND_DISPLAY=wayland-1 qs ipc call lock lock`; back on the Hyprland TTY, unlock with the password.
- No optional calls (`fn?.()`): Qt 6.11's QML compiler segfaults on them and quickshell dies on load. Use `if (fn) fn()`.
