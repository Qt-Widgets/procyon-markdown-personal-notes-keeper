#include "DocumentHandler.h"
#include "../../src/hl/PythonSyntaxHighlighter.h"
#include "../../src/hl/ShellMemoSyntaxHighlighter.h"

#include <QDebug>
#include <QQuickTextDocument>
#include <QTextCursor>

DocumentHandler::DocumentHandler(QObject *parent) : QObject(parent)
{
}

void DocumentHandler::setTarget(QQuickItem *target)
{
    _doc = nullptr;
    _target = target;
    if (!_target) return;

    QVariant doc = _target->property("textDocument");
    if (doc.canConvert<QQuickTextDocument*>())
    {
        auto qqdoc = doc.value<QQuickTextDocument*>();
        if (qqdoc)
            _doc = qqdoc->textDocument();
    }
    emit targetChanged();
}

void DocumentHandler::applyTextStyles()
{
    if (!_doc) return;
    _doc->setUndoRedoEnabled(false);
    processHyperlinks();
    // Should be applied after hyperlinks to get correct finish style.
    applyHighlighter();
    _doc->setUndoRedoEnabled(true);
    _doc->setModified(false);
}

void DocumentHandler::processHyperlinks()
{
    static QList<QRegExp> rex;
    if (rex.isEmpty())
    {
        rex.append(QRegExp("\\bhttp(s?)://[^\\s]+\\b", Qt::CaseInsensitive));
    }
    for (const QRegExp& re : rex)
    {
        QTextCursor cursor = _doc->find(re);
        while (!cursor.isNull())
        {
            QString href = cursor.selectedText();
            QTextCharFormat f;
            f.setAnchor(true);
            f.setAnchorHref(href);
            f.setForeground(Qt::blue);
            f.setFontUnderline(true);
            cursor.mergeCharFormat(f);
            cursor = _doc->find(re, cursor);
        }
    }
}

void DocumentHandler::applyHighlighter()
{
    auto text = _doc->toPlainText();

    // TODO preserve highlighter if its type is not changed
    // TODO highlighter should be selected bu user and saved into catalog
    if (text.startsWith("#!/usr/bin/env python"))
        _highlighter.reset(new PythonSyntaxHighlighter(_doc));
    else if (text.startsWith("#shell-memo"))
        _highlighter.reset(new ShellMemoSyntaxHighlighter(_doc));
    else
        _highlighter.reset();
}
