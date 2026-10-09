import QtQuick
import qs.config

// Small caps heading between groups in a panel ("OUTPUT", "APPS").
Text {
    color: Theme.accent
    font.pixelSize: Theme.fontSmall - 2
    font.weight: Font.DemiBold
    font.capitalization: Font.AllUppercase
    font.letterSpacing: 1
}
