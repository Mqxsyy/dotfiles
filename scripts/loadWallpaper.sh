#!/bin/zsh

echo "Loading wallpaper..."

# Variables
wallpaper_path="$HOME/dotfiles/wallpaper.mp4"
first_frame_path="$HOME/dotfiles/first_frame.jpg"

# Check and extract input file path
[[ -z "$1" ]] && echo "Missing file path" && exit 1

# Silence outputs
{
    # Remove old image from dir
    rm -f "$wallpaper_path"

    # Copy wallpaper to new location
    cp "$1" "$wallpaper_path"

    # Extract first frame
    ffmpeg -i "$wallpaper_path" -frames:v 1 "$first_frame_path" 

    # Generate palette
    matugen image "$first_frame_path"

    # Clean first frame
    rm "$first_frame_path"

    # Replace wallpaper
    pkill mpvpaper
    mpvpaper -o "no-audio --loop-file inf" '*' "$wallpaper_path" &
    disown
} > /dev/null 2>&1

# Terminal Output
clear
neofetch
