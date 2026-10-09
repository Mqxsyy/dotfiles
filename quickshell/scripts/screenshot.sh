#!/bin/zsh
# Take a screenshot, save it to <file> and copy it to the clipboard.
# Usage: screenshot.sh <region|screen> <file>
#   region: drag to select (Esc cancels); screen: the focused monitor

mode="$1"
file="$2"
mkdir -p "${file:h}"

if [[ "$mode" == "region" ]]; then
    geometry="$("${0:A:h}/pick-region.sh")" || exit 1
    grim -g "$geometry" "$file" || exit 1
else
    monitor="$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')"
    grim -o "$monitor" "$file" || exit 1
fi

wl-copy --type image/png <"$file"
