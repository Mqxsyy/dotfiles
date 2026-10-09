#!/bin/zsh
# Pick a random wallpaper, show it, and recolor everything from it
# (generate-colors.sh; quickshell, kitty, tmux, ...: see matugen/config.toml).
# Usage: randomize-wallpaper.sh [folder]   (default: all wallpapers)

folder="${1:-$HOME/dotfiles/wallpapers}"

wallpaper="$(find "$folder" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) | shuf -n 1)"
if [[ -z "$wallpaper" ]]; then
    echo "No wallpapers found in $folder" >&2
    exit 1
fi

awww img "$wallpaper" -t wipe
"$HOME/dotfiles/scripts/generate-colors.sh" "$wallpaper"
