cmake_minimum_required(VERSION 3.16)

project(UPEdit VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Widgets Network)

# ── 核心数据模块 ──────────────────────────────────────────
set(CORE_SOURCES
    src/core/head.h
    src/core/head.cpp
    src/core/encoding.h
    src/core/encoding.cpp
    src/core/fileio.h
    src/core/fileio.cpp
    src/core/rfile.h
    src/core/rfile.cpp
    src/core/mapdata.h
    src/core/mapdata.cpp
    src/core/eventdata.h
    src/core/eventdata.cpp
    src/core/imzdata.h
    src/core/imzdata.cpp
    src/core/grpdata.h
    src/core/grpdata.cpp
    src/core/iniconfig.h
    src/core/iniconfig.cpp
)

# ── 外部库封装 ──────────────────────────────────────────
set(LIB_SOURCES
    src/libs/luawrapper.h
    src/libs/luawrapper.cpp
    src/libs/sqlite3wrapper.h
    src/libs/sqlite3wrapper.cpp
    src/libs/zipwrapper.h
    src/libs/zipwrapper.cpp
    src/libs/xlsxiowrapper.h
    src/libs/xlsxiowrapper.cpp
)

# ── UI 模块 ──────────────────────────────────────────────
set(UI_SOURCES
    src/ui/mainwindow.h
    src/ui/mainwindow.cpp
    src/ui/aboutdialog.h
    src/ui/aboutdialog.cpp
    src/ui/redit.h
    src/ui/redit.cpp
    src/ui/reditform.h
    src/ui/reditform.cpp
    src/ui/grpedit.h
    src/ui/grpedit.cpp
    src/ui/grplist.h
    src/ui/grplist.cpp
    src/ui/picedit.h
    src/ui/picedit.cpp
    src/ui/waredit.h
    src/ui/waredit.cpp
    src/ui/warmapedit.h
    src/ui/warmapedit.cpp
    src/ui/scenemapedit.h
    src/ui/scenemapedit.cpp
    src/ui/mainmapedit.h
    src/ui/mainmapedit.cpp
    src/ui/kdefedit.h
    src/ui/kdefedit.cpp
    src/ui/imagezform.h
    src/ui/imagezform.cpp
    src/ui/pngimport.h
    src/ui/pngimport.cpp
    src/ui/cyhead.h
    src/ui/cyhead.cpp
    src/ui/txtleadin.h
    src/ui/txtleadin.cpp
    src/ui/setlanguage.h
    src/ui/setlanguage.cpp
    src/ui/replicatedlist.h
    src/ui/replicatedlist.cpp
    src/ui/filerelation.h
    src/ui/filerelation.cpp
    src/ui/updatedialog.h
    src/ui/updatedialog.cpp
    src/ui/splashscreen.h
    src/ui/splashscreen.cpp
    src/ui/takein.h
    src/ui/takein.cpp
    src/ui/fightframeform.h
    src/ui/fightframeform.cpp
    src/ui/outputmap.h
    src/ui/outputmap.cpp
)

set(RESOURCES
    resources/resources.qrc
)

add_executable(UPEdit
    main.cpp
    ${CORE_SOURCES}
    ${LIB_SOURCES}
    ${UI_SOURCES}
    ${RESOURCES}
)

target_include_directories(UPEdit PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    ${CMAKE_CURRENT_SOURCE_DIR}/src/core
    ${CMAKE_CURRENT_SOURCE_DIR}/src/libs
    ${CMAKE_CURRENT_SOURCE_DIR}/src/ui
)

target_link_libraries(UPEdit PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Widgets
    Qt6::Network
)

# 外部库 (运行时动态加载，无需链接期依赖)
# sqlite3.dll, lua5.1.dll, zip.dll, libxlsxio_read.dll, xlsxwriter.dll
# 放在可执行文件同目录即可

if(WIN32)
    set_target_properties(UPEdit PROPERTIES WIN32_EXECUTABLE TRUE)
endif()
