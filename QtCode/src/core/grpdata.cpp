#include "grpdata.h"
#include "fileio.h"
#include <QImage>
#include <cstring>
#include <QtEndian>
#include <QFileInfo>

bool GrpIO::readGrp(const QString &idxFile, const QString &grpFile, QVector<GrpPic> &pics)
{
    QFile indexFile(idxFile), dataFile(grpFile);
    if (!indexFile.open(QIODevice::ReadOnly) || !dataFile.open(QIODevice::ReadOnly)) return false;
    QByteArray index = indexFile.readAll(), data = dataFile.readAll();
    if (indexFile.error() != QFileDevice::NoError || dataFile.error() != QFileDevice::NoError
        || index.size() % 4 != 0 || index.size() / 4 > 1000000) return false;
    QVector<GrpPic> decoded(index.size() / 4);
    qint32 begin = 0;
    for (int entry = 0; entry < decoded.size(); ++entry) {
        qint32 end = qFromLittleEndian<qint32>(index.constData() + entry * 4);
        if (end < begin || end > data.size()) return false;
        auto &picture = decoded[entry];
        picture.data = data.mid(begin, end - begin);
        picture.size = picture.data.size();
        begin = end;
        if (picture.data.isEmpty()) continue;
        if (isPNG(picture)) {
            QImage image = decodePNG(picture);
            if (image.isNull()) return false;
            picture.width = image.width();
            picture.height = image.height();
        } else {
            if (picture.data.size() < 8) return false;
            picture.width = qFromLittleEndian<qint16>(picture.data.constData());
            picture.height = qFromLittleEndian<qint16>(picture.data.constData() + 2);
            picture.xoff = qFromLittleEndian<qint16>(picture.data.constData() + 4);
            picture.yoff = qFromLittleEndian<qint16>(picture.data.constData() + 6);
            if (picture.width < 0 || picture.height < 0) return false;
        }
    }
    if (begin != data.size()) return false;
    pics = decoded;
    return true;
}

bool GrpIO::saveGrp(const QString &idxFile, const QString &grpFile, const QVector<GrpPic> &pics)
{
    QByteArray grpData;
    QByteArray idxData(pics.size() * 4, '\0');
    int32_t *offsets = reinterpret_cast<int32_t *>(idxData.data());

    for (int i = 0; i < pics.size(); ++i) {
        QByteArray data = pics[i].data;
        if (!isPNG(pics[i]) && data.size() >= 8) {
            if (pics[i].xoff < SHRT_MIN || pics[i].xoff > SHRT_MAX || pics[i].yoff < SHRT_MIN || pics[i].yoff > SHRT_MAX) return false;
            qToLittleEndian<qint16>(pics[i].xoff, data.data() + 4);
            qToLittleEndian<qint16>(pics[i].yoff, data.data() + 6);
        }
        if (qint64(grpData.size()) + data.size() > INT_MAX) return false;
        grpData.append(data);
        qToLittleEndian<qint32>(grpData.size(), reinterpret_cast<char *>(offsets) + i * 4);
    }

    if (QFileInfo(idxFile).absoluteFilePath().compare(QFileInfo(grpFile).absoluteFilePath(), Qt::CaseInsensitive) == 0) return false;
    return FileIO::writeFiles({{grpFile, grpData}, {idxFile, idxData}});
}

