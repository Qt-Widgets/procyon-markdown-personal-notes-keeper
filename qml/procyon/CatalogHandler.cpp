#include "CatalogHandler.h"

#include <QDebug>
#include <QFileInfo>
#include <QSettings>
#include <QTimer>

#include "../../src/Catalog.h"
#include "../../src/CatalogModel.h"
#include "../../src/CatalogStore.h"
#include "../../src/Memo.h"

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
    _memoWordWrap = s.value("wordWrap", false).toBool();
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
    s.setValue("wordWrap", _memoWordWrap);
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
    return _catalog->findById(memoId);
}

QString CatalogHandler::getMemoText(int memoId) const
{
    if (!_catalog) return QString();
    auto item = _catalog->findById(memoId);
    if (!item || !item->isMemo()) return QString();
    _catalog->loadMemo(item->asMemo());
    // TODO check errors
    return item->asMemo()->memo()->data();
}

QMap<QString, QVariant> CatalogHandler::getMemoInfo(int memoId)
{
    if (!_catalog) return {};
    auto item = _catalog->findById(memoId);
    if (!item || !item->isMemo()) return {};
    return {
        { "memoId", memoId },
        { "memoTitle", item->title() },
        { "memoPath", item->path() },
        { "memoIconPath", item->asMemo()->type()->iconPath() }
    };
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

void CatalogHandler::setMemoWordWrap(bool on)
{
    _memoWordWrap = on;
    emit memoWordWrapChanged();
}
