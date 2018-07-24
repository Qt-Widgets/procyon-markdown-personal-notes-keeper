import org.orion_project.procyon.catalog 1.0

import QtQuick 2.7
import QtQml 2.2
import QtQuick.Controls 1.4
import QtQuick.Dialogs 1.1
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
        property alias x: mainWindow.x
        property alias y: mainWindow.y
        property alias width: mainWindow.width
        property alias height: mainWindow.height
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
        catalog.loadSettings()

        // Default geometry when no position is stored
        if (width == 10 || height == 10) {
            width = 1024
            height = 600
            x = Screen.width / 2 - width / 2
            y = Screen.height / 2 - height / 2
        }
    }

    onClosing: {
        catalog.saveSettings()
        close.accepted = catalog.closeCatalog()
    }

    Action {
        id: newCatalogAction
        text: qsTr("&New...")
        shortcut: StandardKey.New
    }
    Action {
        id: openCatalogAction
        text: qsTr("&Open...")
        tooltip: qsTr("Open catalog")
        iconSource: "qrc:/icon/folder_opened"
        shortcut: StandardKey.Open
        onTriggered: openDialog.open()
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
            title: qsTr("&View")
        }
        Menu {
            title: qsTr("&Catalog")
            MenuItem { action: openMemoAction }
        }
        Menu {
            title: qsTr("&Options")
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

    function getRecentOpenFolder() {
        return encodeURIComponent("/home/nikolay"); // TODO
    }

    statusBar: StatusBar {
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
            width: 5
            color: styleData.pressed ? appearance.selectionColor() : appearance.baseColor()
        }

        OpenedMemosView {
            width: 200
            height: parent.height
            Layout.maximumWidth: 400
            Layout.minimumWidth: 100
        }

        MemoView {
            memoId: currentMemoId
            Layout.fillWidth: true
            Layout.minimumWidth: 100
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

    FileDialog {
        id: openDialog
        nameFilters: [qsTr("Procyon Memo Catalogs (*.enot)"), qsTr("All files (*.*)")]
        folder: getRecentOpenFolder()
        onAccepted: catalog.loadCatalog(fileUrl)
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
