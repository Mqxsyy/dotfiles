#!/bin/zsh
# Record the screen to <file> until wf-recorder gets SIGINT. Prints "started"
# once recording begins (after the region is picked).
# Usage: record.sh <region|screen> <file> [audio device]
#   region: drag to select (Esc cancels); screen: the focused monitor
#   audio device: a Pipewire node name, e.g. the speakers' "<sink>.monitor"
#                 for desktop sound; none records no sound

mode="$1"
file="$2"
audio="$3"
mkdir -p "${file:h}"

if [[ "$mode" == "region" ]]; then
    geometry="$("${0:A:h}/pick-region.sh")" || exit 1
    target=(-g "$geometry")
else
    target=(-o "$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')")
fi

arguments=(-f "$file" -r 30 -c libx264 -p crf=22)
[[ -n "$audio" ]] && arguments+=(--audio="$audio")

echo started
exec wf-recorder $target $arguments
