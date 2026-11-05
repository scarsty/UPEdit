#include "mapdata.h"
#include <QtEndian>
#include "fileio.h"
#include <QFile>
#include <cstring>
#include <QDataStream>
#include <QPainter>
#include <algorithm>
#include "imzdata.h"

bool MapIO::loadPngTiles(const QString &path, QVector<GrpPic> &pictures, QVector<QImage> &tiles)
{
    Imz sprites;
    if (!ImzIO::readImz(path, sprites)) return false;
    int maximumId = -1;
    for (const auto &sprite : sprites.imzPng) {
        if (sprite.fileNum < 0 || sprite.fileNum > 1000000) return false;
        maximumId = qMax(maximumId, sprite.fileNum);
    }
    pictures.clear();
    tiles.clear();
    pictures.resize(maximumId + 1);
    tiles.resize(maximumId + 1);
    for (const auto &sprite : sprites.imzPng) {
        if (sprite.frameData.isEmpty()) continue;
        auto &picture = pictures[sprite.fileNum];
        picture.data = sprite.frameData[0].data;
        picture.size = picture.data.size();
        picture.xoff = sprite.x;
        picture.yoff = sprite.y;
        tiles[sprite.fileNum].loadFromData(picture.data, "PNG");
        picture.width = tiles[sprite.fileNum].width();
        picture.height = tiles[sprite.fileNum].height();
    }
    return maximumId >= 0;
}

QImage MapIO::renderMainMap(const Map &map, const QVector<QImage> &tiles, const QVector<GrpPic> &pictures,
                            bool ground, bool surface, bool building, int scale, int zoom,
                            const std::function<bool(int)> &progress)
{
    if (map.layerNum < 3 || map.mapLayer.size() < 3 || map.x <= 0 || map.y <= 0
        || map.x > 32767 || map.y > 32767 || scale <= 0 || scale > 64 || zoom <= 0 || zoom > 10000) return {};
    for (int layer = 0; layer < 3; ++layer) {
        if (map.mapLayer[layer].pic.size() < map.x) return {};
        for (int column = 0; column < map.x; ++column)
            if (map.mapLayer[layer].pic[column].size() < map.y) return {};
    }
    double factor = zoom / 100.0;
    qint64 width = qint64((qint64(map.x + map.y) * 18 + 80) * scale * factor);
    qint64 height = qint64((qint64(map.x + map.y) * 9 + 60) * scale * factor);
    if (width <= 0 || height <= 0 || width > 32767 || height > 32767 || width * height > 300000000) return {};
    QImage image(int(width), int(height), QImage::Format_ARGB32);
    if (image.isNull()) return {};
    image.fill(Qt::transparent);
    QPainter painter(&image);
    painter.setRenderHint(QPainter::SmoothPixmapTransform);
    painter.scale(factor, factor);
    int originX = ((map.x + map.y) * 18 + 80) * scale / 2 + 18 * scale;
    int originY = 30 * scale;
    auto draw = [&](int layer, int column, int row) {
        int id = map.mapLayer[layer].pic[column][row] / 2;
        if (id < 0 || (id == 0 && layer != 0) || id >= tiles.size() || tiles[id].isNull()) return;
        int offsetX = id < pictures.size() ? pictures[id].xoff : 0;
        int offsetY = id < pictures.size() ? pictures[id].yoff : 0;
        painter.drawImage(originX + (column - row) * 18 * scale - offsetX,
                          originY + (column + row) * 9 * scale - offsetY, tiles[id]);
    };
    for (int layer = 0; layer < 2; ++layer) {
        if ((layer == 0 && !ground) || (layer == 1 && !surface)) continue;
        for (int diagonal = 0; diagonal < map.x + map.y - 1; ++diagonal) {
            if (progress && !progress((layer * 30) + diagonal * 30 / (map.x + map.y - 1))) return {};
            for (int column = qMax(0, diagonal - map.y + 1); column <= qMin(map.x - 1, diagonal); ++column)
                draw(layer, column, diagonal - column);
        }
    }
    if (building) {
        struct Building { int column; int row; int depth; };
        QVector<Building> ordered;
        for (int column = 0; column < map.x; ++column) {
            if (progress && !progress(60 + column * 15 / map.x)) return {};
            for (int row = 0; row < map.y; ++row) {
                int id = map.mapLayer[2].pic[column][row] / 2;
                if (id <= 0 || id >= tiles.size() || tiles[id].isNull()) continue;
                int span = 36 * scale;
                int depth = 2 * (column + row) - (tiles[id].width() + span - 1) / span
                    - (tiles[id].height() + span - 1) / span + 2;
                ordered.append({column, row, depth});
            }
            }
        std::stable_sort(ordered.begin(), ordered.end(), [](const Building &left, const Building &right) { return left.depth < right.depth; });
        for (int index = 0; index < ordered.size(); ++index) {
            if (progress && index % 128 == 0 && !progress(75 + index * 24 / qMax(1, ordered.size()))) return {};
            const auto &entry = ordered[index];
            draw(2, entry.column, entry.row);
        }
    }
    if (progress && !progress(100)) return {};
    return image;
}

