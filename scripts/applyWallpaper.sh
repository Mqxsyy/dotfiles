#!/bin/zsh

# Variables
wallpaper_path="$HOME/.config/wallpaper.mp4"

{
    # Apply Wallpaper
    pkill mpvpaper
    mpvpaper -p -o "--panscan=1 --loop-file=inf --mute=yes --speed=0.4" '*' "$wallpaper_path" &
    disown
} > /dev/null 2>&1
