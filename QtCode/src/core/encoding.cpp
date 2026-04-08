#include "encoding.h"
#include "PotConv.h"
#include <cstring>

int Encoding::dataCode    = 1; // 默认 BIG5
int Encoding::talkCode    = 1;
int Encoding::talkInvert  = 0;
int Encoding::language    = 0;

static const char *iconvNameForCode(int code)
{
    switch (code) {
    case 0: return "cp936";
    case 1: return "cp950";
    case 3: return "utf-8";
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

    const char *encName = iconvNameForCode(code);
    if (!encName)
        return {};

    // 截断到第一个 \0
    const char *raw = reinterpret_cast<const char *>(data);
    int actualLen = 0;
    while (actualLen < len && raw[actualLen] != '\0')
        ++actualLen;
    if (actualLen == 0)
        return {};

    std::string src(raw, actualLen);
    std::string utf8 = PotConv::conv(src, encName, "utf-8");
    return QString::fromUtf8(utf8.c_str(), static_cast<int>(utf8.size()));
}

void Encoding::writeInStr(const QString &str, void *data, int len)
{
    writeInStrWithCode(str, data, len, dataCode);
}

int Encoding::encodedByteLength(const QString &str)
{
    return encodedByteLengthWithCode(str, dataCode);
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

    const char *encName = iconvNameForCode(code);
    if (!encName) return;

    std::string utf8 = str.toUtf8().toStdString();
    std::string encoded = PotConv::conv(utf8, "utf-8", encName);
    int copyLen = qMin(static_cast<int>(encoded.size()), len);
    memcpy(data, encoded.c_str(), copyLen);
}

int Encoding::encodedByteLengthWithCode(const QString &str, int code)
{
    if (str.isEmpty())
        return 0;

    if (code == 2)
        return str.size() * 2;

    const char *encName = iconvNameForCode(code);
    if (!encName)
        return 0;

    std::string utf8 = str.toUtf8().toStdString();
    std::string encoded = PotConv::conv(utf8, "utf-8", encName);
    return static_cast<int>(encoded.size());
}

QString Encoding::traditionalToSimplified(const QString &s)
{
    // 通过 cp950 → cp936 转码实现繁→简（近似转换）
    std::string utf8 = s.toUtf8().toStdString();
    std::string cp950 = PotConv::conv(utf8, "utf-8", "cp950");
    std::string cp936 = PotConv::conv(cp950, "cp950", "cp936");
    std::string result = PotConv::conv(cp936, "cp936", "utf-8");
    return QString::fromUtf8(result.c_str(), static_cast<int>(result.size()));
}

QString Encoding::simplifiedToTraditional(const QString &s)
{
    std::string utf8 = s.toUtf8().toStdString();
    std::string cp936 = PotConv::conv(utf8, "utf-8", "cp936");
    std::string cp950 = PotConv::conv(cp936, "cp936", "cp950");
    std::string result = PotConv::conv(cp950, "cp950", "utf-8");
    return QString::fromUtf8(result.c_str(), static_cast<int>(result.size()));
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
