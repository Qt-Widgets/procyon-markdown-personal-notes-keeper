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

    onCatalogChanged: {
        textArea.font = catalog.memoFont
        textArea.wrapMode = catalog.memoWordWrap ? TextEdit.Wrap : TextEdit.NoWrap
    }

    function loadMemo() {
        var info = catalog.getMemoInfo(memoId)

        memoPathText.text = info.memoPath

        headerText.isProcessing = true
        headerText.text = info.memoTitle
        headerText.isModified = false
        headerText.isProcessing = false

        document.isMemoProcessing = true
        textArea.text = catalog.getMemoText(memoId)
        document.applyTextStyles()
        document.isMemoModified = false
        document.isMemoProcessing = false
    }

    function isModified() {
        return document.isMemoModified || headerText.isModified
    }

    function saveChanges() {
        var info = {}
        info.memoId = memoId
        info.memoTitle = headerText.text.trim()
        info.memoText = textArea.text
        var res = catalog.saveMemo(info)
        if (res === "") {
            headerText.isModified = false

            document.isMemoProcessing = true
            document.applyTextStyles()
            document.isMemoModified = false
            document.isMemoProcessing = false

            editMemoMode = false
            signalProxy.memoModified(memoId, false)
        }
        return res
    }

    function cancelEditing() {
        loadMemo()
        editMemoMode = false
        signalProxy.memoModified(memoId, false)
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

                    property bool isProcessing: false
                    property bool isModified: false

                    onTextChanged: {
                        isModified = true
                        if (!isProcessing)
                            signalProxy.memoModified(memoId, true)
                    }

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
                    onClicked: saveChanges()
                }
                ToolButton {
                    visible: editMemoMode
                    tooltip: qsTr("Cancel changes")
                    iconSource: "qrc:/toolbar/memo_cancel"
                    onClicked: cancelEditing()
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