QImage GrpIO::decodeRLE(const GrpPic &pic, const uint8_t r[256], const uint8_t g[256], const uint8_t b[256])
{
    if (pic.data.size() < 8)
        return {};

    const uint8_t *p = reinterpret_cast<const uint8_t *>(pic.data.constData());

    // RLE8 头部: pw(2) + ph(2) + xs(2) + ys(2) = 8 字节
    int16_t pw = *reinterpret_cast<const int16_t *>(p);
    int16_t ph = *reinterpret_cast<const int16_t *>(p + 2);
    // xs, ys 是偏移量, 已在 readGrp 中提取到 pic.xoff/yoff

    if (pw <= 0 || ph <= 0 || qint64(pw) * ph > 16777216) return {};

    QImage img(pw, ph, QImage::Format_ARGB32);
    img.fill(Qt::transparent);

    const uint8_t *pData = p + 8; // 跳过 8 字节头
    int remaining = pic.data.size() - 8;

    for (int iy = 0; iy < ph; ++iy) {
        if (remaining <= 0) return {};

        // 每行首先读 1 字节 linesize
        uint8_t linesize = *pData++;
        remaining--;

        if (remaining < linesize) return {};
        if (linesize == 0) continue;

        // 状态机: state=2→跳过, state=1→读像素计数, state>2→绘制像素
        int state = 2;
        int ix = 0;
        const uint8_t *lineEnd = pData + linesize;

        while (pData < lineEnd) {
            uint8_t temp = *pData++;

            if (state == 2) {
                // 跳过 temp 个透明像素
                ix += temp;
                state = 1;
            } else if (state == 1) {
                // temp = 接下来要绘制的不透明像素数
                if (pData + temp > lineEnd || ix + temp > pw) return {};
                state = temp == 0 ? 2 : 2 + temp;
            } else {
                // state > 2: 绘制 1 个像素
                if (ix >= 0 && ix < pw && iy < ph) {
                    img.setPixelColor(ix, iy, QColor(r[temp], g[temp], b[temp]));
                }
                ix++;
                state--;
            }
        }

        remaining -= linesize;
    }
    return img;
}

GrpPic GrpIO::encodeRLE(const QImage &img, const uint8_t r[256], const uint8_t g[256], const uint8_t b[256])
{
    GrpPic result;
    if (img.isNull() || img.width() > SHRT_MAX || img.height() > SHRT_MAX) return result;

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
    int16_t pw = img.width(), ph = img.height();
    int16_t xs = 0, ys = 0;
    // 8 字节头: pw + ph + xs + ys
    data.append(reinterpret_cast<const char *>(&pw), 2);
    data.append(reinterpret_cast<const char *>(&ph), 2);
    data.append(reinterpret_cast<const char *>(&xs), 2);
    data.append(reinterpret_cast<const char *>(&ys), 2);

    QImage src = img.convertToFormat(QImage::Format_ARGB32);
    for (int y = 0; y < ph; ++y) {
        QByteArray lineData;
        int x = 0;
        while (x < pw) {
            // 计算透明像素 (skip)
            int skip = 0;
            while (x + skip < pw && qAlpha(src.pixel(x + skip, y)) < 128) {
                skip++;
                if (skip >= 255) break;
            }
            lineData.append(static_cast<char>(skip)); // skip count
            x += skip;

            // 计算不透明像素 (draw)
            QByteArray pixels;
            while (x + pixels.size() < pw && qAlpha(src.pixel(x + pixels.size(), y)) >= 128
                   && pixels.size() < 255) {
                pixels.append(static_cast<char>(findNearest(src.pixel(x + pixels.size(), y))));
            }
            lineData.append(static_cast<char>(pixels.size())); // pixel count
            lineData.append(pixels);
            x += pixels.size();
        }

        // linesize 必须 <= 255 (1 字节)
        if (lineData.size() > 255) return {};
        uint8_t linesize = static_cast<uint8_t>(lineData.size());
        data.append(static_cast<char>(linesize));
        data.append(lineData);
    }

    result.data = data;
    result.size = data.size();
    result.width = pw;
    result.height = ph;
    result.xoff = xs;
    result.yoff = ys;
    return result;
}

bool GrpIO::isPNG(const GrpPic &pic)
{
    return pic.data.size() >= 8 && FileIO::isPNG(pic.data.constData());
}

QImage GrpIO::decodePNG(const GrpPic &pic)
{
    QImage img;
    img.loadFromData(pic.data, "PNG");
    return img;
}
