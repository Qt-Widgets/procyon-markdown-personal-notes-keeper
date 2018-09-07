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
    property MemoView currentMemoPage: null
    signal needToCloseMemo(int memoId)
    signal memoModified(int memoId, bool modified)

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

    onCurrentIndexChanged: {
        currentMemoPage = (currentIndex < 0) ? null : getTab(currentIndex).item
    }

    function saveMemo(memoId) {
        var index = __getTabIndex(memoId)
        if (index > -1)
            return getTab(index).item.saveChanges()
        return ""
    }

    function closeMemo(memoId) {
        var index = __getTabIndex(memoId)
        if (index > -1)
            // TODO: tons of warnings about invalid parent are occurred here, don't know how to fix
            removeTab(index)
    }

    function closeAllMemos() {
        while (count > 0)
            removeTab(count-1)
    }

    function isMemoModified(memoId) {
        var index = __getTabIndex(memoId)
        return (index > -1) && getTab(index).item.isModified()
    }

    function getModifiedMemos() {
        var memoList = []
        for (var i = 0; i < count; i++) {
            var memoView = getTab(i).item
            if (memoView.isModified()) {
                console.log("Modified: " + memoView.memoId)
                var info = catalog.getMemoInfo(memoView.memoId)
                info.checked = false
                memoList.push(info)
            }
        }
        return memoList
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
