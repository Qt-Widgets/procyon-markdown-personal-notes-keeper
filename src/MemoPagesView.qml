import QtQuick 2.0
import QtQuick.Controls 1.4

import org.orion_project.procyon.catalog 1.0

TabView {
    id: self
    tabsVisible: false
    frameVisible: false

    property Options options
    property CatalogHandler catalog
    property MainController controller
    property Component memoViewComponent: null
    property MemoView currentMemoPage: null
    property int currentMemoId: 0

    Connections {
        target: controller

        onMemoOpened: {
            if (memoId === currentMemoId) return
            var index = __getTabIndex(memoId)
            if (index < 0) {
                var tab = addTab(memoId, __getMemoViewComponent())
                tab.active = true // force memo view creation
                tab.item.options = options
                tab.item.catalog = catalog
                tab.item.controller = controller
                tab.item.memoId = memoId
                tab.item.loadMemo()
                index = count - 1
            }
            currentIndex = index
            currentMemoId = memoId
            currentMemoPage = (currentIndex < 0) ? null : getTab(currentIndex).item
        }

        onMemoClosed: {
            var index = __getTabIndex(memoId)
            if (index > -1) {
                // TODO: tons of warnings about invalid parent are occurred here, don't know how to fix
                removeTab(index)
                currentIndex = -1
                currentMemoId = 0
                currentMemoPage = null
            }
        }

        onAllMemosClosed: {
            while (count > 0)
                removeTab(count-1)
            currentIndex = -1
            currentMemoId = 0
            currentMemoPage = null
        }
    }

    function saveMemo(memoId) {
        var index = __getTabIndex(memoId)
        if (index > -1)
            return getTab(index).item.saveChanges()
        return ""
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
        for (var i = 0; i < count; i++)
            if (getTab(i).item.memoId === memoId)
                return i
        return -1
    }
}
