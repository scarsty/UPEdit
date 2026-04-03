#pragma once

/*
 * GRP 图片组数据读写
 * 对应原 Delphi 版 grplist.pas / grpedit.pas 中的精灵组二进制格式
 * GRP 格式: .idx 文件包含偏移/大小, .grp 文件包含 RLE 或 PNG 像素数据
 */

#include "head.h"
#include <QString>
#include <QImage>

namespace GrpIO {
    // 从 idx+grp 读取所有精灵
    bool readGrp(const QString &idxFile, const QString &grpFile, QVector<GrpPic> &pics);
    // 保存精灵组到 idx+grp
    void saveGrp(const QString &idxFile, const QString &grpFile, const QVector<GrpPic> &pics);

    // 将 RLE 编码的精灵解码为 QImage (需要调色板)
    QImage decodeRLE(const GrpPic &pic, const uint8_t r[256], const uint8_t g[256], const uint8_t b[256]);

    // 将 32 位 QImage 编码为 RLE 精灵数据
    GrpPic encodeRLE(const QImage &img, const uint8_t r[256], const uint8_t g[256], const uint8_t b[256]);

    // 判断精灵数据是否为 PNG
    bool isPNG(const GrpPic &pic);
    // 将 PNG 数据解码为 QImage
    QImage decodePNG(const GrpPic &pic);
}
