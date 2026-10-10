pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// What's playing, split into frequency bands by cava (config/cava.conf sets
// the band count and smoothing): `levels` is 0..1 per band, bass first.
// Runs whenever music plays, not just while a visualizer is on screen: cava
// takes a second or so to settle on the volume, which would show as flat
// bars every time the media panel opens.
Singleton {
    id: root

    property var levels: []
    // How many bands; changes only when the config does.
    readonly property int bands: levels.length

    // Stopped: the bands rest flat.
    function rest() {
        levels = levels.map(() => 0);
    }

    Process {
        running: Media.player?.isPlaying ?? false
        command: ["cava", "-p", Quickshell.shellDir + "/config/cava.conf"]
        onRunningChanged: if (!running) root.rest()

        // One frame per line: "12;40;33;..." (0-100, with a trailing ";").
        stdout: SplitParser {
            onRead: line => root.levels = line.split(";").filter(value => value !== "").map(value => value / 100)
        }
    }
}
