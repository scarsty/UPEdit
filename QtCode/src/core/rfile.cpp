#include "rfile.h"
#include "encoding.h"
#include "fileio.h"
#include "iniconfig.h"
#include "sqlite3wrapper.h"
#include <QFile>
#include <QSettings>

// QSettings IniFormat 将含逗号的值拆为 QStringList，
// toString() 将返回空串。此辅助函数统一还原原始字符串。
static QString iniStr(QSettings &ini, const QString &key, const QString &defVal = {})
{
    QVariant v = ini.value(key);
    if (!v.isValid()) return defVal;
    if (v.typeId() == QMetaType::QStringList)
        return v.toStringList().join(',');
    return v.toString();
}
#include <QDataStream>
#include <QSettings>
#include <QStringList>
#include <QStringEncoder>
#include <QRegularExpression>
#include <cstring>

// ── 读写 RDataSingle ────────────────────────────────────

void RFileIO::writeRDataStr(RDataSingle &rds, const QString &data)
{
    if (rds.dataType == 0) {
        bool ok;
        int64_t v = data.toLongLong(&ok);
        if (ok) writeRDataInt(rds, v);
    } else if (rds.dataType == 1 && rds.dataLen > 0) {
        Encoding::writeInStr(data, rds.data.data(), rds.dataLen);
    }
}

void RFileIO::writeRDataInt(RDataSingle &rds, int64_t data)
{
    if (rds.dataLen <= 0) return;
    if (rds.data.size() < rds.dataLen)
        rds.data.resize(rds.dataLen);

    memset(rds.data.data(), 0, rds.dataLen);

    if (rds.dataLen == 1) {
        *reinterpret_cast<int8_t *>(rds.data.data()) = static_cast<int8_t>(data);
    } else if (rds.dataLen == 2) {
        *reinterpret_cast<int16_t *>(rds.data.data()) = static_cast<int16_t>(data);
    } else if (rds.dataLen >= 4 && rds.dataLen < 8) {
        *reinterpret_cast<int32_t *>(rds.data.data()) = static_cast<int32_t>(data);
    } else if (rds.dataLen >= 8) {
        *reinterpret_cast<int64_t *>(rds.data.data()) = data;
    } else if (rds.dataLen == 3) {
        *reinterpret_cast<int16_t *>(rds.data.data()) = static_cast<int16_t>(data);
    }
}

int64_t RFileIO::readRDataInt(const RDataSingle &rds)
{
    if (rds.dataLen <= 0 || rds.data.isEmpty()) return 0;

    if (rds.dataLen == 1) {
        return static_cast<int8_t>(rds.data[0]);
    } else if (rds.dataLen >= 2 && rds.dataLen < 4) {
        return *reinterpret_cast<const int16_t *>(rds.data.constData());
    } else if (rds.dataLen >= 4 && rds.dataLen < 8) {
        return *reinterpret_cast<const int32_t *>(rds.data.constData());
    } else if (rds.dataLen >= 8) {
        return *reinterpret_cast<const int64_t *>(rds.data.constData());
    }
    return 0;
}

QString RFileIO::readRDataStr(const RDataSingle &rds)
{
    if (rds.dataType == 0) {
        return QString::number(readRDataInt(rds));
    } else {
        return Encoding::readOutStr(rds.data.constData(), rds.dataLen);
    }
}

// ── 深拷贝 ──────────────────────────────────────────────

void RFileIO::copyRData(const RData &source, RData &dest)
{
    dest.num = source.num;
    dest.rDataLine.resize(source.rDataLine.size());
    for (int i = 0; i < source.rDataLine.size(); ++i) {
        auto &sl = source.rDataLine[i];
        auto &dl = dest.rDataLine[i];
        dl.len = sl.len;
        dl.rArray.resize(sl.rArray.size());
        for (int j = 0; j < sl.rArray.size(); ++j) {
            auto &sa = sl.rArray[j];
            auto &da = dl.rArray[j];
            da.incNum = sa.incNum;
            da.dataArray.resize(sa.dataArray.size());
            for (int k = 0; k < sa.dataArray.size(); ++k) {
                da.dataArray[k].dataType = sa.dataArray[k].dataType;
                da.dataArray[k].dataLen  = sa.dataArray[k].dataLen;
                da.dataArray[k].data     = sa.dataArray[k].data; // QByteArray 隐式共享
            }
        }
    }
}

