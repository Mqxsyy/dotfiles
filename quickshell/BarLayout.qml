pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Where each screen's top bar is, for windows placed around it:
//   rightBottom: how far down its status card reaches (toasts sit under it)
// Values are 0 while a screen has no bar yet.
// open(part) shows the bar on the focused screen with that part expanded:
// "media", "dashboard", "notifications", "wifi", "audio" or "brightness".
//   qs ipc call bar open audio
Singleton {
    id: root

    signal openRequested(string part)

    function open(part) {
        openRequested(part);
    }

    // Screen name -> { rightBottom }.
    property var screens: ({})

    function report(screenName, values) {
        const current = screens[screenName] ?? {};
        const changed = Object.keys(values).some(key => current[key] !== values[key]);
        if (!changed)
            return;
        const next = Object.assign({}, screens);
        next[screenName] = Object.assign({}, current, values);
        screens = next;
    }

    function of(screenName) {
        return screens[screenName] ?? { rightBottom: 0 };
    }

    IpcHandler {
        target: "bar"

        function open(part: string): void {
            root.open(part);
        }
    }
}
