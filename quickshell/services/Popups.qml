pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Which panel is open: "power", "wallpapers", "settings", "clipboard",
// "screenshot", "record", or "" for none. Only one is open at a time.
//   qs ipc call popup toggle clipboard
Singleton {
    id: root

    property string current: ""
    // Where it opens; the focused screen when not given.
    property ShellScreen screen: null
    // What the panel starts with, when given, e.g. the power action to confirm.
    property var request: null

    function open(name, screen, request) {
        root.screen = screen ?? FocusedScreen.screen;
        root.request = request ?? null;
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
