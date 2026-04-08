#include "grpdata.h"
#include "fileio.h"
#include <QImage>
#include <cstring>

bool GrpIO::readGrp(const QString &idxFile, const QString &grpFile, QVector<GrpPic> &pics)
{
    QByteArray idxData = FileIO::readFileAll(idxFile);
    QByteArray grpData = FileIO::readFileAll(grpFile);
    if (idxData.isEmpty()) return false;

    // idx 文件格式: 每 4 字节一个累积偏移 (Delphi: offset[i] = 到第 i 帧末尾的累积位置)
    int count = idxData.size() / 4;
    if (count <= 0) return false;

    const int32_t *offsets = reinterpret_cast<const int32_t *>(idxData.constData());
    pics.resize(count);

    int32_t prevOffset = 0;
    int grpPos = 0;  // 当前在 grp 文件中的读取位置

    for (int i = 0; i < count; ++i) {
        int32_t sz = offsets[i] - prevOffset;
        prevOffset = offsets[i];

        if (sz <= 0 || grpPos + sz > grpData.size()) {
            pics[i].size = 0;
            grpPos += qMax(sz, 0);
            continue;
        }

        pics[i].size = sz;
        pics[i].data = grpData.mid(grpPos, sz);
        grpPos += sz;

        // 从帧数据中解析 8 字节头 (pw:2 + ph:2 + xs:2 + ys:2)
        if (isPNG(pics[i])) {
            // PNG: 从 IHDR 解析宽高
            if (sz >= 24) {
                const uint8_t *d = reinterpret_cast<const uint8_t *>(pics[i].data.constData());
                pics[i].width  = (d[16] << 24) | (d[17] << 16) | (d[18] << 8) | d[19];
                pics[i].height = (d[20] << 24) | (d[21] << 16) | (d[22] << 8) | d[23];
                pics[i].xoff = 0;
                pics[i].yoff = 0;
            }
        } else if (sz >= 8) {
            const int16_t *hdr = reinterpret_cast<const int16_t *>(pics[i].data.constData());
            pics[i].width  = hdr[0]; // pw
            pics[i].height = hdr[1]; // ph
            pics[i].xoff   = hdr[2]; // xs
            pics[i].yoff   = hdr[3]; // ys
        }
    }
    return true;
}

void GrpIO::saveGrp(const QString &idxFile, const QString &grpFile, const QVector<GrpPic> &pics)
{
    QByteArray grpData;
    QByteArray idxData(pics.size() * 4, '\0');
    int32_t *offsets = reinterpret_cast<int32_t *>(idxData.data());

    for (int i = 0; i < pics.size(); ++i) {
        grpData.append(pics[i].data);
        offsets[i] = static_cast<int32_t>(grpData.size()); // 累积偏移 = 到当前帧末尾的位置
    }

    FileIO::writeFileAll(grpFile, grpData);
    FileIO::writeFileAll(idxFile, idxData);
}

QImage GrpIO::decodeRLE(const GrpPic &pic, const uint8_t r[256], const uint8_t g[256], const uint8_t b[256])
{
    if (pic.size < 8 || pic.data.isEmpty())
        return {};

    const uint8_t *p = reinterpret_cast<const uint8_t *>(pic.data.constData());

    // RLE8 头部: pw(2) + ph(2) + xs(2) + ys(2) = 8 字节
    int16_t pw = *reinterpret_cast<const int16_t *>(p);
    int16_t ph = *reinterpret_cast<const int16_t *>(p + 2);
    // xs, ys 是偏移量, 已在 readGrp 中提取到 pic.xoff/yoff

    if (pw <= 0 || ph <= 0) return {};

    QImage img(pw, ph, QImage::Format_ARGB32);
    img.fill(Qt::transparent);

    const uint8_t *pData = p + 8; // 跳过 8 字节头
    int remaining = pic.size - 8;

    for (int iy = 0; iy < ph; ++iy) {
        if (remaining <= 0) break;

        // 每行首先读 1 字节 linesize
        uint8_t linesize = *pData++;
        remaining--;

        if (linesize == 0 || remaining < linesize) {
            pData += qMin((int)linesize, remaining);
            remaining -= qMin((int)linesize, remaining);
            continue;
        }

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
                state = 2 + temp;
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
    if (img.isNull()) return result;

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
        uint8_t linesize = qMin(static_cast<int>(lineData.size()), 255);
        data.append(static_cast<char>(linesize));
        data.append(lineData.left(linesize));
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
    return pic.size >= 8 && FileIO::isPNG(pic.data.constData());
}

QImage GrpIO::decodePNG(const GrpPic &pic)
{
    QImage img;
    img.loadFromData(pic.data, "PNG");
    return img;
}
