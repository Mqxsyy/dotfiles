import Quickshell
import QtQuick
import QtQuick.Effects
import "icons.js" as Icons

// What the lock screen shows: the wallpaper, blurred and dimmed, with the
// time, the date and the password as dots. Drawn by LockCover.qml (fading
// over the desktop) and LockSurface.qml (the locked session), so the two
// line up exactly, and by greeter.qml (the login screen).
//
// Typing goes straight into the password (no text box to click) while it
// has focus; Enter checks it, Escape clears it. `auth` is what checks it:
// Lock.qml, or the greeter's login. It has:
//   password, error (rw), checking (ro), submit(), signal failed()
Item {
    id: root

    property real reveal: 1 // 0 = not there, 1 = fully shown
    required property var auth
    // The current wallpaper is loaded and shown (LockSurface.qml waits for
    // it at boot).
    readonly property bool ready: small.status === Image.Ready && small.source.toString() === next.source.toString()

    Keys.onPressed: event => type(event)

    function type(event) {
        event.accepted = true;
        if (auth.checking)
            return;
        auth.error = "";
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
            auth.submit();
        else if (event.key === Qt.Key_Escape)
            auth.password = "";
        else if (event.key === Qt.Key_Backspace)
            auth.password = event.modifiers & Qt.ControlModifier ? "" : auth.password.slice(0, -1);
        else if (event.text.length === 1 && event.text >= " " && event.text !== "\x7f") // printable
            auth.password += event.text;
    }

    // Blurred: a small copy is cheap to blur and smooth when stretched.
    // Zooms in a little as it fades in, which also keeps the blur's soft
    // edges off the screen.
    // The copy has a fixed size (not the window's, unknown until it shows),
    // so with the image cache it's decoded once, in the background, and
    // every screen's cover and lock surface reuse it. Decoding a wallpaper
    // takes ~100 ms, which would freeze the fade.
    // A new wallpaper loads in `next` first and only then replaces the one
    // shown (straight from the cache), so it never goes blank in between.
    Item {
        anchors.fill: parent
        opacity: root.reveal
        scale: 1 + 0.08 * root.reveal

        component SmallWallpaper: Image {
            anchors.fill: parent
            visible: false
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(160, 160) // the smaller side; the other keeps the image's shape
            asynchronous: true
        }

        SmallWallpaper {
            id: next

            source: Wallpaper.current ? "file://" + Wallpaper.current : ""
            onStatusChanged: {
                if (status === Image.Ready)
                    small.source = source;
            }
            Component.onCompleted: {
                if (status === Image.Ready)
                    small.source = source;
            }
        }

        SmallWallpaper {
            id: small
        }

        MultiEffect {
            anchors.fill: parent
            source: small
            blurEnabled: true
            blurMax: 64
            blur: 1
        }

        // Dims it toward the theme's surface color, for the text.
        Rectangle {
            anchors.fill: parent
            color: Theme.surface
            opacity: 0.45
        }
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height * 0.3 + (1 - root.reveal) * 24
        opacity: root.reveal
        spacing: 4

        SystemClock {
            id: clock
            precision: SystemClock.Minutes
        }

        // The colon in the accent color, like the bar's clock.
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            textFormat: Text.StyledText
            text: Qt.formatDateTime(clock.date, "HH") + `<font color="${Theme.accent}">:</font>` + Qt.formatDateTime(clock.date, "mm")
            color: Theme.textPrimary
            font.pixelSize: 112
            font.weight: Font.Normal
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
            color: Theme.textPrimary
            opacity: 0.8
            font.pixelSize: Theme.fontLarge + 3
        }

        Item {
            width: 1
            height: 48
        }

        PasswordField {
            anchors.horizontalCenter: parent.horizontalCenter
            auth: root.auth
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            topPadding: 10
            text: root.auth.error
            color: Theme.error
            opacity: root.auth.error ? 1 : 0
            font.pixelSize: Theme.fontSmall

            Behavior on opacity {
                NumberAnimation { duration: 150 }
            }
        }
    }

    // A dot per typed character; shakes on a wrong password.
    component PasswordField: Rectangle {
        id: field

        required property var auth
        readonly property int dotSize: 8
        readonly property int dotGap: 6
        readonly property int step: dotSize + dotGap
        readonly property int sidePadding: 40 // room for the lock icon
        readonly property int fadeWidth: 32   // dots that don't fit fade out at the left

        // One entry per character. Typing adds or removes only the last
        // one, so the other dots don't redraw.
        function sync() {
            while (dots.count < field.auth.password.length)
                dots.append({});
            while (dots.count > field.auth.password.length)
                dots.remove(dots.count - 1);
        }

        width: 280
        height: 46
        radius: Math.min(Theme.radius, height / 2)
        color: Theme.surface
        border.color: field.auth.checking ? Theme.accent : Theme.border
        border.width: 1

        Behavior on border.color {
            ColorAnimation { duration: 150 }
        }

        RectangularShadow {
            z: -1
            anchors.fill: parent
            radius: parent.radius
            offset.y: 4
            blur: 20
            color: Theme.shadow
        }

        transform: Translate {
            id: shift
        }

        Connections {
            target: field.auth

            function onFailed() {
                shake.restart();
            }

            function onPasswordChanged() {
                field.sync();
            }
        }

        ListModel {
            id: dots
        }

        SequentialAnimation {
            id: shake

            NumberAnimation { target: shift; property: "x"; to: -10; duration: 50 }
            NumberAnimation { target: shift; property: "x"; to: 10; duration: 80 }
            NumberAnimation { target: shift; property: "x"; to: -6; duration: 70 }
            NumberAnimation { target: shift; property: "x"; to: 0; duration: 60 }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            x: 16
            text: Icons.lock
            color: field.auth.checking ? Theme.accent : Theme.textSecondary
            font.family: Theme.iconFont
            font.pixelSize: 16
        }

        Text {
            anchors.centerIn: parent
            opacity: field.auth.password === "" ? 1 : 0
            text: "Password"
            color: Theme.textSecondary
            font.pixelSize: Theme.fontSmall

            Behavior on opacity {
                NumberAnimation { duration: 120 }
            }
        }

        // Centered while they fit. Past that, the newest stay in view and
        // the row slides left, the oldest fading out at the edge.
        Item {
            anchors.fill: parent
            anchors.leftMargin: field.sidePadding
            anchors.rightMargin: field.sidePadding
            clip: true

            Item {
                id: row

                readonly property bool overflowing: width > parent.width

                anchors.verticalCenter: parent.verticalCenter
                x: overflowing ? parent.width - width : (parent.width - width) / 2
                width: dots.count * field.step - field.dotGap
                height: field.dotSize

                Behavior on x {
                    NumberAnimation { duration: 90; easing.type: Easing.OutCubic }
                }

                Repeater {
                    model: dots

                    Rectangle {
                        required property int index

                        x: index * field.step
                        width: field.dotSize
                        height: field.dotSize
                        radius: field.dotSize / 2
                        color: field.auth.checking ? Theme.accent : Theme.textPrimary
                        opacity: row.overflowing ? Math.min(1, Math.max(0, (row.x + x) / field.fadeWidth)) : 1

                        NumberAnimation on scale {
                            from: 0
                            to: 1
                            duration: 140
                            easing.type: Easing.OutBack
                        }

                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }
                    }
                }
            }
        }
    }
}
