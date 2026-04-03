#pragma once

/*
 * INI 配置管理 (全局状态)
 * 对应原 Delphi 版全局变量和 AppInitial 过程
 */

#include "head.h"
#include "rfile.h"
#include <QString>
#include <QVector>

class IniConfig {
public:
    static IniConfig &instance();

    // 从 INI 文件加载配置
    void load(const QString &iniPath);

    // ── 路径与基本设置 ──────────────────────────────────
    QString updatePath;
    QString gamePath;
    QString palette;
    int     grpListNum  = 0;
    QVector<QString> grpListIdx;
    QVector<QString> grpListGrp;
    QVector<QString> grpListName;
    QVector<GRPListSection> grpListSection;

    QString fightIdx;
    QString fightGrp;
    QString fightName;
    int     fightGrpNum = 0;

    int     checkUpdate = 0;
    int     dataCode    = 1;
    int     talkCode    = 1;
    int     talkInvert  = 0;
    int     language    = 0;
    int     gameVersion = 0;
    int     fmCursor    = 1;
    int     tileScale   = 1;

    // R 文件相关
    int     rFileNum = 0;
    QVector<QString> rFileName;
    QVector<QString> rFileNote;
    QVector<QString> rIdxFileName;

    // KDEF 文件
    QString kdefIdx, kdefGrp;
    QString nameIdx, nameGrp;

    // 战斗文件
    WIni    wIni;
    int     wTypeDataItem = 0;
    QString warData;
    QString headPicName;
    QString warMapGrp, warMapIdx;
    QString warMapDefGrp, warMapDefIdx;

    // 场景地图
    QVector<QString> sIdx, sGrp, dIdx, dGrp;
    QString smapIdx, smapGrp;
    QString smapImz, mmapImz, wmapImz;
    QString smapPNGPath, mmapPNGPath, wmapPNGPath;
    int     sceneNum = 0;

    // 主地图
    QString mmapFileGrp, mmapFileIdx;
    QString mEarth, mSurface, mBuilding, mBuildX, mBuildY;

    // 其他
    QString talkIdx, talkGrp;
    QString leave, effect, match, exp_;
    int     listBeginNum = 0;
    uint32_t usualTrans = 0x707030;

    // R 文件全局
    RFileGlobals rGlobals;

    // D 文件
    DFile   dFile;
    DIni    dIni;


    QString startPath;
    QString iniFileName = "Upedit.ini";

private:
    IniConfig() = default;
};
