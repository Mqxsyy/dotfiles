# Login screen (greetd)

At boot, the lock screen is the login screen. greetd logs in and starts
Hyprland with the session already locked (`--locked-cmd`, before anything is
drawn); `quickshell/scripts/start-locked.sh` tells the shell to put its lock
screen up as soon as it starts (`Lock.qml`), and it fades in from black. The
password is checked like logging in (PAM `login`, including the lockout after
wrong tries). Unlocking fades straight onto the desktop: one Hyprland from boot
to desktop, nothing in between. If the shell never starts, Hyprland stays
locked (and says so after 5 seconds); if Hyprland crashes while locked,
`start-hyprland` restarts it locked.

After logging out, greetd shows a separate login screen that looks the same:
a small Hyprland (`hypr/greeter.lua`, sharing `hypr/hardware.lua` with the
session) running the quickshell greeter (`quickshell/greeter.qml`, drawing
`LockView.qml`). Type the password, Enter logs in and starts `start-hyprland`.

The greeter runs as the `greeter` user but reads the user's colors, settings
and wallpaper. The user's home is private, so `greeter` gets an ACL to pass
through the folders on the way (it can't list them, and only reads files that
are readable by everyone anyway).

## Setup

1. Let `greeter` reach the shell config, colors, settings and wallpaper:

   ```sh
   sudo setfacl -m u:greeter:x /home/mqx /home/mqx/.local /home/mqx/.local/state
   ```

2. Check it can read them (each should print `ok`):

   ```sh
   sudo -u greeter test -r /home/mqx/dotfiles/quickshell/greeter.qml && echo ok
   sudo -u greeter test -r /home/mqx/.local/state/quickshell/colors.json && echo ok
   sudo -u greeter test -r "$(cat ~/.local/state/quickshell/wallpaper)" && echo ok
   ```

3. Install the greetd config:

   ```sh
   sudo cp ~/dotfiles/greetd/config.toml /etc/greetd/config.toml
   ```

4. Switch from SDDM to greetd (takes effect on the next boot):

   ```sh
   sudo systemctl disable sddm
   sudo systemctl enable greetd
   ```

5. Reboot.

Changes to the QML or Hyprland files apply on the next boot or login screen;
only `greetd/config.toml` needs copying again.

## If the login screen doesn't come up

A warning that the lock screen died: the session is locked, but the shell
didn't take over. From a text login (below), start it in the session:

```sh
WAYLAND_DISPLAY=wayland-1 qs -n -d
WAYLAND_DISPLAY=wayland-1 qs ipc call lock lock
```

Then go back with `Ctrl + Alt + F1` and unlock.

Anything else:

`Ctrl + Alt + F2` for a text login, log in, then go back to SDDM:

```sh
sudo systemctl disable greetd
sudo systemctl enable sddm
sudo reboot
```

What went wrong:

- greetd: `journalctl -b -u greetd`
- the greeter's Hyprland: `sudo cat /run/user/$(id -u greeter)/hypr/*/hyprland.log`
- the greeter itself: `sudo find /run/user/$(id -u greeter)/quickshell -name '*.qslog'`, then `sudo qs log <that file>`

Three wrong passwords in a row lock the account for 10 minutes (Arch's
`pam_faillock`, same as with SDDM).
