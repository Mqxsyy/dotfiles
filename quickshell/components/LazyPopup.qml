import Quickshell
import qs.services

// Makes its panel only while it is open or animating out, then frees it,
// so closed panels hold no memory (images, lists, windows).
//   LazyPopup { name: "power"; PowerMenu {} }
LazyLoader {
    required property string name

    active: Popups.current === name || Popups.closing === name
}
