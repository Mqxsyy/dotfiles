#!/bin/zsh
# Runs the shell, and starts it again whenever it dies (a crash, `qs kill`,
# restart.sh) until the session ends. Started by Hyprland (hypr/hyprland.lua);
# only one runs at a time.

exec {lock}>"$XDG_RUNTIME_DIR/quickshell-keep-running.lock"
flock -n $lock || exit 0

while [[ -S "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" ]]; do
	qs -n {lock}>&- # apps it starts must not hold the lock
	sleep 2
done
