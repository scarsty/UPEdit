#include "encoding.h"
#include <QTextCodec>

int Encoding::dataCode    = 1; // 默认 BIG5
int Encoding::talkCode    = 1;
int Encoding::talkInvert  = 0;
int Encoding::language    = 0;

static QTextCodec *codecForCode(int code)
{
    switch (code) {
    case 0: return QTextCodec::codecForName("GBK");
    case 1: return QTextCodec::codecForName("Big5");
    case 3: return QTextCodec::codecForName("UTF-8");
    default: return nullptr; // UTF-16LE 需特殊处理
    }
}

QString Encoding::readOutStr(const void *data, int len)
{
    return readOutStrWithCode(data, len, dataCode);
}

QString Encoding::readOutStrWithCode(const void *data, int len, int code)
{
    if (!data || len <= 0)
        return {};

    if (code == 2) {
        // UTF-16LE
        int charCount = len / 2;
        const char16_t *u16 = reinterpret_cast<const char16_t *>(data);
        QString result;
        for (int i = 0; i < charCount; ++i) {
            if (u16[i] == 0) break;
            result.append(QChar(u16[i]));
        }
        return result;
    }

    QTextCodec *codec = codecForCode(code);
    if (!codec)
        return {};

    QByteArray ba(reinterpret_cast<const char *>(data), len);
    // 截断到第一个 \0
    int nul = ba.indexOf('\0');
    if (nul >= 0) ba.truncate(nul);
    return codec->toUnicode(ba);
}

void Encoding::writeInStr(const QString &str, void *data, int len)
{
    writeInStrWithCode(str, data, len, dataCode);
}

void Encoding::writeInStrWithCode(const QString &str, void *data, int len, int code)
{
    if (!data || len <= 0)
        return;

    memset(data, 0, len);

    if (code == 2) {
        // UTF-16LE
        const ushort *u16 = str.utf16();
        int bytes = qMin(static_cast<int>(str.size() * 2), len);
        memcpy(data, u16, bytes);
        return;
    }

    QTextCodec *codec = codecForCode(code);
    if (!codec) return;

    QByteArray encoded = codec->fromUnicode(str);
    int copyLen = qMin(encoded.size(), len);
    memcpy(data, encoded.constData(), copyLen);
}

QString Encoding::traditionalToSimplified(const QString &s)
{
#ifdef Q_OS_WIN
    // Windows: 使用 LCMapString 转简
    std::wstring ws = s.toStdWString();
    std::wstring result(ws.size(), L'\0');
    extern int __stdcall LCMapStringW(unsigned int, unsigned int, const wchar_t *, int, wchar_t *, int);
    LCMapStringW(0x0804, 0x02000000, ws.c_str(), ws.size(), &result[0], result.size());
    return QString::fromStdWString(result);
#else
    return s;
#endif
}

QString Encoding::simplifiedToTraditional(const QString &s)
{
#ifdef Q_OS_WIN
    std::wstring ws = s.toStdWString();
    std::wstring result(ws.size(), L'\0');
    extern int __stdcall LCMapStringW(unsigned int, unsigned int, const wchar_t *, int, wchar_t *, int);
    LCMapStringW(0x0804, 0x04000000, ws.c_str(), ws.size(), &result[0], result.size());
    return QString::fromStdWString(result);
#else
    return s;
#endif
}

QString Encoding::displayStr(const QString &s)
{
    return s;
}

QString Encoding::displayName(const QString &s)
{
    return displayStr(s);
}

QString Encoding::displayBackStr(const QString &s)
{
    return s;
}
