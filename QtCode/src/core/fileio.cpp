#include "fileio.h"
#include <QFile>
#include <QCryptographicHash>
#include <QCoreApplication>
#include <QSaveFile>
#include <QTemporaryFile>
#include <QFileInfo>
#include <QDir>
#include <QSet>
#include <cstring>

#ifdef Q_OS_WIN
#include <windows.h>
#pragma comment(lib, "version.lib")
#endif

QByteArray FileIO::readFileAll(const QString &filename)
{
    QFile f(filename);
    if (!f.open(QIODevice::ReadOnly))
        return {};
    return f.readAll();
}

bool FileIO::writeFileAll(const QString &filename, const QByteArray &data)
{
    QSaveFile f(filename);
    if (!f.open(QIODevice::WriteOnly))
        return false;
    return f.write(data) == data.size() && f.commit();
}

bool FileIO::writeFiles(const QMap<QString, QByteArray> &files)
{
    struct Pending { QString target, staged, backup; bool existed = false, installed = false; };
    QVector<Pending> pending;
    QSet<QString> targets;
    auto cleanup = [&](bool rollback) {
        for (auto &file : pending) {
            if (rollback && file.installed) QFile::remove(file.target);
            if (!file.staged.isEmpty()) QFile::remove(file.staged);
            if (!file.backup.isEmpty()) {
                if (rollback) QFile::rename(file.backup, file.target);
                else QFile::remove(file.backup);
            }
        }
    };
    for (auto entry = files.constBegin(); entry != files.constEnd(); ++entry) {
        QFileInfo info(entry.key());
        QString target = info.absoluteFilePath();
        QString key = target;
#ifdef Q_OS_WIN
        key = key.toCaseFolded();
#endif
        if (targets.contains(key) || info.isSymLink() || (info.exists() && !info.isFile())) { cleanup(true); return false; }
        targets.insert(key);
        QTemporaryFile staged(info.dir().filePath(".upedit-new-XXXXXX"));
        if (!staged.open() || staged.write(entry.value()) != entry.value().size() || !staged.flush()) { cleanup(true); return false; }
        staged.setAutoRemove(false);
        pending.append({target, staged.fileName(), {}, info.exists(), false});
    }
    for (auto &file : pending) {
        if (!file.existed) continue;
        QTemporaryFile backup(QFileInfo(file.target).dir().filePath(".upedit-old-XXXXXX"));
        if (!backup.open()) { cleanup(true); return false; }
        QString name = backup.fileName();
        backup.close();
        backup.remove();
        if (!QFile::rename(file.target, name)) { cleanup(true); return false; }
        file.backup = name;
    }
    for (auto &file : pending) {
        if (!QFile::rename(file.staged, file.target)) { cleanup(true); return false; }
        file.installed = true;
        file.staged.clear();
    }
    cleanup(false);
    return true;
}

QString FileIO::hashFile(const QString &filename)
{
    QFile f(filename);
    if (!f.open(QIODevice::ReadOnly))
        return {};
    QCryptographicHash hash(QCryptographicHash::Md5);
    hash.addData(&f);
    return hash.result().toHex().toUpper();
}

QString FileIO::hashMyself()
{
    return hashFile(QCoreApplication::applicationFilePath());
}

bool FileIO::isPNG(const void *data)
{
    if (!data) return false;
    const uint8_t *p = static_cast<const uint8_t *>(data);
    // PNG 签名: 89 50 4E 47 0D 0A 1A 0A
    return p[0] == 0x89 && p[1] == 0x50 && p[2] == 0x4E && p[3] == 0x47
        && p[4] == 0x0D && p[5] == 0x0A && p[6] == 0x1A && p[7] == 0x0A;
}

QString FileIO::fileVersion(const QString &filename)
{
#ifdef Q_OS_WIN
    std::wstring wpath = filename.toStdWString();
    DWORD dummy;
    DWORD size = GetFileVersionInfoSizeW(wpath.c_str(), &dummy);
    if (size == 0) return {};

    QByteArray buf(size, 0);
    if (!GetFileVersionInfoW(wpath.c_str(), 0, size, buf.data()))
        return {};

    VS_FIXEDFILEINFO *pInfo = nullptr;
    UINT infoLen = 0;
    if (!VerQueryValueW(buf.data(), L"\\", reinterpret_cast<void **>(&pInfo), &infoLen))
        return {};

    return QString("%1.%2.%3.%4")
        .arg(HIWORD(pInfo->dwFileVersionMS))
        .arg(LOWORD(pInfo->dwFileVersionMS))
        .arg(HIWORD(pInfo->dwFileVersionLS))
        .arg(LOWORD(pInfo->dwFileVersionLS));
#else
    Q_UNUSED(filename);
    return {};
#endif
}
