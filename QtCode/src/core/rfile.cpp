#include "rfile.h"
#include "encoding.h"
#include "fileio.h"
#include <QFile>
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

    // 读取类型名列表
    QString typesStr = ini.value("R_Modify/types", "").toString();
    QStringList typeNames = typesStr.split(' ', Qt::SkipEmptyParts);

    g.typeName.resize(g.typeNumber);
    g.typeNameName.resize(g.typeNumber);
    g.typeRefString.resize(g.typeNumber);
    g.typeDataItem.resize(g.typeNumber);
    g.rIni.resize(g.typeNumber);

    QString nameNameStr = ini.value("R_Modify/TypeNameName", "").toString();
    QStringList nameNames = nameNameStr.split(' ', Qt::SkipEmptyParts);

    for (int t = 0; t < g.typeNumber; ++t) {
        g.typeName[t] = (t < typeNames.size()) ? typeNames[t] : QString("type%1").arg(t);
        g.typeNameName[t] = (t < nameNames.size()) ? nameNames[t] : "";
        g.typeRefString[t] = ini.value(QString("R_Modify/Typeref%1").arg(t), "").toString();

        QString key = QString("R_Modify/typename%1").arg(t);
        g.typeName[t] = ini.value(key, g.typeName[t]).toString();

        int dataItemCount = ini.value(QString("R_Modify/typedataitem%1").arg(t), 0).toInt();
        g.typeDataItem[t] = dataItemCount;

        g.rIni[t].rTerm.resize(dataItemCount);
        for (int d = 0; d < dataItemCount; ++d) {
            QString dataKey = QString("R_Modify/data(%1,%2)").arg(t).arg(d);
            QString line = ini.value(dataKey, "").toString();
            QStringList parts = line.split(' ', Qt::SkipEmptyParts);

            RTermini &term = g.rIni[t].rTerm[d];
            if (parts.size() >= 7) {
                term.datanum = parts[0].toShort();
                term.incnum  = parts[1].toShort();
                term.datalen = parts[2].toShort();
                term.isstr   = parts[3].toShort();
                term.isname  = parts[4].toShort();
                term.quote   = parts[5].toShort();
                term.name    = parts[6];
                if (parts.size() >= 8)
                    term.note = parts[7];
            }
        }
    }

    g.initialized = true;
}

// ── 读取 R 文件 (idx + grp 二进制) ──────────────────────

