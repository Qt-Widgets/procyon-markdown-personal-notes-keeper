#include "CatalogHandler.h"

#include <QDebug>
#include <QFileInfo>
#include <QSettings>
#include <QTimer>

#include "catalog/Catalog.h"
#include "catalog/CatalogStore.h"
#include "catalog/Memo.h"
#include "CatalogModel.h"

// We may not translate some messages as they point to an inconsistent
// program state and they are not a message to a user but a reason to debug
#define NO_TRANSLATE QString

namespace {
const int MAX_MRU_FILES_COUNT = 24;
QString DEFAULT_EXT = ".enot";
}

CatalogHandler::CatalogHandler(QObject *parent) : QObject(parent)
{
}

CatalogHandler::~CatalogHandler()
{
    closeCatalog();
}

void CatalogHandler::loadSettings()
{
    QSettings s;
    s.beginGroup("MRU");
    for (const auto& key: s.allKeys())
        _recentFiles.append(s.value(key).toString());
    s.endGroup();
    emit recentFilesChanged();

    s.beginGroup("State");
    _recentFile = s.value("catalogFile").toString();
    s.endGroup();

    s.beginGroup("View");
    _memoFont = qvariant_cast<QFont>(s.value("memoFont", QFont("Arial", 12)));
    s.endGroup();
}

void CatalogHandler::saveSettings()
{
    QSettings s;
    s.beginGroup("MRU");
    for (const auto& key: s.allKeys())
        s.remove(key);
    for (int i = 0; i < _recentFiles.size(); i++)
        s.setValue(QString::number(i), _recentFiles.at(i));
    s.endGroup();

    s.beginGroup("State");
    s.setValue("catalogFile", _catalog ? _catalog->fileName() : QString());
    s.endGroup();

    s.beginGroup("View");
    s.setValue("memoFont", _memoFont);
    s.endGroup();
}

bool CatalogHandler::sameFile(const QString &fileName) const
{
    if (!_catalog) return false;

    // Check if we try to open the same file as already opened
    auto curPath = QFileInfo(_catalog->fileName()).canonicalFilePath();
    auto newPath = QFileInfo(fileName).canonicalFilePath();
    return curPath == newPath;
}

bool CatalogHandler::sameUrl(const QUrl &fileUrl) const
{
    if (!_catalog) return false;

    return sameFile(fileUrl.toString());
}

QString CatalogHandler::urlToFileName(const QUrl &fileUrl) const
{
#ifdef Q_OS_WIN
    auto fileName = fileUrl.toString();
    // Qt 5.10, 5.11.1: an url returned by FileDialog has format "file:///C:/dir/..."
    // `fileUrl.path()` strips only "file://" but leaves the slash there ("/C:/dir...")
    if (fileName.startsWith('/'))
        fileName = fileName.remove(0, 1);
    return fileName;
#else
    return fileUrl.path();
#endif
}

void CatalogHandler::newCatalog(const QUrl &fileUrl)
{
    qInfo() << "Creating catalog" << fileUrl;

    auto fileName = urlToFileName(fileUrl);
    if (fileName.isEmpty())
    {
        qWarning() << "Filename is not set" << fileUrl;
        return;
    }

    // TODO: FileDialog.defaultSuffix doesn't work even in Qt 5.10 despite of it was introduced there
    auto res = Catalog::create(fileName.endsWith(DEFAULT_EXT) ? fileName : fileName + DEFAULT_EXT);
    if (res.ok())
        catalogOpened(res.result());
    else
        emit error(tr("Unable to create catalog.\n\n%1").arg(res.error()));
}

void CatalogHandler::loadCatalogUrl(const QUrl &fileUrl)
{
    qInfo() << "Loading catalog from url" << fileUrl;

    auto fileName = urlToFileName(fileUrl);
    if (fileName.isEmpty())
    {
        qWarning() << "Filename is not set" << fileUrl;
        return;
    }

    loadCatalogFile(fileName);
}

void CatalogHandler::loadCatalogFile(const QString &fileName)
{
    qInfo() << "Loading catalog from file" << fileName;

    if (fileName.isEmpty())
    {
        qWarning() << "Filename is not set";
        return;
    }

    if (!QFile::exists(fileName))
    {
        emit error(tr("File does not exist: %1").arg(fileName));
        return;
    }

    auto res = Catalog::open(fileName);
    if (res.ok())
        catalogOpened(res.result());
    else
        emit error(tr("Unable to load catalog.\n\n%1").arg(res.error()));
}

