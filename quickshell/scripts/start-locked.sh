#!/bin/zsh
# Hyprland's --locked-cmd at boot (greetd/config.toml). Hyprland starts with
# the session already locked; this leaves a note for the shell (Lock.qml),
# which takes it and puts its lock screen up as soon as it starts.

touch "$XDG_RUNTIME_DIR/quickshell-start-locked"
