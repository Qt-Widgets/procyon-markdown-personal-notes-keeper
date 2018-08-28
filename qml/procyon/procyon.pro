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
        main.cpp \
    CatalogHandler.cpp \
    ../../src/Catalog.cpp \
    ../../src/CatalogStore.cpp \
    ../../src/SqlHelper.cpp \
    ../../src/Memo.cpp \
    DocumentHandler.cpp \
    ../../src/hl/HighlightingRule.cpp \
    ../../src/hl/PythonSyntaxHighlighter.cpp \
    ../../src/hl/ShellMemoSyntaxHighlighter.cpp

RESOURCES += qml.qrc

# Additional import path used to resolve QML modules in Qt Creator's code model
QML_IMPORT_PATH =

# Additional import path used to resolve QML modules just for Qt Quick Designer
QML_DESIGNER_IMPORT_PATH =

# Default rules for deployment.
qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: target.path = /opt/$${TARGET}/bin
!isEmpty(target.path): INSTALLS += target

HEADERS += \
    CatalogHandler.h \
    ../../src/Catalog.h \
    ../../src/CatalogStore.h \
    ../../src/SqlHelper.h \
    ../../src/CatalogModel.h \
    ../../src/Memo.h \
    DocumentHandler.h \
    ../../src/hl/HighlightingRule.h \
    ../../src/hl/PythonSyntaxHighlighter.h \
    ../../src/hl/ShellMemoSyntaxHighlighter.h
