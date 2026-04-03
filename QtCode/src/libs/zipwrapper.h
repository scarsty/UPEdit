#pragma once

/*
 * libzip 动态加载封装
 * 对应原 Delphi 版 libzip.pas
 */

#include <QLibrary>
#include <QString>
#include <QByteArray>
#include <QStringList>

class ZipWrapper {
public:
    enum OpenMode { ReadOnly = 16, Create = 1, Truncate = 8 };

    ZipWrapper();
    ~ZipWrapper();

    static bool loadLibrary(const QString &dllPath = "zip");
    static bool isLibraryLoaded();

    bool open(const QString &filename, int mode = ReadOnly);
    void close();
    bool isOpen() const { return m_zip != nullptr; }

    // 获取所有条目名称
    QStringList entryNames() const;
    // 获取条目数量
    int entryCount() const;

    // 读取条目
    QByteArray readEntry(const QString &name) const;
    QByteArray readEntry(int index) const;

    // 获取条目大小
    int entrySize(const QString &name) const;

    // 添加条目
    bool addEntry(const QString &name, const QByteArray &data);

    // 查找条目索引
    int findEntry(const QString &name) const;

private:
    void *m_zip = nullptr; // zip_t*

    static QLibrary s_lib;
    static bool s_loaded;

    // 函数指针
    using FnOpen       = void *(*)(const char *, int, int *);
    using FnClose      = int (*)(void *);
    using FnGetNumEntries = int64_t (*)(void *, int);
    using FnGetName    = const char *(*)(void *, int64_t, int);
    using FnNameLocate = int64_t (*)(void *, const char *, int);
    using FnFopen      = void *(*)(void *, const char *, int);
    using FnFopenIndex = void *(*)(void *, int64_t, int);
    using FnFread      = int64_t (*)(void *, void *, uint64_t);
    using FnFclose     = int (*)(void *);
    using FnStatIndex  = int (*)(void *, int64_t, void *, int);
    using FnSourceBuffer = void *(*)(void *, const void *, uint64_t, int);
    using FnFileAdd    = int64_t (*)(void *, const char *, void *, int);
    using FnSetCompression = int (*)(void *, int64_t, uint16_t, uint32_t);

    static FnOpen       fn_open;
    static FnClose      fn_close;
    static FnGetNumEntries fn_get_num_entries;
    static FnGetName    fn_get_name;
    static FnNameLocate fn_name_locate;
    static FnFopen      fn_fopen;
    static FnFopenIndex fn_fopen_index;
    static FnFread      fn_fread;
    static FnFclose     fn_fclose;
    static FnStatIndex  fn_stat_index;
    static FnSourceBuffer fn_source_buffer;
    static FnFileAdd    fn_file_add;
    static FnSetCompression fn_set_file_compression;
};