bool RFileIO::readR(const QString &idxFile, const QString &grpFile, RFile *prf, const RFileGlobals &g)
{
    // 检测是否是 .db 文件
    if (grpFile.endsWith(".db", Qt::CaseInsensitive)) {
        // 委托给 readDB
        return false; // 由调用者处理
    }

    QFile fidx(idxFile);
    QFile fgrp(grpFile);
    if (!fidx.open(QIODevice::ReadOnly) || !fgrp.open(QIODevice::ReadOnly))
        return false;

    prf->typeNumber = g.typeNumber;
    prf->rType.resize(prf->typeNumber);

    // 读取 idx 偏移数组
    QVector<uint32_t> offsets(prf->typeNumber + 1);
    fidx.read(reinterpret_cast<char *>(offsets.data()), prf->typeNumber * 4);
    offsets[prf->typeNumber] = static_cast<uint32_t>(fgrp.size());
    fidx.close();

    QByteArray grpData = fgrp.readAll();
    fgrp.close();

    for (int t = 0; t < prf->typeNumber; ++t) {
        RType &rt = prf->rType[t];
        if (t >= g.typeDataItem.size()) break;

        int fieldCount = g.typeDataItem[t];
        if (fieldCount <= 0) continue;

        // 计算单条记录大小
        int recordSize = 0;
        for (int d = 0; d < fieldCount && d < g.rIni[t].rTerm.size(); ++d) {
            const RTermini &term = g.rIni[t].rTerm[d];
            recordSize += term.datanum * term.incnum * term.datalen;
        }

        if (recordSize <= 0) continue;

        uint32_t startOff = offsets[t];
        uint32_t endOff   = offsets[t + 1];
        int dataSize = static_cast<int>(endOff - startOff);
        int recordCount = dataSize / recordSize;

        rt.dataNum = recordCount;
        rt.rData.resize(recordCount);

        int pos = static_cast<int>(startOff);

        for (int r = 0; r < recordCount; ++r) {
            RData &rd = rt.rData[r];
            rd.num = fieldCount;
            rd.rDataLine.resize(fieldCount);

            for (int d = 0; d < fieldCount && d < g.rIni[t].rTerm.size(); ++d) {
                const RTermini &term = g.rIni[t].rTerm[d];
                RDataLine &line = rd.rDataLine[d];
                line.len = term.datanum;
                line.rArray.resize(term.datanum);

                for (int dn = 0; dn < term.datanum; ++dn) {
                    RArray &arr = line.rArray[dn];
                    arr.incNum = term.incnum;
                    arr.dataArray.resize(term.incnum);

                    for (int inc = 0; inc < term.incnum; ++inc) {
                        RDataSingle &single = arr.dataArray[inc];
                        single.dataType = term.isstr;
                        single.dataLen  = term.datalen;
                        single.data.resize(term.datalen);

                        if (pos + term.datalen <= grpData.size()) {
                            memcpy(single.data.data(), grpData.constData() + pos, term.datalen);
                        }
                        pos += term.datalen;
                    }
                }
            }
        }
    }

    return true;
}

// ── 保存 R 文件 ─────────────────────────────────────────

void RFileIO::saveR(const QString &idxFile, const QString &grpFile, const RFile *prf, const RFileGlobals &g)
{
    QByteArray grpData;
    QVector<uint32_t> offsets(prf->typeNumber);

    for (int t = 0; t < prf->typeNumber; ++t) {
        offsets[t] = static_cast<uint32_t>(grpData.size());
        const RType &rt = prf->rType[t];

        for (int r = 0; r < rt.rData.size(); ++r) {
            const RData &rd = rt.rData[r];
            for (int d = 0; d < rd.rDataLine.size(); ++d) {
                const RDataLine &line = rd.rDataLine[d];
                for (int dn = 0; dn < line.rArray.size(); ++dn) {
                    const RArray &arr = line.rArray[dn];
                    for (int inc = 0; inc < arr.dataArray.size(); ++inc) {
                        grpData.append(arr.dataArray[inc].data);
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
    // SQLite 读取会在 sqlite3wrapper 模块中实现
    // 此处预留接口
    Q_UNUSED(dbFile);
    Q_UNUSED(prf);
    Q_UNUSED(g);
    return false;
}

// ── 保存到 SQLite ───────────────────────────────────────

void RFileIO::saveDB(const QString &dbFile, const RFile *prf, const RFileGlobals &g)
{
    Q_UNUSED(dbFile);
    Q_UNUSED(prf);
    Q_UNUSED(g);
}

// ── 计算 name 位置 ──────────────────────────────────────

void RFileIO::calcNamePos(RFile *prf, const RFileGlobals &g)
{
    for (int t = 0; t < prf->typeNumber && t < g.rIni.size(); ++t) {
        prf->rType[t].namePos = -1;
        for (int d = 0; d < g.rIni[t].rTerm.size(); ++d) {
            if (g.rIni[t].rTerm[d].isname == 1) {
                prf->rType[t].namePos = d;
                break;
            }
        }
    }
}

// ── 添加新记录 ──────────────────────────────────────────

void RFileIO::addNewRData(RFile *prf, int crType, const RData &rd)
{
    if (crType < 0 || crType >= prf->rType.size()) return;
    prf->rType[crType].rData.append(rd);
    prf->rType[crType].dataNum = prf->rType[crType].rData.size();
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
