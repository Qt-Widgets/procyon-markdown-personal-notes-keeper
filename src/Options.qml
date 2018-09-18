import QtQuick 2.0
import Qt.labs.settings 1.0

Item {
    id: options

    property bool memoWordWrap: false

    Settings {
        category: "Options"
        property alias memoWordWrap: options.memoWordWrap
    }
}
