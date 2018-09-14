﻿import QtQuick 2.7
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
    property MainController controller: null

    Connections {
        target: catalog

        onMemoFontChanged: textArea.font = catalog.memoFont
        onMemoWordWrapChanged: textArea.wrapMode = catalog.memoWordWrap ? TextEdit.Wrap : TextEdit.NoWrap

        onFolderRenamed: {
            // TODO: We can't say if the memo is in one of subfolders
            // of the given folder, so just update path anyway
            var info = catalog.getMemoInfo(memoId)
            memoPathText.text = info.memoPath
        }
    }

    DocumentHandler {
        id: document
        target: textArea
        onDocumentModified: controller.memoModified(memoId, changed)
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

    function beginEditing() {
        editMemoMode = true
        textArea.focus = true
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
            controller.memoModified(memoId, false)
        }
        return res
    }

    function cancelEditing() {
        loadMemo()
        editMemoMode = false
        controller.memoModified(memoId, false)
    }

    function toggleFocus() {
        if (headerText.focus)
            textArea.focus = true
        else headerText.focus = true
    }

    ColumnLayout {
        anchors.fill: parent

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 6

            TextField {
                id: headerText
                font { pixelSize: 24 }
                readOnly: !editMemoMode
                selectByMouse: true
                style: TextFieldStyle {
                    selectionColor: Appearance.selectionColor()
                    selectedTextColor: Appearance.textColorSelected()
                    background: Rectangle {
                        color: editMemoMode ? Appearance.editorColor() : Appearance.baseColor()
                        radius: 4
                        height: 30
                    }
                }
                Layout.fillWidth: true

                property bool isProcessing: false
                property bool isModified: false

                onTextChanged: {
                    isModified = true
                    if (!isProcessing)
                        controller.memoModified(memoId, true)
                }
            }
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
                onClicked: controller.needToCloseMemo(memoId)
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

            style: TextAreaStyle {
                selectionColor: Appearance.selectionColor()
                selectedTextColor: Appearance.textColorSelected()
            }
        }
    }
}
