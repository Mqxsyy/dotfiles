pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "icons.js" as Icons

// Screenshots, screen recordings and the color picker. Both only go to
// /tmp (gone after a reboot) and the clipboard; paste one somewhere to keep it.
//   screenshot("region" | "screen"): saved to `screenshots`, copied to the clipboard
//   record("region" | "screen"):     saved to `recordings`; stop() ends it and
//                                    copies the file to the clipboard (paste it
//                                    into a chat or file manager)
//   pickColor():                     click anywhere to copy that color's hex
// "region" lets you drag a rectangle; Esc cancels. "screen" is the focused monitor.
//   qs ipc call recorder screenshot region | record screen | stop
Singleton {
    id: root

    readonly property string screenshots: "/tmp/quickshell/screenshots"
    readonly property string recordings: "/tmp/quickshell/recordings"
    readonly property string scripts: Quickshell.shellDir + "/scripts/"

    // Hotkeys shown as hints (KeyHint.qml); the binds are in hypr/hyprland.lua.
    //   screenshot: region screenshot, record: open the record panel, stop: stop recording
    readonly property var keys: ({
        screenshot: ["Super", "P"],
        record: ["Super", "["],
        stop: ["Super", "]"],
    })

    // Sound in recordings: "none", or "all": everything the computer plays
    // (the default output's monitor; never the microphone).
    property string audio: "none"

    readonly property bool busy: recorder.running
    property bool recording: false
    property real startedAt: 0
    property int elapsed: 0 // seconds
    property string file: ""

    // Run after the panel that asked for it is gone, so it isn't in the shot.
    property var pending: null

    function later(action) {
        Popups.close();
        pending = action;
        delay.restart();
    }

    function stamp() {
        return Qt.formatDateTime(new Date(), "yyyy-MM-dd_HH-mm-ss");
    }

    function screenshot(mode) {
        later(() => {
            const file = `${screenshots}/${stamp()}.png`;
            shooter.file = file;
            shooter.exec([scripts + "screenshot.sh", mode, file]);
        });
    }

    function record(mode) {
        if (busy)
            return;
        later(() => {
            const devices = {
                none: "",
                all: Audio.sink ? Audio.sink.name + ".monitor" : "",
            };
            file = `${recordings}/${stamp()}.mp4`;
            recorder.exec([scripts + "record.sh", mode, file, devices[audio]]);
        });
    }

    function stop() {
        if (busy) {
            recorder.signal(2); // SIGINT: wf-recorder finishes the file
            return;
        }
        Notifications.notify({
            title: "Nothing to stop",
            body: "No recording in progress",
            glyph: Icons.record,
            timeout: 2500,
            history: false,
        });
    }

    function pickColor() {
        later(() => Quickshell.execDetached(["hyprpicker", "--autocopy"]));
    }

    function open(file) {
        Quickshell.execDetached(["xdg-open", file]);
    }

    Timer {
        id: delay
        interval: Theme.animationDuration + 100
        onTriggered: root.pending()
    }

    Timer {
        running: root.recording
        interval: 1000
        repeat: true
        onTriggered: root.elapsed = Math.round((Date.now() - root.startedAt) / 1000)
    }

    Process {
        id: shooter

        property string file: ""

        onExited: exitCode => {
            if (exitCode !== 0)
                return;
            const file = shooter.file;
            Notifications.notify({
                title: "Screenshot · copied",
                body: "In " + file,
                glyph: Icons.screenshot,
                image: file,
                action: () => root.open(file),
            });
        }
    }

    Process {
        id: recorder

        stdout: SplitParser {
            onRead: line => {
                if (line !== "started")
                    return;
                root.startedAt = Date.now();
                root.elapsed = 0;
                root.recording = true;
            }
        }

        onExited: exitCode => {
            const wasRecording = root.recording;
            root.recording = false;
            if (!wasRecording)
                return; // region picking was cancelled
            const file = root.file;
            Quickshell.execDetached(["sh", "-c", 'printf "file://%s" "$1" | wl-copy --type text/uri-list', "sh", file]);
            Notifications.notify({
                title: "Recording · copied",
                body: "In " + file,
                glyph: Icons.record,
                action: () => root.open(file),
            });
        }
    }

    IpcHandler {
        target: "recorder"

        function screenshot(mode: string): void {
            root.screenshot(mode);
        }

        function record(mode: string): void {
            root.record(mode);
        }

        function stop(): void {
            root.stop();
        }

        function toggle(mode: string): void {
            if (root.busy)
                root.stop();
            else
                root.record(mode);
        }
    }
}
