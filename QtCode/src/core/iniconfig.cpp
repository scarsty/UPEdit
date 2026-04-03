#include "iniconfig.h"
#include "encoding.h"
#include "rfile.h"
#include "mapdata.h"
#include <QSettings>
#include <QFile>
#include <QCoreApplication>
#include <QDir>

IniConfig &IniConfig::instance()
{
    static IniConfig cfg;
    return cfg;
}

void IniConfig::load(const QString &iniPath)
{
    startPath = QCoreApplication::applicationDirPath() + "/";

    // 检测 INI 编码
    QFile f(iniPath);
    if (!f.open(QIODevice::ReadOnly)) return;
    QByteArray header = f.read(2);
    f.close();

    bool isUtf16 = (header.size() >= 2 && static_cast<uint8_t>(header[0]) == 0xFF
                    && static_cast<uint8_t>(header[1]) == 0xFE);

    QSettings ini(iniPath, QSettings::IniFormat);
    if (!isUtf16)
        ini.setIniCodec("UTF-8");

    // [run] 节
    gamePath    = ini.value("run/gamepath", "").toString();
    dataCode    = ini.value("run/datacode", 1).toInt();
    talkCode    = ini.value("run/talkcode", 1).toInt();
    talkInvert  = ini.value("run/talkinvert", 0).toInt();
    language    = ini.value("run/language", 0).toInt();
    tileScale   = ini.value("run/TileScale", 1).toInt();
    checkUpdate = ini.value("run/checkupdate", 0).toInt();
    fmCursor    = ini.value("run/fmcursor", 1).toInt();
    gameVersion = ini.value("run/GameVersion", 0).toInt();

    // 应用编码设置
    Encoding::dataCode   = dataCode;
    Encoding::talkCode   = talkCode;
    Encoding::talkInvert = talkInvert;
    Encoding::language   = language;

    // [file] 节
    palette = ini.value("file/palette", "").toString();

    // 对话文件
    talkIdx = ini.value("file/talkidx", "").toString();
    talkGrp = ini.value("file/talkgrp", "").toString();

    // KDEF
    kdefIdx = ini.value("file/kdefidx", "").toString();
    kdefGrp = ini.value("file/kdefgrp", "").toString();
    nameIdx = ini.value("file/nameidx", "").toString();
    nameGrp = ini.value("file/namegrp", "").toString();

    // GRP 列表
    grpListNum = ini.value("file/grplistnum", 0).toInt();
    grpListIdx.resize(grpListNum);
    grpListGrp.resize(grpListNum);
    grpListName.resize(grpListNum);
    for (int i = 0; i < grpListNum; ++i) {
        grpListIdx[i]  = ini.value(QString("file/grplistidx%1").arg(i), "").toString();
        grpListGrp[i]  = ini.value(QString("file/grplistgrp%1").arg(i), "").toString();
        grpListName[i] = ini.value(QString("file/grplistname%1").arg(i), "").toString();
    }

    // 战斗
    fightIdx = ini.value("file/fightidx", "").toString();
    fightGrp = ini.value("file/fightgrp", "").toString();
    fightName = ini.value("file/fightname", "").toString();
    warData = ini.value("file/wardata", "").toString();
    headPicName = ini.value("file/headpicname", "").toString();
    warMapGrp = ini.value("file/warmapgrp", "").toString();
    warMapIdx = ini.value("file/warmapidx", "").toString();

    // 场景
    sceneNum = ini.value("file/scenenum", 0).toInt();
    sIdx.resize(sceneNum);
    sGrp.resize(sceneNum);
    dIdx.resize(sceneNum);
    dGrp.resize(sceneNum);
    for (int i = 0; i < sceneNum; ++i) {
        sIdx[i] = ini.value(QString("file/Sidx%1").arg(i), "").toString();
        sGrp[i] = ini.value(QString("file/Sgrp%1").arg(i), "").toString();
        dIdx[i] = ini.value(QString("file/Didx%1").arg(i), "").toString();
        dGrp[i] = ini.value(QString("file/Dgrp%1").arg(i), "").toString();
    }

    smapIdx = ini.value("file/Smapidx", "").toString();
    smapGrp = ini.value("file/Smapgrp", "").toString();
    smapImz = ini.value("file/Smapimz", "").toString();
    mmapImz = ini.value("file/Mmapimz", "").toString();
    wmapImz = ini.value("file/Wmapimz", "").toString();
    smapPNGPath = ini.value("file/SmapPNGpath", "").toString();
    mmapPNGPath = ini.value("file/MmapPNGpath", "").toString();
    wmapPNGPath = ini.value("file/WmapPNGpath", "").toString();

    // 主地图
    mmapFileGrp = ini.value("file/Mmapfilegrp", "").toString();
    mmapFileIdx = ini.value("file/Mmapfileidx", "").toString();
    mEarth    = ini.value("file/Mearth", "").toString();
    mSurface  = ini.value("file/Msurface", "").toString();
    mBuilding = ini.value("file/Mbuilding", "").toString();
    mBuildX   = ini.value("file/Mbuildx", "").toString();
    mBuildY   = ini.value("file/Mbuildy", "").toString();

    // R 文件
    rFileNum = ini.value("file/Rfilenum", 0).toInt();
    rFileName.resize(rFileNum);
    rFileNote.resize(rFileNum);
    rIdxFileName.resize(rFileNum);
    for (int i = 0; i < rFileNum; ++i) {
        rFileName[i]    = ini.value(QString("file/Rfilename%1").arg(i), "").toString();
        rFileNote[i]    = ini.value(QString("file/Rfilenote%1").arg(i), "").toString();
        rIdxFileName[i] = ini.value(QString("file/Ridxfilename%1").arg(i), "").toString();
    }

    // 读取 R 文件 INI 定义
    RFileIO::readIni(rGlobals, iniPath);

    // 其他
    leave  = ini.value("file/leave", "").toString();
    effect = ini.value("file/effect", "").toString();
    match  = ini.value("file/match", "").toString();
    exp_   = ini.value("file/exp", "").toString();
    usualTrans = ini.value("run/usualtrans", 0x707030).toUInt();
    listBeginNum = ini.value("run/list_begin_num", 0).toInt();
}
