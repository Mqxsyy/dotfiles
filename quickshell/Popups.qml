pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Which panel is open: "wifi", "audio", "media", "power", "wallpapers",
// "settings", or "" for none. Only one is open at a time.
//   qs ipc call popup toggle wifi
Singleton {
    id: root

    property string current: ""
    // Where it opens; the focused screen when not given.
    property ShellScreen screen: null

    function open(name, screen) {
        root.screen = screen ?? FocusedScreen.screen;
        current = name;
    }

    function toggle(name, screen) {
        if (current === name)
            close();
        else
            open(name, screen);
    }

    function close() {
        current = "";
    }

    IpcHandler {
        target: "popup"

        function toggle(name: string): void {
            root.toggle(name);
        }

        function close(): void {
            root.close();
        }
    }
}
