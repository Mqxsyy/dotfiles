pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import QtQuick
import qs.config

// The media player the bar shows and controls. The one picked in the media
// view while it's still around, otherwise the one playing, otherwise the
// first one with a track loaded. null when there is none.
//   artSources: album art to try, best first (see ArtImage.qml)
//   artColor:   the most colorful color in the art, to tint the media card
//   length:     the track's length in seconds, 0 while unknown
// Media keys (hypr/hyprland.lua):  qs ipc call media playPause | next | previous
// They also make the bar show the player for a moment (keyPressed).
Singleton {
    id: root

    readonly property var players: Mpris.players.values
    property MprisPlayer chosen: null

    // A media key was used on the player.
    signal keyPressed()

    readonly property MprisPlayer player: {
        if (chosen && players.includes(chosen))
            return chosen;
        return players.find(p => p.isPlaying) ?? players.find(p => p.trackTitle) ?? null;
    }

    // Firefox learns a track's length after it starts, but doesn't announce
    // it, so the player's `length` stays unknown until its next play/pause.
    // Until then it's asked for directly, every second while playing.
    readonly property bool lengthKnown: (player?.lengthSupported ?? false) && player.length > 0
    readonly property real length: lengthKnown ? player.length : askedLength
    property real askedLength: 0

    onPlayerChanged: askedLength = 0

    Connections {
        target: root.player

        function onTrackChanged() {
            root.askedLength = 0;
        }
    }

    Timer {
        running: (root.player?.isPlaying ?? false) && !root.lengthKnown && root.askedLength === 0
        interval: 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: lengthQuery.running = true
    }

    Process {
        id: lengthQuery
        command: ["busctl", "--user", "get-property", root.player?.dbusName ?? "", "/org/mpris/MediaPlayer2", "org.mpris.MediaPlayer2.Player", "Metadata"]

        // ... "mpris:length" x 246000000 ... (microseconds)
        stdout: StdioCollector {
            onStreamFinished: {
                const match = text.match(/"mpris:length" [xt] (\d+)/);
                if (match)
                    root.askedLength = Number(match[1]) / 1000000;
            }
        }
    }

    // Browsers hand MPRIS a tiny (60px) thumbnail. For YouTube and YouTube
    // Music the full one comes from YouTube itself; songs have their album
    // art as the center square of it.
    readonly property var artSources: {
        const sources = [];
        const id = youtubeId(player?.metadata["xesam:url"] ?? "");
        if (id) {
            sources.push(`https://i.ytimg.com/vi/${id}/maxresdefault.jpg`);
            sources.push(`https://i.ytimg.com/vi/${id}/hqdefault.jpg`);
        }
        if (player?.trackArtUrl)
            sources.push(player.trackArtUrl);
        return sources;
    }

    readonly property color artColor: {
        let best = Theme.accent;
        let bestScore = -1;
        for (const color of quantizer.colors) {
            const score = color.hsvSaturation * color.hsvValue;
            if (color.hsvValue > 0.25 && score > bestScore) {
                best = color;
                bestScore = score;
            }
        }
        return best;
    }

    // "dQw4w9WgXcQ" from youtube.com/watch?v=..., music.youtube.com/watch?v=... or youtu.be/...
    function youtubeId(url) {
        const match = url.match(/(?:youtube\.com\/watch\?(?:.*&)?v=|youtu\.be\/)([\w-]{11})/);
        return match ? match[1] : "";
    }

    // "3:07", or "1:02:45" past an hour.
    function formatTime(seconds) {
        const total = Math.max(0, Math.floor(seconds));
        const hours = Math.floor(total / 3600);
        const minutes = Math.floor(total % 3600 / 60);
        const secs = String(total % 60).padStart(2, "0");
        return hours > 0 ? `${hours}:${String(minutes).padStart(2, "0")}:${secs}` : `${minutes}:${secs}`;
    }

    // The small local art is plenty for picking colors.
    ColorQuantizer {
        id: quantizer
        source: root.player?.trackArtUrl ?? ""
        depth: 3
        rescaleSize: 64
    }

    IpcHandler {
        target: "media"

        function playPause(): void {
            if (root.player?.canTogglePlaying) {
                root.player.togglePlaying();
                root.keyPressed();
            }
        }

        function next(): void {
            if (root.player?.canGoNext) {
                root.player.next();
                root.keyPressed();
            }
        }

        function previous(): void {
            if (root.player?.canGoPrevious) {
                root.player.previous();
                root.keyPressed();
            }
        }
    }
}
