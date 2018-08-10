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
        /*document: textArea.textDocument
        cursorPosition: textArea.cursorPosition
        selectionStart: textArea.selectionStart
        selectionEnd: textArea.selectionEnd
        textColor: colorDialog.color
        Component.onCompleted: document.load("qrc:/texteditor.html")
        onLoaded: {
            textArea.text = text
        }*/
        onError: errorDialog.show(message)
        onInfo: infoDialog.show(message)
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

        if (catalog.recentFile)
            loadCatalogFile(catalog.recentFile)
    }

    onClosing: {
        catalog.saveSettings()
        close.accepted = closeCatalog()
    }

    function createNewCatalog(fileUrl) {
        if (closeCatalog())
            catalog.newCatalog(fileUrl)
    }

    function loadCatalogFile(fileName) {
        if (!catalog.sameFile(fileName) && closeCatalog()) {
            catalog.loadCatalogFile(fileName)
            restoreSession()
        }
    }

    function loadCatalogUrl(fileUrl) {
        if (!catalog.sameUrl(fileUrl) && closeCatalog()) {
            catalog.loadCatalogUrl(fileUrl)
            restoreSession()
        }
    }

    function restoreSession() {
        var session = catalog.getStoredSession()

        openedMemosView.setAllIdsStr(session["openedMemos"])
        catalogView.setExpandedIdsStr(session["expandedFolders"])

        var activeMemoId = session["activeMemo"]
        if (activeMemoId > 0)
            openedMemosView.currentMemoId = activeMemoId
    }

    function storeSession() {
        catalog.storeSession({
            "openedMemos": openedMemosView.getAllIdsStr(),
            "activeMemo": openedMemosView.currentMemoId,
            "expandedFolders": catalogView.getExpandedIdsStr()
        })
    }

    function closeCatalog() {
        // TODO check if memos were changed and save them
        if (catalog.isOpened) storeSession()
        closeAllMemos()
        catalog.closeCatalog()
        return true
    }

    function openMemo(memoId) {
        if (memoId > 0) {
            openedMemosView.currentMemoId = memoId
            memoPagesView.currentMemoId = memoId
        }
    }

    function closeMemo(memoId) {
        if (memoId > 0) {
            // TODO check if memo was changed and save it
            openedMemosView.memoClosed(memoId)
            memoPagesView.closeMemo(memoId)
        }
    }

    function closeAllMemos() {
        openedMemosView.allMemosClosed()
        memoPagesView.closeAllMemos()
    }

    Item {
        id: actions
        Action {
            id: newCatalogAction
            text: qsTr("&New...")
            shortcut: StandardKey.New
            onTriggered: newCatalogDialog.open()
        }
        Action {
            id: openCatalogAction
            text: qsTr("&Open...")
            tooltip: qsTr("Open catalog")
            iconSource: "qrc:/icon/folder_opened"
            shortcut: StandardKey.Open
            onTriggered: openCatalogDialog.open()
        }
        Action {
            id: closeCatalogAction
            text: qsTr("&Close")
            enabled: catalog.isOpened
            onTriggered: closeCatalog()
        }
        Action {
            id: quitAppAction
            text: qsTr("E&xit")
            shortcut: StandardKey.Quit
            onTriggered: Qt.quit()
        }
        Action {
            id: openMemoAction
            text: qsTr("&Open Memo")
            onTriggered: openMemo(catalogView.getSelectedMemoId())
        }
        Action {
            id: closeMemoAction
            text: qsTr("&Close Memo")
            shortcut: StandardKey.Close
            enabled: openedMemosView.currentMemoId > 0
            onTriggered: closeMemo(openedMemosView.currentMemoId)
        }
        Action {
            id: closeAllMemosAction
            text: qsTr("Close &All Memos")
            enabled: openedMemosView.currentMemoId > 0
            onTriggered: closeAllMemos()
        }
        Action {
            id: showOpenedMemosViewAction
            text: qsTr("Show &Opened Memos Panel")
            checkable: true
            checked: true
            onToggled: openedMemosView.visible = checked
        }
        Action {
            id: showCatalogViewAction
            text: qsTr("Show &Catalog Panel")
            checkable: true
            checked: true
            onToggled: catalogView.visible = checked
        }
        Action {
            id: showStatusBarAction
            text: qsTr("Show &Status Bar")
            checkable: true
            checked: true
            onToggled: statusBar.visible = checked
        }
    }

    menuBar: MenuBar {
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
                        onTriggered: loadCatalogFile(text)
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
            title: qsTr("&Edit")
        }
        Menu {
            title: qsTr("&Catalog")
            MenuItem { action: openMemoAction }
            MenuItem { action: closeMemoAction }
            MenuItem { action: closeAllMemosAction }
        }
        Menu {
            title: qsTr("&Options")
            MenuItem { action: showOpenedMemosViewAction }
            MenuItem { action: showCatalogViewAction }
            MenuItem { action: showStatusBarAction }
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
        anchors.fill: parent
        orientation: Qt.Horizontal
        handleDelegate: Rectangle {
            width: 4
            color: styleData.pressed ? Appearance.selectionColor() : Appearance.baseColor()
        }

        OpenedMemosView {
            id: openedMemosView
            catalog: catalog
            width: 200
            height: parent.height
            Layout.maximumWidth: 400
            Layout.minimumWidth: 100
            onNeedToActivateMemo: openMemo(memoId)
            onNeedToCloseMemo: closeMemo(memoId)
        }

        MemoPagesView {
            id: memoPagesView
            catalog: catalog
            Layout.fillWidth: true
            Layout.minimumWidth: 100
            Layout.leftMargin: openedMemosView.visible ? 0 : 4
            Layout.rightMargin: catalogView.visible ? 0 : 4
            onNeedToCloseMemo: closeMemo(memoId)
        }

        CatalogView {
            id: catalogView
            catalogModel: catalog.model
            width: 200
            Layout.maximumWidth: 400
            Layout.minimumWidth: 100
            Layout.rightMargin: 4
            Layout.bottomMargin: 4
            Layout.topMargin: 4
            onNeedToOpenMemo: openMemo(memoId)
        }
    }

    Item {
        id: dialogs

        FileDialog {
            id: openCatalogDialog
            nameFilters: [qsTr("Procyon Memo Catalogs (*.enot)"), qsTr("All files (*.*)")]
            folder: shortcuts.documents
            onAccepted: loadCatalogUrl(fileUrl)
        }

        FileDialog {
            id: newCatalogDialog
            nameFilters: openCatalogDialog.nameFilters
            selectExisting: false
            folder: shortcuts.documents
            onAccepted: createNewCatalog(fileUrl)
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
    }
}
