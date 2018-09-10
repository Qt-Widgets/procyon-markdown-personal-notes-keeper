import QtQuick 2.0

Item {
    signal needToOpenMemo(int memoId)
    signal memoOpened(int memoId)

    signal needToCloseMemo(int memoId)
    signal memoClosed(int memoId)

    signal allMemosClosed()

    signal memoModified(int memoId, bool modified)
}
