import QtQuick 2.7
import QtQuick.Controls 1.4
import QtQuick.Dialogs 1.1
import QtQuick.Layouts 1.0
import QtQuick.Controls.Styles 1.4

import org.orion_project.procyon.catalog 1.0
import "appearance.js" as Appearance

Rectangle {
    color: Appearance.baseColor()

    property int memoId: 0
    property bool editMemoMode: false
    property CatalogHandler catalog: null
    property var signalProxy

    function getMemoText(id) {
        return id;
    }

    function getMemoHeader(id) {
        return "Header " + id;
    }

    function editingDone(ok) {
        editMemoMode = false;
    }

    function loadMemo() {
        textArea.text = catalog.getMemoText(memoId)
    }

    Item  {
        id: action
        Action {
            id: editMemoAction
            text: qsTr("Edit")
            tooltip: qsTr("Edit memo")
            iconSource: "qrc:/toolbar/memo_edit"
            shortcut: "Return,Return"
            enabled: !editMemoMode
            onTriggered: editMemoMode = true
        }
        Action {
            id: saveMemoAction
            text: qsTr("Save")
            tooltip: qsTr("Save changes")
            iconSource: "qrc:/toolbar/memo_save"
            shortcut: StandardKey.Save
            enabled: editMemoMode
            onTriggered: editingDone(true)
        }
        Action {
            id: cancelMemoAction
            text: qsTr("Cancel")
            tooltip: qsTr("Cancel changes")
            iconSource: "qrc:/toolbar/memo_cancel"
            shortcut: "Esc,Esc"
            enabled: editMemoMode
            onTriggered: editingDone(false)
        }
        Action {
            id: closeMemoAction
            text: qsTr("Close")
            tooltip: qsTr("Close memo")
            iconSource: "qrc:/toolbar/memo_close"
            //shortcut: StandardKey.Close <-- this shortcut is in MainWindow
            onTriggered: signalProxy.needToCloseMemo(memoId)
        }
    }

    ColumnLayout {
        anchors.fill: parent

        RowLayout {
            id: headerRow

            Rectangle {
                id: headerTextBackground

                color: editMemoMode ? Appearance.editorColor() : Appearance.baseColor()
                radius: 4
                height: 30

                Layout.topMargin: 4
                Layout.fillWidth: true

                TextInput {
                    id: headerText
                    anchors.fill: parent
                    font { pixelSize: 24 }
                    leftPadding: 4
                    readOnly: !editMemoMode
                    selectByMouse: true
                    text: getMemoHeader(memoId)
                    verticalAlignment: TextEdit.AlignVCenter
                    wrapMode: TextEdit.NoWrap

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.RightButton
                        onClicked: headerContextMenu.popup()
                    }

                    Menu {
                        id: headerContextMenu
                        MenuItem {
                            text: qsTr("Copy")
                            onTriggered: headerText.copy()
                            iconName: "edit-copy"
                        }
                        MenuSeparator {}
                        MenuItem {
                            text: qsTr("Select All")
                            onTriggered: headerText.selectAll()
                        }
                    }
                }
            }
            RowLayout {
                id: headerToolbar

                Layout.topMargin: 4

                ToolButton { action: editMemoAction; visible: !editMemoMode }
                ToolButton { action: saveMemoAction; visible: editMemoMode }
                ToolButton { action: cancelMemoAction; visible: editMemoMode }
                ToolButton { action: closeMemoAction }
            }
        }

        TextArea {
            id: textArea
            textFormat: Qt.PlainText
            readOnly: !editMemoMode
            wrapMode: TextEdit.Wrap
            focus: true
            selectByMouse: true
            selectByKeyboard: true
            onLinkActivated: Qt.openUrlExternally(link)

            Layout.bottomMargin: 4
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }

    MessageDialog {
        id: infoDialog
    }

}
