#!/usr/bin/env bash
# Claude Code Stop hook: show the quickshell popup when Claude finishes a response.
# Reads the hook's JSON payload on stdin.

cwd=$(jq -r '.cwd // empty')
project=$(basename "${cwd:-$PWD}")

# Serialize startup: simultaneous hooks would otherwise all see "not running"
# and each launch an instance (-n alone is racy).
(
    flock -w 5 9
    if ! qs ipc show >/dev/null 2>&1; then
        qs -n -d >/dev/null 2>&1
        for _ in {1..30}; do
            qs ipc show >/dev/null 2>&1 && break
            sleep 0.1
        done
    fi
) 9>"${XDG_RUNTIME_DIR:-/tmp}/claude-notify.lock"

qs ipc call claude notify "Claude" "Task finished in $project" >/dev/null 2>&1
