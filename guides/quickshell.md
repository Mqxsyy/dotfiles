# Quickshell

- Simple overview of quickshell
- Short & concise
- Keep up to date

## Layout

Config lives in `quickshell/` (symlinked to `~/.config/quickshell`).

```
shell.qml      the shell: lists its windows
greeter.qml    the login screen after logout, run by greetd (guides/greeter.md)
config/        Settings, Theme, Commands: what you tweak
services/      singletons holding state (audio, lock, wallpaper, ...), no UI
components/    reusable widgets (cards, buttons, sliders, rows, windows)
modules/       the parts of the shell, one folder each
utils/         plain JS helpers (icons, fuzzy search, calculator, units)
scripts/       shell scripts the services run
```

Folders are imported as modules: `import qs.services`, `import qs.components`, `import qs.modules.bar`. Files in the same folder need no import. JS files are imported by path (`import "../../utils/icons.js" as Icons`). Singletons (`pragma Singleton`) are used by name, e.g. `Theme.accent`.

User state lives in `~/.local/state/quickshell/`: `settings.json`, `colors.json` (matugen, from `matugen/templates/quickshell-colors.json`), `wallpaper`, `notifications.json`, `launcher.json`.

## Modules

All windows are `components/ShellWindow.qml`: transparent, above other windows, namespaced `qs-<name>` (or `qs-blur-<name>` with Glass on, blurred by the `quickshell-glass` layer rule in `hypr/hyprland.lua`).

- `bar/` — `Bar.qml` slides down when the pointer touches the top edge, and stays while it is within the bar's height. Three cards grow into panels on hover: now playing (`MediaView`; its spectrum visualizer needs `cava`, set up in `config/cava.conf`), the clock (the dashboard), and the status card (`NotificationsView`, `WifiView`, `BluetoothView`, `AudioView`, `BrightnessView`; power opens the power menu). The bluetooth icon only shows while Bluetooth is on (dashboard toggle; needs `bluetooth.service`). `qs ipc call bar open <part>` or `> audio`, `> wifi`, `> bluetooth`, `> media`, `> notifications` open a part.
- `dashboard/` — `DashboardView.qml`, the clock card's panel. Tabs: Overview (`Calendar`, quick toggles, shortcuts), System (`SystemView`: CPU, memory, GPU, disk, processes), Clean (`CleanView`: caches, old packages, logs; click twice to clean, hover shows the command, system entries run in kitty where sudo asks).
- `launcher/` — `Launcher.qml`: apps, calculator, units, `>` commands (`config/Commands.qml`). `SUPER + R`, `qs ipc call launcher toggle`. Often and recently used apps rank higher.
- `popups/` — panels opened one at a time through `services/Popups.qml` (`qs ipc call popup toggle <name>`), closed with Esc or a click outside:
  - `ClipboardPanel` (`clipboard`, `SUPER + SHIFT + V`): history, filter, Enter copies back.
  - `CapturePanel` (`screenshot`, `record`): region / screen; Freeze holds the screen still while picking a region (also used by `SUPER + P`); recording with or without sound.
  - `PowerMenu` (`power`): lock, log out, suspend, restart, shut down; each needs a confirming click (or Enter), and runs once the menu has slid away. `> logout`, `> suspend`, `> restart`, `> shutdown` open it with that action armed.
  - `WallpaperPicker` (`wallpapers`): thumbnails, type to filter.
  - `SettingsPage` (`settings`): categories on the left (Appearance, Wallpaper, Night light, Screenshots, Lock; Up/Down switch), the page slides in on the right.
  - `WindowOverview` (`windows`, `SUPER + Tab`): quick glance at every workspace in use, as small live desktops in centered, evenly filled rows with their apps' icons under them. Only for looking: hold `SUPER + Tab` to peek, let go to dismiss; opened another way, Esc, a click or `SUPER + Tab` closes it. `qs ipc call windows toggle`.
  - `PolkitPrompt` (`polkit`): the session's polkit agent; asks for the password when an app needs admin rights (pkexec, mounting drives). Closing it cancels.
- `overlays/` — `Toasts.qml` (notifications, top right), `Osd.qml` (volume / brightness), `RecordingCard.qml` (time and stop while recording).
- `lock/` — `LockScreen.qml` locks the session with a `LockSurface` per screen; `LockCover.qml` fades the same `LockView` in over the desktop first, since Hyprland locks instantly. Type the password, Enter checks, Esc clears. `SUPER + Escape`, `> lock`, `qs ipc call lock lock`, or after the idle minutes set in settings.
- `background/` — `Background.qml`, the wallpaper per screen; `WallpaperView.qml` grows or swipes a new one in.

## Services

- `Lock` — lock state, kept across config reloads so saving a file doesn't unlock. Password checked with PAM `login` (lockout after wrong tries). At boot it is the login screen (`guides/greeter.md`).
- `Notifications` — notification server, do not disturb, history; Claude toasts via `qs ipc call claude notify "<title>" "<body>"`.
- `Recorder` — screenshots (`scripts/screenshot.sh`), recordings (`scripts/record.sh`, wf-recorder), color picker (hyprpicker). Files go to `/tmp/quickshell/` and the clipboard. `SUPER + P` region screenshot of the screen as it is (panels and bar included), `SUPER + [` record panel, `SUPER + ]` stop.
- `Wallpaper` — current wallpaper and picker list; `scripts/set-wallpaper.sh`, `randomize-wallpaper.sh` (`> shuffle`), `generate-colors.sh`.
- `NightLight` — warmer colors through a Hyprland screen shader; `> night`, `qs ipc call nightlight toggle`.
- `Cleanup` — the Clean tab's list. Add an entry with `name`, `detail`, `paths` or `size` / `clean`, and `root` when it needs sudo.
- `Clipboard` (`scripts/clipboard-watch.sh`, skips password manager copies), `Audio` (Pipewire), `Brightness` (brightnessctl, `qs ipc call brightness up|down`), `Battery` (UPower, low battery toasts), `Network` (NetworkManager), `Media` (MPRIS, `qs ipc call media playPause|next|previous`), `System` (top, sensors, nvidia-smi, df), `Popups` (which panel is open), `BarLayout` (where the bar is, for toasts), `FocusedScreen`.

## Config

- `Settings.qml` — user settings, saved to `settings.json`. Changing a color setting regenerates the colors.
- `Theme.qml` — colors, sizes, fonts.
- `Commands.qml` — launcher `>` commands: add an entry with `name`, `description`, `run`.

## Gotchas

- Keep text out of layers (`layer.enabled`): it gets resampled and looks blurry.
- No optional calls (`fn?.()`): Qt 6.11's QML compiler segfaults on them and quickshell dies on load. Use `if (fn) fn()`.
- No `options` or `status` variables in zsh scripts: zsh reserves them.
- Hyprland gives the pointer to a newly shown overlay (slurp) only after the pointer moves; `pick-region.sh` moves the cursor onto itself to hand it over.
- Commands run by quickshell get an open stdin pipe: give tools that read stdin when it isn't a terminal (slurp) `</dev/null`.
- If quickshell dies while locked, Hyprland keeps the session locked (with a warning screen). From a TTY (`Ctrl + Alt + F2`, log in): `hyprctl --instance 0 eval 'hl.config({ misc = { allow_session_lock_restore = true } })'`, then `WAYLAND_DISPLAY=wayland-1 qs -n -d` and `WAYLAND_DISPLAY=wayland-1 qs ipc call lock lock`; back on the Hyprland TTY, unlock with the password.
