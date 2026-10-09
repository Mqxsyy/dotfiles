import QtQuick
import QtQuick.Effects
import qs.services

// A wallpaper filling its size. A new `source` is revealed over the old one:
//   "grow":  a soft-edged circle growing from the center
//   "swipe": a soft diagonal edge sweeping from the top-right corner to the
//            bottom-left
// The first wallpaper just shows.
Item {
    id: root

    property string source: ""           // image path
    property string transition: "grow"
    property real pixelRatio: 1          // screen pixels per item pixel, for a sharp image
    property int duration: 900
    property int softness: 40            // width of the soft edge, px

    // Two images take turns: `front` is on screen; `back` loads the next
    // wallpaper, is revealed over it, then becomes the front.
    property Image front: first
    readonly property Image back: front === first ? second : first
    property real progress: 0            // how much of `back` is revealed, 0..1

    onSourceChanged: show()
    Component.onCompleted: show()

    function show() {
        if (source === "")
            return;
        if (front.source.toString() === "") {
            front.source = "file://" + source;
            return;
        }
        if (reveal.running) {
            reveal.stop();
            swap();
        }
        back.source = "file://" + source; // revealed once loaded
    }

    // The revealed image becomes the one on screen; free the old one.
    function swap() {
        const old = front;
        front = back;
        progress = 0;
        old.source = "";
    }

    component Wallpaper: Image {
        id: image

        anchors.fill: parent
        visible: image === root.front
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(root.width * root.pixelRatio, root.height * root.pixelRatio)
        asynchronous: true
        cache: false

        onStatusChanged: {
            if (status === Image.Ready && image === root.back)
                reveal.restart();
        }
    }

    Wallpaper {
        id: first
    }

    Wallpaper {
        id: second
    }

    NumberAnimation {
        id: reveal
        target: root
        property: "progress"
        from: 0
        to: 1
        duration: root.duration
        easing.type: Easing.InOutCubic
        onFinished: root.swap()
    }

    // `back`, shown where the mask is white.
    MultiEffect {
        anchors.fill: parent
        visible: root.progress > 0
        source: root.back
        maskEnabled: true
        maskSource: maskTexture
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1 // soft edge, from the blurred shapes below
    }

    // The mask's texture; a hidden item's layer would stop updating.
    ShaderEffectSource {
        id: maskTexture
        sourceItem: mask
        hideSource: true
        live: root.progress > 0
    }

    Item {
        id: mask
        anchors.fill: parent

        // Grow: a circle reaching past the corners at the end.
        RectangularShadow {
            readonly property real size: root.progress * (Math.hypot(root.width, root.height) + root.softness * 2)

            visible: root.transition === "grow"
            anchors.centerIn: parent
            width: size
            height: size
            radius: size / 2
            blur: root.softness
            color: "white"
        }

        // Swipe: a square turned so its top faces the top-right corner,
        // filling from its top. `reach` is the screen's length along that
        // direction.
        Item {
            readonly property real reach: (root.width + root.height) / Math.SQRT2

            visible: root.transition === "swipe"
            anchors.centerIn: parent
            width: root.width + root.height
            height: width
            rotation: 45

            RectangularShadow {
                width: parent.width
                height: (parent.height - parent.reach) / 2 - root.softness + root.progress * (parent.reach + root.softness * 2)
                blur: root.softness
                color: "white"
            }
        }
    }
}
