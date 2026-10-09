import Quickshell
import Quickshell.Widgets
import QtQuick
import "icons.js" as Icons
import "fuzzy.js" as Fuzzy

// Clipboard history (Clipboard.qml), newest first. Type to filter, Enter or
// click to copy an entry again and close; then paste as usual.
// Opened with SUPER + SHIFT + V, "> clipboard" in the launcher, or
// `qs ipc call popup toggle clipboard`.
//   Up/Down/Tab move, Enter copies, Delete removes, Ctrl+Backspace clears
//   the search, Esc closes.
Popup {
    id: root

    property int cardWidth: 560
    property int listHeight: 420

    // Matches keep their order (newest first); images only show unfiltered.
    readonly property var matches: Clipboard.entries.filter(entry => {
        if (search.text.trim() === "")
            return true;
        return entry.kind === "text" && Fuzzy.score(search.text, entry.text) !== null;
    })

    // Time since a copy: "now", "5m", "3h", "2d".
    function age(time) {
        const minutes = Math.floor((Date.now() - time) / 60000);
        if (minutes < 1)
            return "now";
        if (minutes < 60)
            return `${minutes}m`;
        if (minutes < 1440)
            return `${Math.floor(minutes / 60)}h`;
        return `${Math.floor(minutes / 1440)}d`;
    }

    function copy(index) {
        if (index < 0 || index >= matches.length)
            return;
        Clipboard.copy(matches[index]);
        Popups.close();
    }

    name: "clipboard"
    surface: card

    onOpenChanged: {
        if (!open)
            return;
        list.currentIndex = 0;
        search.text = "";
        search.input.forceActiveFocus();
        clearAll.armed = false;
    }

    PanelCard {
        id: card

        x: (parent.width - width) / 2
        y: (parent.height - height) / 2 + (1 - root.reveal) * 12
        width: root.cardWidth
        opacity: root.reveal

        Row {
            width: parent.width
            spacing: 6

            TextField {
                id: search

                width: parent.width - clearAll.width - parent.spacing
                placeholder: `Search ${Clipboard.entries.length} copies`

                onTextChanged: list.currentIndex = 0

                onKeyPressed: event => {
                    const ctrl = event.modifiers & Qt.ControlModifier;
                    if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab)
                        list.incrementCurrentIndex();
                    else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab)
                        list.decrementCurrentIndex();
                    else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                        root.copy(list.currentIndex);
                    else if (event.key === Qt.Key_Delete && list.currentItem)
                        Clipboard.remove(root.matches[list.currentIndex]);
                    else if (ctrl && event.key === Qt.Key_Backspace)
                        search.text = "";
                    else
                        return;
                    event.accepted = true;
                }
            }

            // Two clicks: the first only arms it.
            PanelButton {
                id: clearAll

                property bool armed: false

                height: search.height
                icon: Icons.trash
                label: armed ? "Click to clear" : "Clear"
                primary: armed
                onClicked: {
                    if (armed)
                        Clipboard.clear();
                    armed = !armed;
                }
            }
        }

        Text {
            visible: list.count === 0
            text: Clipboard.entries.length === 0 ? "Nothing copied yet" : "No matches"
            color: Theme.textSecondary
            font.pixelSize: Theme.fontSmall
        }

        ListView {
            id: list

            width: parent.width
            height: Math.min(contentHeight, root.listHeight)
            visible: count > 0
            clip: true
            spacing: 2
            boundsBehavior: Flickable.StopAtBounds
            highlightMoveDuration: 0
            model: root.matches

            delegate: Rectangle {
                id: entry

                required property var modelData
                required property int index
                readonly property bool isImage: modelData.kind === "image"

                width: list.width
                height: isImage ? 84 : 36
                radius: Theme.innerRadius
                color: ListView.isCurrentItem ? Theme.highlight : hover.hovered ? Qt.alpha(Theme.textPrimary, 0.05) : "transparent"

                HoverHandler {
                    id: hover
                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    onTapped: root.copy(entry.index)
                }

                Text {
                    x: 12
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - x - ageText.width - 24
                    visible: !entry.isImage
                    text: entry.isImage ? "" : Clipboard.preview(entry.modelData.text)
                    color: Theme.textPrimary
                    font.pixelSize: Theme.fontSmall
                    elide: Text.ElideRight
                }

                ClippingRectangle {
                    x: 12
                    anchors.verticalCenter: parent.verticalCenter
                    visible: entry.isImage
                    width: thumb.status === Image.Ready ? Math.min(240, thumb.implicitWidth * height / thumb.implicitHeight) : 120
                    height: 68
                    radius: Theme.innerRadius / 2
                    color: Theme.highlight

                    Image {
                        id: thumb
                        anchors.fill: parent
                        source: entry.isImage ? "file://" + entry.modelData.path : ""
                        sourceSize.height: 136
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                }

                Text {
                    id: ageText
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.age(entry.modelData.time)
                    color: Theme.textSecondary
                    font.pixelSize: Theme.fontSmall - 2
                }
            }
        }
    }
}
