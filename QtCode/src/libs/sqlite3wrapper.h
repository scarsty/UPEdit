#pragma once

/*
 * SQLite3 动态加载封装
 * 对应原 Delphi 版 SQLite3.pas / SQLite3Wrap.pas
 */

#include <QLibrary>
#include <QString>
#include <QByteArray>
#include <QVector>
#include <functional>

struct sqlite3;
struct sqlite3_stmt;

class SQLite3Statement;

class SQLite3Database {
public:
    SQLite3Database();
    ~SQLite3Database();

    static bool loadLibrary(const QString &dllPath = "sqlite3");
    static bool isLibraryLoaded();

    bool open(const QString &filename, int flags = 0);
    void close();
    bool isOpen() const { return m_db != nullptr; }

    void execute(const QString &sql);
    int64_t lastInsertRowID();
    SQLite3Statement prepare(const QString &sql);

    void beginTransaction();
    void commit();
    void rollback();

    sqlite3 *handle() const { return m_db; }

private:
    sqlite3 *m_db = nullptr;
    static QLibrary s_lib;
    static bool s_loaded;

public:
    // 内部函数指针 (静态)
    static decltype(nullptr) (*fn_open)(const char *, sqlite3 **);
    static int (*fn_open_v2)(const char *, sqlite3 **, int, const char *);
    static int (*fn_close)(sqlite3 *);
    static int (*fn_exec)(sqlite3 *, const char *, void *, void *, char **);
    static int64_t (*fn_last_insert_rowid)(sqlite3 *);
    static int (*fn_prepare_v2)(sqlite3 *, const char *, int, sqlite3_stmt **, const char **);
    static int (*fn_step)(sqlite3_stmt *);
    static int (*fn_reset)(sqlite3_stmt *);
    static int (*fn_finalize)(sqlite3_stmt *);
    static int (*fn_column_count)(sqlite3_stmt *);
    static int (*fn_column_type)(sqlite3_stmt *, int);
    static int (*fn_column_int)(sqlite3_stmt *, int);
    static int64_t (*fn_column_int64)(sqlite3_stmt *, int);
    static double (*fn_column_double)(sqlite3_stmt *, int);
    static const unsigned char *(*fn_column_text)(sqlite3_stmt *, int);
    static const void *(*fn_column_blob)(sqlite3_stmt *, int);
    static int (*fn_column_bytes)(sqlite3_stmt *, int);
    static const char *(*fn_column_name)(sqlite3_stmt *, int);
    static int (*fn_bind_int)(sqlite3_stmt *, int, int);
    static int (*fn_bind_int64)(sqlite3_stmt *, int, int64_t);
    static int (*fn_bind_text)(sqlite3_stmt *, int, const char *, int, void (*)(void *));
    static int (*fn_bind_blob)(sqlite3_stmt *, int, const void *, int, void (*)(void *));
    static int (*fn_bind_null)(sqlite3_stmt *, int);
    static int (*fn_clear_bindings)(sqlite3_stmt *);
    static const char *(*fn_errmsg)(sqlite3 *);
};

class SQLite3Statement {
public:
    SQLite3Statement() = default;
    SQLite3Statement(sqlite3_stmt *stmt) : m_stmt(stmt) {}
    ~SQLite3Statement();

    SQLite3Statement(SQLite3Statement &&other) noexcept;
    SQLite3Statement &operator=(SQLite3Statement &&other) noexcept;
    SQLite3Statement(const SQLite3Statement &) = delete;
    SQLite3Statement &operator=(const SQLite3Statement &) = delete;

    bool isValid() const { return m_stmt != nullptr; }

    // 绑定参数 (1-indexed)
    void bindInt(int index, int value);
    void bindInt64(int index, int64_t value);
    void bindText(int index, const QString &value);
    void bindBlob(int index, const void *data, int size);
    void bindNull(int index);
    void clearBindings();

    // 执行
    int step();       // 返回 SQLITE_ROW(100) 或 SQLITE_DONE(101)
    void reset();
    int stepAndReset();

    // 列读取 (0-indexed)
    int columnCount();
    int columnType(int index);
    int columnInt(int index);
    int64_t columnInt64(int index);
    QString columnText(int index);
    QByteArray columnBlob(int index);
    int columnBytes(int index);
    QString columnName(int index);

    void finalize();

    static constexpr int SQLITE_ROW  = 100;
    static constexpr int SQLITE_DONE = 101;

private:
    sqlite3_stmt *m_stmt = nullptr;
};
