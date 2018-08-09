import QtQuick 2.0
import QtQuick.Controls 1.4

import org.orion_project.procyon.catalog 1.0

TabView {
    tabsVisible: false
    frameVisible: false

    property Component memoViewComponent: null
    property CatalogHandler catalog: null
    property int currentMemoId: -1

    onCurrentMemoIdChanged: {
        if (currentMemoId < 0) return
        var index = __getTabIndex(currentMemoId)
        if (index < 0) {
            var tab = addTab(currentMemoId, __getMemoViewComponent())
            tab.active = true // force memo view creation
            tab.item.catalog = catalog
            tab.item.memoId = currentMemoId
            tab.item.loadMemo()
            index = count - 1
        }
        currentIndex = index
    }

    function __getMemoViewComponent() {
        if (!memoViewComponent) {
            memoViewComponent = Qt.createComponent("MemoView.qml")
            if (memoViewComponent.status !== Component.Ready) {
                console.log("Unable to load component MemoView")
                return null
            }
        }
        return memoViewComponent
    }

    function __getTabIndex(memoId) {
        var s = memoId.toString()
        for (var i = 0; i < count; i++)
            if (getTab(i).title === s)
                return i
        return -1
    }
}
