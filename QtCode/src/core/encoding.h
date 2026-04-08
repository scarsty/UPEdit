#pragma once

/*
 * 编码转换模块
 * 对应原 Delphi 版 head.pas 中的 readOutstr / writeinstr / MultiToUnicode 等
 */

#include <QString>
#include <QByteArray>
#include <cstdint>

class Encoding {
public:
    // 当前数据编码 (0=GBK, 1=BIG5, 2=UTF16LE, 3=UTF8)
    static int dataCode;
    static int talkCode;
    static int talkInvert;
    static int language;

    // 将游戏数据中的原始字节按 dataCode 解码为 QString
    static QString readOutStr(const void *data, int len);

    // 将 QString 编码回游戏数据格式，写入 data 指向的缓冲区 (最多 len 字节)
    static void writeInStr(const QString &str, void *data, int len);
    static int encodedByteLength(const QString &str);

    // 有指定编码的版本
    static QString readOutStrWithCode(const void *data, int len, int code);
    static void writeInStrWithCode(const QString &str, void *data, int len, int code);
    static int encodedByteLengthWithCode(const QString &str, int code);

    // 繁简转换
    static QString traditionalToSimplified(const QString &s);
    static QString simplifiedToTraditional(const QString &s);

    // 显示用
    static QString displayStr(const QString &s);
    static QString displayName(const QString &s);
    static QString displayBackStr(const QString &s);
};