// ── 从 INI 读取类型定义 ──────────────────────────────────

void RFileIO::readIni(RFileGlobals &g, const QString &iniPath)
{
    QSettings ini(iniPath, QSettings::IniFormat);

    g.typeNumber = ini.value("R_Modify/TypeNumber", 0).toInt();
    if (g.typeNumber <= 0) return;

    g.typeName.resize(g.typeNumber);
    g.typeNameName.resize(g.typeNumber);
    g.typeRefString.resize(g.typeNumber);
    g.typeDataItem.resize(g.typeNumber);
    g.rIni.resize(g.typeNumber);

    // 短格式: types = "base role item ..." → 仅设置名称后退出(供 DB 模式)
    QString typesStr = iniStr(ini, "R_Modify/types");
    if (!typesStr.isEmpty()) {
        QStringList typeNames = typesStr.split(' ', Qt::SkipEmptyParts);
        QString nameNameStr = iniStr(ini, "R_Modify/TypeNameName");
        QStringList nameNames = nameNameStr.split(' ', Qt::SkipEmptyParts);
        for (int t = 0; t < g.typeNumber && t < typeNames.size(); ++t) {
            g.typeName[t] = typeNames[t];
            if (t < nameNames.size())
                g.typeNameName[t] = nameNames[t];
            g.typeRefString[t] = iniStr(ini, QString("R_Modify/Typeref%1").arg(t));
        }
        g.initialized = true;
        return; // Delphi 中此处 exit
    }

    // 长格式: typename0, typedataitem0, data(0,0)...
    for (int t = 0; t < g.typeNumber; ++t) {
        g.typeName[t] = iniStr(ini, QString("R_Modify/typename%1").arg(t));
        int dataItemCount = ini.value(QString("R_Modify/typedataitem%1").arg(t), 0).toInt();
        g.typeDataItem[t] = dataItemCount;

        if (dataItemCount <= 0) continue;

        g.rIni[t].rTerm.resize(dataItemCount);
        int diff = 0;
        for (int d = 0; d < dataItemCount; ++d) {
            QString dataKey = QString("R_Modify/data(%1,%2)").arg(t).arg(d);
            QString line = iniStr(ini, dataKey);
            QStringList parts = line.split(' ', Qt::SkipEmptyParts);

            RTermini &term = g.rIni[t].rTerm[d];
            if (parts.size() >= 8) {
                term.datanum = parts[0].toShort();
                term.incnum  = parts[1].toShort();
                term.datalen = parts[2].toShort();
                term.isstr   = parts[3].toShort();
                term.isname  = parts[4].toShort();
                term.quote   = parts[5].toShort();
                term.name    = parts[6];
                term.note    = parts[7] + QString("(%1)").arg(diff);
                diff += term.datalen / 2 * term.datanum;

                // 供 DB 模式检测名称列
                if (term.isname == 1)
                    g.typeNameName[t] = term.name;
            }
        }
    }

    g.initialized = true;
}

// ── 读取 R 文件 (idx + grp 二进制) ──────────────────────

