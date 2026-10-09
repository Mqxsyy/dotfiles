pragma Singleton

import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

// Volume of the default speaker/headphones (Pipewire).
Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property real volume: sink?.audio?.volume ?? 0 // 0..1
    readonly property bool muted: sink?.audio?.muted ?? false

    function setVolume(value) {
        if (sink?.audio)
            sink.audio.volume = Math.max(0, Math.min(1, value));
    }

    function toggleMute() {
        if (sink?.audio)
            sink.audio.muted = !sink.audio.muted;
    }

    // Pipewire only reports volume for nodes that are tracked.
    PwObjectTracker {
        objects: [root.sink]
    }
}
