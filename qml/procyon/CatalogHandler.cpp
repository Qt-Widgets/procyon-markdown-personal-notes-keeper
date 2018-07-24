#include "CatalogHandler.h"

#include <QDebug>
#include <QFileInfo>
#include <QSettings>
#include <QTimer>

#include "../../src/Catalog.h"
#include "../../src/CatalogModel.h"

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
    auto lastFile = s.value("catalogFile").toString();
    if (!lastFile.isEmpty())
        QTimer::singleShot(0, [&, lastFile]{ loadCatalog(lastFile); });
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
}

void CatalogHandler::newCatalog(const QUrl &fileUrl)
{
    auto fileName = fileUrl.path();
    if (fileName.isEmpty())
    {
        qWarning() << "Filename is not set" << fileUrl;
        return;
    }

    if (!closeCatalog()) return;

    // TODO: FileDialog.defaultSuffix doesn't work even in Qt 5.10 despite of it was introduced there
    auto res = Catalog::create(fileName.endsWith(DEFAULT_EXT) ? fileName : fileName + DEFAULT_EXT);
    if (res.ok())
        catalogOpened(res.result());
    else
        emit error(tr("Unable to create catalog.\n\n%1").arg(res.error()));
}

void CatalogHandler::loadCatalog(const QUrl &fileUrl)
{
    auto fileName = fileUrl.path();

    if (fileName.isEmpty())
    {
        qWarning() << "Filename is not set" << fileUrl;
        return;
    }

    if (!QFile::exists(fileName))
    {
        emit error(tr("File does not exist: %1").arg(fileName));
        return;
    }

    if (_catalog)
    {
        // Check if we try to open the same file as already opened
        auto curPath = QFileInfo(_catalog->fileName()).canonicalFilePath();
        auto newPath = QFileInfo(fileName).canonicalFilePath();
        if (curPath == newPath) return;
    }

    if (!closeCatalog()) return;

    auto res = Catalog::open(fileName);
    if (res.ok())
        catalogOpened(res.result());
    else
        emit error(tr("Unable to load catalog.\n\n%1").arg(res.error()));
}

bool CatalogHandler::closeCatalog()
{
    if (!_catalog)
        return true;

    // TODO check if some opened memos were changed
    // TODO save catalog session

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
    return true;
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

    // TODO restore catalog session

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
