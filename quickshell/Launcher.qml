import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import "fuzzy.js" as Fuzzy
import "calc.js" as Calc
import "units.js" as Units

// App launcher with fuzzy search and a calculator, driven over IPC:
//   qs ipc call launcher toggle
//
// Closing only hides the window, so the query survives until the next open,
// selected so typing replaces it.
// Typing math ("2^10 / 3", "sqrt 2", "=pi") or a conversion ("10 km to mi")
// shows the result as the first row; Enter copies it. Starting with ">" lists
// the commands from Commands.qml instead ("> wallpaper"). Launching an app,
// running a command or Ctrl+Backspace clears the query.
ShellWindow {
    id: root

    property int cardWidth: 560
    property int searchHeight: 56
    property int rowHeight: 48
    property int maxRows: 4
    property int listPadding: 8

    // Which entry properties the search looks at, and how much a hit there counts.
    readonly property var searchFields: ({
        name: 1,
        genericName: 0.6,
        keywords: 0.5,
        id: 0.5,
    })

    readonly property var apps: Array.from(DesktopEntries.applications.values)
        .filter(app => !app.noDisplay)
        .sort((a, b) => a.name.localeCompare(b.name))

    // Rows shown in the list: an optional calculator row, then matching apps.
    // Each row draws its icon, or its glyph when there is no icon.
    readonly property var results: {
        const query = input.text;
        const rows = [];

        if (query.startsWith(">")) {
            for (const command of Fuzzy.rank(query.slice(1), Commands.list, { name: 1 }))
                rows.push({ kind: "command", title: command.name, subtitle: command.description, glyph: ">", command: command });
            return rows;
        }

        const calculation = calculate(query);
        if (calculation !== null)
            rows.push(calculation);

        for (const app of Fuzzy.rank(query, apps, searchFields))
            rows.push({
                kind: "app",
                title: app.name,
                subtitle: app.genericName || app.comment,
                icon: Quickshell.iconPath(app.icon, true), // "" when the theme has no such icon
                glyph: app.name.charAt(0).toUpperCase(),
                app: app,
            });

        return rows;
    }

    // The calculator row for a query, or null when the query isn't math.
    // Conversions evaluate their amount as math first: "3*12 in to cm".
    function calculate(query) {
        let value = null;
        let unit = "";

        const conversion = Units.parse(query);
        if (conversion !== null) {
            const amount = Calc.evaluate(conversion.amount);
            value = amount === null ? null : Units.convert(amount, conversion.from, conversion.to);
            unit = conversion.to;
        } else if (Calc.isExpression(query)) {
            value = Calc.evaluate(query);
        } else {
            return null;
        }

        if (value === null || !isFinite(value))
            return { kind: "calc", title: "Invalid", subtitle: "", glyph: "=", invalid: true };

        const result = Calc.format(value);
        return {
            kind: "calc",
            title: unit ? result + " " + unit : result,
            subtitle: "Enter to copy",
            glyph: "=",
            copy: result,
            invalid: false,
        };
    }

    function open() {
        if (FocusedScreen.screen)
            root.screen = FocusedScreen.screen;

        list.currentIndex = 0;
        root.shown = true;
        input.forceActiveFocus();
        input.selectAll(); // typing replaces the old query; arrow keys keep it
    }

    function close() {
        root.shown = false;
    }

    function toggle() {
        root.shown ? close() : open();
    }

    function activate(row) {
        if (!row)
            return;

        if (row.kind === "calc") {
            if (row.invalid)
                return;
            Quickshell.clipboardText = row.copy;
        } else if (row.kind === "command") {
            row.command.run();
            input.clear();
        } else {
            row.app.execute();
            input.clear();
        }
        close();
    }

    function move(step) {
        if (list.count > 0)
            list.currentIndex = Math.max(0, Math.min(list.count - 1, list.currentIndex + step));
    }

    name: "launcher"
    shown: false

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            root.toggle();
        }

        function open(): void {
            root.open();
        }

        function close(): void {
            root.close();
        }
    }

    // Clicking anywhere outside the card closes the launcher.
    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    Card {
        id: card

        x: (parent.width - width) / 2
        // The search row, divider (1px) and first result sit at the screen center; more results grow downward.
        y: (parent.height - (root.searchHeight + 1 + root.listPadding + root.rowHeight)) / 2
        width: root.cardWidth
        height: content.implicitHeight
        clip: true

        // Swallow clicks on the card itself so they don't reach the close area behind it.
        MouseArea {
            anchors.fill: parent
        }

        Column {
            id: content

            width: parent.width

            Item {
                width: parent.width
                height: root.searchHeight

                TextInput {
                    id: input

                    anchors.fill: parent
                    anchors.leftMargin: Theme.padding + 4
                    anchors.rightMargin: Theme.padding + 4
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.textPrimary
                    selectionColor: Theme.accent
                    selectedTextColor: Theme.accentText
                    font.pixelSize: Theme.fontLarge
                    clip: true

                    onTextChanged: list.currentIndex = 0

                    Keys.onPressed: event => {
                        const ctrl = event.modifiers & Qt.ControlModifier;

                        if (event.key === Qt.Key_Escape)
                            root.close();
                        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                            root.activate(root.results[list.currentIndex]);
                        else if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab || (ctrl && (event.key === Qt.Key_J || event.key === Qt.Key_N)))
                            root.move(1);
                        else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab || (ctrl && (event.key === Qt.Key_K || event.key === Qt.Key_P)))
                            root.move(-1);
                        else if (event.key === Qt.Key_PageDown)
                            root.move(root.maxRows);
                        else if (event.key === Qt.Key_PageUp)
                            root.move(-root.maxRows);
                        else if (ctrl && event.key === Qt.Key_Backspace)
                            input.clear();
                        else
                            return;

                        event.accepted = true;
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: input.text.length === 0
                        text: "Search apps, calculate, or > command"
                        color: Theme.textSecondary
                        font: input.font
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Theme.border
                visible: list.count > 0
            }

            ListView {
                id: list

                width: parent.width
                height: Math.min(count, root.maxRows) * root.rowHeight + (count > 0 ? root.listPadding * 2 : 0)
                topMargin: root.listPadding
                bottomMargin: root.listPadding
                clip: true
                model: root.results
                boundsBehavior: Flickable.StopAtBounds
                highlightMoveDuration: 0

                delegate: Item {
                    id: row

                    required property var modelData
                    required property int index

                    readonly property bool selected: ListView.isCurrentItem

                    width: list.width
                    height: root.rowHeight

                    Rectangle {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        radius: Theme.innerRadius
                        color: row.selected ? Theme.highlight : "transparent"
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: list.currentIndex = row.index
                        onClicked: root.activate(row.modelData)
                    }

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        x: Theme.padding + 4
                        width: parent.width - x * 2
                        spacing: 14

                        Item {
                            id: iconBox
                            width: Theme.iconSize
                            height: Theme.iconSize

                            IconImage {
                                anchors.fill: parent
                                visible: source != ""
                                source: row.modelData.icon ?? ""
                                asynchronous: true
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: !row.modelData.icon
                                text: row.modelData.glyph
                                color: row.modelData.kind === "app" ? Theme.textSecondary : Theme.accent
                                font.pixelSize: Theme.fontLarge + 3
                                font.weight: Font.DemiBold
                            }
                        }

                        Text {
                            id: title

                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.min(implicitWidth, parent.width - iconBox.width - parent.spacing)
                            text: row.modelData.title
                            color: row.modelData.invalid ? Theme.textSecondary : Theme.textPrimary
                            font.pixelSize: Theme.fontNormal
                            font.weight: row.modelData.kind === "calc" ? Font.DemiBold : Font.Normal
                            elide: Text.ElideRight
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - iconBox.width - parent.spacing - title.width - parent.spacing
                            text: row.modelData.subtitle ?? ""
                            color: Theme.textSecondary
                            font.pixelSize: Theme.fontSmall
                            elide: Text.ElideRight
                            opacity: row.selected ? 1 : 0.7
                        }
                    }
                }
            }
        }
    }
}