void CatalogHandler::closeCatalog()
{
    if (!_catalog)
        return;

    if (_catalogModel)
    {
        delete _catalogModel;
        _catalogModel = nullptr;
    }
    if (_catalog)
    {
        delete _catalog;
        _catalog = nullptr;
    }
    emit fileNameChanged();
    emit memoCountChanged();
    emit catalogModelChanged();
    emit isOpenedChanged();
    qInfo() << "Catalog closed";
}

QString CatalogHandler::filePath() const
{
    return _catalog ? _catalog->fileName() : QString();
}

QString CatalogHandler::fileName() const
{
    return _catalog ? QFileInfo(_catalog->fileName()).baseName() : QString();
}

QString CatalogHandler::memoCount() const
{
    if (!_catalog)
        return QString();
    auto res = _catalog->countMemos();
    if (res.ok())
        return QString::number(res.result());
    else
    {
        emit error(tr("Error while counting memos.\n\n%1").arg(res.error()));
        return tr("ERROR");
    }
}

QAbstractItemModel* CatalogHandler::catalogModel() const
{
    return _catalogModel;
}

void CatalogHandler::catalogOpened(Catalog *catalog)
{
    qInfo() << "Catalog opened" << catalog->fileName();

    _catalog = catalog;
    _catalogModel = new CatalogModel(catalog);

    addToRecent(catalog->fileName());

    emit fileNameChanged();
    emit memoCountChanged();
    emit catalogModelChanged();
    emit isOpenedChanged();
}

void CatalogHandler::addToRecent(const QString &fileName)
{
    if (_recentFiles.contains(fileName))
        _recentFiles.removeAll(fileName);
    _recentFiles.insert(0, fileName);
    while (_recentFiles.count() > MAX_MRU_FILES_COUNT)
        _recentFiles.removeLast();
    emit recentFilesChanged();
}

void CatalogHandler::deleteInvalidMruItems()
{
    QStringList recentFiles;
    for (const auto& fileName : _recentFiles)
        if (QFileInfo(fileName).exists())
            recentFiles.append(fileName);
    int removedCount = _recentFiles.count() - recentFiles.count();
    if (removedCount > 0)
    {
        _recentFiles = recentFiles;
        emit info(tr("Invalid paths deleted: %1").arg(removedCount));
        emit recentFilesChanged();
    }
    else
        emit info(tr("All paths are valid"));
}

void CatalogHandler::deleteAllMruItems()
{
    _recentFiles.clear();
    emit recentFilesChanged();
}

bool CatalogHandler::isValidId(int memoId) const
{
    if (!_catalog) return false;
    return _catalog->findMemoById(memoId);
}

QMap<QString, QVariant> CatalogHandler::getMemoInfo(int memoId)
{
    if (!_catalog) return {};
    auto item = _catalog->findMemoById(memoId);
    if (!item) return {};
    return {
        { "memoId", memoId },
        { "memoTitle", item->title() },
        { "memoPath", item->path() },
        { "memoIconPath", item->asMemo()->type()->iconPath() }
    };
}

QString CatalogHandler::getMemoText(int memoId) const
{
    if (!_catalog) return QString();
    auto memoItem = _catalog->findMemoById(memoId);
    if (!memoItem)
        return NO_TRANSLATE("ERROR: Memo id=%1 is not found in the catalog").arg(memoId);
    if (!memoItem->memo())
    {
        auto res = _catalog->loadMemo(memoItem);
        if (!res.isEmpty())
        {
            emit error(tr("Failed to load memo %1: %2").arg(memoId).arg(res));
            return QString();
        }
    }
    return memoItem->memo()->data();
}

QString CatalogHandler::saveMemo(const QMap<QString, QVariant>& data)
{
    if (!_catalog) return QString();

    int memoId = data["memoId"].toInt();
    auto memoItem = _catalog->findMemoById(memoId);
    if (!memoItem)
        return NO_TRANSLATE("Memo id=%1 is not found in the catalog").arg(memoId);
    if (!memoItem->memo())
        return NO_TRANSLATE("Unable to save memo %1: memo must be loaded before saving but it is not").arg(memoId);

    auto memo = memoItem->type()->makeMemo();
    // TODO preserve additional non editable data - dates, etc.
    memo->setId(memoItem->memo()->id());
    memo->setTitle(data["memoTitle"].toString());
    memo->setData(data["memoText"].toString());

    auto res = _catalog->updateMemo(memoItem, memo);
    if (!res.isEmpty()) return res;

    _catalogModel->itemRenamed(_catalogModel->findIndex(memoItem));
    emit memoChanged(data);

    qInfo() << "Memo" << memoId << "saved";
    return QString();
}

