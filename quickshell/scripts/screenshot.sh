#!/bin/zsh
# Take a screenshot, save it to <file> and copy it to the clipboard.
# Usage: screenshot.sh <region|screen> <file> [freeze]
#   region: drag to select (Esc cancels); screen: the focused monitor
#   freeze: the screen holds still while picking the region, so what's
#           taken is what was there when it started (menus, videos)
#
# Freezing: hyprpicker draws a still copy of the screen over everything
# (its color picking unused: slurp is on top and gets the clicks), and the
# screenshot is taken of that copy.

mode="$1"
file="$2"
freeze="$3"
mkdir -p "${file:h}"

if [[ "$mode" == "region" ]]; then
    if [[ "$freeze" == "freeze" ]]; then
        hyprpicker --render-inactive --no-zoom --disable-preview --quiet >/dev/null &
        picker=$!
        trap 'kill $picker 2>/dev/null' EXIT
        # Wait (up to a second) for the still copy to be on screen.
        for _ in {1..50}; do
            hyprctl layers | grep -q "namespace: hyprpicker, pid: $picker" && break
            sleep 0.02
        done
    fi
    geometry="$("${0:A:h}/pick-region.sh")" || exit 1
    grim -g "$geometry" "$file" || exit 1
else
    monitor="$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')"
    grim -o "$monitor" "$file" || exit 1
fi

wl-copy --type image/png <"$file"
