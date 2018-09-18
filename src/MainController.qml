import QtQuick 2.7
import QtQuick.Controls 1.4
import QtQuick.Dialogs 1.3
import QtQuick.Layouts 1.0

import org.orion_project.procyon.catalog 1.0
import "appearance.js" as Appearance

Item {
    property CatalogHandler catalog: null

    // functions to be injected
    property var isMemoModified // bool function(memoId)
    property var getModifiedMemos // int[] function()
    property var saveMemo // void function(memoId)

    signal memoOpened(int memoId)
    signal memoClosed(int memoId)
    signal allMemosClosed()
    signal memoModified(int memoId, bool modified)

    Connections {
        target: catalog
        onError: __showDialog(errorDialog, message)
        onInfo: __showDialog(infoDialog, message)
        onMemoDeleted: memoClosed(memoId)
    }

    function makePath(itemPath, itemTitle) {
        var path = itemPath.length ? (itemPath + "/") : ""
        var title = itemTitle.length ? itemTitle : ("&lt;" + qsTr("Untitled") + "&gt;")
        return path + "<b>" + title + "</b>"
    }

    function deleteMemo(memoId) {
        var info = catalog.getMemoInfo(memoId)
        if (info.memoId)
            deleteDialog.show(
                qsTr("Delete memo?"),
                makePath(info.memoPath, info.memoTitle),
                function() { catalog.deleteMemo(memoId) }
            )
    }

    function openMemo(memoId) {
        if (memoId < 1) return
        // No special activity is required
        memoOpened(memoId)
    }

    function renameFolder(folderId) {
        if (folderId < 1) return
        folderDialog.showForRename(folderId)
    }

    function createFolder(parentFolderId) {
        folderDialog.showForCreate(parentFolderId)
    }

    function deleteFolder(folderId) {
        var info = catalog.getFolderInfo(folderId)
        if (info.folderId)
            deleteDialog.show(
                qsTr("Delete folder and all its content?"),
                makePath(info.folderPath, info.folderTitle),
                function() { catalog.deleteFolder(folderId) }
            )
    }

    function closeMemo(memoId) {
        if (memoId < 1) return
        if (isMemoModified(memoId))
            saveAndCloseMemoDialog.show(memoId, saveMemo, memoClosed)
        else
            memoClosed(memoId)
    }

    function closeAllMemos(onAccept) {
        var changedMemos = getModifiedMemos()
        if (changedMemos.length === 0) {
            allMemosClosed()
            if (onAccept) onAccept()
        }
        else if (changedMemos.length === 1) {
            saveAndCloseMemoDialog.show(changedMemos[0].memoId,
                                        saveMemo,
                                        function() {
                                            allMemosClosed()
                                            if (onAccept) onAccept()
                                        })
        }
        else {
            console.log("TODO show dialog with multi-selector")
            if (onAccept) onAccept()
        }
    }

    function __showDialog(dialog, message) {
        dialog.text = message
        dialog.visible = true
    }

    MessageDialog { id: infoDialog; icon: StandardIcon.Information }
    MessageDialog { id: errorDialog; icon: StandardIcon.Critical }
    MessageDialog { id: warningDialog; icon: StandardIcon.Warning }

    Dialog {
        id: folderDialog
        standardButtons: StandardButton.Ok | StandardButton.Cancel

        property bool doCreate: false
        property int folderId: 0
        property string folderTitle: ""

        ColumnLayout {
            spacing: 6
            anchors.fill: parent
            Label {
                id: promptLabel;
                text: "It's autowidth adjuster and will be overriden"
            }
            RowLayout {
                spacing: 0
                Layout.fillWidth: true
                Label { id: pathLabel; color: Appearance.textColorModest() }
                Label { id: titleLabel; font.bold: true }
            }
            TextField {
                id: titleEditor
                placeholderText: qsTr("Folder title")
                Layout.fillWidth: true
                Layout.bottomMargin: 12
            }
        }

        function showForCreate(parentFolderId) {
            promptLabel.text = qsTr("Enter a title for new folder")
            folderId = parentFolderId
            if (folderId > 0) {
                var info = catalog.getFolderInfo(folderId)
                if (info.folderPath.length)
                    pathLabel.text = info.folderPath + "/" + info.folderTitle + "/"
                else pathLabel.text = ""
            }
            else pathLabel.text = ""
            folderTitle = ""
            titleLabel.text = "<?>"
            titleEditor.text = ""
            doCreate = true
            visible = true
        }

        function showForRename(folderId) {
            promptLabel.text = qsTr("Enter a new title for the folder")
            folderDialog.folderId = folderId
            var info = catalog.getFolderInfo(folderId)
            folderTitle = info.folderTitle
            pathLabel.text = info.folderPath.length ? (info.folderPath + "/") : ""
            titleLabel.text = info.folderTitle + ":"
            titleEditor.text = info.folderTitle
            doCreate = false
            visible = true
        }

        onVisibleChanged: if (visible) titleEditor.focus = true

        onAccepted: {
            var newTitle = titleEditor.text.trim()
            if (newTitle.length === 0) {
                __showDialog(warningDialog, qsTr("Folder title can't be empty"))
                return
            }
            if (folderTitle === newTitle) {
                console.log("Old and new titles are the same, nothing to change")
                return
            }
            var res = doCreate
                    ? catalog.createFolder(folderId, newTitle)
                    : catalog.renameFolder(folderId, newTitle)
            if (res.length > 0)
                __showDialog(errorDialog, res)
        }
    }

    MessageDialog {
        id: deleteDialog
        icon: StandardIcon.Question
        standardButtons: StandardButton.Yes | StandardButton.No

        property var deleteMethod

        function show(question, subject, method) {
            text = subject + "<p>" + question
            deleteMethod = method
            visible = true
        }

        onYes: deleteMethod()
    }

    MessageDialog {
        id: saveAndCloseMemoDialog
        icon: StandardIcon.Question
        standardButtons: StandardButton.Yes | StandardButton.No | StandardButton.Cancel
        property int memoId: 0
        property var saveMethod: null
        property var closeMethod: null

        function show(memoId, saveMethod, closeMethod) {
            var info = catalog.getMemoInfo(memoId)
            text = info.memoPath + "/<b>" + info.memoTitle + "</b><p>" + qsTr("Save changes?")
            saveAndCloseMemoDialog.memoId = memoId
            saveAndCloseMemoDialog.saveMethod = saveMethod
            saveAndCloseMemoDialog.closeMethod = closeMethod
            visible = true
        }

        onYes: {
            if (saveMethod) {
                var error = saveMethod(memoId)
                if (error !== "") {
                    errorDialog.show(error)
                    return
                }
                if (closeMethod)
                    closeMethod(memoId)
            }
        }

        onNo: {
            if (closeMethod)
                closeMethod(memoId)
        }
    }
}