void CatalogHandler::createMemo(int folderId)
{
    if (!_catalog) return;
    auto parentItem = _catalog->findFolderById(folderId);
    if (!parentItem) return;

    // TODO: select memo type
    auto memo = plainTextMemoType()->makeMemo();
    auto res = _catalog->createMemo(parentItem, memo);
    if (!res.ok()) return error(res.error());

    QModelIndex parentIndex = _catalogModel->findIndex(parentItem);
    _catalogModel->itemAdded(parentIndex);

    MemoItem* newItem = res.result();
    QModelIndex newIndex = _catalogModel->findIndex(newItem, parentIndex);

    emit needExpandIndex(parentIndex);
    emit needSelectIndex(newIndex);
    emit memoCountChanged();
    emit memoCreated(res.result()->id());

    qInfo() << "New memo created in" << folderId << ":" << newItem->id();
}

void CatalogHandler::deleteMemo(int memoId)
{
    if (!_catalog) return;
    auto memoItem = _catalog->findMemoById(memoId);
    if (!memoItem) return;

    ItemRemoverGuard guard(_catalogModel, _catalogModel->findIndex(memoItem));

    auto res = _catalog->removeMemo(memoItem);
    if (!res.isEmpty()) return error(res);

    emit memoCountChanged();
    emit memoDeleted(memoId);

    qInfo() << "Memo deleted" << memoId;
}

QMap<QString, QVariant> CatalogHandler::getFolderInfo(int folderId)
{
    if (!_catalog) return {};
    auto item = _catalog->findFolderById(folderId);
    if (!item) return {};
    return {
        { "folderId", folderId },
        { "folderTitle", item->title() },
        { "folderPath", item->path() },
    };
}

QString CatalogHandler::renameFolder(int folderId, const QString& newTitle)
{
    if (!_catalog) return QString();
    auto item = _catalog->findFolderById(folderId);
    if (!item) return QString();

    auto res = _catalog->renameFolder(item, newTitle);
    if (!res.isEmpty()) return res;

    _catalogModel->itemRenamed(_catalogModel->findIndex(item));
    emit folderRenamed(folderId);

    qInfo() << "Folder" << folderId << "renamed";
    return QString();
}

QString CatalogHandler::createFolder(int parentFolderId, const QString& title)
{
    if (!_catalog) return QString();

    auto parentItem = _catalog->findFolderById(parentFolderId);
    auto res = _catalog->createFolder(parentItem, title);
    if (!res.ok()) return res.error();

    // TODO: merge (_catalogModel->itemAdded) and (emit itemCreated) into single method and signal raised by CatalogModel
    QModelIndex parentIndex = parentItem ? _catalogModel->findIndex(parentItem) : QModelIndex();
    _catalogModel->itemAdded(parentIndex);

    FolderItem* newItem = res.result();
    QModelIndex newIndex = _catalogModel->findIndex(newItem, parentIndex);

    emit needExpandIndex(parentIndex);
    emit needSelectIndex(newIndex);

    qInfo() << "New folder created in" << parentFolderId << ":" << newItem->id();
    return QString();
}

void CatalogHandler::deleteFolder(int folderId)
{
    if (!_catalog) return;

    auto folderItem = _catalog->findFolderById(folderId);
    if (!folderItem) return;

    QVector<int> deletedMemoIds;
    _catalog->fillMemoIdsFlat(folderItem, deletedMemoIds);

    ItemRemoverGuard guard(_catalogModel, _catalogModel->findIndex(folderItem));

    auto res = _catalog->removeFolder(folderItem);
    if (!res.isEmpty()) return error(res);

    for (auto id : deletedMemoIds)
        emit memoDeleted(id);
    emit memoCountChanged();
    emit needSelectIndex(guard.parentIndex);

    qInfo() << "Folder deleted" << folderId;
}

QMap<QString, QVariant> CatalogHandler::getStoredSession()
{
    return {
        { "openedMemos", CatalogStore::settingsManager()->readValue("openedMemos", "") },
        { "activeMemo", CatalogStore::settingsManager()->readValue("activeMemo", 0) },
        { "expandedFolders", CatalogStore::settingsManager()->readValue("expandedFolders", "") }
    };
}

void CatalogHandler::storeSession(const QMap<QString, QVariant>& session)
{
    for (const auto& key : session.keys())
        CatalogStore::settingsManager()->writeValue(key, session[key]);
}

void CatalogHandler::setMemoFont(const QFont& font)
{
    _memoFont = font;
    emit memoFontChanged();
}
