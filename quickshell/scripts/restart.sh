#!/bin/zsh
# Restarts the shell, also when it froze or broke: stops it, and
# keep-running.sh starts it again (this becomes that when it isn't running).
# SUPER + SHIFT + R, "> restart shell" in the launcher, or Reload on the dashboard.

qs kill
exec "${0:A:h}/keep-running.sh"