bool RFileIO::readR(const QString &idxFile, const QString &grpFile, RFile *prf, const RFileGlobals &g)
{
    if (grpFile.endsWith(".db", Qt::CaseInsensitive))
        return false;

    QFile fidx(idxFile);
    QFile fgrp(grpFile);
    if (!fidx.open(QIODevice::ReadOnly) || !fgrp.open(QIODevice::ReadOnly))
        return false;

    prf->typeNumber = g.typeNumber;
    prf->rType.resize(prf->typeNumber);

    // 初始化
    for (int i = 0; i < prf->typeNumber; ++i) {
        prf->rType[i].dataNum = 0;
        prf->rType[i].namePos = -1;
        prf->rType[i].mapPos  = -1;
        prf->rType[i].rData.clear();
    }

    // Delphi 约定: offset[i] = 前 i+1 个类型的累积字节数末尾位置
    // type 0 数据: [0, offset[0])
    // type 1 数据: [offset[0], offset[1])
    QVector<int32_t> offsets(prf->typeNumber);
    fidx.read(reinterpret_cast<char *>(offsets.data()), prf->typeNumber * 4);
    fidx.close();

    for (int i1 = 0; i1 < prf->typeNumber; ++i1) {
        RType &rt = prf->rType[i1];
        if (i1 >= g.typeDataItem.size()) break;

        int fieldCount = g.typeDataItem[i1];
        if (fieldCount <= 0) continue;

        // 计算单条记录大小 (与 Delphi 一致)
        int recordSize = 0;
        for (int i2 = 0; i2 < fieldCount && i2 < g.rIni[i1].rTerm.size(); ++i2) {
            const RTermini &term = g.rIni[i1].rTerm[i2];
            if (term.datanum > 0) {
                for (int i3 = 0; i3 < term.incnum; ++i3) {
                    int termIdx = i2 + i3;
                    if (termIdx < g.rIni[i1].rTerm.size())
                        recordSize += term.datanum * g.rIni[i1].rTerm[termIdx].datalen;
                }
            }
        }
        if (recordSize <= 0) continue;

        // 计算记录数
        int dataSize;
        if (i1 == 0)
            dataSize = offsets[i1];
        else
            dataSize = offsets[i1] - offsets[i1 - 1];
        int recordCount = qMax(dataSize / recordSize, 1);

        // 预分配记录 (使用 addNewRData 的逻辑)
        for (int i2 = 0; i2 < recordCount; ++i2)
            addNewRData(prf, i1, g);

        // 定位到正确偏移
        if (i1 != 0)
            fgrp.seek(offsets[i1 - 1]);

        // 读数据
        for (int i2 = 0; i2 < rt.dataNum; ++i2) {
            int temp = -1;
            for (int i3 = 0; i3 < fieldCount && i3 < g.rIni[i1].rTerm.size(); ++i3) {
                const RTermini &term = g.rIni[i1].rTerm[i3];
                if (term.datanum > 0) {
                    ++temp;

                    if (i3 == 0 && term.isname == 1)
                        rt.namePos = temp;

                    for (int i4 = 0; i4 < term.datanum; ++i4) {
                        for (int i5 = 0; i5 < term.incnum; ++i5) {
                            int termIdx = i3 + i5;
                            if (termIdx < g.rIni[i1].rTerm.size()) {
                                int dl = g.rIni[i1].rTerm[termIdx].datalen;
                                if (dl > 0 && temp < rt.rData[i2].rDataLine.size()
                                    && i4 < rt.rData[i2].rDataLine[temp].rArray.size()
                                    && i5 < rt.rData[i2].rDataLine[temp].rArray[i4].dataArray.size()) {
                                    fgrp.read(
                                        rt.rData[i2].rDataLine[temp].rArray[i4].dataArray[i5].data.data(),
                                        dl);
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    fgrp.close();
    return true;
}

// ── 保存 R 文件 ─────────────────────────────────────────

void RFileIO::saveR(const QString &idxFile, const QString &grpFile, const RFile *prf, const RFileGlobals &g)
{
    if (grpFile.endsWith(".db", Qt::CaseInsensitive)) {
        saveDB(grpFile, prf, g);
        return;
    }

    // Delphi 约定: offset[i] 为累积末尾偏移
    QVector<int32_t> offsets(prf->typeNumber, 0);
    QByteArray grpData;

    for (int i1 = 0; i1 < prf->typeNumber; ++i1) {
        if (i1 > 0)
            offsets[i1] = offsets[i1 - 1];

        const RType &rt = prf->rType[i1];
        for (int i2 = 0; i2 < rt.rData.size(); ++i2) {
            const RData &rd = rt.rData[i2];
            for (int i3 = 0; i3 < rd.rDataLine.size(); ++i3) {
                const RDataLine &line = rd.rDataLine[i3];
                for (int i4 = 0; i4 < line.rArray.size(); ++i4) {
                    const RArray &arr = line.rArray[i4];
                    for (int i5 = 0; i5 < arr.dataArray.size(); ++i5) {
                        const RDataSingle &ds = arr.dataArray[i5];
                        if (ds.dataLen > 0) {
                            grpData.append(ds.data);
                        }
                        offsets[i1] += ds.dataLen;
                    }
                }
            }
        }
    }

    FileIO::writeFileAll(grpFile, grpData);

    QByteArray idxData(prf->typeNumber * 4, '\0');
    memcpy(idxData.data(), offsets.data(), prf->typeNumber * 4);
    FileIO::writeFileAll(idxFile, idxData);
}

// ── 从 SQLite 读取 ──────────────────────────────────────

bool RFileIO::readDB(const QString &dbFile, RFile *prf, RFileGlobals &g)
{
    if (!SQLite3Database::isLibraryLoaded()) return false;

    SQLite3Database db;
    if (!db.open(dbFile)) return false;

    int tableNum = g.typeNumber;
    g.rIni.resize(tableNum);
    g.typeName.resize(tableNum);
    g.typeDataItem.resize(tableNum);
    prf->typeNumber = tableNum;
    prf->rType.resize(tableNum);

    // 枚举表名 (实际使用 INI 中的 typeName)
    SQLite3Statement stmtTables = db.prepare("select name from sqlite_master where type='table'");
    if (!stmtTables.isValid()) return false;

    int i1 = 0;
    while (stmtTables.step() == SQLite3Statement::SQLITE_ROW && i1 < tableNum) {
        // Delphi: tname := typename[i1] — 用 INI 类型名作为表名
        QString tname = g.typeName[i1];
        if (tname == "bindata") continue;

        // 获取表结构
        SQLite3Statement stmtStruct = db.prepare(
            QStringLiteral("PRAGMA table_info(%1)").arg(tname));
        if (!stmtStruct.isValid()) { ++i1; continue; }

        // 计数列数
        int termNum = 0;
        while (stmtStruct.step() == SQLite3Statement::SQLITE_ROW)
            ++termNum;
        stmtStruct.reset();

        g.rIni[i1].rTerm.resize(termNum);
        g.typeDataItem[i1] = termNum;

        prf->rType[i1].dataNum = 0;
        prf->rType[i1].namePos = -1;
        prf->rType[i1].mapPos  = -1;
        prf->rType[i1].rData.clear();

        // 填充 RIni 的 term 信息
        int j = 0;
        while (stmtStruct.step() == SQLite3Statement::SQLITE_ROW) {
            RTermini &term = g.rIni[i1].rTerm[j];
            term.name    = stmtStruct.columnText(1); // 列名
            term.isstr   = 0;
            QString colType = stmtStruct.columnText(2); // 列类型
            term.datanum = 1;
            term.incnum  = 1;
            term.datalen = 4;
            term.isname  = 0;
            term.quote   = -1;
            term.note.clear();

            if (colType == "TEXT") {
                term.isstr   = 1;
                term.datalen = 100;
            }

            // 检测 name 字段
            if (i1 < g.typeNameName.size() && term.name == g.typeNameName[i1])
                term.isname = 1;

            // 引用检测: 去掉尾部数字, 用 |name| 匹配 typeRefString
            QString name1 = term.name;
            for (int c = 0; c < name1.size(); ++c) {
                if (name1[c].isDigit()) {
                    name1 = name1.left(c);
                    break;
                }
            }
            name1 = "|" + name1 + "|";
            for (int i2 = 0; i2 < g.typeNumber && i2 < g.typeRefString.size(); ++i2) {
                if (g.typeRefString[i2].contains(name1)) {
                    term.quote = i2;
                    break;
                }
            }
            ++j;
        }

        // 读取数据行
        SQLite3Statement stmtData = db.prepare(
            QStringLiteral("select * from %1").arg(tname));
        if (!stmtData.isValid()) { ++i1; continue; }

        // 计数行数
        int rowCount = 0;
        while (stmtData.step() == SQLite3Statement::SQLITE_ROW)
            ++rowCount;
        stmtData.reset();

        // 创建空记录
        for (int r = 0; r < rowCount; ++r)
            addNewRData(prf, i1, g);

        // 填充数据
        for (int i2 = 0; i2 < prf->rType[i1].dataNum; ++i2) {
            stmtData.step();
            int temp = -1;
            for (int i3 = 0; i3 < g.typeDataItem[i1] && i3 < g.rIni[i1].rTerm.size(); ++i3) {
                if (g.rIni[i1].rTerm[i3].datanum <= 0) continue;
                ++temp;

                if (i3 == 0 && g.rIni[i1].rTerm[i3].isname == 1)
                    prf->rType[i1].namePos = temp;

                if (temp >= prf->rType[i1].rData[i2].rDataLine.size()) continue;

                for (int i4 = 0; i4 < g.rIni[i1].rTerm[i3].datanum; ++i4) {
                    if (i4 >= prf->rType[i1].rData[i2].rDataLine[temp].rArray.size()) continue;
                    for (int i5 = 0; i5 < g.rIni[i1].rTerm[i3].incnum; ++i5) {
                        int termIdx = i3 + i5;
                        if (termIdx >= g.rIni[i1].rTerm.size()) continue;
                        if (i5 >= prf->rType[i1].rData[i2].rDataLine[temp].rArray[i4].dataArray.size()) continue;

                        auto &ds = prf->rType[i1].rData[i2].rDataLine[temp].rArray[i4].dataArray[i5];
                        if (ds.dataLen <= 0) continue;

                        if (g.rIni[i1].rTerm[termIdx].isstr == 0) {
                            // 整数列
                            int value = stmtData.columnInt(i3);
                            writeRDataInt(ds, value);
                        } else {
                            // 文本列: 从 UTF-8 转换为原生 dataCode 编码存储
                            ds.data.fill(0, ds.dataLen);
                            QString str = stmtData.columnText(i3);
                            Encoding::writeInStr(str, ds.data.data(), ds.dataLen);
                        }
                    }
                }
            }
        }
        ++i1;
    }

    return true;
}

// ── 保存到 SQLite ───────────────────────────────────────

void RFileIO::saveDB(const QString &dbFile, const RFile *prf, const RFileGlobals &g)
{
    if (!SQLite3Database::isLibraryLoaded()) return;

    // 对应 Delphi: DeleteFile(dbfile) 后重新创建
    QFile::remove(dbFile);

    SQLite3Database db;
    if (!db.open(dbFile)) return;

    db.beginTransaction();

    for (int i1 = 0; i1 < prf->typeNumber && i1 < g.rIni.size(); ++i1) {
        if (i1 >= g.typeName.size()) break;
        QString tname = g.typeName[i1];
        if (tname.isEmpty()) continue;

        // ── CREATE TABLE ──
        QString sql = QStringLiteral("create table %1(").arg(tname);
        for (int j = 0; j < g.rIni[i1].rTerm.size(); ++j) {
            const RTermini &term = g.rIni[i1].rTerm[j];
            for (int j1 = 0; j1 < term.datanum; ++j1) {
                for (int j2 = 0; j2 < term.incnum; ++j2) {
                    int termIdx = j + j2;
                    if (termIdx >= g.rIni[i1].rTerm.size()) continue;
                    QString colName = g.rIni[i1].rTerm[termIdx].name;
                    if (term.datanum > 1)
                        colName += QString::number(j1 + IniConfig::instance().listBeginNum);
                    if (term.isstr != 0)
                        sql += QStringLiteral("\"%1\" text,").arg(colName);
                    else
                        sql += QStringLiteral("\"%1\" integer,").arg(colName);
                }
            }
        }
        // 末尾逗号替换为空格 (对应 Delphi sql[length(sql)] := ' ')
        if (sql.endsWith(','))
            sql.chop(1);
        sql += ")";
        db.execute(sql);

        // ── INSERT DATA ──
        for (int i2 = 0; i2 < prf->rType[i1].dataNum; ++i2) {
            sql = QStringLiteral("insert into %1 values(").arg(tname);
            const RData &rd = prf->rType[i1].rData[i2];
            for (int i3 = 0; i3 < rd.rDataLine.size(); ++i3) {
                for (int i4 = 0; i4 < rd.rDataLine[i3].rArray.size(); ++i4) {
                    const RArray &arr = rd.rDataLine[i3].rArray[i4];
                    for (int i5 = 0; i5 < arr.dataArray.size(); ++i5) {
                        const RDataSingle &ds = arr.dataArray[i5];
                        if (ds.dataLen <= 0) continue;

                        int termIdx = i3;
                        if (termIdx < g.rIni[i1].rTerm.size() && g.rIni[i1].rTerm[termIdx].isstr != 0) {
                            // 文本列: 从原生 dataCode 编码解码 → 给 SQLite
                            QString str = Encoding::readOutStr(ds.data.constData(), ds.dataLen);
                            // 转义双引号
                            str.replace('"', "\"\"");
                            sql += QStringLiteral("\"%1\",").arg(str);
                        } else {
                            // 整数列
                            int64_t value = readRDataInt(ds);
                            sql += QString::number(value) + ",";
                        }
                    }
                }
            }
            if (sql.endsWith(','))
                sql.chop(1);
            sql += ")";
            db.execute(sql);
        }
    }

    db.commit();
}

// ── 计算 name 位置 ──────────────────────────────────────

void RFileIO::calcNamePos(RFile *prf, const RFileGlobals &g)
{
    for (int i1 = 0; i1 < prf->typeNumber && i1 < g.rIni.size(); ++i1) {
        prf->rType[i1].namePos = -1;
        int temp = -1;
        for (int i2 = 0; i2 < g.typeDataItem[i1] && i2 < g.rIni[i1].rTerm.size(); ++i2) {
            if (g.rIni[i1].rTerm[i2].datanum > 0)
                ++temp;
            if (g.rIni[i1].rTerm[i2].isname == 1) {
                prf->rType[i1].namePos = temp;
                break;
            }
        }
    }
}

// ── 添加新记录 ──────────────────────────────────────────

void RFileIO::addNewRData(RFile *prf, int crType, const RFileGlobals &g, const RData *prd)
{
    if (crType < 0 || crType >= prf->rType.size()) return;
    RType &rt = prf->rType[crType];

    if (rt.dataNum < 0) rt.dataNum = 0;
    ++rt.dataNum;
    rt.rData.resize(rt.dataNum);
    RData &newRd = rt.rData[rt.dataNum - 1];

    int fieldCount = (crType < g.typeDataItem.size()) ? g.typeDataItem[crType] : 0;

    // 计算有效 RDataLine 数量 (仅 datanum > 0 的 term)
    int lineCount = 0;
    for (int i3 = 0; i3 < fieldCount && i3 < g.rIni[crType].rTerm.size(); ++i3) {
        if (g.rIni[crType].rTerm[i3].datanum > 0)
            ++lineCount;
    }

    newRd.num = lineCount;
    newRd.rDataLine.resize(lineCount);

    int temp = -1;
    for (int i3 = 0; i3 < fieldCount && i3 < g.rIni[crType].rTerm.size(); ++i3) {
        const RTermini &term = g.rIni[crType].rTerm[i3];
        if (term.datanum <= 0) continue;

        ++temp;
        RDataLine &line = newRd.rDataLine[temp];
        line.len = term.datanum;
        line.rArray.resize(term.datanum);

        for (int i4 = 0; i4 < term.datanum; ++i4) {
            RArray &arr = line.rArray[i4];
            arr.incNum = term.incnum;
            arr.dataArray.resize(term.incnum);

            for (int i5 = 0; i5 < term.incnum; ++i5) {
                int termIdx = i3 + i5;
                RDataSingle &ds = arr.dataArray[i5];
                if (termIdx < g.rIni[crType].rTerm.size()) {
                    ds.dataType = g.rIni[crType].rTerm[termIdx].isstr;
                    ds.dataLen  = g.rIni[crType].rTerm[termIdx].datalen;
                } else {
                    ds.dataType = 0;
                    ds.dataLen  = 0;
                }
                if (ds.dataLen < 0) ds.dataLen = 0;
                ds.data.fill(0, ds.dataLen);
            }
        }
    }

    // 如果提供了源数据则覆盖
    if (prd)
        copyRData(*prd, newRd);
}

// ── 对话读写 ─────────────────────────────────────────────

QString RFileIO::readTalkStr(const TalkStr &ts)
{
    if (ts.len <= 0 || ts.str.isEmpty()) return {};
    return Encoding::readOutStrWithCode(ts.str.constData(), ts.len, Encoding::talkCode);
}

void RFileIO::writeTalkStr(TalkStr &ts, const QString &str)
{
    QByteArray encoded;
    int code = Encoding::talkCode;

    if (code == 2) {
        const ushort *u16 = str.utf16();
        encoded = QByteArray(reinterpret_cast<const char *>(u16), str.size() * 2);
    } else {
        const char *encName = "UTF-8";
        switch (code) {
        case 0: encName = "GBK"; break;
        case 1: encName = "Big5"; break;
        default: break;
        }
        auto encoder = QStringEncoder(encName);
        if (encoder.isValid()) encoded = encoder(str);
    }

    ts.len = encoded.size();
    ts.str = encoded;
}
