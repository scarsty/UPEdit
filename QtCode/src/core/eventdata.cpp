#include "eventdata.h"
#include "fileio.h"
#include <QSettings>
#include <QDataStream>
#include <cstring>

bool EventIO::readEvents(const QString &idxFile, const QString &grpFile, DFile &dfile)
{
    QByteArray idxData = FileIO::readFileAll(idxFile);
    QByteArray grpData = FileIO::readFileAll(grpFile);
    if (idxData.isEmpty() || grpData.isEmpty())
        return false;

    const int bytesPerMap = 200 * static_cast<int>(sizeof(SceneEvent));
    if (bytesPerMap <= 0)
        return false;

    int mapCount = grpData.size() / bytesPerMap;
    if (mapCount <= 0)
        return false;

    dfile.mapNum = mapCount;
    dfile.mapEvent.resize(mapCount);

    for (int i = 0; i < mapCount; ++i) {
        int off = i * bytesPerMap;
        if (off + bytesPerMap > grpData.size())
            break;

        const SceneEvent *src = reinterpret_cast<const SceneEvent *>(grpData.constData() + off);
        for (int e = 0; e < 200; ++e) {
            dfile.mapEvent[i].sceneEvent[e] = src[e];
        }
    }
    return true;
}

void EventIO::saveEvents(const QString &idxFile, const QString &grpFile, const DFile &dfile)
{
    QByteArray grpData;
    QByteArray idxData(dfile.mapNum * 4, '\0');
    uint32_t *offsets = reinterpret_cast<uint32_t *>(idxData.data());

    for (int i = 0; i < dfile.mapNum; ++i) {
        offsets[i] = static_cast<uint32_t>(grpData.size());
        grpData.append(reinterpret_cast<const char *>(dfile.mapEvent[i].sceneEvent),
                       200 * sizeof(SceneEvent));
    }

    FileIO::writeFileAll(grpFile, grpData);
    FileIO::writeFileAll(idxFile, idxData);
}

void EventIO::readKDEFIni(const QString &iniPath, KDEFIni &kdefIni)
{
    QSettings ini(iniPath, QSettings::IniFormat);
    kdefIni.kdefNum = ini.value("KDEF/KDEFnum", 0).toInt();
    kdefIni.talkArrange = ini.value("KDEF/talkarrange", 0).toInt();

    kdefIni.kdefItem.resize(kdefIni.kdefNum);
    for (int i = 0; i < kdefIni.kdefNum; ++i) {
        QString line = ini.value(QString("KDEF/kdef%1").arg(i), "").toString();
        QStringList parts = line.split(' ', Qt::SkipEmptyParts);
        KDEFItem &item = kdefIni.kdefItem[i];
        if (parts.size() >= 6) {
            item.index     = parts[0].toShort();
            item.paramount = parts[1].toShort();
            item.ifjump    = parts[2].toShort();
            item.yesjump   = parts[3].toShort();
            item.nojump    = parts[4].toShort();
            item.note      = parts[5];
        }
    }
}

void EventIO::readDIni(const QString &iniPath, DIni &dini)
{
    QSettings ini(iniPath, QSettings::IniFormat);
    dini.num = ini.value("D_Modify/num", 0).toInt();
    dini.attrib.resize(dini.num);
    for (int i = 0; i < dini.num; ++i) {
        dini.attrib[i] = ini.value(QString("D_Modify/attrib%1").arg(i), "").toString();
    }
}

Event EventIO::parseEvent(const QByteArray &data)
{
    Event evt;
    if (data.size() < 2) return evt;

    const int16_t *p = reinterpret_cast<const int16_t *>(data.constData());
    int maxIdx = data.size() / 2;
    int idx = 0;

    // 第一个 int16 = 指令总数
    evt.attribAmount = p[idx++];
    evt.attrib.resize(evt.attribAmount);

    for (int a = 0; a < evt.attribAmount && idx < maxIdx; ++a) {
        Attrib &at = evt.attrib[a];
        at.attribNum = p[idx++]; if (idx >= maxIdx) break;
        at.parCount  = p[idx++]; if (idx >= maxIdx) break;

        at.par.resize(at.parCount);
        for (int pa = 0; pa < at.parCount && idx < maxIdx; ++pa) {
            at.par[pa] = p[idx++];
        }
    }
    return evt;
}

QByteArray EventIO::encodeEvent(const Event &evt)
{
    QByteArray data;
    auto write16 = [&](int16_t v) {
        data.append(reinterpret_cast<const char *>(&v), 2);
    };

    write16(evt.attribAmount);
    for (int a = 0; a < evt.attribAmount; ++a) {
        const Attrib &at = evt.attrib[a];
        write16(at.attribNum);
        write16(at.parCount);
        for (int pa = 0; pa < at.parCount; ++pa) {
            write16(at.par[pa]);
        }
    }
    return data;
}
