#!/bin/zsh

echo "Loading wallpaper..."

# Variables
wallpaper_path="$HOME/.config/wallpaper.jpg"

# Check and extract input file path
[[ -z "$1" ]] && echo "Missing file path" && exit 1

# Silence outputs
{
    # Remove old image from dir
    rm -f "$wallpaper_path"

    # Copy wallpaper to new location
    cp "$1" "$wallpaper_path"

    # Generate palette
    matugen image "$wallpaper_path" --type scheme-content

    # Replace wallpaper
    swww img "$wallpaper_path" &
    disown
} > /dev/null 2>&1

# Terminal Output
clear
neofetch
