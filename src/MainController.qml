import QtQml 2.2
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
    property var getModifiedMemoIds // int[] function()
    property var getCurrentMemoId // int function()
    property var saveMemo // void function(memoId)
    property var storeSessionFuncs: [] // [void function(json)]
    property var restoreSessionFuncs: [] // [void function(json)]

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

    function createNewCatalog(fileUrl) {
        closeCatalog(function() {
            catalog.newCatalog(fileUrl)
        });
    }

    function loadCatalogFile(fileName) {
        if (!catalog.sameFile(fileName)) {
            closeCatalog(function() {
                catalog.loadCatalogFile(fileName)
                __restoreSession()
            })
        }
    }

    function loadCatalogUrl(fileUrl) {
        if (!catalog.sameUrl(fileUrl)) {
            closeCatalog(function() {
                catalog.loadCatalogUrl(fileUrl)
                __restoreSession()
            })
        }
    }

    function closeCatalog(onAccept) {
        if (!catalog.isOpened) {
            onAccept()
            return
        }
        __storeSession()
        closeAllMemos(function() {
            catalog.closeCatalog()
            onAccept()
        })
    }

    function makePath(itemPath, itemTitle) {
        var path = itemPath.length ? (itemPath + "/") : ""
        var title = itemTitle.length ? itemTitle : ("<i>&lt;" + qsTr("Untitled") + "&gt;</i>")
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
        else memoClosed(memoId)
    }

    function closeAllMemos(onAccept) {
        var closeMemos = function() {
            allMemosClosed()
            if (onAccept) onAccept()
        }
        var memoIds = getModifiedMemoIds()
        if (memoIds.length === 0)
            closeMemos()
        else if (memoIds.length === 1)
            saveAndCloseMemoDialog.show(memoIds[0], saveMemo, closeMemos)
        else
            saveAndCloseMemosDialog.show(memoIds, saveMemo, closeMemos)
    }

    function __showDialog(dialog, message) {
        dialog.text = message
        dialog.visible = true
    }

    function __restoreSession() {
        var session = catalog.getStoredSession()

        for (var i = 0; i < restoreSessionFuncs.length; i++)
            restoreSessionFuncs[i](session)

        openMemo(session.activeMemo)
    }

    function __storeSession() {
        var session = {}

        for (var i = 0; i < storeSessionFuncs.length; i++)
            storeSessionFuncs[i](session)

        session.activeMemo = getCurrentMemoId()

        catalog.storeSession(session)
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
                id: promptLabel
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
        property int memoId
        property var saveMethod
        property var closeMethod

        function show(memoId, saveMethod, closeMethod) {
            saveAndCloseMemoDialog.memoId = memoId
            saveAndCloseMemoDialog.saveMethod = saveMethod
            saveAndCloseMemoDialog.closeMethod = closeMethod

            var info = catalog.getMemoInfo(memoId)
            text = makePath(info.memoPath, info.memoTitle) + "<p>" + qsTr("Save changes?")

            visible = true
        }

        onYes: {
            var error = saveMethod(memoId)
            if (error.length) {
                __showDialog(errorDialog, error)
                return
            }
            closeMethod(memoId)
        }

        onNo: closeMethod(memoId)
    }

    Dialog {
        id: saveAndCloseMemosDialog
        standardButtons: StandardButton.Ok | StandardButton.Cancel

        property var saveMethod
        property var closeMethod
        property var memoIds

        ColumnLayout {
            spacing: 12
            anchors.fill: parent
            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                Image { source: "qrc:/icon/save_memos_dialog" }
                Label { text: qsTr("These memos were changed.\n" +
                    "Which of them should be saved before closing?") }
            }
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                ListView {
                    spacing: 3
                    model: ListModel {id: memosModel }
                    delegate: CheckBox {
                        text: makePath(model.memoPath, model.memoTitle)
                        checked: model.isChecked
                        onCheckedChanged: model.isChecked = checked
                    }
                }
            }
        }

        function show(memoIds, saveMethod, closeMethod) {
            saveAndCloseMemosDialog.memoIds = memoIds
            saveAndCloseMemosDialog.saveMethod = saveMethod
            saveAndCloseMemosDialog.closeMethod = closeMethod

            memosModel.clear()
            for (var i = 0; i < memoIds.length; i++) {
                var info = catalog.getMemoInfo(memoIds[i])
                info.isChecked = true
                memosModel.append(info)
            }

            visible = true
        }

        onAccepted: {
            for (var i = 0; i < memosModel.count; i++) {
                var item = memosModel.get(i)
                if (item.isChecked) {
                    var error = saveMethod(item.memoId)
                    if (error.length) {
                        __showDialog(errorDialog, error)
                        return
                    }
                }
            }
            closeMethod()
        }
    }
}
