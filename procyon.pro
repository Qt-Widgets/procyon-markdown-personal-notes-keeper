TEMPLATE = app

QT += quick quickcontrols2 sql
!no_desktop: QT += widgets

CONFIG += c++11

# The following define makes your compiler emit warnings if you use
# any feature of Qt which as been marked deprecated (the exact warnings
# depend on your compiler). Please consult the documentation of the
# deprecated API in order to know how to port your code away from it.
DEFINES += QT_DEPRECATED_WARNINGS

cross_compile: DEFINES += QT_EXTRA_FILE_SELECTOR=\\\"touch\\\"

# You can also make your code fail to compile if you use deprecated APIs.
# In order to do so, uncomment the following line.
# You can also select to disable deprecated APIs only up to a certain version of Qt.
#DEFINES += QT_DISABLE_DEPRECATED_BEFORE=0x060000    # disables all the APIs deprecated before Qt 6.0.0

SOURCES += \
    src/main.cpp \
    src/CatalogHandler.cpp \
    src/DocumentHandler.cpp \
    src/catalog/Catalog.cpp \
    src/catalog/CatalogStore.cpp \
    src/catalog/SqlHelper.cpp \
    src/catalog/Memo.cpp \
    src/highlighter/HighlightingRule.cpp \
    src/highlighter/PythonSyntaxHighlighter.cpp \
    src/highlighter/ShellMemoSyntaxHighlighter.cpp

RESOURCES += resources.qrc

# Additional import path used to resolve QML modules in Qt Creator's code model
QML_IMPORT_PATH =

# Additional import path used to resolve QML modules just for Qt Quick Designer
QML_DESIGNER_IMPORT_PATH =

# Default rules for deployment.
qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: target.path = /opt/$${TARGET}/bin
!isEmpty(target.path): INSTALLS += target

DESTDIR = $$_PRO_FILE_PWD_/bin 

HEADERS += \
    src/CatalogHandler.h \
    src/DocumentHandler.h \
    src/CatalogModel.h \
    src/catalog/Catalog.h \
    src/catalog/CatalogStore.h \
    src/catalog/SqlHelper.h \
    src/catalog/Memo.h \
    src/highlighter/HighlightingRule.h \
    src/highlighter/PythonSyntaxHighlighter.h \
    src/highlighter/ShellMemoSyntaxHighlighter.h
