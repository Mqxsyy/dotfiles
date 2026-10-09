pragma Singleton

import Quickshell
import Quickshell.Services.Mpris
import QtQuick

// The media player the bar shows and controls: the one playing, otherwise
// the first one that has a track loaded. null when there is none.
Singleton {
    readonly property MprisPlayer player: {
        const players = Mpris.players.values;
        return players.find(p => p.isPlaying) ?? players.find(p => p.trackTitle) ?? null;
    }
}
