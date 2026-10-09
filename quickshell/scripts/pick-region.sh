#!/bin/zsh
# Drag to pick a screen region (slurp) and print it as "x,y wxh".
# Exits non-zero when cancelled with Esc.
#
# Hyprland only gives the pointer to slurp's overlay once the pointer moves,
# so a click right after the overlay appears would miss it (it took a second
# click). Moving the cursor onto its own position once the overlay is up
# hands the pointer over straight away.

output="$(mktemp)"
# </dev/null: without a terminal on stdin, slurp waits to read predefined
# boxes from it, and quickshell keeps that pipe open; slurp would never show.
slurp <"/dev/null" >"$output" &
slurp_pid=$!

# Wait (up to a second) for slurp's overlay, the "selection" layer, to be on
# screen. A fixed wait isn't enough: the first run after boot is slower.
for _ in {1..50}; do
    hyprctl layers | grep -q "namespace: selection, pid: $slurp_pid" && break
    sleep 0.02
done

position="$(hyprctl cursorpos | tr -d ' ')"
hyprctl dispatch "hl.dsp.cursor.move({ x = ${position%,*}, y = ${position#*,} })" >/dev/null

wait $slurp_pid
result=$?
[[ $result -eq 0 ]] && cat "$output"
rm -f "$output"
exit $result
