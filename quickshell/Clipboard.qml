pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Clipboard history, newest first. scripts/clipboard-watch.sh reports every
// copy; text is kept here, images as files in `folder`. Saved to
// `folder`/history.json so it survives restarts. Copying something again
// moves it to the top instead of adding it twice.
//   entry: { kind: "text", text, time } or { kind: "image", path, time }
Singleton {
    id: root

    readonly property string folder: Quickshell.env("HOME") + "/.cache/quickshell/clipboard"
    property int maxEntries: 200

    readonly property var entries: saved.entries

    function same(a, b) {
        return a.kind === b.kind && (a.kind === "text" ? a.text === b.text : a.path === b.path);
    }

    // record: "text\n<text>" or "image\n<path>"
    function add(record) {
        const newline = record.indexOf("\n");
        const kind = record.slice(0, newline);
        const content = record.slice(newline + 1);
        if (kind === "text" && content.trim() === "")
            return;

        const entry = kind === "image"
            ? { kind: "image", path: content, time: Date.now() }
            : { kind: "text", text: content, time: Date.now() };
        const all = [entry, ...entries.filter(old => !same(old, entry))];
        forgetImages(all.slice(maxEntries));
        saved.entries = all.slice(0, maxEntries);
    }

    // Put an entry back on the clipboard. The watcher sees it and moves it to the top.
    function copy(entry) {
        if (entry.kind === "image")
            Quickshell.execDetached(["sh", "-c", 'wl-copy --type image/png < "$1"', "sh", entry.path]);
        else
            Quickshell.execDetached(["wl-copy", "--", entry.text]);
    }

    function remove(entry) {
        forgetImages([entry]);
        saved.entries = entries.filter(old => !same(old, entry));
    }

    function clear() {
        forgetImages(entries);
        saved.entries = [];
    }

    function forgetImages(dropped) {
        const paths = dropped.filter(entry => entry.kind === "image").map(entry => entry.path);
        if (paths.length > 0)
            Quickshell.execDetached(["rm", "-f", ...paths]);
    }

    // One line to show for a text entry.
    function preview(text) {
        return text.replace(/\s+/g, " ").trim().slice(0, 300);
    }

    Process {
        id: watcher
        running: true
        command: [Quickshell.shellDir + "/scripts/clipboard-watch.sh", root.folder]
        stdout: SplitParser {
            splitMarker: "\x1e"
            onRead: record => root.add(record)
        }
        // Start again if it ever stops.
        onExited: restart.start()
    }

    Timer {
        id: restart
        interval: 2000
        onTriggered: watcher.running = true
    }

    FileView {
        path: root.folder + "/history.json"
        // Loaded before the watcher reports its first copy, so that copy isn't lost.
        blockLoading: true
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
        }

        JsonAdapter {
            id: saved
            property var entries: []
        }
    }
}
