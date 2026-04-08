#include "sqlite3wrapper.h"

// 静态成员定义
QLibrary SQLite3Database::s_lib;
bool SQLite3Database::s_loaded = false;

decltype(nullptr) (*SQLite3Database::fn_open)(const char *, sqlite3 **) = nullptr;
int (*SQLite3Database::fn_open_v2)(const char *, sqlite3 **, int, const char *) = nullptr;
int (*SQLite3Database::fn_close)(sqlite3 *) = nullptr;
int (*SQLite3Database::fn_exec)(sqlite3 *, const char *, void *, void *, char **) = nullptr;
int64_t (*SQLite3Database::fn_last_insert_rowid)(sqlite3 *) = nullptr;
int (*SQLite3Database::fn_prepare_v2)(sqlite3 *, const char *, int, sqlite3_stmt **, const char **) = nullptr;
int (*SQLite3Database::fn_step)(sqlite3_stmt *) = nullptr;
int (*SQLite3Database::fn_reset)(sqlite3_stmt *) = nullptr;
int (*SQLite3Database::fn_finalize)(sqlite3_stmt *) = nullptr;
int (*SQLite3Database::fn_column_count)(sqlite3_stmt *) = nullptr;
int (*SQLite3Database::fn_column_type)(sqlite3_stmt *, int) = nullptr;
int (*SQLite3Database::fn_column_int)(sqlite3_stmt *, int) = nullptr;
int64_t (*SQLite3Database::fn_column_int64)(sqlite3_stmt *, int) = nullptr;
double (*SQLite3Database::fn_column_double)(sqlite3_stmt *, int) = nullptr;
const unsigned char *(*SQLite3Database::fn_column_text)(sqlite3_stmt *, int) = nullptr;
const void *(*SQLite3Database::fn_column_blob)(sqlite3_stmt *, int) = nullptr;
int (*SQLite3Database::fn_column_bytes)(sqlite3_stmt *, int) = nullptr;
const char *(*SQLite3Database::fn_column_name)(sqlite3_stmt *, int) = nullptr;
int (*SQLite3Database::fn_bind_int)(sqlite3_stmt *, int, int) = nullptr;
int (*SQLite3Database::fn_bind_int64)(sqlite3_stmt *, int, int64_t) = nullptr;
int (*SQLite3Database::fn_bind_text)(sqlite3_stmt *, int, const char *, int, void (*)(void *)) = nullptr;
int (*SQLite3Database::fn_bind_blob)(sqlite3_stmt *, int, const void *, int, void (*)(void *)) = nullptr;
int (*SQLite3Database::fn_bind_null)(sqlite3_stmt *, int) = nullptr;
int (*SQLite3Database::fn_clear_bindings)(sqlite3_stmt *) = nullptr;
const char *(*SQLite3Database::fn_errmsg)(sqlite3 *) = nullptr;

#define RESOLVE(name) reinterpret_cast<decltype(fn_##name)>(s_lib.resolve("sqlite3_" #name))

bool SQLite3Database::loadLibrary(const QString &dllPath)
{
    if (s_loaded) return true;
    s_lib.setFileName(dllPath);
    if (!s_lib.load()) return false;

    fn_open_v2          = reinterpret_cast<decltype(fn_open_v2)>(s_lib.resolve("sqlite3_open_v2"));
    fn_close            = RESOLVE(close);
    fn_exec             = reinterpret_cast<decltype(fn_exec)>(s_lib.resolve("sqlite3_exec"));
    fn_last_insert_rowid = RESOLVE(last_insert_rowid);
    fn_prepare_v2       = RESOLVE(prepare_v2);
    fn_step             = RESOLVE(step);
    fn_reset            = RESOLVE(reset);
    fn_finalize         = RESOLVE(finalize);
    fn_column_count     = RESOLVE(column_count);
    fn_column_type      = RESOLVE(column_type);
    fn_column_int       = RESOLVE(column_int);
    fn_column_int64     = RESOLVE(column_int64);
    fn_column_double    = RESOLVE(column_double);
    fn_column_text      = RESOLVE(column_text);
    fn_column_blob      = RESOLVE(column_blob);
    fn_column_bytes     = RESOLVE(column_bytes);
    fn_column_name      = RESOLVE(column_name);
    fn_bind_int         = RESOLVE(bind_int);
    fn_bind_int64       = RESOLVE(bind_int64);
    fn_bind_text        = RESOLVE(bind_text);
    fn_bind_blob        = RESOLVE(bind_blob);
    fn_bind_null        = RESOLVE(bind_null);
    fn_clear_bindings   = RESOLVE(clear_bindings);
    fn_errmsg           = RESOLVE(errmsg);

    s_loaded = (fn_open_v2 && fn_close && fn_prepare_v2);
    return s_loaded;
}

bool SQLite3Database::isLibraryLoaded() { return s_loaded; }

SQLite3Database::SQLite3Database() {}
SQLite3Database::~SQLite3Database() { close(); }

bool SQLite3Database::open(const QString &filename, int flags)
{
    if (!s_loaded) return false;
    close();
    QByteArray utf8 = filename.toUtf8();
    if (flags == 0) flags = 0x00000002 | 0x00000004; // READWRITE | CREATE
    return fn_open_v2(utf8.constData(), &m_db, flags, nullptr) == 0;
}

void SQLite3Database::close()
{
    if (m_db && fn_close) { fn_close(m_db); m_db = nullptr; }
}

void SQLite3Database::execute(const QString &sql)
{
    if (!m_db || !fn_exec) return;
    QByteArray utf8 = sql.toUtf8();
    fn_exec(m_db, utf8.constData(), nullptr, nullptr, nullptr);
}

