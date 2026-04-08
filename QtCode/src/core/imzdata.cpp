#include "imzdata.h"
#include "ZipFile.h"
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QBuffer>
#include <QImage>
#include <QPainter>
#include <algorithm>

bool ImzIO::readImz(const QString &path, Imz &imz)
{
    QFileInfo fi(path);
    if (fi.isDir()) {
        return readImzFromFolder(path, imz);
    }

    // ZIP 格式 (.imz)
    ZipFile zip;
    zip.openRead(path.toLocal8Bit().toStdString());
    if (!zip.opened())
        return false;

    // 先获取条目总数
    auto entries = zip.getFileNames();
    if (entries.empty()) return false;

    // 读 index.ka 或 index.txt
    std::string idxKaStr = zip.readFile("index.ka");
    QByteArray indexData = QByteArray(idxKaStr.data(), (int)idxKaStr.size());
    std::string idxTxtStr = zip.readFile("index.txt");
    QByteArray indexTxt = QByteArray(idxTxtStr.data(), (int)idxTxtStr.size());

    // 收集所有 PNG 条目, 按 baseId 分组
    QMap<int, QMap<int, QString>> groups; // baseId → { frameIdx → entryName }
    for (auto &e : entries) {
        QString name = QString::fromStdString(e);
        if (!name.endsWith(".png", Qt::CaseInsensitive)) continue;
        QString stem = name.left(name.lastIndexOf('.'));
        int uscore = stem.indexOf('_');
        if (uscore < 0) {
            bool ok;
            int id = stem.toInt(&ok);
            if (!ok) continue;
            groups[id][-1] = name;  // -1 = 单帧
        } else {
            bool ok1, ok2;
            int id = stem.left(uscore).toInt(&ok1);
            int frame = stem.mid(uscore + 1).toInt(&ok2);
            if (!ok1 || !ok2) continue;
            groups[id][frame] = name;
        }
    }

    imz.pngNum = groups.size();
    imz.imzPng.resize(imz.pngNum);

    // 解析 index.ka 偏移 (每个精灵 4 字节: int16 x + int16 y)
    int i = 0;
    for (auto it = groups.constBegin(); it != groups.constEnd(); ++it, ++i) {
        int baseId = it.key();
        const QMap<int, QString> &frames = it.value();
        ImzPng &ip = imz.imzPng[i];
        ip.fileNum = baseId;
        ip.x = 0;
        ip.y = 0;

        if (!indexData.isEmpty() && (i + 1) * 4 <= indexData.size()) {
            const int16_t *p = reinterpret_cast<const int16_t *>(indexData.constData() + i * 4);
            ip.x = p[0];
            ip.y = p[1];
        }

        if (frames.contains(-1)) {
            // 单帧
            std::string pngStr = zip.readFile(frames[-1].toStdString());
            QByteArray pngData = QByteArray(pngStr.data(), (int)pngStr.size());
            ip.frame = 1;
            ip.frameLen.resize(1);
            ip.frameLen[0] = pngData.size();
            ip.frameData.resize(1);
            ip.frameData[0].data = pngData;
            ip.len = pngData.size();
        } else {
            // 多帧
            ip.frame = frames.size();
            ip.frameLen.resize(ip.frame);
            ip.frameData.resize(ip.frame);
            ip.len = 0;
            int fi = 0;
            for (auto fit = frames.constBegin(); fit != frames.constEnd(); ++fit, ++fi) {
                std::string pngStr = zip.readFile(fit.value().toStdString());
                QByteArray pngData = QByteArray(pngStr.data(), (int)pngStr.size());
                ip.frameLen[fi] = pngData.size();
                ip.frameData[fi].data = pngData;
                ip.len += pngData.size();
            }
        }
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

    return true;
}

bool ImzIO::saveImz(const QString &path, const Imz &imz)
{
    ZipFile zip;
    zip.create(path.toLocal8Bit().toStdString());
    if (!zip.opened())
        return false;

    // 写入 index.ka
    QByteArray indexData(imz.pngNum * 4, '\0');
    for (int i = 0; i < imz.pngNum; ++i) {
        int16_t *p = reinterpret_cast<int16_t *>(indexData.data() + i * 4);
        p[0] = imz.imzPng[i].x;
        p[1] = imz.imzPng[i].y;
    }
    zip.addData("index.ka", indexData.constData(), indexData.size());

    // 写入 PNG 文件
    for (int i = 0; i < imz.pngNum; ++i) {
        const ImzPng &ip = imz.imzPng[i];
        std::string name = QString("%1.png").arg(i).toStdString();
        if (ip.frame > 0 && !ip.frameData.isEmpty()) {
            zip.addData(name, ip.frameData[0].data.constData(), ip.frameData[0].data.size());
        }
    }

    return true;
}

bool ImzIO::readImzFromFolder(const QString &folder, Imz &imz)
{
    QDir dir(folder);
    QStringList allPngs = dir.entryList({"*.png"}, QDir::Files);

    // 按 baseId 分组: baseId → [ (frameIdx, filename) ]
    // 文件名格式: "{id}.png" (单帧) 或 "{id}_{frame}.png" (多帧)
    QMap<int, QMap<int, QString>> groups;  // baseId → { frameIdx → filename }

    for (const QString &fn : allPngs) {
        QString stem = fn.left(fn.lastIndexOf('.'));
        int uscore = stem.indexOf('_');
        if (uscore < 0) {
            // "123.png" → single frame
            bool ok;
            int id = stem.toInt(&ok);
            if (!ok) continue;
            groups[id][-1] = fn;  // -1 标记为单帧
        } else {
            // "123_0.png" → multi-frame
            bool ok1, ok2;
            int id = stem.left(uscore).toInt(&ok1);
            int frame = stem.mid(uscore + 1).toInt(&ok2);
            if (!ok1 || !ok2) continue;
            groups[id][frame] = fn;
        }
    }

    // 如果某个 baseId 同时有单帧 (-1) 和多帧条目, 优先使用单帧
    imz.pngNum = groups.size();
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

    int i = 0;
    for (auto it = groups.constBegin(); it != groups.constEnd(); ++it, ++i) {
        int baseId = it.key();
        const QMap<int, QString> &frames = it.value();
        ImzPng &ip = imz.imzPng[i];
        ip.fileNum = baseId;
        ip.x = 0;
        ip.y = 0;

        if (!indexData.isEmpty() && (i + 1) * 4 <= indexData.size()) {
            const int16_t *p = reinterpret_cast<const int16_t *>(indexData.constData() + i * 4);
            ip.x = p[0];
            ip.y = p[1];
        }

        if (frames.contains(-1)) {
            // 单帧: "{id}.png"
            QFile pngFile(dir.filePath(frames[-1]));
            if (pngFile.open(QIODevice::ReadOnly)) {
                QByteArray pngData = pngFile.readAll();
                ip.frame = 1;
                ip.frameLen = {(int)pngData.size()};
                ip.frameData.resize(1);
                ip.frameData[0].data = pngData;
                ip.len = pngData.size();
            }
        } else {
            // 多帧: "{id}_0.png", "{id}_1.png", ...
            ip.frame = frames.size();
            ip.frameLen.resize(ip.frame);
            ip.frameData.resize(ip.frame);
            ip.len = 0;
            int fi = 0;
            for (auto fit = frames.constBegin(); fit != frames.constEnd(); ++fit, ++fi) {
                QFile pngFile(dir.filePath(fit.value()));
                if (pngFile.open(QIODevice::ReadOnly)) {
                    QByteArray pngData = pngFile.readAll();
                    ip.frameLen[fi] = pngData.size();
                    ip.frameData[fi].data = pngData;
                    ip.len += pngData.size();
                }
            }
        }
    }

    // index.txt 覆盖 (格式 "baseId:x,y")
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
