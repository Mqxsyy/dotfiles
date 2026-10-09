#!/bin/zsh
# Pick a random wallpaper and set it (set-wallpaper.sh: shows it and recolors).
# Usage: randomize-wallpaper.sh [folder]   (default: all wallpapers)

folder="${1:-$HOME/dotfiles/wallpapers}"

wallpaper="$(find "$folder" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) | shuf -n 1)"
if [[ -z "$wallpaper" ]]; then
    echo "No wallpapers found in $folder" >&2
    exit 1
fi

exec "${0:A:h}/set-wallpaper.sh" "$wallpaper"