int64_t SQLite3Database::lastInsertRowID()
{
    return (m_db && fn_last_insert_rowid) ? fn_last_insert_rowid(m_db) : 0;
}

SQLite3Statement SQLite3Database::prepare(const QString &sql)
{
    if (!m_db || !fn_prepare_v2) return {};
    sqlite3_stmt *stmt = nullptr;
    QByteArray utf8 = sql.toUtf8();
    fn_prepare_v2(m_db, utf8.constData(), utf8.size(), &stmt, nullptr);
    return SQLite3Statement(stmt);
}

void SQLite3Database::beginTransaction() { execute("BEGIN TRANSACTION"); }
void SQLite3Database::commit()           { execute("COMMIT"); }
void SQLite3Database::rollback()         { execute("ROLLBACK"); }

// ── SQLite3Statement ────────────────────────────────────

SQLite3Statement::~SQLite3Statement() { finalize(); }

SQLite3Statement::SQLite3Statement(SQLite3Statement &&other) noexcept
    : m_stmt(other.m_stmt) { other.m_stmt = nullptr; }

SQLite3Statement &SQLite3Statement::operator=(SQLite3Statement &&other) noexcept
{
    if (this != &other) { finalize(); m_stmt = other.m_stmt; other.m_stmt = nullptr; }
    return *this;
}

void SQLite3Statement::finalize()
{
    if (m_stmt && SQLite3Database::fn_finalize) {
        SQLite3Database::fn_finalize(m_stmt);
        m_stmt = nullptr;
    }
}

void SQLite3Statement::bindInt(int i, int v)     { if (m_stmt && SQLite3Database::fn_bind_int) SQLite3Database::fn_bind_int(m_stmt, i, v); }
void SQLite3Statement::bindInt64(int i, int64_t v) { if (m_stmt && SQLite3Database::fn_bind_int64) SQLite3Database::fn_bind_int64(m_stmt, i, v); }

void SQLite3Statement::bindText(int i, const QString &v)
{
    if (!m_stmt || !SQLite3Database::fn_bind_text) return;
    QByteArray utf8 = v.toUtf8();
    // SQLITE_TRANSIENT = -1 → 让 SQLite 复制
    SQLite3Database::fn_bind_text(m_stmt, i, utf8.constData(), utf8.size(),
                                  reinterpret_cast<void (*)(void *)>(-1));
}

void SQLite3Statement::bindBlob(int i, const void *data, int size)
{
    if (m_stmt && SQLite3Database::fn_bind_blob)
        SQLite3Database::fn_bind_blob(m_stmt, i, data, size, reinterpret_cast<void (*)(void *)>(-1));
}

void SQLite3Statement::bindNull(int i) { if (m_stmt && SQLite3Database::fn_bind_null) SQLite3Database::fn_bind_null(m_stmt, i); }

void SQLite3Statement::clearBindings()
{
    if (m_stmt && SQLite3Database::fn_clear_bindings) SQLite3Database::fn_clear_bindings(m_stmt);
}

int SQLite3Statement::step()  { return (m_stmt && SQLite3Database::fn_step)  ? SQLite3Database::fn_step(m_stmt)  : -1; }
void SQLite3Statement::reset() { if (m_stmt && SQLite3Database::fn_reset) SQLite3Database::fn_reset(m_stmt); }

int SQLite3Statement::stepAndReset()
{
    int r = step();
    reset();
    return r;
}

int SQLite3Statement::columnCount() { return (m_stmt && SQLite3Database::fn_column_count) ? SQLite3Database::fn_column_count(m_stmt) : 0; }
int SQLite3Statement::columnType(int i) { return (m_stmt && SQLite3Database::fn_column_type) ? SQLite3Database::fn_column_type(m_stmt, i) : 0; }
int SQLite3Statement::columnInt(int i) { return (m_stmt && SQLite3Database::fn_column_int) ? SQLite3Database::fn_column_int(m_stmt, i) : 0; }
int64_t SQLite3Statement::columnInt64(int i) { return (m_stmt && SQLite3Database::fn_column_int64) ? SQLite3Database::fn_column_int64(m_stmt, i) : 0; }

QString SQLite3Statement::columnText(int i)
{
    if (!m_stmt || !SQLite3Database::fn_column_text || !SQLite3Database::fn_column_bytes) return {};
    const unsigned char *p = SQLite3Database::fn_column_text(m_stmt, i);
    if (!p) return {};
    int bytes = SQLite3Database::fn_column_bytes(m_stmt, i);
    return QString::fromUtf8(reinterpret_cast<const char *>(p), bytes);
}

QByteArray SQLite3Statement::columnBlob(int i)
{
    if (!m_stmt || !SQLite3Database::fn_column_blob || !SQLite3Database::fn_column_bytes) return {};
    const void *data = SQLite3Database::fn_column_blob(m_stmt, i);
    int bytes = SQLite3Database::fn_column_bytes(m_stmt, i);
    return QByteArray(static_cast<const char *>(data), bytes);
}

int SQLite3Statement::columnBytes(int i)
{
    return (m_stmt && SQLite3Database::fn_column_bytes) ? SQLite3Database::fn_column_bytes(m_stmt, i) : 0;
}

QString SQLite3Statement::columnName(int i)
{
    if (!m_stmt || !SQLite3Database::fn_column_name) return {};
    const char *n = SQLite3Database::fn_column_name(m_stmt, i);
    return n ? QString::fromUtf8(n) : QString();
}
