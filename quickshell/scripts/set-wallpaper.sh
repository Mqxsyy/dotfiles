#!/bin/zsh
# Show a wallpaper and recolor everything from it
# (generate-colors.sh; quickshell, kitty, tmux, ...: see matugen/config.toml).
# Quickshell shows the image named in the state file (Background.qml).
# Usage: set-wallpaper.sh <image>

wallpaper="$1"
state="$HOME/.local/state/quickshell/wallpaper"
if [[ ! -f "$wallpaper" ]]; then
    echo "No such image: $wallpaper" >&2
    exit 1
fi

mkdir -p "${state:h}"
print -r -- "${wallpaper:A}" >"$state"
"${0:A:h}/generate-colors.sh" "$wallpaper"
