import Quickshell
import Quickshell.Services.Greetd
import Quickshell.Wayland
import QtQuick

// The login screen: the lock screen's look (LockView.qml) on every screen,
// logging in through greetd. Not part of the shell (shell.qml); greetd
// runs it in its own small Hyprland, hypr/greeter.lua:
//   qs -p ~/dotfiles/quickshell/greeter.qml
// It runs as the `greeter` user, with HOME set to the user's home so Theme,
// Settings and Wallpaper read the user's colors, settings and wallpaper.
// GREETER_USER is who logs in.
ShellRoot {
    id: root

    // The session started after logging in, as the login manager started it
    // before (/usr/share/wayland-sessions/hyprland.desktop).
    readonly property var session: ["start-hyprland"]
    readonly property var environment: ["XDG_SESSION_TYPE=wayland", "XDG_CURRENT_DESKTOP=Hyprland", "XDG_SESSION_DESKTOP=Hyprland"]
    property int fadeDuration: 500

    // Fades in from black on start, back to black before the session starts.
    property bool shown: false

    Component.onCompleted: shown = true

    // The password check, shaped like Lock.qml for LockView.
    QtObject {
        id: login

        readonly property string user: Quickshell.env("GREETER_USER")
        property string password: ""
        property string error: ""
        readonly property bool checking: Greetd.state !== GreetdState.Inactive

        signal failed()

        function submit() {
            if (password === "" || checking)
                return;
            if (!Greetd.available) {
                fail("Not running under greetd");
                return;
            }
            error = "";
            Greetd.createSession(user);
        }

        function fail(message) {
            password = "";
            error = message;
            failed();
        }
    }

    Connections {
        target: Greetd

        function onAuthMessage(message, error, responseRequired, echoResponse) {
            if (responseRequired)
                Greetd.respond(login.password);
        }

        function onAuthFailure(message) {
            login.fail("Wrong password");
        }

        function onError(error) {
            login.fail(error);
        }

        function onReadyToLaunch() {
            login.password = "";
            root.shown = false;
            launchDelay.restart();
        }
    }

    // Start the session once faded out; quickshell quits after, and so does
    // the greeter's Hyprland (hypr/greeter.lua).
    Timer {
        id: launchDelay
        interval: root.fadeDuration
        onTriggered: Greetd.launch(root.session, root.environment)
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: window

            required property ShellScreen modelData
            property real reveal: root.shown ? 1 : 0

            screen: modelData
            color: "black"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            WlrLayershell.namespace: "qs-greeter"

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            Behavior on reveal {
                NumberAnimation {
                    duration: root.fadeDuration
                    easing.type: Easing.OutCubic
                }
            }

            LockView {
                anchors.fill: parent
                reveal: window.reveal
                auth: login
                focus: true
            }
        }
    }
}
