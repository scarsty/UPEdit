#include "mapdata.h"
#include "fileio.h"
#include <QFile>
#include <cstring>

bool MapIO::readMap(const QString &idxFile, const QString &grpFile, MapStruct &ms)
{
    QByteArray idxData = FileIO::readFileAll(idxFile);
    QByteArray grpData = FileIO::readFileAll(grpFile);
    if (idxData.isEmpty() || grpData.isEmpty())
        return false;

    // idx 文件: 每 4 字节一个 uint32 偏移
    int count = idxData.size() / 4;
    ms.num = count;
    ms.map.resize(count);

    const uint32_t *offsets = reinterpret_cast<const uint32_t *>(idxData.constData());

    for (int i = 0; i < count; ++i) {
        uint32_t off = offsets[i];
        if (off >= static_cast<uint32_t>(grpData.size())) continue;

        // 地图头部: layerNum(2), x(2), y(2)
        const uint8_t *p = reinterpret_cast<const uint8_t *>(grpData.constData()) + off;
        int remaining = grpData.size() - static_cast<int>(off);
        if (remaining < 6) continue;

        Map &m = ms.map[i];
        m.layerNum = *reinterpret_cast<const int16_t *>(p);     p += 2;
        m.x        = *reinterpret_cast<const int16_t *>(p);     p += 2;
        m.y        = *reinterpret_cast<const int16_t *>(p);     p += 2;

        if (m.layerNum <= 0 || m.x <= 0 || m.y <= 0) continue;

        m.mapLayer.resize(m.layerNum);
        for (int l = 0; l < m.layerNum; ++l) {
            MapLayer &layer = m.mapLayer[l];
            layer.pic.resize(m.x);
            for (int x = 0; x < m.x; ++x)
                layer.pic[x].resize(m.y, 0);

            // Delphi 按行(y)连续读取: for iy := 0 to y-1 do fileread(pic[iy][0], x*2)
            // Qt pic[x][y]，需要转置读取
            for (int y = 0; y < m.y; ++y) {
                for (int x = 0; x < m.x; ++x) {
                    if (p + 2 <= reinterpret_cast<const uint8_t *>(grpData.constData()) + grpData.size()) {
                        layer.pic[x][y] = *reinterpret_cast<const int16_t *>(p);
                        p += 2;
                    }
                }
            }
        }
    }

    return true;
}

void MapIO::saveMap(const QString &idxFile, const QString &grpFile, const MapStruct &ms)
{
    QByteArray grpData;
    QByteArray idxData(ms.num * 4, '\0');
    uint32_t *offsets = reinterpret_cast<uint32_t *>(idxData.data());

    for (int i = 0; i < ms.num; ++i) {
        offsets[i] = static_cast<uint32_t>(grpData.size());
        const Map &m = ms.map[i];

        // 写入头部
        int16_t header[3] = { static_cast<int16_t>(m.layerNum),
                              static_cast<int16_t>(m.x),
                              static_cast<int16_t>(m.y) };
        grpData.append(reinterpret_cast<const char *>(header), 6);

        // 写入图层数据 (按行写入，匹配 Delphi: for iy := 0 to y-1)
        for (int l = 0; l < m.layerNum && l < m.mapLayer.size(); ++l) {
            const MapLayer &layer = m.mapLayer[l];
            for (int y = 0; y < m.y; ++y) {
                for (int x = 0; x < m.x; ++x) {
                    int16_t v = (x < layer.pic.size() && y < layer.pic[x].size())
                                ? layer.pic[x][y] : 0;
                    grpData.append(reinterpret_cast<const char *>(&v), 2);
                }
            }
        }
    }

    FileIO::writeFileAll(grpFile, grpData);
    FileIO::writeFileAll(idxFile, idxData);
}

bool MapIO::readSingleMap(const QByteArray &data, int offset, Map &m, int layerNum, int width, int height)
{
    m.layerNum = layerNum;
    m.x = width;
    m.y = height;
    m.mapLayer.resize(layerNum);

    const int16_t *p = reinterpret_cast<const int16_t *>(data.constData() + offset);
    int maxIdx = (data.size() - offset) / 2;
    int idx = 0;

    for (int l = 0; l < layerNum; ++l) {
        m.mapLayer[l].pic.resize(width);
        for (int x = 0; x < width; ++x)
            m.mapLayer[l].pic[x].resize(height, 0);

        // 按行(y)读取，匹配 Delphi
        for (int y = 0; y < height; ++y) {
            for (int x = 0; x < width; ++x) {
                if (idx < maxIdx)
                    m.mapLayer[l].pic[x][y] = p[idx++];
            }
        }
    }
    return true;
}

void MapIO::readPalette(const QString &filename, uint8_t r[256], uint8_t g[256], uint8_t b[256])
{
    QFile f(filename);
    if (!f.open(QIODevice::ReadOnly)) return;

    for (int i = 0; i < 256; ++i) {
        uint8_t rgb[3] = {};
        f.read(reinterpret_cast<char *>(rgb), 3);
        r[i] = rgb[0] << 2;
        g[i] = rgb[1] << 2;
        b[i] = rgb[2] << 2;
    }
}
