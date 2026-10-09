import Quickshell
import QtQuick
import "icons.js" as Icons

// Month calendar (in the dashboard). Arrows or scrolling change the month;
// clicking the month name jumps back to today. Resets to this month when
// it's shown again.
Item {
    id: root

    property int cellSize: 32
    readonly property int headerHeight: 28

    readonly property date today: clock.date
    property int year: today.getFullYear()
    property int month: today.getMonth()

    // JS day number (0 = Sunday) the weeks start on, from the system locale.
    readonly property int firstDay: Qt.locale().firstDayOfWeek % 7
    // How many days of the previous month fill the first row.
    readonly property int leading: (new Date(year, month, 1).getDay() - firstDay + 7) % 7

    function showMonth(offset) {
        const shown = new Date(year, month + offset, 1);
        year = shown.getFullYear();
        month = shown.getMonth();
    }

    function showToday() {
        year = today.getFullYear();
        month = today.getMonth();
    }

    implicitWidth: grid.width
    implicitHeight: content.implicitHeight

    onVisibleChanged: if (visible) showToday()

    SystemClock {
        id: clock
        precision: SystemClock.Hours
    }

    WheelHandler {
        onWheel: event => root.showMonth(event.angleDelta.y > 0 ? -1 : 1)
    }

    Column {
        id: content
        spacing: 8

        Item {
            width: grid.width
            height: root.headerHeight

            BarButton {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                icon: Icons.chevronLeft
                onClicked: root.showMonth(-1)
            }

            BarButton {
                anchors.centerIn: parent
                label: Qt.locale().standaloneMonthName(root.month) + " " + root.year
                onClicked: root.showToday()
            }

            BarButton {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                icon: Icons.chevronRight
                onClicked: root.showMonth(1)
            }
        }

        Grid {
            id: grid
            columns: 7

            // Weekday names.
            Repeater {
                model: 7

                Text {
                    required property int index
                    width: root.cellSize
                    height: root.cellSize * 0.8
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: Qt.locale().dayName((root.firstDay + index) % 7, Locale.ShortFormat).slice(0, 2)
                    color: Theme.textSecondary
                    font.pixelSize: Theme.fontSmall - 1
                }
            }

            // Six weeks of days, starting with the tail of the previous month.
            Repeater {
                model: 42

                Item {
                    id: day

                    required property int index
                    readonly property date date: new Date(root.year, root.month, index - root.leading + 1)
                    readonly property bool inMonth: date.getMonth() === root.month
                    readonly property bool isToday: date.toDateString() === root.today.toDateString()

                    width: root.cellSize
                    height: root.cellSize

                    // Today: a lit circle.
                    Rectangle {
                        anchors.centerIn: parent
                        width: root.cellSize
                        height: width
                        radius: width / 2
                        visible: day.isToday
                        gradient: Theme.accentGradient

                        Glow {}
                    }

                    Text {
                        anchors.centerIn: parent
                        text: day.date.getDate()
                        color: day.isToday ? Theme.accentText : day.inMonth ? Theme.textPrimary : Theme.textSecondary
                        opacity: day.inMonth ? 1 : 0.5
                        font.pixelSize: Theme.fontSmall
                        font.weight: day.isToday ? Font.DemiBold : Font.Normal
                    }
                }
            }
        }
    }
}
