#include "imzdata.h"
#include "ZipFile.h"
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QBuffer>
#include <QImage>
#include <QPainter>
#include <algorithm>
#include <QtEndian>
#include <QTemporaryFile>
#include <QSaveFile>
#include <QTemporaryDir>
#include <QJsonDocument>
#include <QJsonArray>

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
            if (!ok || id < 0 || id > 1000000) continue;
            groups[id][-1] = name;  // -1 = 单帧
        } else {
            bool ok1, ok2;
            int id = stem.left(uscore).toInt(&ok1);
            int frame = stem.mid(uscore + 1).toInt(&ok2);
            if (!ok1 || !ok2 || id < 0 || id > 1000000 || frame < 0) continue;
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

        if (baseId >= 0 && (qint64(baseId) + 1) * 4 <= indexData.size()) {
            const int16_t *p = reinterpret_cast<const int16_t *>(indexData.constData() + baseId * 4);
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
            for (auto &sprite : imz.imzPng)
                if (sprite.fileNum == idx) {
                    sprite.x = coords.left(comma).trimmed().toShort();
                    sprite.y = coords.mid(comma + 1).trimmed().toShort();
                    break;
                }
        }
    }

    return true;
}

bool ImzIO::saveImz(const QString &path, const Imz &imz)
{
    if (imz.pngNum != imz.imzPng.size()) return false;
    QSet<int> ids;
    for (const auto &sprite : imz.imzPng) {
        if (sprite.fileNum < 0 || sprite.fileNum > 1000000 || ids.contains(sprite.fileNum)
            || sprite.frame <= 0 || sprite.frame != sprite.frameData.size()) return false;
        ids.insert(sprite.fileNum);
    }
    QMap<std::string, std::string> metadata;
    if (QFile::exists(path)) {
        ZipFile original;
        original.openRead(path.toLocal8Bit().toStdString());
        if (!original.opened()) return false;
        for (const auto &entry : original.getFileNames()) {
            QString name = QString::fromStdString(entry);
            if (!name.endsWith(".png", Qt::CaseInsensitive) && name != "index.ka" && name != "index.txt")
                metadata.insert(entry, original.readFile(entry));
        }
    }
    QTemporaryFile temporary(QFileInfo(path).absolutePath() + "/upedit-XXXXXX.zip");
    if (!temporary.open()) return false;
    QString temporaryPath = temporary.fileName();
    if (!temporary.remove()) return false;
    ZipFile zip;
    zip.create(temporaryPath.toLocal8Bit().toStdString());
    if (!zip.opened())
        return false;

    // 写入 index.ka
    int maximumId = -1;
    for (const auto &sprite : imz.imzPng) {
        if (sprite.fileNum < 0 || sprite.fileNum > 1000000) return false;
        maximumId = qMax(maximumId, sprite.fileNum);
    }
    QByteArray indexData((maximumId + 1) * 4, '\0');
    for (const auto &sprite : imz.imzPng) {
        qToLittleEndian<qint16>(sprite.x, indexData.data() + sprite.fileNum * 4);
        qToLittleEndian<qint16>(sprite.y, indexData.data() + sprite.fileNum * 4 + 2);
    }
    if (!zip.addData("index.ka", indexData.constData(), indexData.size())) return false;
    for (auto entry = metadata.constBegin(); entry != metadata.constEnd(); ++entry)
        if (!zip.addData(entry.key(), entry.value().data(), int(entry.value().size()))) return false;

    // 写入 PNG 文件
    for (int i = 0; i < imz.pngNum; ++i) {
        const ImzPng &ip = imz.imzPng[i];
        int frameCount = qMin(ip.frame, ip.frameData.size());
        for (int frame = 0; frame < frameCount; ++frame) {
            QString entry = frameCount == 1
                ? QString("%1.png").arg(ip.fileNum)
                : QString("%1_%2.png").arg(ip.fileNum).arg(frame);
            const QByteArray &png = ip.frameData[frame].data;
            if (!zip.addData(entry.toStdString(), png.constData(), png.size())) return false;
        }
    }

    if (!zip.commit()) return false;
    QFile completed(temporaryPath);
    QSaveFile destination(path);
    if (!completed.open(QIODevice::ReadOnly) || !destination.open(QIODevice::WriteOnly)) return false;
    while (!completed.atEnd()) {
        QByteArray block = completed.read(1024 * 1024);
        if (block.isEmpty() && completed.error() != QFile::NoError) return false;
        if (destination.write(block) != block.size()) return false;
    }
    return destination.commit();
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
            if (!ok || id < 0 || id > 1000000) continue;
            groups[id][-1] = fn;  // -1 标记为单帧
        } else {
            // "123_0.png" → multi-frame
            bool ok1, ok2;
            int id = stem.left(uscore).toInt(&ok1);
            int frame = stem.mid(uscore + 1).toInt(&ok2);
            if (!ok1 || !ok2 || id < 0 || id > 1000000 || frame < 0) continue;
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

        if (baseId >= 0 && (qint64(baseId) + 1) * 4 <= indexData.size()) {
            const int16_t *p = reinterpret_cast<const int16_t *>(indexData.constData() + baseId * 4);
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
            for (auto &sprite : imz.imzPng)
                if (sprite.fileNum == idx) {
                    sprite.x = coords.left(comma).trimmed().toShort();
                    sprite.y = coords.mid(comma + 1).trimmed().toShort();
                    break;
                }
        }
    }

    return imz.pngNum > 0;
}

