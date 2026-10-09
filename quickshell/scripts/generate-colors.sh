#!/bin/zsh
# Generate the color scheme from an image with matugen, using the color
# settings from the quickshell settings page ("> settings" in the launcher).
# Usage: generate-colors.sh [image]   (default: the current wallpaper)

settings="$HOME/.local/state/quickshell/settings.json"
image="${1:-$(<"$HOME/.local/state/quickshell/wallpaper")}"

# A value from the settings file, or nothing when it (or the file) is missing.
setting() {
    jq -r ".$1 // empty" "$settings" 2>/dev/null
}

matugen image "$image" \
    --type "${$(setting scheme):-scheme-tonal-spot}" \
    --mode "${$(setting mode):-dark}" \
    --contrast "${$(setting contrast):-0}" \
    --prefer "${$(setting prefer):-saturation}" \
    --quiet
