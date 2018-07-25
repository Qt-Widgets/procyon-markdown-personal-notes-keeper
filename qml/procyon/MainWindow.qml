import org.orion_project.procyon.catalog 1.0

import QtQuick 2.7
import QtQml 2.2
import QtQuick.Controls 1.4
import QtQuick.Dialogs 1.3
import QtQuick.Layouts 1.0
import QtQuick.Window 2.2
import Qt.labs.settings 1.0

ApplicationWindow {
    Appearance { id: appearance }

    id: mainWindow
    visible: true
    width: 10 // dummy default value
    height: 10 // dummy default value
    title: catalog.fileName + ' - ' + Qt.application.name
    color: appearance.baseColor()

    property int currentMemoId: 0

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
        property alias statusBarVisible: statusBar.visible
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
        onError: {
            errorDialog.text = message
            errorDialog.visible = true
        }
        onInfo: {
            infoDialog.text = message
            infoDialog.visible = true
        }
    }

    Component.onCompleted: {
        // Default geometry when no position is stored
        if (width == 10 || height == 10) {
            width = 1024
            height = 600
            x = Screen.width / 2 - width / 2
            y = Screen.height / 2 - height / 2
        }
        catalog.loadSettings()

        // We can't restore visibility of these components automatically
        // because they are on a splitter and it restores their visibility
        // after its panels are restored. So we store action check state instead
        // and use it for setting visibilty of splitter subcomponents at the very end.
        catalogView.visible = showCatalogViewAction.checked
        openedMemosView.visible = showOpenedMemosViewAction.checked
    }

    onClosing: {
        catalog.saveSettings()
        close.accepted = catalog.closeCatalog()
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
            onTriggered: catalog.closeCatalog()
        }
        Action {
            id: quitAppAction
            text: qsTr("E&xit")
            shortcut: StandardKey.Quit
            onTriggered: Qt.quit()
        }
        Action {
            id: openMemoAction
            text: qsTr("&Open memo")
            onTriggered: {
                infoDialog.text = catalogView.getSelectedMemoId()
                infoDialog.visible = true
            }
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
            checked: statusBar.visible
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
                        onTriggered: catalog.loadCatalog(text)
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
        }
        Menu {
            title: qsTr("&Options")
            MenuItem { action: showOpenedMemosViewAction }
            MenuItem { action: showCatalogViewAction }
            MenuItem { action: showStatusBarAction }
        }
    }

    /*toolBar: ToolBar {
        height: 38
        width: parent.width

        Flow {
            topPadding: 2

            Row {
                id: fileActionsToolbarRow
                ToolButton { action: openCatalogAction }
            }
        }
    }*/

    statusBar: StatusBar {
        id: statusBar

        RowLayout {
            anchors.fill: parent
            Row {
                visible: catalog.isOpened
                Label { text: qsTr("Memos: "); color: appearance.textColorModest() }
                Label { text: catalog.memoCount }
            }
            Row {
                Label { text: qsTr("Catalog: "); color: appearance.textColorModest() }
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
            color: styleData.pressed ? appearance.selectionColor() : appearance.baseColor()
        }

        OpenedMemosView {
            id: openedMemosView
            width: 200
            height: parent.height
            Layout.maximumWidth: 400
            Layout.minimumWidth: 100
        }

        MemoView {
            memoId: currentMemoId
            Layout.fillWidth: true
            Layout.minimumWidth: 100
            Layout.leftMargin: openedMemosView.visible ? 0 : 4
            Layout.rightMargin: catalogView.visible ? 0 : 4
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
        }
    }

    Item {
        id: dialogs

        FileDialog {
            id: openCatalogDialog
            nameFilters: [qsTr("Procyon Memo Catalogs (*.enot)"), qsTr("All files (*.*)")]
            folder: shortcuts.documents
            onAccepted: catalog.loadCatalog(fileUrl)
        }

        FileDialog {
            id: newCatalogDialog
            nameFilters: openCatalogDialog.nameFilters
            selectExisting: false
            folder: shortcuts.documents
            onAccepted: catalog.newCatalog(fileUrl)
        }

        MessageDialog {
            id: errorDialog
            icon: StandardIcon.Critical
        }

        MessageDialog {
            id: infoDialog
            icon: StandardIcon.Information
        }
    }
}
