pragma Singleton

import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

// Speakers, microphones and apps playing sound (Pipewire).
//   sink/source:   the default output/input device
//   sinks/sources: every output/input device, to pick the default from
//   streams:       apps currently playing sound, each with its own volume
Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property real volume: sink?.audio?.volume ?? 0 // 0..1
    readonly property bool muted: sink?.audio?.muted ?? false

    readonly property var nodes: Pipewire.nodes.values.filter(node => node.audio)
    readonly property var sinks: nodes.filter(node => node.isSink && !node.isStream)
    readonly property var sources: nodes.filter(node => !node.isSink && !node.isStream)
    readonly property var streams: nodes.filter(node => node.isStream && !node.isSink)

    function setVolume(value) {
        setNodeVolume(sink, value);
    }

    function toggleMute() {
        toggleNodeMute(sink);
    }

    function setNodeVolume(node, value) {
        if (node?.audio)
            node.audio.volume = Math.max(0, Math.min(1, value));
    }

    function toggleNodeMute(node) {
        if (node?.audio)
            node.audio.muted = !node.audio.muted;
    }

    function setDefault(node) {
        if (node.isSink)
            Pipewire.preferredDefaultAudioSink = node;
        else
            Pipewire.preferredDefaultAudioSource = node;
    }

    // Readable names. Devices: "Speaker", apps: "Firefox".
    function deviceName(node) {
        return node?.description || node?.nickname || node?.name || "";
    }

    function appName(node) {
        const props = node.properties;
        return props["application.name"] || node.description || node.name;
    }

    // What the app is playing, e.g. a tab title.
    function streamTitle(node) {
        return node.properties["media.name"] ?? "";
    }

    function appIcon(node) {
        const props = node.properties;
        return props["application.icon-name"] || props["application.process.binary"] || "";
    }

    // Pipewire only reports volume for nodes that are tracked.
    PwObjectTracker {
        objects: root.nodes
    }
}
