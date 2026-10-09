import QtQuick

// Album art from the first of `sources` that loads (Media.artSources), so a
// missing high resolution version falls back to the next one.
Image {
    id: root

    property var sources: []
    property int tried: 0

    source: sources[tried] ?? ""
    // Decode at twice the shown size: sharp on scaled screens, small in memory.
    sourceSize.height: height * 2
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
    smooth: true
    mipmap: true

    onSourcesChanged: tried = 0
    onStatusChanged: {
        if (status === Image.Error && tried < sources.length - 1)
            tried++;
    }
}
