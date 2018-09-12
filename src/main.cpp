#ifdef QT_WIDGETS_LIB
#include <QtWidgets/QApplication>
#else
#include <QtGui/QGuiApplication>
#endif
#include <QQmlApplicationEngine>
#include <QQmlFileSelector>
#include <QIcon>

#include "CatalogHandler.h"
#include "DocumentHandler.h"

int main(int argc, char *argv[])
{
    QCoreApplication::setApplicationName("Procyon");
    QCoreApplication::setOrganizationName("orion-project.org");
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);

#ifdef QT_WIDGETS_LIB
    QApplication app(argc, argv);
#else
    QGuiApplication app(argc, argv);
#endif
    //app.setWindowIcon(QIcon("qrc:/icon/main"));

    qmlRegisterType<CatalogHandler>("org.orion_project.procyon.catalog", 1, 0, "CatalogHandler");
    qmlRegisterType<DocumentHandler>("org.orion_project.procyon.document", 1, 0, "DocumentHandler");

    QStringList selectors;
#ifdef QT_EXTRA_FILE_SELECTOR
    selectors += QT_EXTRA_FILE_SELECTOR;
#else
    if (app.arguments().contains("-touch"))
        selectors += "touch";
#endif

    QQmlApplicationEngine engine;
    QQmlFileSelector::get(&engine)->setExtraSelectors(selectors);

    engine.load(QUrl("qrc:/src/MainWindow.qml"));
    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
