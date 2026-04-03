#pragma once

/*
 * XLSX I/O 动态加载封装
 * 对应原 Delphi 版 xlsxio.pas
 * 读取: libxlsxio_read.dll   写入: xlsxwriter.dll
 */

#include <QLibrary>
#include <QString>
#include <QVector>
#include <QStringList>
#include <functional>

class XlsxReader {
public:
    XlsxReader();
    ~XlsxReader();

    static bool loadLibrary(const QString &dllPath = "libxlsxio_read");
    bool open(const QString &filename);
    void close();

    bool openSheet(const QString &name = {}, int flags = 0);
    void closeSheet();

    bool nextRow();
    QString nextCell();

    // 便捷: 读取整个表
    QVector<QStringList> readAll(const QString &sheetName = {});

private:
    void *m_reader  = nullptr;
    void *m_sheet   = nullptr;

    static QLibrary s_lib;
    static bool s_loaded;

    using FnOpen        = void *(*)(const char *);
    using FnClose       = void (*)(void *);
    using FnSheetOpen   = void *(*)(void *, const char *, int);
    using FnSheetClose  = void (*)(void *);
    using FnNextRow     = int (*)(void *);
    using FnNextCell    = char *(*)(void *);
    using FnFree        = void (*)(char *);

    static FnOpen       fn_open;
    static FnClose      fn_close;
    static FnSheetOpen  fn_sheet_open;
    static FnSheetClose fn_sheet_close;
    static FnNextRow    fn_next_row;
    static FnNextCell   fn_next_cell;
    static FnFree       fn_free;
};

class XlsxWriter {
public:
    XlsxWriter();
    ~XlsxWriter();

    static bool loadLibrary(const QString &dllPath = "xlsxwriter");
    bool create(const QString &filename);
    void close();

    bool addWorksheet(const QString &name = {});
    void writeString(int row, int col, const QString &value);
    void writeNumber(int row, int col, double value);

private:
    void *m_workbook  = nullptr;
    void *m_worksheet = nullptr;

    static QLibrary s_lib;
    static bool s_loaded;

    using FnNew           = void *(*)(const char *);
    using FnClose         = int (*)(void *);
    using FnAddWorksheet  = void *(*)(void *, const char *);
    using FnWriteString   = int (*)(void *, uint32_t, uint16_t, const char *, void *);
    using FnWriteNumber   = int (*)(void *, uint32_t, uint16_t, double, void *);

    static FnNew           fn_new;
    static FnClose         fn_close;
    static FnAddWorksheet  fn_add_worksheet;
    static FnWriteString   fn_write_string;
    static FnWriteNumber   fn_write_number;
};
