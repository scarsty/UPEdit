#pragma once

/*
 * IMZ (精灵容器) 数据读写
 * 对应原 Delphi 版 ImzObject.pas 和 imagez.pas
 * IMZ 格式本质上是一个 ZIP 包，内含多帧 PNG 图片和 index.ka 偏移文件
 */

#include "head.h"
#include <QString>
#include <QImage>

namespace ImzIO {
    // 从文件读取 IMZ（自动判断 .imz / 文件夹）
    bool readImz(const QString &path, Imz &imz);
    // 保存 IMZ 到 ZIP 文件
    bool saveImz(const QString &path, const Imz &imz);
    // 从文件夹读取 IMZ 散文件
    bool readImzFromFolder(const QString &folder, Imz &imz);

    // 将 ImzPng 中指定帧绘制到 QImage
    void drawImzPngToImage(QImage &target, const ImzPng &png, int frameIndex, int x, int y);
    // 深拷贝
    void copyImzPng(ImzPng &dest, const ImzPng &src);
    // 解析 PNG 二进制数据为 PNGBuf (BGRA)
    bool decodePngToBuf(const QByteArray &pngData, PNGBuf &buf);
    // 从 QImage 编码回 PNG 字节
    QByteArray encodePng(const QImage &img);
}
