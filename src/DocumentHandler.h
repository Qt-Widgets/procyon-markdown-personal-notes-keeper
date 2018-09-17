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
    Q_PROPERTY(QQuickItem *target READ target WRITE setTarget NOTIFY dummyNotify)
    Q_PROPERTY(bool isMemoProcessing READ isMemoProcessing WRITE setMemoProcessing NOTIFY dummyNotify)
    Q_PROPERTY(bool isMemoModified READ isMemoModified WRITE setMemoModified NOTIFY dummyNotify)

public:
    explicit DocumentHandler(QObject *parent = nullptr);

    QQuickItem *target() const { return _target; }
    void setTarget(QQuickItem *target);
    bool isMemoProcessing() const { return _isMemoProcessing; }
    void setMemoProcessing(bool on) { _isMemoProcessing = on; }
    bool isMemoModified() const;
    void setMemoModified(bool on);

signals:
    void dummyNotify();
    void documentModified(bool changed);

public slots:
    void applyTextStyles(bool rehighlight = false);

private:
    QQuickItem *_target;
    QTextDocument *_doc;
    QSharedPointer<QSyntaxHighlighter> _highlighter;
    bool _isMemoProcessing = false;

    void processHyperlinks();
    void applyHighlighter(bool rehighlight);
};

#endif // DOCUMENTHANDLER_H
