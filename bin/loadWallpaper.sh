#!/bin/zsh

wallpaper_path="../wallpaper.jpg"

if [ $# -lt 1 ]; then
    echo "Missing file path"
    exit 1
fi

image_path="$1"

if [ -f "$wallpaper_path" ]; then
    rm "$wallpaper_path"
fi

cp "$image_path" "$wallpaper_path"

matugen image "$wallpaper_path"

kill -SIGUSR1 $KITTY_PID

clear
neofetch
