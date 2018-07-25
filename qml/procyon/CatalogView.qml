import QtQuick 2.7
import QtQuick.Controls 1.4
import QtQml.Models 2.2

Rectangle {
    property variant catalogModel

    function getSelectedMemoId() {
        return memoSelector.currentIndex.id;
    }

    Appearance { id: appearance }

    function getTreeItemIconPath(styleData) {
        if (!styleData.value) return ""
        if (styleData.value.isFolder) {
            if (styleData.isExpanded )
                return "qrc:/icon/folder_opened"
            return "qrc:/icon/folder_closed"
        }
        return styleData.value.memoIconPath
    }

    ItemSelectionModel {
        id: memoSelector
        model: catalogModel
    }

    TreeView {
        model: catalogModel
        headerVisible: false
        anchors.fill: parent
        selection: memoSelector
        rowDelegate: Rectangle {
            height: 22 // TODO: should be somehow depended on icon size and font size
            color: styleData.selected ? appearance.selectionColor() : appearance.editorColor()
        }
        itemDelegate: Row {
            spacing: 4
            Image {
                source: getTreeItemIconPath(styleData)
                mipmap: true
                smooth: true
                height: 16
                width: 16
                anchors.verticalCenter: parent.verticalCenter
            }
            Text {
                text: styleData.value ? styleData.value.memoTitle : ""
                font { pointSize: 10; bold: styleData.selected }
                color: styleData.selected ? appearance.textColorSelected() : appearance.textColor()
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        TableViewColumn { role: "display" }
    }
}
