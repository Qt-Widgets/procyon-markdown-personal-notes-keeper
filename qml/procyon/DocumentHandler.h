#ifndef DOCUMENTHANDLER_H
#define DOCUMENTHANDLER_H

#include <QObject>
#include <QSharedPointer>

QT_BEGIN_NAMESPACE
class QQuickItem;
class QTextDocument;
class QSyntaxHighlighter;
QT_END_NAMESPACE

class DocumentHandler : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QQuickItem *target READ target WRITE setTarget NOTIFY targetChanged)

public:
    explicit DocumentHandler(QObject *parent = nullptr);

    QQuickItem *target() const { return _target; }
    void setTarget(QQuickItem *target);

signals:
    void targetChanged();

public slots:
    void applyTextStyles();

private:
    QQuickItem *_target;
    QTextDocument *_doc;
    QSharedPointer<QSyntaxHighlighter> _highlighter;

    void processHyperlinks();
    void applyHighlighter();
};

#endif // DOCUMENTHANDLER_H
