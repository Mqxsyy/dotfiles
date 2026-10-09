pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Things that pile up and can go: caches, old packages, logs. The
// dashboard's Clean tab (CleanView.qml) shows how much each takes and
// cleans one when clicked.
//
// To add one, add an entry:
//   name, detail  what it is, shown in the list
//   paths         folders it takes up; cleaning deletes them (apps make
//                 them again when needed)
//   size          shell command printing the bytes cleaning frees, when
//                 it isn't just `paths`; none = unknown
//   clean         shell command that cleans it, when it isn't deleting `paths`
//   root          needs the admin password: runs in a terminal that shows
//                 the command, and sudo asks there
// Size commands can use the helpers in `helpers`.
Singleton {
    id: root

    readonly property var list: [
        {
            name: "Trash",
            detail: "Deleted files, gone for good once emptied",
            paths: ["$HOME/.local/share/Trash"],
            clean: "gio trash --empty",
        },
        {
            name: "Thumbnails",
            detail: "Previews of images and videos",
            paths: ["$HOME/.cache/thumbnails"],
        },
        {
            name: "Download caches",
            detail: "pip, npm, pnpm, Go, Electron, Wine and ProtonPlus",
            paths: [
                "$HOME/.cache/pip",
                "$HOME/.npm/_cacache",
                "$HOME/.cache/pnpm",
                "$HOME/.cache/go-build",
                "$HOME/.cache/electron",
                "$HOME/.cache/wine",
                "$HOME/.cache/winetricks",
                "$HOME/.cache/ProtonPlus",
            ],
        },
        {
            name: "AUR builds",
            detail: "Where yay builds packages; fetched again on the next update",
            paths: ["$HOME/.cache/yay"],
        },
        {
            name: "Shader caches",
            detail: "Compiled graphics shaders; a little stutter while they rebuild",
            paths: ["$HOME/.cache/nvidia", "$HOME/.cache/mesa_shader_cache", "$HOME/.cache/mesa_shader_cache_db"],
        },
        {
            name: "Steam shaders",
            detail: "Per game, rebuilt on its next launch. Close Steam first",
            paths: ["$HOME/.local/share/Steam/steamapps/shadercache"],
        },
        {
            name: "Old packages",
            detail: "Downloaded package versions, keeps the installed one",
            size: "{ paccache -dk1; paccache -duk0; } | sed -n 's/.*disk space saved: \\(.*\\))/\\1/p' | bytes | sum",
            clean: "sudo paccache -rk1 && sudo paccache -ruk0",
            root: true,
        },
        {
            name: "Unused packages",
            detail: "Installed as dependencies, no longer needed by anything",
            size: "unused=$(pacman -Qdtq) && pacman -Qi $unused | sed -n 's/^Installed Size *: //p' | bytes | sum",
            clean: "sudo pacman -Rns $(pacman -Qdtq)",
            root: true,
        },
        {
            name: "System logs",
            detail: "Keeps the newest 100 MB",
            size: "logs=$(folders /var/log/journal); echo $(( logs > 104857600 ? logs - 104857600 : 0 ))",
            clean: "sudo journalctl --vacuum-size=100M",
            root: true,
        },
        {
            name: "Crash reports",
            detail: "Memory dumps of programs that crashed",
            paths: ["/var/lib/systemd/coredump"],
            clean: "sudo find /var/lib/systemd/coredump -type f -delete",
            root: true,
        },
        {
            name: "Unused Flatpak runtimes",
            detail: "Lists them and asks before removing",
            clean: "flatpak uninstall --unused",
            root: true,
        },
    ]

    // For size commands:
    //   folders a b   bytes the folders take together (missing ones count 0)
    //   bytes         each line "1.5 GiB" -> 1610612736
    //   sum           adds up the lines
    readonly property string helpers: `
        folders() { du -scb "$@" 2>/dev/null | tail -1 | cut -f1; }
        bytes() { sed 's/ //; s/iB$//; s/B$//' | numfmt --from=iec; }
        sum() { awk '{ total += $1 } END { print total + 0 }'; }
    `

    // Shows what's cleaned and the command, then runs it in the terminal.
    readonly property string terminalScript: `
        printf '\\033[1m%s\\033[0m\\n%s\\n\\n$ %s\\n\\n' "$1" "$2" "$3"
        sh -c "$3"
        printf '\\nDone. Press Enter to close.'
        read -r _
    `

    // Bytes each entry frees, by name; missing while unknown.
    property var sizes: ({})
    readonly property bool measuring: measure.running
    // The entry being cleaned, or "".
    property string cleaning: ""

    readonly property real total: Object.values(sizes).reduce((sum, bytes) => sum + bytes, 0)

    function quoted(paths) {
        return paths.map(path => `"${path}"`).join(" ");
    }

    function sizeCommand(entry) {
        return entry.size ?? (entry.paths ? `folders ${quoted(entry.paths)}` : "");
    }

    function cleanCommand(entry) {
        return entry.clean ?? `rm -rf -- ${quoted(entry.paths)}`;
    }

    function refresh() {
        if (!measure.running)
            measure.running = true;
    }

    function clean(entry) {
        if (cleaning !== "")
            return;
        cleaning = entry.name;
        cleaner.command = entry.root
            ? ["kitty", "--title", `Clean: ${entry.name}`, "sh", "-c", terminalScript, "sh", entry.name, entry.detail, cleanCommand(entry)]
            : ["sh", "-c", cleanCommand(entry)];
        cleaner.running = true;
    }

    // One script measuring every entry; prints "index<tab>bytes" per line.
    Process {
        id: measure

        command: ["sh", "-c", root.helpers + root.list
            .map((entry, index) => ({ index: index, command: root.sizeCommand(entry) }))
            .filter(item => item.command !== "")
            .map(item => `printf '%s\\t%s\\n' ${item.index} "$( ${item.command} 2>/dev/null )"`)
            .join("\n")]

        stdout: StdioCollector {
            onStreamFinished: {
                const sizes = {};
                for (const line of text.trim().split("\n")) {
                    const [index, bytes] = line.split("\t");
                    const entry = root.list[parseInt(index)];
                    if (entry)
                        sizes[entry.name] = parseFloat(bytes) || 0;
                }
                root.sizes = sizes;
            }
        }
    }

    Process {
        id: cleaner

        onExited: {
            root.cleaning = "";
            root.refresh();
        }
    }
}
