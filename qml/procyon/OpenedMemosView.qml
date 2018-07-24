import QtQuick 2.0

Rectangle {

    ListModel {
        id: demoOpenedMemosData
        ListElement { memoId: 1; memoTitle: "Проектирование"; memoFolder: "3D print"; memoType: "text/rich" }
        ListElement { memoId: 2; memoTitle: "dev commands"; memoFolder: "OS/Ubuntu"; memoType: "text/code/bash" }
        ListElement { memoId: 3; memoTitle: "Read text from file"; memoFolder: "Programming/Python/Code snippets"; memoType: "text/code/python" }
        ListElement { memoId: 4; memoTitle: "Проектирование"; memoFolder: "3D print"; memoType: "text/rich" }
        ListElement { memoId: 5; memoTitle: "dev commands"; memoFolder: "OS/Ubuntu"; memoType: "text/code/bash" }
        ListElement { memoId: 6; memoTitle: "Read text from file"; memoFolder: "Programming/Python/Code snippets"; memoType: "text/code/python" }
        ListElement { memoId: 7; memoTitle: "Проектирование"; memoFolder: "3D print"; memoType: "text/rich" }
        ListElement { memoId: 8; memoTitle: "dev commands"; memoFolder: "OS/Ubuntu"; memoType: "text/code/bash" }
        ListElement { memoId: 9; memoTitle: "Read text from file"; memoFolder: "Programming/Python/Code snippets"; memoType: "text/code/python" }
        ListElement { memoId: 10; memoTitle: "Проектирование"; memoFolder: "3D print"; memoType: "text/rich" }
        ListElement { memoId: 11; memoTitle: "dev commands"; memoFolder: "OS/Ubuntu"; memoType: "text/code/bash" }
        ListElement { memoId: 12; memoTitle: "Read text from file"; memoFolder: "Programming/Python/Code snippets"; memoType: "text/code/python" }
        ListElement { memoId: 13; memoTitle: "Проектирование"; memoFolder: "3D print"; memoType: "text/rich" }
        ListElement { memoId: 14; memoTitle: "dev commands"; memoFolder: "OS/Ubuntu"; memoType: "text/code/bash" }
        ListElement { memoId: 15; memoTitle: "Read text from file"; memoFolder: "Programming/Python/Code snippets"; memoType: "text/code/python" }
        ListElement { memoId: 16; memoTitle: "Проектирование"; memoFolder: "3D print"; memoType: "text/rich" }
        ListElement { memoId: 17; memoTitle: "dev commands"; memoFolder: "OS/Ubuntu"; memoType: "text/code/bash" }
        ListElement { memoId: 18; memoTitle: "Read text from file"; memoFolder: "Programming/Python/Code snippets"; memoType: "text/code/python" }
        ListElement { memoId: 19; memoTitle: "Проектирование"; memoFolder: "3D print"; memoType: "text/rich" }
        ListElement { memoId: 20; memoTitle: "dev commands"; memoFolder: "OS/Ubuntu"; memoType: "text/code/bash" }
        ListElement { memoId: 21; memoTitle: "Read text from file"; memoFolder: "Programming/Python/Code snippets"; memoType: "text/code/python" }
    }

    ListView {
        model: demoOpenedMemosData
        delegate: OpenedMemoItemDelegate { itemSize: parent.width }
        spacing: 3
        anchors.fill: parent
    }
}
