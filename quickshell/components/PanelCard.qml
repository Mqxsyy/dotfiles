import QtQuick
import qs.config

// The card a panel draws on: its content stacked in a padded column, the
// card as tall as the content.
Card {
    id: root

    default property alias content: column.data
    property alias spacing: column.spacing

    implicitHeight: column.implicitHeight + Theme.padding * 2
    glows: true

    Column {
        id: column
        x: Theme.padding
        y: Theme.padding
        width: parent.width - Theme.padding * 2
        spacing: 12
    }
}
