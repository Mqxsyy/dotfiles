pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Screen brightness through brightnessctl. The kernel doesn't announce
// brightness changes, so the brightness keys go through here (hyprland.lua):
//   qs ipc call brightness up
//   qs ipc call brightness down
Singleton {
    id: root

    property real value: 0      // 0..1
    property string step: "10%"

    // Emitted after up() or down() took effect; the OSD listens for it.
    signal adjusted()

    function up() {
        adjust.exec(["brightnessctl", "-m", "set", step + "+"]);
    }

    function down() {
        adjust.exec(["brightnessctl", "-m", "set", step + "-"]);
    }

    // brightnessctl -m prints "device,class,current,percent,max".
    function parse(text) {
        const fields = text.trim().split(",");
        if (fields.length >= 5)
            root.value = Number(fields[2]) / Number(fields[4]);
    }

    Process {
        command: ["brightnessctl", "-m"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
    }

    Process {
        id: adjust
        stdout: StdioCollector {
            onStreamFinished: {
                root.parse(text);
                root.adjusted();
            }
        }
    }

    IpcHandler {
        target: "brightness"

        function up(): void {
            root.up();
        }

        function down(): void {
            root.down();
        }
    }
}
