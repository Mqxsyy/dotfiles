#!/bin/bash

VINEGAR_DATA="$HOME/.var/app/org.vinegarhq.Vinegar/data/vinegar"
VINEGAR_WINE="$VINEGAR_DATA/kombucha/bin/wine"
export WINEPREFIX="$VINEGAR_DATA/prefixes/studio"

# version-* dir changes on every Studio update, pick newest
VINEGAR_MCP=$(ls -td "$VINEGAR_DATA"/versions/version-*/StudioMCP.exe 2>/dev/null | head -n1)

if [ -f "$VINEGAR_MCP" ]; then
    exec "$VINEGAR_WINE" "$VINEGAR_MCP" "$@"
else
    CONTENT_FOLDER=$("$VINEGAR_WINE" reg query "HKEY_CURRENT_USER\\Software\\Roblox\\RobloxStudio" /v ContentFolder 2>/dev/null | grep -oP '(?<=ContentFolder\s{4}REG_SZ\s{4}).+' | tr -d '\r')
    if [ -n "$CONTENT_FOLDER" ]; then

        MCP_WIN_PATH="${CONTENT_FOLDER}\\..\\StudioMCP.exe"
        exec "$VINEGAR_WINE" "$MCP_WIN_PATH" "$@"
    else
        echo "wtf 67 studiomcp.exe dont exists" >&2
        exit 1
    fi
fi
