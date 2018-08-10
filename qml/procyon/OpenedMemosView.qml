import QtQuick 2.7
import QtQuick.Layouts 1.0
import QtQuick.Controls 1.4

import org.orion_project.procyon.catalog 1.0
import "appearance.js" as Appearance

// TODO: add keyboard switching: Ctrl+Tab / Ctrl+Shift+Tab

Rectangle {
    property CatalogHandler catalog: null
    property int currentMemoId: 0
    signal needToCloseMemo(int memoId)
    signal needToActivateMemo(int memoId)

    onCurrentMemoIdChanged: {
        if (currentMemoId > 0) {
            var index = __getItemIndex(currentMemoId)
            if (index < 0) {
                var info = catalog.getMemoInfo(currentMemoId)
                if (info) {
                    memosListModel.append(info)
                    index = memosListModel.count-1
                }
            }
            memosListView.currentIndex = index
        }
        needToActivateMemo(currentMemoId)
    }

    function memoClosed(memoId) {
        var index = __getItemIndex(memoId)
        if (index > -1) {
            memosListModel.remove(index, 1)
            memosListView.currentIndex = Math.min(memosListModel.count-1, index)
            currentMemoId = __getMemoId(memosListView.currentIndex)
        }
    }

    function __getMemoId(index) {
        return (index > -1 && index < memosListModel.count) ? memosListModel.get(index)["memoId"] : 0;
    }

    function __getItemIndex(memoId) {
        for (var i = 0; i < memosListModel.count; i++)
            if (__getMemoId(i) === memoId)
                return i
        return -1
    }

    ListModel {
        id: memosListModel
    }

    ListView {
        id: memosListView
        model: memosListModel
        spacing: 3
        anchors.fill: parent
        focus: true
        delegate: Rectangle {
            id: memoItemDelegate
            width: parent.width
            height: 36 // TODO: should be somehow depended on icon size and font size
            color: ListView.isCurrentItem ? Appearance.selectionColor() : Appearance.editorColor()
            property bool selected: ListView.isCurrentItem

            MouseArea {
                anchors.fill: parent
                onClicked: currentMemoId = model.memoId
            }

            RowLayout {
                anchors.fill: parent
                spacing: 6

                Image {
                    id: memoIcon
                    source: model.memoIconPath
                    mipmap: true
                    smooth: true
                    Layout.preferredHeight: 24
                    Layout.preferredWidth: 24
                    Layout.leftMargin: 6
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Label {
                        text: model.memoTitle
                        color: memoItemDelegate.selected ? Appearance.textColorSelected() : Appearance.textColor()
                        font.pointSize: Appearance.fontSizeDefaultUI()
                        font.bold: memoItemDelegate.selected
                        Layout.fillWidth: true
                    }

                    Label {
                        text: model.memoPath
                        color: memoItemDelegate.selected ? Appearance.textColorSelected() : Appearance.textColorModest()
                        font.pointSize: Appearance.fontSizeSmallUI()
                        font.italic: true
                        Layout.fillWidth: true
                        Layout.bottomMargin: 3
                    }
                }

                ColumnLayout {
                    Image {
                        id: closeButton
                        source: "toolbar/memo_close"
                        Layout.preferredHeight: 16
                        Layout.preferredWidth: 16
                        Layout.rightMargin: 3
                        MouseArea {
                            anchors.fill: parent
                            onClicked: needToCloseMemo(model.memoId)
                        }
                    }
                }
            }
        }
    }
}
