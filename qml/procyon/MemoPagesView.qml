import QtQuick 2.0
import QtQuick.Controls 1.4

import org.orion_project.procyon.catalog 1.0

TabView {
    id: self
    tabsVisible: false
    frameVisible: false

    property Component memoViewComponent: null
    property CatalogHandler catalog: null
    property int currentMemoId: 0
    signal needToCloseMemo(int memoId)

    onCurrentMemoIdChanged: {
        if (currentMemoId > 0) {
            var index = __getTabIndex(currentMemoId)
            if (index < 0) {
                var tab = addTab(currentMemoId, __getMemoViewComponent())
                tab.active = true // force memo view creation
                tab.item.catalog = catalog
                tab.item.signalProxy = self
                tab.item.memoId = currentMemoId
                tab.item.loadMemo()
                index = count - 1
            }
            currentIndex = index
        }
    }

    function closeMemo(memoId) {
        var index = __getTabIndex(memoId)
        if (index > -1) {
            removeTab(index)
        }
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
