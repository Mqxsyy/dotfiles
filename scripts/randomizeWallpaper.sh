#!/bin/zsh

wallpaper_path="$(find "$HOME/dotfiles/wallpapers/wallpapers" -type f | sort -R | head -n 1)"

awww img "$wallpaper_path" -t wipe
