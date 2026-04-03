#include "zipwrapper.h"
#include <cstring>

QLibrary ZipWrapper::s_lib;
bool ZipWrapper::s_loaded = false;

ZipWrapper::FnOpen       ZipWrapper::fn_open = nullptr;
ZipWrapper::FnClose      ZipWrapper::fn_close = nullptr;
ZipWrapper::FnGetNumEntries ZipWrapper::fn_get_num_entries = nullptr;
ZipWrapper::FnGetName    ZipWrapper::fn_get_name = nullptr;
ZipWrapper::FnNameLocate ZipWrapper::fn_name_locate = nullptr;
ZipWrapper::FnFopen      ZipWrapper::fn_fopen = nullptr;
ZipWrapper::FnFopenIndex ZipWrapper::fn_fopen_index = nullptr;
ZipWrapper::FnFread      ZipWrapper::fn_fread = nullptr;
ZipWrapper::FnFclose     ZipWrapper::fn_fclose = nullptr;
ZipWrapper::FnStatIndex  ZipWrapper::fn_stat_index = nullptr;
ZipWrapper::FnSourceBuffer ZipWrapper::fn_source_buffer = nullptr;
ZipWrapper::FnFileAdd    ZipWrapper::fn_file_add = nullptr;
ZipWrapper::FnSetCompression ZipWrapper::fn_set_file_compression = nullptr;

ZipWrapper::ZipWrapper() {}
ZipWrapper::~ZipWrapper() { close(); }

bool ZipWrapper::loadLibrary(const QString &dllPath)
{
    if (s_loaded) return true;
    s_lib.setFileName(dllPath);
    if (!s_lib.load()) return false;

    fn_open              = reinterpret_cast<FnOpen>(s_lib.resolve("zip_open"));
    fn_close             = reinterpret_cast<FnClose>(s_lib.resolve("zip_close"));
    fn_get_num_entries   = reinterpret_cast<FnGetNumEntries>(s_lib.resolve("zip_get_num_entries"));
    fn_get_name          = reinterpret_cast<FnGetName>(s_lib.resolve("zip_get_name"));
    fn_name_locate       = reinterpret_cast<FnNameLocate>(s_lib.resolve("zip_name_locate"));
    fn_fopen             = reinterpret_cast<FnFopen>(s_lib.resolve("zip_fopen"));
    fn_fopen_index       = reinterpret_cast<FnFopenIndex>(s_lib.resolve("zip_fopen_index"));
    fn_fread             = reinterpret_cast<FnFread>(s_lib.resolve("zip_fread"));
    fn_fclose            = reinterpret_cast<FnFclose>(s_lib.resolve("zip_fclose"));
    fn_stat_index        = reinterpret_cast<FnStatIndex>(s_lib.resolve("zip_stat_index"));
    fn_source_buffer     = reinterpret_cast<FnSourceBuffer>(s_lib.resolve("zip_source_buffer"));
    fn_file_add          = reinterpret_cast<FnFileAdd>(s_lib.resolve("zip_file_add"));
    fn_set_file_compression = reinterpret_cast<FnSetCompression>(s_lib.resolve("zip_set_file_compression"));

    s_loaded = (fn_open && fn_close);
    return s_loaded;
}

bool ZipWrapper::isLibraryLoaded() { return s_loaded; }

bool ZipWrapper::open(const QString &filename, int mode)
{
    if (!s_loaded || !fn_open) return false;
    close();
    QByteArray utf8 = filename.toUtf8();
    int err = 0;
    m_zip = fn_open(utf8.constData(), mode, &err);
    return m_zip != nullptr;
}

void ZipWrapper::close()
{
    if (m_zip && fn_close) { fn_close(m_zip); m_zip = nullptr; }
}

QStringList ZipWrapper::entryNames() const
{
    QStringList result;
    if (!m_zip || !fn_get_num_entries || !fn_get_name) return result;
    int64_t count = fn_get_num_entries(m_zip, 0);
    for (int64_t i = 0; i < count; ++i) {
        const char *name = fn_get_name(m_zip, i, 0);
        if (name) result.append(QString::fromUtf8(name));
    }
    return result;
}

int ZipWrapper::entryCount() const
{
    if (!m_zip || !fn_get_num_entries) return 0;
    return static_cast<int>(fn_get_num_entries(m_zip, 0));
}

// zip_stat 结构: 前 8 bytes valid标志, 接着各字段
// 简化实现: 使用 8+8+8+8=32 的偏移取 size
struct zip_stat_simple {
    uint64_t valid;
    uint64_t reserved1; // name
    uint64_t index;
    uint64_t size;      // 解压后大小
    uint64_t comp_size;
    // ...
};

QByteArray ZipWrapper::readEntry(const QString &name) const
{
    if (!m_zip || !fn_fopen || !fn_fread || !fn_fclose) return {};

    QByteArray utf8Name = name.toUtf8();

    // 获取大小
    int idx = findEntry(name);
    if (idx < 0) return {};

    zip_stat_simple stat = {};
    if (fn_stat_index)
        fn_stat_index(m_zip, idx, &stat, 0);

    void *zf = fn_fopen(m_zip, utf8Name.constData(), 0);
    if (!zf) return {};

    int64_t size = static_cast<int64_t>(stat.size);
    if (size <= 0) size = 1024 * 1024; // 默认 1MB 上限

    QByteArray data(static_cast<int>(size), '\0');
    int64_t bytesRead = fn_fread(zf, data.data(), size);
    fn_fclose(zf);

    if (bytesRead > 0)
        data.resize(static_cast<int>(bytesRead));
    else
        data.clear();

    return data;
}

QByteArray ZipWrapper::readEntry(int index) const
{
    if (!m_zip || !fn_fopen_index || !fn_fread || !fn_fclose) return {};

    zip_stat_simple stat = {};
    if (fn_stat_index)
        fn_stat_index(m_zip, index, &stat, 0);

    void *zf = fn_fopen_index(m_zip, index, 0);
    if (!zf) return {};

    int64_t size = static_cast<int64_t>(stat.size);
    if (size <= 0) size = 1024 * 1024;

    QByteArray data(static_cast<int>(size), '\0');
    int64_t bytesRead = fn_fread(zf, data.data(), size);
    fn_fclose(zf);

    if (bytesRead > 0)
        data.resize(static_cast<int>(bytesRead));
    else
        data.clear();

    return data;
}

int ZipWrapper::entrySize(const QString &name) const
{
    int idx = findEntry(name);
    if (idx < 0) return -1;
    zip_stat_simple stat = {};
    if (fn_stat_index)
        fn_stat_index(m_zip, idx, &stat, 0);
    return static_cast<int>(stat.size);
}

bool ZipWrapper::addEntry(const QString &name, const QByteArray &data)
{
    if (!m_zip || !fn_source_buffer || !fn_file_add) return false;
    QByteArray utf8Name = name.toUtf8();

    // 注意: 需要持久化 data，使用 needfree=0 让 libzip 不释放
    void *src = fn_source_buffer(m_zip, data.constData(), data.size(), 0);
    if (!src) return false;

    int64_t idx = fn_file_add(m_zip, utf8Name.constData(), src, 0x0800 /*ZIP_FL_OVERWRITE*/);
    return idx >= 0;
}

int ZipWrapper::findEntry(const QString &name) const
{
    if (!m_zip || !fn_name_locate) return -1;
    QByteArray utf8 = name.toUtf8();
    return static_cast<int>(fn_name_locate(m_zip, utf8.constData(), 0));
}
