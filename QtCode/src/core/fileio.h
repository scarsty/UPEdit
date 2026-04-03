#pragma once

/*
 * 基础文件读写工具
 * 对应原 Delphi 版中二进制文件操作、MD5 计算等
 */

#include <QString>
#include <QByteArray>

namespace FileIO {
    // 读取整个文件到字节数组
    QByteArray readFileAll(const QString &filename);
    // 写入整个字节数组到文件
    bool writeFileAll(const QString &filename, const QByteArray &data);

    // 文件 MD5 哈希
    QString hashFile(const QString &filename);
    // 当前可执行文件 MD5
    QString hashMyself();

    // 检测 PNG 头部签名
    bool isPNG(const void *data);

    // 获取文件版本信息 (Windows)
    QString fileVersion(const QString &filename);
}
