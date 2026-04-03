#include "grpdata.h"
#include "fileio.h"
#include <QImage>
#include <cstring>

bool GrpIO::readGrp(const QString &idxFile, const QString &grpFile, QVector<GrpPic> &pics)
{
    QByteArray idxData = FileIO::readFileAll(idxFile);
    QByteArray grpData = FileIO::readFileAll(grpFile);
    if (idxData.isEmpty()) return false;

    // idx 文件格式: 每 8 字节 (offset:4 + size:4) 或 (offset:4)
    // 常见格式: 每条 4 字节偏移
    int count = idxData.size() / 4;
    if (count <= 0) return false;

    const uint32_t *offsets = reinterpret_cast<const uint32_t *>(idxData.constData());
    pics.resize(count);

    for (int i = 0; i < count; ++i) {
        uint32_t offset = offsets[i];
        uint32_t nextOffset = (i + 1 < count) ? offsets[i + 1] : static_cast<uint32_t>(grpData.size());
        if (offset >= static_cast<uint32_t>(grpData.size())) {
            pics[i].size = 0;
            continue;
        }

        int sz = static_cast<int>(nextOffset - offset);
        if (sz <= 0) { pics[i].size = 0; continue; }

        pics[i].size = sz;
        pics[i].data = grpData.mid(static_cast<int>(offset), sz);
    }
    return true;
}

void GrpIO::saveGrp(const QString &idxFile, const QString &grpFile, const QVector<GrpPic> &pics)
{
    QByteArray grpData;
    QByteArray idxData(pics.size() * 4, '\0');
    uint32_t *offsets = reinterpret_cast<uint32_t *>(idxData.data());

    for (int i = 0; i < pics.size(); ++i) {
        offsets[i] = static_cast<uint32_t>(grpData.size());
        grpData.append(pics[i].data);
    }

    FileIO::writeFileAll(grpFile, grpData);
    FileIO::writeFileAll(idxFile, idxData);
}

QImage GrpIO::decodeRLE(const GrpPic &pic, const uint8_t r[256], const uint8_t g[256], const uint8_t b[256])
{
    if (pic.size < 4 || pic.data.isEmpty())
        return {};

    const uint8_t *p = reinterpret_cast<const uint8_t *>(pic.data.constData());

    // RLE 头部: xs(2), ys(2) -> 宽高
    int16_t xs = *reinterpret_cast<const int16_t *>(p);
    int16_t ys = *reinterpret_cast<const int16_t *>(p + 2);
    if (xs <= 0 || ys <= 0) return {};

    QImage img(xs, ys, QImage::Format_ARGB32);
    img.fill(Qt::transparent);

    int offset = 4;
    int px = 0, py = 0;

    while (offset < pic.size && py < ys) {
        uint8_t byte = p[offset++];
        if (byte == 0) {
            // 换行
            py++;
            px = 0;
        } else if (byte & 0x80) {
            // 跳过 (byte & 0x7F) 个像素
            px += (byte & 0x7F);
        } else {
            // 绘制 byte 个像素
            int count = byte;
            for (int c = 0; c < count && offset < pic.size; ++c) {
                uint8_t colorIdx = p[offset++];
                if (px < xs && py < ys) {
                    img.setPixelColor(px, py, QColor(r[colorIdx], g[colorIdx], b[colorIdx]));
                }
                px++;
            }
        }
    }
    return img;
}

GrpPic GrpIO::encodeRLE(const QImage &img, const uint8_t r[256], const uint8_t g[256], const uint8_t b[256])
{
    GrpPic result;
    if (img.isNull()) return result;

    // 简单实现：找最接近的调色板颜色
    auto findNearest = [&](QRgb c) -> uint8_t {
        int best = 0;
        int bestDist = INT_MAX;
        int cr = qRed(c), cg = qGreen(c), cb = qBlue(c);
        for (int i = 0; i < 256; ++i) {
            int dr = cr - r[i], dg = cg - g[i], db = cb - b[i];
            int d = dr * dr + dg * dg + db * db;
            if (d < bestDist) { bestDist = d; best = i; }
        }
        return static_cast<uint8_t>(best);
    };

    QByteArray data;
    int16_t xs = img.width(), ys = img.height();
    data.append(reinterpret_cast<const char *>(&xs), 2);
    data.append(reinterpret_cast<const char *>(&ys), 2);

    QImage src = img.convertToFormat(QImage::Format_ARGB32);
    for (int y = 0; y < ys; ++y) {
        int x = 0;
        while (x < xs) {
            QRgb c = src.pixel(x, y);
            if (qAlpha(c) < 128) {
                // 透明像素, 计算跳过数
                int skip = 0;
                while (x + skip < xs && qAlpha(src.pixel(x + skip, y)) < 128 && skip < 127)
                    skip++;
                data.append(static_cast<char>(0x80 | skip));
                x += skip;
            } else {
                // 不透明像素, 计算连续数
                QByteArray pixels;
                while (x + pixels.size() < xs && qAlpha(src.pixel(x + pixels.size(), y)) >= 128
                       && pixels.size() < 127) {
                    pixels.append(static_cast<char>(findNearest(src.pixel(x + pixels.size(), y))));
                }
                data.append(static_cast<char>(pixels.size()));
                data.append(pixels);
                x += pixels.size();
            }
        }
        data.append('\0'); // 行结束标记
    }

    result.data = data;
    result.size = data.size();
    return result;
}

bool GrpIO::isPNG(const GrpPic &pic)
{
    return pic.size >= 8 && FileIO::isPNG(pic.data.constData());
}

QImage GrpIO::decodePNG(const GrpPic &pic)
{
    QImage img;
    img.loadFromData(pic.data, "PNG");
    return img;
}
