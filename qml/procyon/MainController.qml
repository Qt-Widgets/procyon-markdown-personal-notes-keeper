import QtQuick 2.7
import QtQuick.Controls 1.4
import QtQuick.Dialogs 1.3
import QtQuick.Layouts 1.0

import org.orion_project.procyon.catalog 1.0
import "appearance.js" as Appearance

Item {
    property CatalogHandler catalog: null

    signal memoOpened(int memoId)

    signal needToCloseMemo(int memoId)
    signal memoClosed(int memoId)

    signal allMemosClosed()

    signal memoModified(int memoId, bool modified)

    function deleteMemo(memoId) {
        if (memoId < 1) return
        console.log("TODO: Delete memo " + memoId)
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
        if (folderId < 1) return
        console.log("TODO: Delete folder " + folderId)
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
                if (info.folderPath.length > 0)
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
            pathLabel.text = info.folderPath.length > 0 ? (info.folderPath + "/") : ""
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
}
