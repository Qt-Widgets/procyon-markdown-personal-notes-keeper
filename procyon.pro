TEMPLATE = app
TEMPLATE = app
DESTDIR = $$_PRO_FILE_PWD_/bin

QT += quick quickcontrols2 sql
!no_desktop: QT += widgets

CONFIG += c++11

# The following define makes your compiler emit warnings if you use
# any feature of Qt which as been marked deprecated (the exact warnings
# depend on your compiler). Please consult the documentation of the
# deprecated API in order to know how to port your code away from it.
DEFINES += QT_DEPRECATED_WARNINGS

cross_compile: DEFINES += QT_EXTRA_FILE_SELECTOR=\\\"touch\\\"

#------------------------------------------------------------
# Version information

include(release/version.pri)
DEFINES += "APP_VER_MAJOR=$$APP_VER_MAJOR"
DEFINES += "APP_VER_MINOR=$$APP_VER_MINOR"
DEFINES += "APP_VER_PATCH=$$APP_VER_PATCH"
DEFINES += "APP_VER_CODENAME=\"\\\"$$APP_VER_CODENAME\\\"\""

win32 {
    DEFINES += "BUILDDATE=\"\\\"$$system(date /T)\\\"\""
    DEFINES += "BUILDTIME=\"\\\"$$system(time /T)\\\"\""
}
else {
    DEFINES += "BUILDDATE=\"\\\"$$system(date '+%F')\\\"\""
    DEFINES += "BUILDTIME=\"\\\"$$system(date '+%T')\\\"\""
}

#------------------------------------------------------------

RESOURCES += resources.qrc

win32: RC_FILE = src/app.rc

#------------------------------------------------------------

# Additional import path used to resolve QML modules in Qt Creator's code model
QML_IMPORT_PATH =

# Additional import path used to resolve QML modules just for Qt Quick Designer
QML_DESIGNER_IMPORT_PATH =

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
