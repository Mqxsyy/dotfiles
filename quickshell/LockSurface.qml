import Quickshell.Wayland
import QtQuick

// The locked session on one screen (LockScreen.qml): LockView, fully shown.
// Typing goes straight into Lock.password (no text box to click); Enter
// checks it, Escape clears it.
WlSessionLockSurface {
    id: root

    color: "black"

    function type(event) {
        event.accepted = true;
        if (Lock.checking)
            return;
        Lock.error = "";
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
            Lock.submit();
        else if (event.key === Qt.Key_Escape)
            Lock.password = "";
        else if (event.key === Qt.Key_Backspace)
            Lock.password = event.modifiers & Qt.ControlModifier ? "" : Lock.password.slice(0, -1);
        else if (event.text.length === 1 && event.text >= " " && event.text !== "\x7f") // printable
            Lock.password += event.text;
    }

    LockView {
        anchors.fill: parent
        focus: true
        Keys.onPressed: event => root.type(event)
    }
}
