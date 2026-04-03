#pragma once

/*
 * KDEF 事件数据读写
 * 对应原 Delphi 版 KDEFedit.pas 中的事件/指令二进制格式
 */

#include "head.h"
#include <QString>

namespace EventIO {
    // 从 idx+grp 读取事件数据
    bool readEvents(const QString &idxFile, const QString &grpFile, DFile &dfile);
    // 保存事件数据
    void saveEvents(const QString &idxFile, const QString &grpFile, const DFile &dfile);

    // 从 INI 读取 KDEF 配置
    void readKDEFIni(const QString &iniPath, KDEFIni &kdefIni);

    // 从 INI 读取 D 文件配置
    void readDIni(const QString &iniPath, DIni &dini);

    // 解析事件二进制
    Event parseEvent(const QByteArray &data);
    // 编码事件为二进制
    QByteArray encodeEvent(const Event &evt);
}
