#pragma once

/*
 * R/W 文件读写及 SQLite 数据库读写
 * 对应原 Delphi 版 Redit.pas 中的 readR/saveR/readDB/saveDB/readini
 */

#include "head.h"
#include <QString>
#include <QVector>

// ── R 文件全局状态 ───────────────────────────────────────
struct RFileGlobals {
    RFile rFile;
    QVector<RIni> rIni;
    int typeNumber = 0;
    QVector<QString> typeName;
    QVector<QString> typeNameName;
    QVector<QString> typeRefString;
    QVector<int>     typeDataItem;
    QVector<Select>  rSelect;
    bool initialized = false;
};

namespace RFileIO {
    // 从 INI 配置读取 R 文件类型定义
    void readIni(RFileGlobals &g, const QString &iniPath);

    // 读取 R 文件 (idx + grp 二进制格式)
    bool readR(const QString &idxFile, const QString &grpFile, RFile *prf, const RFileGlobals &g);

    // 保存 R 文件
    void saveR(const QString &idxFile, const QString &grpFile, const RFile *prf, const RFileGlobals &g);

    // 从 SQLite 数据库读取
    bool readDB(const QString &dbFile, RFile *prf, RFileGlobals &g);

    // 保存到 SQLite 数据库
    void saveDB(const QString &dbFile, const RFile *prf, const RFileGlobals &g);

    // 深拷贝 RData
    void copyRData(const RData &source, RData &dest);

    // 计算 name 在哪个字段
    void calcNamePos(RFile *prf, const RFileGlobals &g);

    // 添加新记录 (prd 非空时从 prd 复制数据)
    void addNewRData(RFile *prf, int crType, const RFileGlobals &g, const RData *prd = nullptr);

    // 整数/字符串 读写
    void writeRDataStr(RDataSingle &rds, const QString &data);
    void writeRDataInt(RDataSingle &rds, int64_t data);
    int64_t readRDataInt(const RDataSingle &rds);
    QString readRDataStr(const RDataSingle &rds);

    // 对话数据读写
    QString readTalkStr(const TalkStr &ts);
    void writeTalkStr(TalkStr &ts, const QString &str);
}
