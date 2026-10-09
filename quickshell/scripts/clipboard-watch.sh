#!/bin/zsh
# Watches the clipboard for quickshell's clipboard history (Clipboard.qml).
# Prints one record per copy, each ending in the \x1e character:
#   text<newline><the copied text>
#   image<newline><path of the png it was saved to, named by its content>
# Copies a password manager marks as secret are skipped.
# Usage: clipboard-watch.sh <image folder>

folder="$1"

# wl-paste runs this script again for every copy, with the copy on stdin.
if [[ "$2" != "--entry" ]]; then
    mkdir -p "$folder"
    exec wl-paste --watch "$0" "$folder" --entry
fi

types="$(wl-paste --list-types)"

if grep -q 'x-kde-passwordManagerHint' <<<"$types"; then
    cat >/dev/null
    exit 0
fi

if grep -q '^image/png' <<<"$types" && ! grep -q '^text/plain' <<<"$types"; then
    cat >/dev/null
    # Named by content, so the same image copied again is the same file.
    incoming="$folder/incoming.png"
    wl-paste --type image/png >"$incoming"
    file="$folder/$(sha1sum <"$incoming" | cut -c1-16).png"
    mv "$incoming" "$file"
    printf 'image\n%s\x1e' "$file"
else
    printf 'text\n'
    cat
    printf '\x1e'
fi
