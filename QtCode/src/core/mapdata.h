#pragma once

/*
 * 地图数据读写
 * 对应原 Delphi 版中场景地图/主地图/战斗地图的二进制读写
 */

#include "head.h"
#include <QString>

namespace MapIO {
    // 从 idx+grp 读取地图结构
    bool readMap(const QString &idxFile, const QString &grpFile, MapStruct &ms);
    // 保存地图
    void saveMap(const QString &idxFile, const QString &grpFile, const MapStruct &ms);

    // 读取单个地图数据（给定偏移和层数/尺寸）
    bool readSingleMap(const QByteArray &data, int offset, Map &m, int layerNum, int width, int height);

    // 读取调色板 (256 色 RGB)
    void readPalette(const QString &filename, uint8_t r[256], uint8_t g[256], uint8_t b[256]);
}
