#include "Catalog.h"
#include "CatalogStore.h"
#include "Memo.h"

#include <QDebug>

MemoType::~MemoType() {}

Memo* PlainTextMemoType::makeMemo() { return new PlainTextMemo(this); }
Memo* WikiTextMemoType::makeMemo() { return new WikiTextMemo(this); }
Memo* RichTextMemoType::makeMemo() { return new RichTextMemo(this); }

//------------------------------------------------------------------------------

CatalogItem::~CatalogItem() {}
bool CatalogItem::isFolder() const { return dynamic_cast<const FolderItem*>(this); }
bool CatalogItem::isMemo() const { return dynamic_cast<const MemoItem*>(this); }
FolderItem* CatalogItem::asFolder() { return dynamic_cast<FolderItem*>(this); }
MemoItem* CatalogItem::asMemo() { return dynamic_cast<MemoItem*>(this); }

const QString CatalogItem::path() const
{
    QStringList path;
    auto p = _parent;
    while (p)
    {
        path.insert(0, p->title());
        p = p->parent();
    }
    return path.join('/');
}

//------------------------------------------------------------------------------

FolderItem::~FolderItem()
{
    qDeleteAll(_children);
}

//------------------------------------------------------------------------------

MemoItem::~MemoItem()
{
    if (_memo) delete _memo;
}

//------------------------------------------------------------------------------

QString Catalog::fileFilter()
{
    return tr("Procyon Memo Catalogs (*.enot);;All files (*.*)");
}

QString Catalog::defaultFileExt()
{
    return QStringLiteral("enot");
}

CatalorResult Catalog::open(const QString& fileName)
{
    QString res = CatalogStore::openDatabase(fileName);
    if (!res.isEmpty())
        return CatalorResult::fail(res);

    Catalog* catalog = new Catalog;
    catalog->_fileName = fileName;

    FoldersResult folders = CatalogStore::folderManager()->selectAll();
    if (!folders.error.isEmpty())
    {
        delete catalog;
        return CatalorResult::fail(folders.error);
    }

    for (FolderItem* item: folders.items.values())
    {
        catalog->_allFolders[item->id()] = item;

        if (!item->parent())
            catalog->_items.append(item);
    }

    MemosResult memos = CatalogStore::memoManager()->selectAll();
    if (!memos.error.isEmpty())
    {
        delete catalog;
        return CatalorResult::fail(memos.error);
    }

    if (!memos.warnings.isEmpty())
        for (auto warning: memos.warnings)
            qWarning() << warning; // TODO make protocol window

    for (int folderId: memos.items.keys())
    {
        if (folderId > 0)
        {
            if (!folders.items.contains(folderId))
            {
                qWarning() << tr("Some memos are stored in folder #%1 but that "
                                 "is not found in the directory.").arg(folderId);
                qDeleteAll(memos.items[folderId]);
                continue;
            }
            FolderItem *parent = folders.items[folderId];
            for (MemoItem* item: memos.items[folderId])
            {
                item->_parent = parent;
                parent->_children.append(item);
            }
        }
        else
            for (MemoItem* item: memos.items[folderId])
                catalog->_items.append(item);
    }

    catalog->_allMemos = memos.allMemos;

    return CatalorResult::ok(catalog);
}

CatalorResult Catalog::create(const QString& fileName)
{
    QString res = CatalogStore::newDatabase(fileName);
    if (!res.isEmpty())
        return CatalorResult::fail(res);

    Catalog* catalog = new Catalog;
    catalog->_fileName = fileName;

    return CatalorResult::ok(catalog);
}

Catalog::Catalog() : QObject()
{
}

Catalog::~Catalog()
{
    qDeleteAll(_items);

    CatalogStore::closeDatabase();
}

QString Catalog::renameFolder(FolderItem* item, const QString& title)
{
    QString res = CatalogStore::folderManager()->rename(item->id(), title);
    if (!res.isEmpty()) return res;

    item->_title = title;

    // TODO sort items after renaming
    return QString();
}

QString Catalog::createFolder(FolderItem* parent, const QString& title)
{
    FolderItem* folder = new FolderItem;
    folder->_title = title;
    folder->_parent = parent;

    auto res = CatalogStore::folderManager()->create(folder);
    if (!res.isEmpty())
    {
        delete folder;
        return res;
    }

    (parent ? parent->_children : _items).append(folder);
    _allFolders.insert(folder->id(), folder);
    // TODO sort items after inserting

    return QString();
}

QString Catalog::removeFolder(FolderItem* item)
{
    QString res = CatalogStore::folderManager()->remove(item);
    if (!res.isEmpty()) return res;

    (item->parent() ? item->parent()->asFolder()->_children : _items).removeOne(item);
    _allFolders.remove(item->id());

    delete item;
    return QString();
}

QString Catalog::createMemo(FolderItem* parent, Memo *memo)
{
    auto item = new MemoItem;
    item->_memo = memo;
    item->_parent = parent;
    item->_type = memo->type();
    item->_title = memo->title();
    item->_info = QString(); // TODO prepare memo info before saving

    auto res = CatalogStore::memoManager()->create(item);
    if (!res.isEmpty())
    {
        delete item;
        return res;
    }

    (parent ? parent->asFolder()->_children : _items).append(item);
    _allMemos.insert(item->id(), item);
    // TODO sort items after inserting

    return QString();
}

QString Catalog::updateMemo(MemoItem* item, Memo *memo)
{
    QString info; // TODO prepage memo info before saving
    QString res = CatalogStore::memoManager()->update(memo, info);
    if (!res.isEmpty())
    {
        delete memo;
        return res;
    }

    delete item->_memo;
    item->_memo = memo;
    item->_type = memo->type();
    item->_title = memo->title();
    item->_info = info;

    // TODO sort items after renaming
    return QString();
}

QString Catalog::loadMemo(MemoItem* item)
{
    Memo* memo = item->type()->makeMemo();
    memo->_id = item->_id;
    QString res = CatalogStore::memoManager()->load(memo);
    if (!res.isEmpty())
    {
        delete memo;
        return res;
    }
    item->_memo = memo;
    return QString();
}

QString Catalog::removeMemo(MemoItem* item)
{
    QString res = CatalogStore::memoManager()->remove(item);
    if (!res.isEmpty()) return res;

    (item->parent() ? item->parent()->asFolder()->_children : _items).removeOne(item);
    _allMemos.remove(item->id());

    delete item;
    return QString();
}

IntResult Catalog::countMemos() const
{
    int count;
    QString res = CatalogStore::memoManager()->countAll(&count);
    return res.isEmpty() ? IntResult::ok(count) : IntResult::fail(res);
}

namespace {

template <typename TItem>
TItem* findInContainerById(const QMap<int, TItem*>& container, int id)
{
    if (id <= 0)
    {
        qCritical() << "Invalid folder or memo id" << id;
        return nullptr;
    }
    if (!container.contains(id))
    {
        qCritical() << "Inconsistent state! Catalog does not contain folder or memo" << id;
        return nullptr;
    }
    return container[id];
}

} // namespace

MemoItem* Catalog::findMemoById(int id) const
{
    return findInContainerById(_allMemos, id);
}

FolderItem* Catalog::findFolderById(int id) const
{
    return findInContainerById(_allFolders, id);
}
