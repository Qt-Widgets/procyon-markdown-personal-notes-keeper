import QtQuick 2.0
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

    function openMemo(memoId) {
        // No special activity is required
        memoOpened(memoId)
    }

    function renameFolder(folderId) {
        if (folderId > 0) {
            renameFolderDialog.folderId = folderId
            renameFolderDialog.visible = true
        }
        else __showSelectFolderHint()
    }

    function __showSelectFolderHint() {
        // TODO: it better to be a tool-tip or a balloon than a message box
        __showDialog(infoDialog, qsTr("Please, select a folder in the Catalog Panel"))
    }

    function __showDialog(dialog, message) {
        dialog.text = message
        dialog.visible = true
    }

    MessageDialog { id: infoDialog; icon: StandardIcon.Information }
    MessageDialog { id: errorDialog; icon: StandardIcon.Critical }
    MessageDialog { id: warningDialog; icon: StandardIcon.Warning }

    Dialog {
        id: renameFolderDialog
        standardButtons: StandardButton.Ok | StandardButton.Cancel

        property int folderId: 0
        property string folderTitle: ""

        ColumnLayout {
            spacing: 6
            Label { text: qsTr("Enter a new title for the folder") }
            RowLayout {
                spacing: 0
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

        onVisibleChanged: {
            if (!visible) return
            var info = catalog.getFolderInfo(folderId)
            folderTitle = info.folderTitle
            pathLabel.text = "/" + info.folderPath + "/"
            titleLabel.text = info.folderTitle + ":"
            titleEditor.text = info.folderTitle
            titleEditor.focus = true
        }

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
            var res = catalog.renameFolder(folderId, newTitle)
            if (res.length > 0)
                __showDialog(errorDialog, res)
        }
    }
}
