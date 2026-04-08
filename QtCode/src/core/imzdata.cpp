#include "imzdata.h"
#include "zipwrapper.h"
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QBuffer>
#include <QImage>
#include <QPainter>

bool ImzIO::readImz(const QString &path, Imz &imz)
{
    QFileInfo fi(path);
    if (fi.isDir()) {
        return readImzFromFolder(path, imz);
    }

    // ZIP 格式 (.imz)
    ZipWrapper zip;
    if (!zip.open(path, ZipWrapper::ReadOnly))
        return false;

    // 先获取条目总数
    QStringList entries = zip.entryNames();
    if (entries.isEmpty()) { zip.close(); return false; }

    // 读 index.ka 或 index.txt
    QByteArray indexData = zip.readEntry("index.ka");
    QByteArray indexTxt  = zip.readEntry("index.txt");

    // 收集所有 PNG 条目
    QStringList pngEntries;
    for (auto &e : entries) {
        if (e.endsWith(".png", Qt::CaseInsensitive))
            pngEntries.append(e);
    }

    imz.pngNum = pngEntries.size();
    imz.imzPng.resize(imz.pngNum);

    // 解析 index.ka 偏移 (每个精灵 4 字节: int16 x + int16 y)
    for (int i = 0; i < imz.pngNum; ++i) {
        ImzPng &ip = imz.imzPng[i];
        ip.x = 0;
        ip.y = 0;

        if (!indexData.isEmpty() && (i + 1) * 4 <= indexData.size()) {
            const int16_t *p = reinterpret_cast<const int16_t *>(indexData.constData() + i * 4);
            ip.x = p[0];
            ip.y = p[1];
        }

        // 读 PNG 数据
        QByteArray pngData = zip.readEntry(pngEntries[i]);
        ip.frame = 1;
        ip.frameLen.resize(1);
        ip.frameLen[0] = pngData.size();
        ip.frameData.resize(1);
        ip.frameData[0].data = pngData;
        ip.len = pngData.size();
    }

    // 解析 index.txt 覆盖偏移 (格式: "0:100,50")
    if (!indexTxt.isEmpty()) {
        QStringList lines = QString::fromUtf8(indexTxt).split('\n', Qt::SkipEmptyParts);
        for (auto &line : lines) {
            int colon = line.indexOf(':');
            if (colon < 0) continue;
            int idx = line.left(colon).trimmed().toInt();
            QString coords = line.mid(colon + 1).trimmed();
            int comma = coords.indexOf(',');
            if (comma < 0) continue;
            if (idx >= 0 && idx < imz.pngNum) {
                imz.imzPng[idx].x = coords.left(comma).trimmed().toShort();
                imz.imzPng[idx].y = coords.mid(comma + 1).trimmed().toShort();
            }
        }
    }

    zip.close();
    return true;
}

bool ImzIO::saveImz(const QString &path, const Imz &imz)
{
    ZipWrapper zip;
    if (!zip.open(path, ZipWrapper::Create))
        return false;

    // 写入 index.ka
    QByteArray indexData(imz.pngNum * 4, '\0');
    for (int i = 0; i < imz.pngNum; ++i) {
        int16_t *p = reinterpret_cast<int16_t *>(indexData.data() + i * 4);
        p[0] = imz.imzPng[i].x;
        p[1] = imz.imzPng[i].y;
    }
    zip.addEntry("index.ka", indexData);

    // 写入 PNG 文件
    for (int i = 0; i < imz.pngNum; ++i) {
        const ImzPng &ip = imz.imzPng[i];
        QString name = QString("%1.png").arg(i);
        if (ip.frame > 0 && !ip.frameData.isEmpty()) {
            zip.addEntry(name, ip.frameData[0].data);
        }
    }

    zip.close();
    return true;
}

