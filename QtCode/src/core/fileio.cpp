#include "fileio.h"
#include <QFile>
#include <QCryptographicHash>
#include <QCoreApplication>
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
    QFile f(filename);
    if (!f.open(QIODevice::WriteOnly | QIODevice::Truncate))
        return false;
    return f.write(data) == data.size();
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
