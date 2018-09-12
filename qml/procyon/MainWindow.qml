import QtQuick 2.7
import QtQml 2.2
import QtQuick.Controls 1.4
import QtQuick.Dialogs 1.3
import QtQuick.Layouts 1.0
import QtQuick.Window 2.2
import Qt.labs.settings 1.0

import org.orion_project.procyon.catalog 1.0
import "appearance.js" as Appearance

ApplicationWindow {
    id: mainWindow
    visible: true
    width: 1024
    height: 600
    title: catalog.isOpened ? (catalog.fileName + ' - ' + Qt.application.name) : Qt.application.name
    color: Appearance.baseColor()

    property bool forceClosing: false

    Settings {
        category: "MainWindow"
        property alias windowX: mainWindow.x
        property alias windowY: mainWindow.y
        property alias windowWidth: mainWindow.width
        property alias windowHeight: mainWindow.height
        property alias openedMemosViewWidth: openedMemosView.width
        property alias openedMemosViewVisible: showOpenedMemosViewAction.checked
        property alias catalogViewWidth: catalogView.width
        property alias catalogViewVisible: showCatalogViewAction.checked
        property alias statusBarVisible: showStatusBarAction.checked
    }

    CatalogHandler {
        id: catalog
        onError: errorDialog.show(message)
        onInfo: infoDialog.show(message)
    }

    MainController {
        id: controller
        catalog: catalog
        onNeedToCloseMemo: operations.closeMemo(memoId)
    }

    Component.onCompleted: {
        // We can't restore visibility of these components automatically
        // because they are on a splitter and it restores their visibility
        // after its panels are restored. So we store action check state instead
        // and use it for setting visibilty of splitter subcomponents at the very end.
        catalogView.visible = showCatalogViewAction.checked
        openedMemosView.visible = showOpenedMemosViewAction.checked
        statusBar.visible = showStatusBarAction.checked

        catalog.loadSettings()

        memoWordWrapAction.checked = catalog.memoWordWrap

        if (catalog.recentFile)
            operations.loadCatalogFile(catalog.recentFile)
    }

    onClosing: {
        if (!forceClosing) {
            close.accepted = false
            catalog.saveSettings()
            operations.closeCatalog(function() {
                forceClosing = true
                mainWindow.close()
            })
        }
    }

    Item {
        id: operations

        function createNewCatalog(fileUrl) {
            closeCatalog(function() {
                catalog.newCatalog(fileUrl)
            });
        }

        function loadCatalogFile(fileName) {
            if (!catalog.sameFile(fileName)) {
                closeCatalog(function() {
                    catalog.loadCatalogFile(fileName)
                    restoreSession()
                })
            }
        }

        function loadCatalogUrl(fileUrl) {
            if (!catalog.sameUrl(fileUrl)) {
                closeCatalog(function() {
                    catalog.loadCatalogUrl(fileUrl)
                    restoreSession()
                })
            }
        }

        function closeCatalog(onAccept) {
            if (!catalog.isOpened) {
                onAccept()
                return
            }
            storeSession()
            closeAllMemos(function() {
                catalog.closeCatalog()
                onAccept()
            })
        }

        function restoreSession() {
            var session = catalog.getStoredSession()

            openedMemosView.setAllIdsStr(session.openedMemos)
            catalogView.setExpandedIdsStr(session.expandedFolders)

            var activeMemoId = session.activeMemo
            if (activeMemoId > 0)
                openedMemosView.currentMemoId = activeMemoId
        }

        function storeSession() {
            catalog.storeSession({
                openedMemos: openedMemosView.getAllIdsStr(),
                activeMemo: openedMemosView.currentMemoId,
                expandedFolders: catalogView.getExpandedIdsStr()
            })
        }

        function closeMemo(memoId) {
            if (memoId > 0) {
                if (memoPagesView.isMemoModified(memoId))
                    saveAndCloseMemoDialog.show(memoId,
                                                memoPagesView.saveMemo,
                                                controller.memoClosed)
                else
                    controller.memoClosed(memoId)
            }
        }

        function closeAllMemos(onAccept) {
            var changedMemos = memoPagesView.getModifiedMemos()
            if (changedMemos.length === 0) {
                controller.allMemosClosed()
                if (onAccept) onAccept()
            }
            else if (changedMemos.length === 1) {
                saveAndCloseMemoDialog.show(changedMemos[0].memoId,
                                            memoPagesView.saveMemo,
                                            function() {
                                                controller.allMemosClosed()
                                                if (onAccept) onAccept()
                                            })
            }
            else {
                console.log("TODO show dialog with multi-selector")
                if (onAccept) onAccept()
            }
        }

        function deleteMemo(memoId) {

        }

        function newMemo() {

        }
    }

    Item {
        id: actions
        Item {
            id: fileActions
            Action {
                id: newCatalogAction
                text: qsTr("&New...")
                iconName: "document-new"
                shortcut: StandardKey.New
                onTriggered: newCatalogDialog.open()
            }
            Action {
                id: openCatalogAction
                text: qsTr("&Open...")
                tooltip: qsTr("Open catalog")
                iconName: "document-open"
                shortcut: StandardKey.Open
                onTriggered: openCatalogDialog.open()
            }
            Action {
                id: closeCatalogAction
                text: qsTr("&Close")
                enabled: catalog.isOpened
                onTriggered: operations.closeCatalog()
            }
            Action {
                id: quitAppAction
                text: qsTr("E&xit")
                iconName: "application-exit"
                shortcut: StandardKey.Quit
                onTriggered: Qt.quit()
            }
        }
        Item {
            id: editActions
            // TODO: how to display edit actions shortcuts in the main menu?
            // They clash with built-in shortcuts of TextArea
            Action {
                id: editUndoAction
                text: qsTr("&Undo")
                iconName: "edit-undo"
                //shortcut: StandardKey.Undo -- Ambiguous shortcut overload
                enabled: activeFocusItem && ("undo" in activeFocusItem)
                         && (!("readOnly" in activeFocusItem) || !activeFocusItem.readOnly)
                onTriggered: activeFocusItem.undo()
            }
            Action {
                id: editRedoAction
                text: qsTr("&Redo")
                iconName: "edit-redo"
                //shortcut: StandardKey.Redo -- Ambiguous shortcut overload
                enabled: activeFocusItem && ("redo" in activeFocusItem)
                         && (!("readOnly" in activeFocusItem) || !activeFocusItem.readOnly)
                onTriggered: activeFocusItem.redo()
            }
            Action {
                id: editCutAction
                text: qsTr("Cu&t")
                iconName: "edit-cut"
                //shortcut: StandardKey.Cut -- Ambiguous shortcut overload
                enabled: activeFocusItem && ("cut" in activeFocusItem)
                         && (!("readOnly" in activeFocusItem) || !activeFocusItem.readOnly)
                onTriggered: activeFocusItem.cut()
            }
            Action {
                id: editCopyAction
                text: qsTr("&Copy")
                iconName: "edit-copy"
                //shortcut: StandardKey.Copy -- Ambiguous shortcut overload
                enabled: activeFocusItem && ("copy" in activeFocusItem)
                onTriggered: activeFocusItem.copy()
            }
            Action {
                id: editPasteAction
                text: qsTr("&Paste")
                iconName: "edit-paste"
                //shortcut: StandardKey.Paste -- Ambiguous shortcut overload
                enabled: activeFocusItem && ("paste" in activeFocusItem)
                         && (!activeFocusItem["readOnly"] || !activeFocusItem.readOnly)
                onTriggered: activeFocusItem.paste()
            }
            Action {
                id: editSelectAllAction
                text: qsTr("Select &All")
                iconName: "edit-select-all"
                //shortcut: StandardKey.SelectAll -- Ambiguous shortcut overload
                enabled: activeFocusItem && ("selectAll" in activeFocusItem)
                onTriggered: activeFocusItem.selectAll()
            }
        }
        Item {
            id: viewActions
            Action {
                id: showOpenedMemosViewAction
                text: qsTr("&Opened Memos Panel")
                checkable: true
                checked: true
                onToggled: openedMemosView.visible = checked
            }
            Action {
                id: showCatalogViewAction
                text: qsTr("&Catalog Panel")
                checkable: true
                checked: true
                onToggled: catalogView.visible = checked
            }
            Action {
                id: showStatusBarAction
                text: qsTr("&Status Bar")
                checkable: true
                checked: true
                onToggled: statusBar.visible = checked
            }
        }
        Item {
            id: catalogActions
            Action {
                id: openMemoAction
                text: qsTr("&Open Memo")
                enabled: catalogView.selectedMemoId > 0
                onTriggered: controller.openMemo(catalogView.selectedMemoId)
            }
            Action {
                id: newMemoAction
                text: qsTr("New Memo")
                onTriggered: operations.newMemo()
            }
            Action {
                id: deleteMemoAction
                text: qsTr("Delete Memo")
                enabled: catalogView.selectedMemoId > 0
                onTriggered: operations.deleteMemo(catalogView.selectedMemoId)
            }
            Action {
                id: closeMemoAction
                text: qsTr("&Close Memo")
                iconSource: "qrc:/toolbar/memo_close"
                shortcut: StandardKey.Close
                enabled: openedMemosView.currentMemoId > 0
                onTriggered: operations.closeMemo(openedMemosView.currentMemoId)
            }
            Action {
                id: closeAllMemosAction
                text: qsTr("Close &All Memos")
                enabled: openedMemosView.currentMemoId > 0
                onTriggered: operations.closeAllMemos()
            }
            Action {
                id: editMemoAction
                text: qsTr("&Edit Memo")
                iconSource: "qrc:/toolbar/memo_edit"
                shortcut: "Return,Return"
                enabled: memoPagesView.currentMemoPage && !memoPagesView.currentMemoPage.editMemoMode
                onTriggered: memoPagesView.currentMemoPage.editMemoMode = true
            }
            Action {
                id: saveMemoAction
                text: qsTr("&Save Memo")
                iconSource: "qrc:/toolbar/memo_save"
                shortcut: StandardKey.Save
                enabled: memoPagesView.currentMemoPage && memoPagesView.currentMemoPage.editMemoMode
                onTriggered: memoPagesView.currentMemoPage.saveChanges()
            }
            Action {
                id: cancelMemoAction
                text: qsTr("Cancel Changes")
                iconSource: "qrc:/toolbar/memo_cancel"
                shortcut: "Esc,Esc"
                enabled: memoPagesView.currentMemoPage && memoPagesView.currentMemoPage.editMemoMode
                onTriggered: memoPagesView.currentMemoPage.cancelEditing()
            }
            Action {
                id: renameFolderAction
                text: qsTr("Rename Folder...")
                enabled: catalogView.selectedFolderId > 0
                onTriggered: controller.renameFolder(catalogView.selectedFolderId)
            }
        }
        Item {
            id: optionsActions
            Action {
                id: chooseMemoFontAction
                text: qsTr("Choose Memo Font...")
                onTriggered: {
                    memoFontDialog.font = catalog.memoFont
                    memoFontDialog.open()
                }
            }
            Action {
                id: memoWordWrapAction
                text: qsTr("Word Wrap")
                checkable: true
                onToggled: catalog.memoWordWrap = checked
            }
        }
    }

    menuBar: MenuBar {
        id: mainMenu
        Menu {
            id: fileMenu
            title: qsTr("&File")
            MenuItem { action: newCatalogAction }
            MenuItem { action: openCatalogAction }
            MenuItem { action: closeCatalogAction }
            Menu {
                id: mruFileMenu
                title: qsTr("&Recent Files")
                Instantiator {
                    model: catalog.recentFilesModel
                    MenuItem {
                        text: modelData
                        onTriggered: operations.loadCatalogFile(text)
                    }
                    onObjectAdded: mruFileMenu.insertItem(index, object)
                    onObjectRemoved: mruFileMenu.removeItem(object)
                }
                MenuSeparator {
                    visible: catalog.hasRecentFiles
                }
                MenuItem {
                    text: qsTr("&Delete Invalid Items ")
                    enabled: catalog.hasRecentFiles
                    onTriggered: catalog.deleteInvalidMruItems()
                }
                MenuItem {
                    text: qsTr("&Clear History")
                    enabled: catalog.hasRecentFiles
                    onTriggered: catalog.deleteAllMruItems()
                }
            }
            MenuSeparator {}
            MenuItem { action: quitAppAction }
        }
        Menu {
            id: editMenu
            title: qsTr("&Edit")
            MenuItem { action: editUndoAction }
            MenuItem { action: editRedoAction }
            MenuSeparator {}
            MenuItem { action: editCutAction }
            MenuItem { action: editCopyAction }
            MenuItem { action: editPasteAction }
            MenuSeparator {}
            MenuItem { action: editSelectAllAction }
        }
        Menu {
            id: viewMenu
            title: qsTr("&View")
            MenuItem { action: showOpenedMemosViewAction }
            MenuItem { action: showCatalogViewAction }
            MenuItem { action: showStatusBarAction }
        }
        Menu {
            id: catalogMenu
            title: qsTr("&Catalog")
            MenuItem { action: renameFolderAction }
            MenuSeparator {}
            MenuItem { action: openMemoAction }
            MenuItem { action: newMemoAction }
            MenuItem { action: deleteMemoAction }
            MenuSeparator {}
            MenuItem { action: editMemoAction }
            MenuItem { action: saveMemoAction }
            MenuItem { action: cancelMemoAction }
            MenuSeparator {}
            MenuItem { action: closeMemoAction }
            MenuItem { action: closeAllMemosAction }
        }
        Menu {
            id: optionsMenu
            title: qsTr("&Options")
            MenuItem { action: chooseMemoFontAction }
            MenuItem { action: memoWordWrapAction }
        }
    }

    statusBar: StatusBar {
        id: statusBar

        RowLayout {
            anchors.fill: parent
            Row {
                visible: catalog.isOpened
                Label { text: qsTr("Memos: "); color: Appearance.textColorModest() }
                Label { text: catalog.memoCount }
            }
            Row {
                visible: catalog.isOpened
                leftPadding: 6
                Label { text: qsTr("Opened: "); color: Appearance.textColorModest() }
                Label { text: memoPagesView.count }
            }
            Row {
                leftPadding: 6
                Label { text: qsTr("Catalog: "); color: Appearance.textColorModest() }
                Label { text: catalog.filePath || qsTr("(not selected)") }
            }
            Item { Layout.fillWidth: true }
        }
    }

    SplitView {
        id: centralArea
        anchors.fill: parent
        orientation: Qt.Horizontal
        handleDelegate: Rectangle {
            width: 4
            color: styleData.pressed ? Appearance.selectionColor() : Appearance.baseColor()
        }

        OpenedMemosView {
            id: openedMemosView
            catalog: catalog
            controller: controller
            width: 200
            height: parent.height
            Layout.maximumWidth: 400
            Layout.minimumWidth: 100
        }

        MemoPagesView {
            id: memoPagesView
            catalog: catalog
            controller: controller
            Layout.fillWidth: true
            Layout.minimumWidth: 100
            Layout.leftMargin: openedMemosView.visible ? 0 : 4
            Layout.rightMargin: catalogView.visible ? 0 : 4
        }

        CatalogView {
            id: catalogView
            controller: controller
            catalogModel: catalog.model
            width: 200
            Layout.maximumWidth: 400
            Layout.minimumWidth: 100
            Layout.rightMargin: 4
            Layout.bottomMargin: 4
            Layout.topMargin: 4
        }
    }

    Item {
        id: dialogs

        FileDialog {
            id: openCatalogDialog
            nameFilters: [qsTr("Procyon Memo Catalogs (*.enot)"), qsTr("All files (*.*)")]
            folder: shortcuts.documents
            onAccepted: operations.loadCatalogUrl(fileUrl)
        }

        FileDialog {
            id: newCatalogDialog
            nameFilters: openCatalogDialog.nameFilters
            selectExisting: false
            folder: shortcuts.documents
            onAccepted: operations.createNewCatalog(fileUrl)
        }

        FontDialog {
            id: memoFontDialog
            onAccepted: catalog.memoFont = font
        }

        MessageDialog {
            id: errorDialog
            icon: StandardIcon.Critical

            function show(message) {
                text = message
                visible = true
            }
        }

        MessageDialog {
            id: infoDialog
            icon: StandardIcon.Information

            function show(message) {
                text = message
                visible = true
            }
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
                text = info.memoPath + "/<b>" + info.memoTitle + "</b><p>Save changes?"
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
}
