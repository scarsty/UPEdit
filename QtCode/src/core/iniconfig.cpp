#include "iniconfig.h"
#include "encoding.h"
#include "rfile.h"
#include "mapdata.h"
#include <QSettings>
#include <QFile>
#include <QFileInfo>
#include <QCoreApplication>
#include <QDir>
#include <QTemporaryFile>

// QSettings IniFormat 会将含逗号的值自动拆为 QStringList,
// 导致 .toString() 返回空或首项。此辅助函数统一还原为原始字符串。
static QString iniStr(QSettings &ini, const QString &key, const QString &defVal = {})
{
    QVariant v = ini.value(key);
    if (!v.isValid()) return defVal;
    if (v.typeId() == QMetaType::QStringList)
        return v.toStringList().join(',');
    return v.toString();
}

IniConfig &IniConfig::instance()
{
    static IniConfig cfg;
    return cfg;
}

// 将 UTF-16LE INI 转为 UTF-8 临时文件以供 QSettings 读取
static bool prepareIniPath(const QString &originalPath,
                           QTemporaryFile &tmpFile,
                           QString &outPath)
{
    QFile f(originalPath);
    if (!f.open(QIODevice::ReadOnly)) return false;
    QByteArray raw = f.readAll();
    f.close();

    bool isUtf16LE = (raw.size() >= 2
                      && static_cast<uint8_t>(raw[0]) == 0xFF
                      && static_cast<uint8_t>(raw[1]) == 0xFE);

    if (isUtf16LE) {
        QString content = QString::fromUtf16(
            reinterpret_cast<const char16_t *>(raw.constData()),
            raw.size() / 2);
        if (!content.isEmpty() && content[0] == QChar(0xFEFF))
            content = content.mid(1);

        tmpFile.setAutoRemove(true);
        if (!tmpFile.open()) return false;
        tmpFile.write(content.toUtf8());
        tmpFile.flush();
        outPath = tmpFile.fileName();
    } else {
        outPath = originalPath;
    }
    return true;
}

