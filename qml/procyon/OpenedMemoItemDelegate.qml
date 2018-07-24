import QtQuick 2.7

Rectangle {
    id: thisComponent

    property bool selected: ListView.isCurrentItem
    property real itemSize

    width: itemSize
    height: 36
    color: selected ? "SteelBlue" : "white"

    function getMemoTypeIcon(typeStr) {
        switch (typeStr) {
        case "text/rich": return "icon/memo_plain_text";
        case "text/code/bash": return "icon/folder_opened";
        case "text/code/python": return "icon/folder_closed";
        }
        return "icon/memo_plain_text";
    }

    Image {
        id: memoIcon
        anchors {
            left: parent.left; leftMargin: 6
            top: parent.top; topMargin: 3
        }
        mipmap: true
        smooth: true
        source: getMemoTypeIcon(memoType) // model->memoType
        width: 24
        height: 24
    }

    Text {
        text: memoTitle // model->memoTitle
        anchors {
            left: parent.left; leftMargin: memoIcon.width + memoIcon.anchors.leftMargin + 6
            right: parent.right; rightMargin: 6
            top: parent.top; topMargin: 3
        }
        color: selected ? "white" : "black"
        font { pointSize: 10; bold: selected }
    }

    Text {
        text: memoFolder // model->memoFolder
        anchors {
            left: parent.left; leftMargin: memoIcon.width + memoIcon.anchors.leftMargin + 6
            right: parent.right; rightMargin: 6
            bottom: parent.bottom; bottomMargin: 3
        }
        color: selected ? "white" : "gray"
        font { pointSize: 8; italic: true }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            parent.ListView.view.currentIndex = index
            if (mainWindow.currentMemoId !== memoId)
                mainWindow.currentMemoId = memoId
        }
    }

    Image {
        id: closeButton
        source: "toolbar/memo_close"
        width: 16
        height: 16
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 4

        MouseArea {
            anchors.fill: parent
            onClicked: {
                Qt.quit()
            }
        }
    }
}
