import QtQuick 2.7
import QtQuick.Controls 1.4
import QtQml.Models 2.2

import org.orion_project.procyon.catalog 1.0
import "appearance.js" as Appearance

Rectangle {
    property MainController controller: null
    property CatalogHandler catalog: null
    property variant catalogModel: null
    property int selectedFolderId: 0
    property int selectedMemoId: 0
    property string selectedTitle: ""
    property string selectedIconSource: ""

    onCatalogModelChanged: if (!catalogModel) __updateSelection(null)

    Connections {
        target: catalog
        onItemCreated: {
            catalogTreeView.expand(parentIndex)
            catalogSelector.setCurrentIndex(newIndex, ItemSelectionModel.ClearAndSelect)
        }
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
                expandedIds.push(catalogModel.data(index).itemId)
            __getExpandedIds(index, expandedIds)
        }
    }

    function __setExpandedIds(parentIndex, expandedIds) {
        if (!catalogModel) return
        var rowCount = catalogModel.rowCount(parentIndex)
        for (var row = 0; row < rowCount; row++) {
            var index = catalogModel.index(row, 0, parentIndex)
            var indexData = catalogModel.data(index)
            if (expandedIds.indexOf(indexData.itemId) > -1)
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
        return styleData.value.iconPath
    }

    function __updateSelection(index) {
        var folderId = 0
        var memoId = 0
        var title = ""
        var iconSource = ""
        if (index) {
            var indexData = catalogModel.data(index)
            if ("itemId" in indexData) {
                if (indexData.isFolder) {
                    folderId = indexData.itemId
                    iconSource = "qrc:/icon/folder_closed"
                }
                else {
                    memoId = indexData.itemId
                    iconSource = indexData.iconPath
                }
                title = indexData.itemTitle
            }
        }
        selectedFolderId = folderId
        selectedMemoId = memoId
        selectedTitle = title
        selectedIconSource = iconSource
    }

    TreeView {
        id: catalogTreeView
        model: catalogModel
        headerVisible: false
        anchors.fill: parent

        selection: ItemSelectionModel {
            id: catalogSelector
            model: catalogModel
            onCurrentChanged: __updateSelection(current)
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
                text: styleData.value ? styleData.value.itemTitle : ""
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
            else controller.openMemo(indexData.itemId)
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.RightButton
            onClicked: {
                if (selectedFolderId > 0) folderContextMenu.popup()
                else if(selectedMemoId > 0) memoContextMenu.popup()
            }
        }

        TableViewColumn { role: "display" }
    }

    Menu {
        id: folderContextMenu
        MenuItem {
            text: selectedTitle
            iconSource: selectedIconSource
            enabled: false
        }
        MenuSeparator {}
        MenuItem {
            text: qsTr("&New Subfolder...")
            onTriggered: controller.createFolder(selectedFolderId)
        }
        MenuItem {
            text: qsTr("New &Memo...")
            onTriggered: catalog.createMemo(selectedFolderId)
        }
        MenuSeparator {}
        MenuItem {
            text: qsTr("&Rename Folder...")
            onTriggered: controller.renameFolder(selectedFolderId)
        }
        MenuItem {
            text: qsTr("&Delete Folder")
            onTriggered: controller.deleteFolder(selectedFolderId)
        }
    }

    Menu {
        id: memoContextMenu
        MenuItem {
            text: selectedTitle
            iconSource: selectedIconSource
            enabled: false
        }
        MenuSeparator {}
        MenuItem {
            text: qsTr("&Open Memo")
            onTriggered: controller.openMemo(selectedMemoId)
        }
        MenuSeparator {}
        MenuItem {
            text: qsTr("&Delete Memo")
            onTriggered: controller.deleteMemo(selectedMemoId)
        }
    }
}
