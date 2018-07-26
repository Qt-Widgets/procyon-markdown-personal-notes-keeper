import QtQuick 2.0
import QtQuick.Controls 1.4

import org.orion_project.procyon.catalog 1.0

TabView {
    tabsVisible: false
    frameVisible: false

    property Component memoViewComponent: null
    property CatalogHandler catalog: null

    function getMemoViewComponent() {
        if (!memoViewComponent) {
            memoViewComponent = Qt.createComponent("MemoView.qml")
            if (memoViewComponent.status !== Component.Ready) {
                console.log("Unable to load component MemoView")
                return null
            }
        }
        return memoViewComponent
    }

    function getExistedTabIndex(memoId) {
        var s = memoId.toString()
        for (var i = 0; i < count; i++)
            if (getTab(i).title === s)
                return i
        return -1
    }

    function openPage(memoId) {
        if (memoId < 0) return
        var index = getExistedTabIndex(memoId)
        if (index < 0) {
            var tab = addTab(memoId, getMemoViewComponent())
            tab.active = true // force memo view creation
            tab.item.catalog = catalog
            tab.item.memoId = memoId
            tab.item.loadMemo()
            index = count - 1
        }
        currentIndex = index
    }
}
