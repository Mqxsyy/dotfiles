import Quickshell
import Quickshell.Widgets
import QtQuick
import qs.config
import qs.services
import qs.components
import "../../utils/icons.js" as Icons
import "../../utils/fuzzy.js" as Fuzzy

// Wallpaper picker: thumbnails of one folder, filtered by typing. Click one
// (or Enter) to set it and recolor everything; the panel stays open to try
// another. Opened with "> wallpaper" in the launcher (or
// `qs ipc call popup toggle wallpapers`).
//   Up/Down/Tab/Shift+Tab move, Enter sets, Esc closes.
Popup {
    id: root

    property int columns: 4
    property int rows: 3
    property int cellWidth: 200
    property int cellHeight: 128

    // Paths with the folder stripped, for searching and showing.
    readonly property string prefix: Wallpaper.directory + Wallpaper.folder + "/"
    readonly property var items: Wallpaper.images.map(path => ({ path: path, name: path.slice(prefix.length) }))
    readonly property var matches: Fuzzy.rank(search.text, items, { name: 1 })

    function apply(index) {
        if (index >= 0 && index < matches.length)
            Wallpaper.set(matches[index].path);
    }

    name: "wallpapers"
    surface: card

    onOpenChanged: {
        if (!open)
            return;
        Wallpaper.load();
        search.input.forceActiveFocus();
        search.input.selectAll();
    }

    PanelCard {
        id: card

        x: (parent.width - width) / 2
        y: (parent.height - height) / 2 + (1 - root.reveal) * 12
        width: root.cellWidth * root.columns + Theme.padding * 2
        opacity: root.reveal

        // Search, folder, random.
        Row {
            width: parent.width
            spacing: 6

            TextField {
                id: search

                width: parent.width - folders.width - random.width - parent.spacing * 2
                placeholder: `Search ${root.items.length} wallpapers`

                onTextChanged: grid.currentIndex = 0

                onKeyPressed: event => {
                    if (event.key === Qt.Key_Down)
                        grid.moveCurrentIndexDown();
                    else if (event.key === Qt.Key_Up)
                        grid.moveCurrentIndexUp();
                    else if (event.key === Qt.Key_Tab)
                        grid.moveCurrentIndexRight();
                    else if (event.key === Qt.Key_Backtab)
                        grid.moveCurrentIndexLeft();
                    else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                        root.apply(grid.currentIndex);
                    else
                        return;
                    event.accepted = true;
                }
            }

            Row {
                id: folders
                spacing: 6

                Repeater {
                    model: Wallpaper.folders

                    PanelButton {
                        required property var modelData
                        height: search.height
                        primary: modelData.path === Wallpaper.folder
                        label: modelData.name
                        onClicked: Wallpaper.folder = modelData.path
                    }
                }
            }

            PanelButton {
                id: random
                height: search.height
                icon: Icons.shuffle
                label: "Random"
                onClicked: Wallpaper.randomize()
            }
        }

        GridView {
            id: grid

            width: parent.width
            height: root.cellHeight * root.rows
            cellWidth: root.cellWidth
            cellHeight: root.cellHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            keyNavigationWraps: true
            model: root.matches

            delegate: Item {
                id: cell

                required property var modelData
                required property int index
                readonly property bool isCurrent: GridView.isCurrentItem
                readonly property bool onScreen: modelData.path === Wallpaper.current

                width: grid.cellWidth
                height: grid.cellHeight

                ClippingRectangle {
                    anchors.fill: parent
                    anchors.margins: 4
                    radius: Theme.innerRadius
                    color: Theme.highlight
                    border.width: cell.onScreen || cell.isCurrent ? 2 : 0
                    border.color: cell.onScreen ? Theme.accent : Theme.textSecondary

                    Image {
                        id: thumb
                        anchors.fill: parent
                        source: "file://" + cell.modelData.path
                        // Decode small: the originals are several megapixels.
                        sourceSize: Qt.size(width * 2, height * 2)
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        opacity: hover.hovered || cell.isCurrent || cell.onScreen ? 1 : 0.8
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: thumb.status !== Image.Ready
                        text: Icons.image
                        color: Theme.textSecondary
                        font.family: Theme.iconFont
                        font.pixelSize: 22
                    }
                }

                HoverHandler {
                    id: hover
                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    onTapped: {
                        grid.currentIndex = cell.index;
                        root.apply(cell.index);
                    }
                }
            }
        }

        // Name of the selected one.
        Text {
            width: parent.width
            text: root.matches[grid.currentIndex]?.name ?? "No matches"
            color: Theme.textSecondary
            font.pixelSize: Theme.fontSmall - 1
            elide: Text.ElideMiddle
        }
    }
}
