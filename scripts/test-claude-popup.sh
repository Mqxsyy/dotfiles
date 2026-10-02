#!/usr/bin/env bash
# Fire the quickshell Claude popup. Starts quickshell if it isn't running.
# Usage: test-claude-popup.sh [title] [body]

title="${1:-Claude finished}"
body="${2:-Done generating in ~/dotfiles. Waiting for your next prompt.}"

if ! qs ipc show >/dev/null 2>&1; then
    qs -n -d >/dev/null 2>&1
    sleep 1
fi

qs ipc call claude notify "$title" "$body"