QByteArray MapIO::encodeMap(const Map &map, bool moduleHeader)
{
    QByteArray data;
    QDataStream stream(&data, QIODevice::WriteOnly);
    stream.setByteOrder(QDataStream::LittleEndian);
    if (moduleHeader) stream << qint32(map.x) << qint32(map.y);
    for (int layer = 0; layer < map.layerNum; ++layer)
        for (int row = 0; row < map.y; ++row)
            for (int column = 0; column < map.x; ++column)
                stream << qint16(map.mapLayer[layer].pic[column][row]);
    return data;
}

bool MapIO::decodeModule(const QByteArray &data, int layers, Map &map, int maxDimension)
{
    if (data.size() < 8 || layers <= 0) return false;
    QDataStream stream(data);
    stream.setByteOrder(QDataStream::LittleEndian);
    qint32 width = 0, height = 0;
    stream >> width >> height;
    if (width <= 0 || height <= 0 || width > maxDimension || height > maxDimension
        || data.size() != 8 + qint64(width) * height * layers * 2) return false;
    Map decoded;
    if (!readSingleMap(data, 8, decoded, layers, width, height)) return false;
    map = decoded;
    return true;
}

Map MapIO::extractRegion(const Map &map, const QRect &region)
{
    QRect bounds = region.normalized().intersected(QRect(0, 0, map.x, map.y));
    Map result;
    if (bounds.isEmpty()) return result;
    result.x = bounds.width();
    result.y = bounds.height();
    result.layerNum = map.layerNum;
    result.mapLayer.resize(map.layerNum);
    for (int layer = 0; layer < map.layerNum; ++layer) {
        result.mapLayer[layer].pic.resize(result.x);
        for (int column = 0; column < result.x; ++column) {
            result.mapLayer[layer].pic[column].resize(result.y);
            for (int row = 0; row < result.y; ++row)
                result.mapLayer[layer].pic[column][row] = map.mapLayer[layer].pic[bounds.x() + column][bounds.y() + row];
        }
    }
    return result;
}

void MapIO::pasteRegion(Map &map, const Map &region, const QPoint &anchor)
{
    for (int layer = 0; layer < qMin(map.layerNum, region.layerNum); ++layer)
        for (int column = 0; column < region.x; ++column)
            for (int row = 0; row < region.y; ++row) {
                int targetX = anchor.x() - region.x + 1 + column;
                int targetY = anchor.y() - region.y + 1 + row;
                if (targetX >= 0 && targetY >= 0 && targetX < map.x && targetY < map.y)
                    map.mapLayer[layer].pic[targetX][targetY] = region.mapLayer[layer].pic[column][row];
            }
}

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
    if (offset < 0 || offset > data.size() || layerNum <= 0 || layerNum > 64
        || width <= 0 || height <= 0 || width > 32767 || height > 32767) return false;
    qint64 valueCount = qint64(layerNum) * width * height;
    if (valueCount > (data.size() - offset) / 2) return false;
    Map decoded;
    decoded.layerNum = layerNum;
    decoded.x = width;
    decoded.y = height;
    decoded.mapLayer.resize(layerNum);

    const char *bytes = data.constData() + offset;
    qint64 position = 0;

    for (int l = 0; l < layerNum; ++l) {
        decoded.mapLayer[l].pic.resize(width);
        for (int x = 0; x < width; ++x)
            decoded.mapLayer[l].pic[x].resize(height, 0);

        // 按行(y)读取，匹配 Delphi
        for (int y = 0; y < height; ++y) {
            for (int x = 0; x < width; ++x) {
                decoded.mapLayer[l].pic[x][y] = qFromLittleEndian<qint16>(bytes + position);
                position += 2;
            }
        }
    }
    m = decoded;
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
