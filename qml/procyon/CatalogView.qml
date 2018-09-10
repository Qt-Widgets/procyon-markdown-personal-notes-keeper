import QtQuick 2.7
import QtQuick.Controls 1.4
import QtQml.Models 2.2

import "appearance.js" as Appearance

Rectangle {
    property MainController controller: null
    property variant catalogModel: null

    function getSelectedMemoId() {
        if (catalogModel && memoSelector.hasSelection && memoSelector.currentIndex) {
            var indexData = catalogModel.data(memoSelector.currentIndex)
            return (indexData && !indexData.isFolder) ? indexData.memoId : 0
        }
        return 0
    }

    function getExpandedIdsStr() {
        var expandedIds = []
        __getExpandedIds(null, expandedIds)
        return expandedIds.join(';')
    }

    function setExpandedIdsStr(expandedIdsStr) {
        var expandedIds = []
        var expandedStr = expandedIdsStr.split(';')
        for (var i = 0; i < expandedStr.length; i++)
            expandedIds.push(parseInt(expandedStr[i]))
        __setExpandedIds(null, expandedIds)
    }

    function __getExpandedIds(parentIndex, expandedIds) {
        if (!catalogModel) return
        var rowCount = catalogModel.rowCount(parentIndex)
        for (var row = 0; row < rowCount; row++) {
            var index = catalogModel.index(row, 0, parentIndex)
            if (catalogTreeView.isExpanded(index))
                expandedIds.push(catalogModel.data(index).memoId)
            __getExpandedIds(index, expandedIds)
        }
    }

    function __setExpandedIds(parentIndex, expandedIds) {
        if (!catalogModel) return
        var rowCount = catalogModel.rowCount(parentIndex)
        for (var row = 0; row < rowCount; row++) {
            var index = catalogModel.index(row, 0, parentIndex)
            var indexData = catalogModel.data(index)
            if (expandedIds.indexOf(indexData.memoId) > -1)
                catalogTreeView.expand(index)
            __setExpandedIds(index, expandedIds)
        }
    }

    function __getTreeItemIconPath(styleData) {
        if (!styleData.value) return ""
        if (styleData.value.isFolder) {
            if (styleData.isExpanded )
                return "qrc:/icon/folder_opened"
            return "qrc:/icon/folder_closed"
        }
        return styleData.value.memoIconPath
    }

    TreeView {
        id: catalogTreeView
        model: catalogModel
        headerVisible: false
        anchors.fill: parent

        selection: ItemSelectionModel {
            id: memoSelector
            model: catalogModel
        }

        rowDelegate: Rectangle {
            height: 22 // TODO: should be somehow depended on icon size and font size
            color: styleData.selected ? Appearance.selectionColor() : Appearance.editorColor()
        }

        itemDelegate: Row {
            spacing: 4
            Image {
                source: __getTreeItemIconPath(styleData)
                mipmap: true
                smooth: true
                height: 16
                width: 16
                anchors.verticalCenter: parent.verticalCenter
            }
            Label {
                text: styleData.value ? styleData.value.memoTitle : ""
                font.pointSize: Appearance.fontSizeDefaultUI()
                font.bold: styleData.selected
                color: styleData.selected ? Appearance.textColorSelected() : Appearance.textColor()
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        onDoubleClicked: {
            var indexData = catalogModel.data(index)
            if (indexData.isFolder) {
                if (isExpanded(index))
                    collapse(index)
                else
                    expand(index)
            }
            else controller.needToOpenMemo(indexData.memoId)
        }

        TableViewColumn { role: "display" }
    }
}
