INCLUDEPATH += $$PWD/hunspell/src

DEFINES += HUNSPELL_STATIC

HEADERS += \
    $$PWD/hunspell/src/hunspell/affentry.hxx \
    $$PWD/hunspell/src/hunspell/affixmgr.hxx \
    $$PWD/hunspell/src/hunspell/atypes.hxx \
    $$PWD/hunspell/src/hunspell/baseaffix.hxx \
    $$PWD/hunspell/src/hunspell/csutil.hxx \
    $$PWD/hunspell/src/hunspell/filemgr.hxx \
    $$PWD/hunspell/src/hunspell/hashmgr.hxx \
    $$PWD/hunspell/src/hunspell/htypes.hxx \
    $$PWD/hunspell/src/hunspell/hunspell.hxx \
    $$PWD/hunspell/src/hunspell/hunzip.hxx \
    $$PWD/hunspell/src/hunspell/langnum.hxx \
    $$PWD/hunspell/src/hunspell/phonet.hxx \
    $$PWD/hunspell/src/hunspell/replist.hxx \
    $$PWD/hunspell/src/hunspell/suggestmgr.hxx \
    $$PWD/hunspell/src/hunspell/utf_info.hxx \
    $$PWD/hunspell/src/hunspell/w_char.hxx

SOURCES += \
    $$PWD/hunspell/src/hunspell/affentry.cxx \
    $$PWD/hunspell/src/hunspell/affixmgr.cxx \
    $$PWD/hunspell/src/hunspell/csutil.cxx \
    $$PWD/hunspell/src/hunspell/filemgr.cxx \
    $$PWD/hunspell/src/hunspell/hashmgr.cxx \
    $$PWD/hunspell/src/hunspell/hunspell.cxx \
    $$PWD/hunspell/src/hunspell/hunzip.cxx \
    $$PWD/hunspell/src/hunspell/phonet.cxx \
    $$PWD/hunspell/src/hunspell/replist.cxx \
    $$PWD/hunspell/src/hunspell/suggestmgr.cxx
