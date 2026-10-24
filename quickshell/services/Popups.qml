pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Which panel is open: "power", "wallpapers", "settings", "clipboard",
// "screenshot", "record", "windows", "polkit", or "" for none. Only one is
// open at a time. Panels exist only while open or closing (LazyPopup.qml).
//   qs ipc call popup toggle clipboard
Singleton {
    id: root

    property string current: ""
    // The panel still animating out after `current` moved on, or "".
    property string closing: ""
    // Where it opens; the focused screen when not given.
    property ShellScreen screen: null
    // What the panel starts with, when given, e.g. the power action to confirm.
    property var request: null

    function open(name, screen, request) {
        root.screen = screen ?? FocusedScreen.screen;
        root.request = request ?? null;
        if (current !== "" && current !== name)
            closing = current;
        current = name;
    }

    function toggle(name, screen) {
        if (current === name)
            close();
        else
            open(name, screen);
    }

    function close() {
        if (current === "")
            return;
        closing = current;
        current = "";
    }

    // Called by a panel once it has animated out.
    function closed(name) {
        if (closing === name)
            closing = "";
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

    // Super+Tab: the window overview, closed again when Super is let go.
    IpcHandler {
        target: "windows"

        function toggle(): void {
            if (root.current === "windows")
                root.close();
            else
                root.open("windows", null, "hold");
        }
    }
}