void IniConfig::load(const QString &path)
{
    iniPath = path;
    startPath = QFileInfo(path).absolutePath() + "/";

    QTemporaryFile tmpFile;
    QString settingsPath;
    if (!prepareIniPath(path, tmpFile, settingsPath))
        return;

    QSettings ini(settingsPath, QSettings::IniFormat);

    // ── [run] section ───────────────────────────────────
    gamePath    = ini.value("run/gamepath", "\\").toString();
    if (!gamePath.isEmpty() && !gamePath.endsWith('\\') && !gamePath.endsWith('/'))
        gamePath += "\\";

    dataCode    = ini.value("run/datacode", 1).toInt();
    talkCode    = ini.value("run/talkcode", dataCode).toInt();
    talkInvert  = ini.value("run/talkinvert", 0).toInt();
    language    = ini.value("run/language", 0).toInt();
    tileScale   = ini.value("run/TileScale", 1).toInt();
    checkUpdate = ini.value("run/checkupdate", 0).toInt();
    fmCursor    = ini.value("run/fmcursor", 1).toInt();
    gameVersion = ini.value("run/GameVersion", 0).toInt();
    listBeginNum = ini.value("run/listbeginnum", 0).toInt();
    usualTrans  = ini.value("run/usualtrans", 0x707030).toUInt();

    Encoding::dataCode   = dataCode;
    Encoding::talkCode   = talkCode;
    Encoding::talkInvert = talkInvert;
    Encoding::language   = language;

    // ── [file] 基本路径 ─────────────────────────────────
    palette     = ini.value("file/palette", "").toString();
    talkIdx     = ini.value("file/talkidx", "").toString();
    talkGrp     = ini.value("file/talkgrp", "").toString();
    kdefIdx     = ini.value("file/kdefidx", "").toString();
    kdefGrp     = ini.value("file/kdefgrp", "").toString();
    nameIdx     = ini.value("file/nameidx", "").toString();
    nameGrp     = ini.value("file/namegrp", "").toString();
    warData     = ini.value("file/WarDefine", "").toString();
    headPicName = ini.value("file/headpicname", "").toString();

    // 战斗地图
    warMapGrp   = ini.value("file/WarMAPGRP", "").toString();
    warMapIdx   = ini.value("file/WarMAPIDX", "").toString();
    wmapImz     = ini.value("file/WMAPIMZ", "").toString();
    wmapPNGPath = ini.value("file/WMAPPNGPATH", "").toString();
    if (!wmapPNGPath.isEmpty() && !wmapPNGPath.endsWith('\\') && !wmapPNGPath.endsWith('/'))
        wmapPNGPath += "\\";
    warMapDefGrp = ini.value("file/WarMAPDefGRP", "").toString();
    warMapDefIdx = ini.value("file/WarMAPDefIDX", "").toString();

    // 场景地图
    smapGrp     = ini.value("file/SMAPGRP", "").toString();
    smapIdx     = ini.value("file/SMAPIDX", "").toString();
    smapImz     = ini.value("file/SMAPIMZ", "").toString();
    smapPNGPath = ini.value("file/SMAPPNGPATH", "").toString();
    if (!smapPNGPath.isEmpty() && !smapPNGPath.endsWith('\\') && !smapPNGPath.endsWith('/'))
        smapPNGPath += "\\";

    // 主地图
    mmapFileGrp = ini.value("file/MMAPGRP", "").toString();
    mmapFileIdx = ini.value("file/MMAPIDX", "").toString();
    mmapImz     = ini.value("file/MMAPIMZ", "").toString();
    mmapPNGPath = ini.value("file/MMAPPNGPATH", "").toString();
    if (!mmapPNGPath.isEmpty() && !mmapPNGPath.endsWith('\\') && !mmapPNGPath.endsWith('/'))
        mmapPNGPath += "\\";

    leave   = ini.value("file/Leave", "").toString();
    effect  = ini.value("file/Effect", "").toString();
    match   = ini.value("file/Match", "").toString();
    exp_    = ini.value("file/Exp", "").toString();

    // ── GRP 文件列表 (File0=idx,grp,name) ──────────────
    grpListNum = ini.value("file/FileNumber", 0).toInt();
    if (grpListNum > 0) {
        grpListIdx.resize(grpListNum);
        grpListGrp.resize(grpListNum);
        grpListName.resize(grpListNum);
        grpListSection.resize(grpListNum);

        for (int i = 0; i < grpListNum; ++i) {
            // File0=idx,grp,name
            QString fileStr = iniStr(ini, QString("file/File%1").arg(i));
            QStringList parts = fileStr.split(',');
            if (parts.size() == 3) {
                grpListIdx[i]  = parts[0].trimmed();
                grpListGrp[i]  = parts[1].trimmed();
                grpListName[i] = parts[2].trimmed();
            }
            // Section0=tag,begin,end[,tag,begin,end,...]
            QString secStr = iniStr(ini, QString("file/Section%1").arg(i));
            QStringList secParts = secStr.split(',', Qt::SkipEmptyParts);
            int secCount = secParts.size() / 3;
            if (secCount > 0 && secParts.size() % 3 == 0) {
                grpListSection[i].num = secCount;
                grpListSection[i].tag.resize(secCount);
                grpListSection[i].beginNum.resize(secCount);
                grpListSection[i].endNum.resize(secCount);
                for (int j = 0; j < secCount; ++j) {
                    grpListSection[i].tag[j]      = secParts[j * 3].trimmed();
                    grpListSection[i].beginNum[j]  = secParts[j * 3 + 1].trimmed().toInt();
                    QString endStr = secParts[j * 3 + 2].trimmed();
                    grpListSection[i].endNum[j] = (endStr == "end") ? -2 : endStr.toInt();
                }
            } else {
                grpListSection[i].num = 0;
            }
        }
    }

    // ── MMAPStruct (comma-split 5 values) ───────────────
    QString mmapStruct = iniStr(ini, "file/MMAPStruct");
    if (!mmapStruct.isEmpty()) {
        QStringList parts = mmapStruct.split(',', Qt::SkipEmptyParts);
        if (parts.size() == 5) {
            mEarth    = parts[0].trimmed();
            mSurface  = parts[1].trimmed();
            mBuilding = parts[2].trimmed();
            mBuildX   = parts[3].trimmed();
            mBuildY   = parts[4].trimmed();
        }
    }

    // ── R 文件路径 (RIDX / RGRP 逗号分隔) ───────────────
    int tempNum = 0;

    auto splitComma = [&](const QString &key) -> QStringList {
        QString s = iniStr(ini, key);
        if (s.isEmpty()) return {};
        return s.split(',', Qt::SkipEmptyParts);
    };

    {
        QStringList p = splitComma("file/RIDX");
        rFileNum = p.size();
        tempNum  = rFileNum;
        rIdxFileName.resize(rFileNum);
        for (int i = 0; i < rFileNum; ++i)
            rIdxFileName[i] = p[i].trimmed();
    }
    {
        QStringList p = splitComma("file/RGRP");
        int n = p.size();
        if (tempNum > n) tempNum = n;
        rFileName.resize(n);
        for (int i = 0; i < n; ++i)
            rFileName[i] = p[i].trimmed();
    }

    // ── 场景 / D 文件路径 ────────────────────────────────
    auto loadVec = [&](const QString &key, QVector<QString> &vec) {
        QStringList p = splitComma(key);
        int n = p.size();
        if (n > 0 && tempNum > n) tempNum = n;
        vec.resize(n);
        for (int i = 0; i < n; ++i) vec[i] = p[i].trimmed();
    };
    loadVec("file/SIDX", sIdx);
    loadVec("file/SGRP", sGrp);
    loadVec("file/DIDX", dIdx);
    loadVec("file/DGRP", dGrp);
    {
        QStringList p = splitComma("file/RecordNote");
        int n = p.size();
        if (n > 0 && tempNum > n) tempNum = n;
        rFileNote.resize(n);
        for (int i = 0; i < n; ++i) rFileNote[i] = p[i].trimmed();
    }
    rFileNum = tempNum;
    sceneNum = tempNum;

    // ── 战斗 (FightNum + FightName=idx,grp,name) ───────
    fightGrpNum = ini.value("file/FightNum", 0).toInt();
    {
        QString fStr = iniStr(ini, "file/FightName");
        if (!fStr.isEmpty()) {
            QStringList p = fStr.split(',', Qt::SkipEmptyParts);
            if (p.size() == 3) {
                fightIdx  = p[0].trimmed();
                fightGrp  = p[1].trimmed();
                fightName = p[2].trimmed();
            }
        }
    }

    // ── 读取 R 文件类型定义 ([R_Modify] section) ────────
    RFileIO::readIni(rGlobals, settingsPath);
}
