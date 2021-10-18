#include "PopupMessage.h"

#include <QApplication>
#include <QGraphicsDropShadowEffect>
#include <QHBoxLayout>
#include <QLabel>
#include <QPainter>
#include <QPaintEvent>
#include <QPropertyAnimation>
#include <QTimer>

void PopupMessage::showAffirm(const QString& text)
{
    (new PopupMessage(text, qApp->activeWindow()))->show();
}

namespace {

struct PopupMsgStyle
{
    int margin = 20;
    int borderRadius = 5;
    QPen borderColor = QColor("gray");
    QBrush affirmBackColor = QColor(181, 252, 181);
    int fadeAfterMs = 1000;
    int fadeDurationMs = 1000;
};

const PopupMsgStyle& msgStyle()
{
    static PopupMsgStyle style;
    return style;
}

} // namespace

PopupMessage::PopupMessage(const QString& text, QWidget *parent) : QWidget(parent)
{
    setAttribute(Qt::WA_DeleteOnClose);

    const auto& style = msgStyle();

    auto label = new QLabel(text);
    label->setAlignment(Qt::AlignHCenter);

    auto layout = new QHBoxLayout(this);
    layout->setContentsMargins(style.margin, style.margin, style.margin, style.margin);
    layout->addWidget(label);

    auto shadow = new QGraphicsDropShadowEffect;
    shadow->setBlurRadius(20);
    shadow->setOffset(2);
    setGraphicsEffect(shadow);

    adjustSize();
    auto sz = size();
    auto psz = parent->size();
    int x = (psz.width() - sz.width())/2;
    int y = (psz.height() - sz.height())/2;
    move(x, y);

    QTimer::singleShot(style.fadeAfterMs, this, [this, style](){
        auto opacity = new QGraphicsOpacityEffect();
        setGraphicsEffect(opacity);
        auto fadeout = new QPropertyAnimation(opacity, "opacity");
        fadeout->setDuration(style.fadeDurationMs);
        fadeout->setStartValue(1);
        fadeout->setEndValue(0);
        fadeout->setEasingCurve(QEasingCurve::OutBack);
        fadeout->start(QPropertyAnimation::DeleteWhenStopped);
        connect(fadeout, &QPropertyAnimation::finished, this, &PopupMessage::close);
    });
}

void PopupMessage::mouseReleaseEvent(QMouseEvent*)
{
    close();
}

void PopupMessage::paintEvent(QPaintEvent *event)
{
    const auto& style = msgStyle();
    QPainter p(this);
    p.setClipRect(event->rect());
    p.setPen(style.borderColor);
    p.setBrush(style.affirmBackColor);
    p.setRenderHint(QPainter::Antialiasing, true);
    p.drawRoundedRect(0, 0, width(), height(), style.borderRadius, style.borderRadius);
    QWidget::paintEvent(event);
}
