import QtQuick

// Click twice to confirm. check(key) arms `key` and returns false; called
// again with the same key within `interval` ms, it returns true.
//   if (confirm.check(index)) run();
Timer {
    id: root

    property var armed: null

    function check(key) {
        if (armed !== key) {
            armed = key;
            restart();
            return false;
        }
        reset();
        return true;
    }

    function reset() {
        armed = null;
        stop();
    }

    interval: 3000
    onTriggered: armed = null
}
