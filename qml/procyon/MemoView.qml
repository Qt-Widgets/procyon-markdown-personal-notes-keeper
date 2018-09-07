import QtQuick 2.7
import QtQuick.Controls 1.4
import QtQuick.Dialogs 1.1
import QtQuick.Layouts 1.0
import QtQuick.Controls.Styles 1.4

import org.orion_project.procyon.catalog 1.0
import org.orion_project.procyon.document 1.0
import "appearance.js" as Appearance

Rectangle {
    color: Appearance.baseColor()

    property int memoId: 0
    property bool editMemoMode: false
    property CatalogHandler catalog: null
    property var signalProxy

    Connections {
        target: catalog
        onMemoFontChanged: textArea.font = catalog.memoFont
        onMemoWordWrapChanged: textArea.wrapMode = catalog.memoWordWrap ? TextEdit.Wrap : TextEdit.NoWrap
    }

    DocumentHandler {
        id: document
        target: textArea
        onDocumentModified: signalProxy.memoModified(memoId, changed)
    }

    function loadMemo() {
        var info = catalog.getMemoInfo(memoId)
        headerText.text = info.memoTitle
        memoPathText.text = info.memoPath

        document.isMemoProcessing = true
        textArea.text = catalog.getMemoText(memoId)
        textArea.font = catalog.memoFont
        textArea.wrapMode = catalog.memoWordWrap ? TextEdit.Wrap : TextEdit.NoWrap
        document.applyTextStyles()
        document.isMemoProcessing = false
    }

    function editingDone(ok) {
        if (ok) {
            console.log('TODO: check if modified and save')
        } else {
            console.log('TODO: Reload memo to discard changes')
        }
        editMemoMode = false;
        document.isMemoModified = false
    }

    function isModified() {
        return document.isMemoModified
    }

    function save(catalog) {
        console.log("SAVE " + memoId)
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

                ToolButton {
                    visible: !editMemoMode
                    tooltip: qsTr("Edit memo")
                    iconSource: "qrc:/toolbar/memo_edit"
                    onClicked: editMemoMode = true
                }
                ToolButton {
                    visible: editMemoMode
                    tooltip: qsTr("Save changes")
                    iconSource: "qrc:/toolbar/memo_save"
                    onClicked: editingDone(true)
                }
                ToolButton {
                    visible: editMemoMode
                    tooltip: qsTr("Cancel changes")
                    iconSource: "qrc:/toolbar/memo_cancel"
                    onClicked: editingDone(false)
                }
                ToolButton {
                    tooltip: qsTr("Close memo")
                    iconSource: "qrc:/toolbar/memo_close"
                    onClicked: signalProxy.needToCloseMemo(memoId)
                }
            }
        }

        Label {
            id: memoPathText
            Layout.fillWidth: true
            color: Appearance.textColorModest()
            font.pointSize: Appearance.fontSizeSmallUI()
            leftPadding: 4
        }

        TextArea {
            id: textArea
            textFormat: Qt.PlainText
            readOnly: !editMemoMode
            wrapMode: TextEdit.Wrap
            font.pointSize: 11
            focus: true
            selectByMouse: true
            selectByKeyboard: true
            onLinkActivated: Qt.openUrlExternally(link)

            Layout.bottomMargin: 4
            Layout.fillWidth: true
            Layout.fillHeight: true
        }
    }
}
