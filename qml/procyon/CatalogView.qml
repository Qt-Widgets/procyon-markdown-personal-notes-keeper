import QtQuick 2.7
import QtQuick.Controls 1.4
import QtQml.Models 2.2

Rectangle {
    property variant catalogModel

    function getSelectedMemoId() {
        return memoSelector.currentIndex.id;
    }

    ItemSelectionModel {
        id: memoSelector
        model: catalogModel
    }

    TreeView {
        model: catalogModel
        alternatingRowColors: false
        headerVisible: false
        anchors.fill: parent
        selection: memoSelector

        TableViewColumn {
            title: "Name"
            role: "display"
        }
    }
}
