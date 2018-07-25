#ifndef CATALOGMODEL_H
#define CATALOGMODEL_H

#include <QAbstractItemModel>
#include <QDebug>

#include "Catalog.h"

class CatalogModel : public QAbstractItemModel
{
public:
    CatalogModel(Catalog* catalog) : _catalog(catalog)
    {
    }

    enum CatalogModelRoles { ID_ROLE = Qt::UserRole + 1, DISPLAY_ROLE };

    QHash<int, QByteArray> roleNames() const override
    {
        return {
            { ID_ROLE, QByteArrayLiteral("id") },
            { DISPLAY_ROLE, QByteArrayLiteral("display") }
        };
    }

    static CatalogItem* catalogItem(const QModelIndex &index)
    {
        return static_cast<CatalogItem*>(index.internalPointer());
    }

    QModelIndex findIndex(CatalogItem* item, const QModelIndex &parent = QModelIndex())
    {
        int rows = rowCount(parent);
        for (int row = 0; row < rows; row++)
        {
            auto currentIndex = index(row, 0, parent);
            auto currentItem = catalogItem(currentIndex);
            if (currentItem == item) return currentIndex;

            auto targetIndex = findIndex(item, currentIndex);
            if (targetIndex.isValid()) return targetIndex;
        }
        return QModelIndex();
    }

    QModelIndex index(int row, int column, const QModelIndex &parent) const override
    {
        if (!parent.isValid())
        {
            if (row < _catalog->items().size())
                return createIndex(row, column, _catalog->items().at(row));
            return QModelIndex();
        }

        auto parentItem = catalogItem(parent);
        if (!parentItem) return QModelIndex();

        auto parentFolder = parentItem->asFolder();
        if (!parentFolder) return QModelIndex();

        if (row < parentFolder->children().size())
            return createIndex(row, column, parentFolder->children().at(row));

        return QModelIndex();
    }

    QModelIndex parent(const QModelIndex &child) const override
    {
        if (!child.isValid()) return QModelIndex();

        auto childItem = catalogItem(child);
        if (!childItem) return QModelIndex();

        auto parentItem = childItem->parent();
        if (!parentItem) return QModelIndex();

        int row = parentItem->parent()
                ? parentItem->parent()->asFolder()->children().indexOf(parentItem)
                : _catalog->items().indexOf(parentItem);

        return createIndex(row, 0, parentItem);
    }

    int rowCount(const QModelIndex &parent) const override
    {
        if (!parent.isValid())
            return _catalog->items().size();

        auto item = catalogItem(parent);
        return item && item->isFolder() ? item->asFolder()->children().size() : 0;
    }

    int columnCount(const QModelIndex &parent) const override
    {
        Q_UNUSED(parent)
        return 1;
    }

    QVariant data(const QModelIndex &index, int role) const override
    {
        if (!index.isValid())
            return QVariant();

        auto item = catalogItem(index);
        if (!item) return QVariant();

        auto memo = item->asMemo();

        switch (role)
        {
        case ID_ROLE:
            return item->id();

        case DISPLAY_ROLE:
            return QVariantMap({
                { QStringLiteral("memoTitle"), item->title() },
                { QStringLiteral("isFolder"), memo == nullptr },
                { QStringLiteral("memoIconPath"), (memo && memo->type()) ? memo->type()->iconPath() : QString() }
            });
        }

        return QVariant();
    }

    void itemRenamed(const QModelIndex &index)
    {
        emit dataChanged(index, index);
    }

    QModelIndex itemAdded(const QModelIndex &parent)
    {
        int row = rowCount(parent) - 1;
        beginInsertRows(parent, row, row);
        endInsertRows();
        return index(row, 0, parent);
    }

    friend class ItemRemoverGuard;
private:
    Catalog* _catalog;
};


class ItemRemoverGuard
{
public:
    ItemRemoverGuard(CatalogModel* model, const QModelIndex &removingIndex) : _model(model)
    {
        parentIndex = _model->parent(removingIndex);
        _model->beginRemoveRows(parentIndex, removingIndex.row(), removingIndex.row());
    }

    ~ItemRemoverGuard()
    {
        _model->endRemoveRows();
    }

    QModelIndex parentIndex;

private:
    CatalogModel* _model;
};

#endif // CATALOGMODEL_H
