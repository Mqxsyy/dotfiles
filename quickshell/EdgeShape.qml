import QtQuick
import QtQuick.Shapes

// A tab attached to a screen edge: rounded on its outer corners, flaring out
// where it meets the edge. Used by the top bar and the volume/brightness OSD.
// Children are placed in the body (the tab without its flares).
//
// The outline is written for a tab hanging from the top edge (a = along the
// edge, d = away from it); for the right edge the same points are rotated.
Shape {
    id: root

    property string edge: "top"   // "top" or "right"
    property real length: 100     // body size along the edge
    property real depth: 36       // body size away from the edge

    default property alias content: body.data

    readonly property bool vertical: edge === "right"
    readonly property real r: Math.min(Theme.radius, depth / 2)                     // outer corners
    readonly property real f: Math.min(Math.round(Theme.radius * 2 / 3), depth - r) // flares

    function px(a, d) {
        return vertical ? depth - d : a;
    }

    function py(a, d) {
        return vertical ? a : d;
    }

    width: vertical ? depth : length + f * 2
    height: vertical ? length + f * 2 : depth
    preferredRendererType: Shape.CurveRenderer

    layer.enabled: true
    layer.effect: Shadow {}

    // Clockwise from where the first flare leaves the edge: flare into the
    // side, round both outer corners, flare back to the edge. The edge side
    // runs 1px past the screen so its border stroke isn't visible.
    ShapePath {
        fillColor: Theme.surface
        strokeColor: Theme.border
        strokeWidth: 1

        startX: root.px(0, -1)
        startY: root.py(0, -1)

        PathArc { x: root.px(root.f, root.f); y: root.py(root.f, root.f); radiusX: root.vertical ? root.f + 1 : root.f; radiusY: root.vertical ? root.f : root.f + 1 }
        PathLine { x: root.px(root.f, root.depth - root.r); y: root.py(root.f, root.depth - root.r) }
        PathArc { x: root.px(root.f + root.r, root.depth); y: root.py(root.f + root.r, root.depth); radiusX: root.r; radiusY: root.r; direction: PathArc.Counterclockwise }
        PathLine { x: root.px(root.f + root.length - root.r, root.depth); y: root.py(root.f + root.length - root.r, root.depth) }
        PathArc { x: root.px(root.f + root.length, root.depth - root.r); y: root.py(root.f + root.length, root.depth - root.r); radiusX: root.r; radiusY: root.r; direction: PathArc.Counterclockwise }
        PathLine { x: root.px(root.f + root.length, root.f); y: root.py(root.f + root.length, root.f) }
        PathArc { x: root.px(root.length + root.f * 2, -1); y: root.py(root.length + root.f * 2, -1); radiusX: root.vertical ? root.f + 1 : root.f; radiusY: root.vertical ? root.f : root.f + 1 }
        PathLine { x: root.px(0, -1); y: root.py(0, -1) }
    }

    Item {
        id: body
        x: root.vertical ? 0 : root.f
        y: root.vertical ? root.f : 0
        width: root.vertical ? root.depth : root.length
        height: root.vertical ? root.length : root.depth
    }
}