bool ImzIO::saveFolder(const QString &folder, const Imz &imz, const QStringList &previousFiles)
{
    QDir directory(folder);
    if (!directory.mkpath(".")) return false;
    if (imz.pngNum != imz.imzPng.size()) return false;
    QMap<QString, QByteArray> files;
    QSet<int> ids;
    int maximumId = -1;
    for (const auto &sprite : imz.imzPng) {
        if (sprite.fileNum < 0 || sprite.fileNum > 1000000 || ids.contains(sprite.fileNum)
            || sprite.frame <= 0 || sprite.frame != sprite.frameData.size()) return false;
        ids.insert(sprite.fileNum);
        maximumId = qMax(maximumId, sprite.fileNum);
        for (int frame = 0; frame < sprite.frame; ++frame) {
            const QByteArray &bytes = sprite.frameData[frame].data;
            if (QImage::fromData(bytes, "PNG").isNull()) return false;
            files.insert(sprite.frame == 1 ? QString("%1.png").arg(sprite.fileNum)
                : QString("%1_%2.png").arg(sprite.fileNum).arg(frame), bytes);
        }
    }
    QByteArray index((maximumId + 1) * 4, '\0');
    for (const auto &sprite : imz.imzPng) {
        qToLittleEndian<qint16>(sprite.x, index.data() + sprite.fileNum * 4);
        qToLittleEndian<qint16>(sprite.y, index.data() + sprite.fileNum * 4 + 2);
    }
    const QString manifestName = ".upedit-images.json";
    QSet<QString> affected;
    for (const QString &name : previousFiles) {
        if (name.isEmpty() || name != QFileInfo(name).fileName() || name.contains('/') || name.contains('\\')
            || !name.endsWith(".png", Qt::CaseInsensitive)) return false;
        affected.insert(name);
    }
    QFile manifest(directory.filePath(manifestName));
    if (manifest.exists()) {
        if (!manifest.open(QIODevice::ReadOnly)) return false;
        QJsonParseError error;
        QJsonDocument document = QJsonDocument::fromJson(manifest.readAll(), &error);
        if (error.error != QJsonParseError::NoError || !document.isArray()) return false;
        for (const auto &entry : document.array()) {
            QString name = entry.toString();
            if (name.isEmpty() || name != QFileInfo(name).fileName() || name.contains('/') || name.contains('\\')
                || !name.endsWith(".png", Qt::CaseInsensitive)) return false;
            affected.insert(name);
        }
        manifest.close();
    }
    QJsonArray owned;
    for (auto entry = files.constBegin(); entry != files.constEnd(); ++entry) {
        owned.append(entry.key());
        affected.insert(entry.key());
    }
    files.insert("index.ka", index);
    files.insert(manifestName, QJsonDocument(owned).toJson(QJsonDocument::Compact));
    affected.unite({"index.ka", "index.txt", manifestName});
    QTemporaryDir transaction(directory.absoluteFilePath(".upedit-save-XXXXXX"));
    if (!transaction.isValid()) return false;
    QDir staging(transaction.path());
    if (!staging.mkdir("new") || !staging.mkdir("old")) return false;
    for (auto entry = files.constBegin(); entry != files.constEnd(); ++entry) {
        QFile staged(staging.filePath("new/" + entry.key()));
        if (!staged.open(QIODevice::WriteOnly) || staged.write(entry.value()) != entry.value().size() || !staged.flush()) return false;
    }
    for (const QString &name : affected) {
        QFileInfo target(directory.filePath(name));
        if (target.isSymLink() || (target.exists() && !target.isFile())) return false;
    }
    QStringList backedUp, installed;
    auto rollback = [&] {
        bool restored = true;
        for (const QString &name : installed) restored = QFile::remove(directory.filePath(name)) && restored;
        for (const QString &name : backedUp)
            restored = QFile::rename(staging.filePath("old/" + name), directory.filePath(name)) && restored;
        if (!restored) transaction.setAutoRemove(false);
        return false;
    };
    for (const QString &name : affected) {
        if (!QFile::exists(directory.filePath(name))) continue;
        if (!QFile::rename(directory.filePath(name), staging.filePath("old/" + name))) return rollback();
        backedUp.append(name);
    }
    for (auto entry = files.constBegin(); entry != files.constEnd(); ++entry) {
        if (!QFile::rename(staging.filePath("new/" + entry.key()), directory.filePath(entry.key()))) return rollback();
        installed.append(entry.key());
    }
    return true;
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