bool ImzIO::readImzFromFolder(const QString &folder, Imz &imz)
{
    QDir dir(folder);
    QStringList pngs = dir.entryList({"*.png"}, QDir::Files, QDir::Name);

    imz.pngNum = pngs.size();
    imz.imzPng.resize(imz.pngNum);

    // 尝试读 index.ka
    QByteArray indexData;
    QFile indexFile(dir.filePath("index.ka"));
    if (indexFile.open(QIODevice::ReadOnly))
        indexData = indexFile.readAll();

    // 尝试读 index.txt
    QFile indexTxt(dir.filePath("index.txt"));
    QByteArray indexTxtData;
    if (indexTxt.open(QIODevice::ReadOnly))
        indexTxtData = indexTxt.readAll();

    for (int i = 0; i < imz.pngNum; ++i) {
        ImzPng &ip = imz.imzPng[i];
        ip.x = 0;
        ip.y = 0;

        if (!indexData.isEmpty() && (i + 1) * 4 <= indexData.size()) {
            const int16_t *p = reinterpret_cast<const int16_t *>(indexData.constData() + i * 4);
            ip.x = p[0];
            ip.y = p[1];
        }

        QFile pngFile(dir.filePath(pngs[i]));
        if (pngFile.open(QIODevice::ReadOnly)) {
            QByteArray pngData = pngFile.readAll();
            ip.frame = 1;
            ip.frameLen = {static_cast<int>(pngData.size())};
            ip.frameData.resize(1);
            ip.frameData[0].data = pngData;
            ip.len = pngData.size();
        }
    }

    // index.txt 覆盖
    if (!indexTxtData.isEmpty()) {
        QStringList lines = QString::fromUtf8(indexTxtData).split('\n', Qt::SkipEmptyParts);
        for (auto &line : lines) {
            int colon = line.indexOf(':');
            if (colon < 0) continue;
            int idx = line.left(colon).trimmed().toInt();
            QString coords = line.mid(colon + 1).trimmed();
            int comma = coords.indexOf(',');
            if (comma < 0) continue;
            if (idx >= 0 && idx < imz.pngNum) {
                imz.imzPng[idx].x = coords.left(comma).trimmed().toShort();
                imz.imzPng[idx].y = coords.mid(comma + 1).trimmed().toShort();
            }
        }
    }

    return imz.pngNum > 0;
}

void ImzIO::drawImzPngToImage(QImage &target, const ImzPng &png, int frameIndex, int x, int y)
{
    if (frameIndex < 0 || frameIndex >= png.frameData.size()) return;

    QImage frame;
    frame.loadFromData(png.frameData[frameIndex].data, "PNG");
    if (frame.isNull()) return;

    QPainter painter(&target);
    painter.drawImage(x + png.x, y + png.y, frame);
}

void ImzIO::copyImzPng(ImzPng &dest, const ImzPng &src)
{
    dest.len   = src.len;
    dest.x     = src.x;
    dest.y     = src.y;
    dest.frame = src.frame;
    dest.frameLen  = src.frameLen;
    dest.frameData = src.frameData;
    dest.png       = src.png;
}

bool ImzIO::decodePngToBuf(const QByteArray &pngData, PNGBuf &buf)
{
    QImage img;
    if (!img.loadFromData(pngData, "PNG")) return false;

    img = img.convertToFormat(QImage::Format_ARGB32);
    buf.width  = img.width();
    buf.height = img.height();
    buf.data.resize(buf.height);
    buf.alpha.resize(buf.height);

    for (int y = 0; y < buf.height; ++y) {
        const uint8_t *line = img.constScanLine(y);
        buf.data[y]  = QByteArray(reinterpret_cast<const char *>(line), buf.width * 4);
        buf.alpha[y].resize(buf.width);
        for (int x = 0; x < buf.width; ++x) {
            buf.alpha[y][x] = line[x * 4 + 3]; // Alpha 通道
        }
    }
    return true;
}

QByteArray ImzIO::encodePng(const QImage &img)
{
    QByteArray ba;
    QBuffer buffer(&ba);
    buffer.open(QIODevice::WriteOnly);
    img.save(&buffer, "PNG");
    return ba;
}
