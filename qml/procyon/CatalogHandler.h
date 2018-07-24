#ifndef CATALOGHANDLER_H
#define CATALOGHANDLER_H

#include <QAbstractItemModel>
#include <QObject>
#include <QUrl>

class Catalog;
class CatalogModel;

class CatalogHandler : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isOpened READ isOpened NOTIFY isOpenedChanged)
    Q_PROPERTY(QString filePath READ filePath NOTIFY fileNameChanged)
    Q_PROPERTY(QString fileName READ fileName NOTIFY fileNameChanged)
    Q_PROPERTY(QString memoCount READ memoCount NOTIFY memoCountChanged)
    Q_PROPERTY(QAbstractItemModel* model READ catalogModel NOTIFY catalogModelChanged)
    Q_PROPERTY(const QStringList& recentFilesModel READ recentFiles NOTIFY recentFilesChanged)
    // TODO: can't read recentFilesModel.count or recentFilesModel.empty in qml, so use this property
    Q_PROPERTY(bool hasRecentFiles READ hasRecentFiles NOTIFY recentFilesChanged)

public:
    explicit CatalogHandler(QObject *parent = nullptr);
    ~CatalogHandler();

    bool isOpened() const { return _catalog; }
    QString filePath() const;
    QString fileName() const;
    QString memoCount() const;
    QAbstractItemModel* catalogModel() const;
    const QStringList& recentFiles() const { return _recentFiles; }
    bool hasRecentFiles() const { return !_recentFiles.empty(); }

signals:
    void error(const QString &message) const;
    void info(const QString &message) const;
    void fileNameChanged() const;
    void memoCountChanged() const;
    void catalogModelChanged() const;
    void recentFilesChanged() const;
    void isOpenedChanged() const;

public slots:
    void loadSettings();
    void saveSettings();
    void loadCatalog(const QUrl &fileUrl);
    bool closeCatalog();
    void deleteInvalidMruItems();
    void deleteAllMruItems();

private:
    Catalog *_catalog = nullptr;
    CatalogModel *_catalogModel = nullptr;
    QStringList _recentFiles;

    void catalogOpened(Catalog *catalog);
    void addToRecent(const QString &fileName);
};

#endif // CATALOGHANDLER_H
