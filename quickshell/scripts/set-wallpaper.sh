#!/bin/zsh
# Show a wallpaper and recolor everything from it
# (generate-colors.sh; quickshell, kitty, tmux, ...: see matugen/config.toml).
# Usage: set-wallpaper.sh <image>

wallpaper="$1"
if [[ ! -f "$wallpaper" ]]; then
    echo "No such image: $wallpaper" >&2
    exit 1
fi

awww img "$wallpaper" -t wipe
"${0:A:h}/generate-colors.sh" "$wallpaper"
