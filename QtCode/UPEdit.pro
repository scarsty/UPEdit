QT       += core gui widgets network

TARGET   = UPEdit
TEMPLATE = app

CONFIG  += c++17
CONFIG  -= app_bundle

win32 {
    CONFIG += windows
    LIBS += -lshell32
}

INCLUDEPATH += \
    src \
    src/core \
    src/libs \
    src/ui

# ── 核心数据模块 ──────────────────────────────────────────

HEADERS += \
    src/core/head.h \
    src/core/encoding.h \
    src/core/fileio.h \
    src/core/rfile.h \
    src/core/mapdata.h \
    src/core/eventdata.h \
    src/core/imzdata.h \
    src/core/grpdata.h \
    src/core/iniconfig.h

SOURCES += \
    src/core/head.cpp \
    src/core/encoding.cpp \
    src/core/fileio.cpp \
    src/core/rfile.cpp \
    src/core/mapdata.cpp \
    src/core/eventdata.cpp \
    src/core/imzdata.cpp \
    src/core/grpdata.cpp \
    src/core/iniconfig.cpp

# ── 外部库封装 ──────────────────────────────────────────

HEADERS += \
    src/libs/luawrapper.h \
    src/libs/sqlite3wrapper.h \
    src/libs/ZipFile.h \
    src/libs/xlsxiowrapper.h \
    src/libs/PotConv.h

SOURCES += \
    src/libs/luawrapper.cpp \
    src/libs/sqlite3wrapper.cpp \
    src/libs/ZipFile.cpp \
    src/libs/xlsxiowrapper.cpp \
    src/libs/PotConv.cpp

# vcpkg x64-windows (libiconv + libzip)
INCLUDEPATH += D:/project/vcpkg/installed/x64-windows/include
LIBS += -LD:/project/vcpkg/installed/x64-windows/lib -liconv -lzip -lzlib -lbz2

# ── UI 模块 ──────────────────────────────────────────────

HEADERS += \
    src/ui/mainwindow.h \
    src/ui/aboutdialog.h \
    src/ui/redit.h \
    src/ui/reditform.h \
    src/ui/grpedit.h \
    src/ui/grplist.h \
    src/ui/picedit.h \
    src/ui/waredit.h \
    src/ui/warmapedit.h \
    src/ui/scenemapedit.h \
    src/ui/mainmapedit.h \
    src/ui/kdefedit.h \
    src/ui/imagezform.h \
    src/ui/pngimport.h \
    src/ui/cyhead.h \
    src/ui/txtleadin.h \
    src/ui/setlanguage.h \
    src/ui/replicatedlist.h \
    src/ui/filerelation.h \
    src/ui/updatedialog.h \
    src/ui/splashscreen.h \
    src/ui/takein.h \
    src/ui/fightframeform.h \
    src/ui/outputmap.h

SOURCES += \
    main.cpp \
    src/ui/mainwindow.cpp \
    src/ui/aboutdialog.cpp \
    src/ui/redit.cpp \
    src/ui/reditform.cpp \
    src/ui/grpedit.cpp \
    src/ui/grplist.cpp \
    src/ui/picedit.cpp \
    src/ui/waredit.cpp \
    src/ui/warmapedit.cpp \
    src/ui/scenemapedit.cpp \
    src/ui/mainmapedit.cpp \
    src/ui/kdefedit.cpp \
    src/ui/imagezform.cpp \
    src/ui/pngimport.cpp \
    src/ui/cyhead.cpp \
    src/ui/txtleadin.cpp \
    src/ui/setlanguage.cpp \
    src/ui/replicatedlist.cpp \
    src/ui/filerelation.cpp \
    src/ui/updatedialog.cpp \
    src/ui/splashscreen.cpp \
    src/ui/takein.cpp \
    src/ui/fightframeform.cpp \
    src/ui/outputmap.cpp

RESOURCES += \
    resources/resources.qrc

# 外部库 (运行时动态加载，无需链接期依赖)
# sqlite3.dll, lua5.1.dll, zip.dll, libxlsxio_read.dll, xlsxwriter.dll
# 放在可执行文件同目录即可
