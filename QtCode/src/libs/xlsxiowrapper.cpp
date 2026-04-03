#include "xlsxiowrapper.h"
#include <cstring>

// ── XlsxReader 静态成员 ────────────────────────────────

QLibrary XlsxReader::s_lib;
bool XlsxReader::s_loaded = false;
XlsxReader::FnOpen       XlsxReader::fn_open = nullptr;
XlsxReader::FnClose      XlsxReader::fn_close = nullptr;
XlsxReader::FnSheetOpen  XlsxReader::fn_sheet_open = nullptr;
XlsxReader::FnSheetClose XlsxReader::fn_sheet_close = nullptr;
XlsxReader::FnNextRow    XlsxReader::fn_next_row = nullptr;
XlsxReader::FnNextCell   XlsxReader::fn_next_cell = nullptr;
XlsxReader::FnFree       XlsxReader::fn_free = nullptr;

XlsxReader::XlsxReader() {}
XlsxReader::~XlsxReader() { close(); }

bool XlsxReader::loadLibrary(const QString &dllPath)
{
    if (s_loaded) return true;
    s_lib.setFileName(dllPath);
    if (!s_lib.load()) return false;

    fn_open       = reinterpret_cast<FnOpen>(s_lib.resolve("xlsxioread_open"));
    fn_close      = reinterpret_cast<FnClose>(s_lib.resolve("xlsxioread_close"));
    fn_sheet_open = reinterpret_cast<FnSheetOpen>(s_lib.resolve("xlsxioread_sheet_open"));
    fn_sheet_close = reinterpret_cast<FnSheetClose>(s_lib.resolve("xlsxioread_sheet_close"));
    fn_next_row   = reinterpret_cast<FnNextRow>(s_lib.resolve("xlsxioread_sheet_next_row"));
    fn_next_cell  = reinterpret_cast<FnNextCell>(s_lib.resolve("xlsxioread_sheet_next_cell"));
    fn_free       = reinterpret_cast<FnFree>(s_lib.resolve("xlsxioread_free"));

    s_loaded = (fn_open && fn_close);
    return s_loaded;
}

bool XlsxReader::open(const QString &filename)
{
    close();
    if (!s_loaded || !fn_open) return false;
    QByteArray utf8 = filename.toUtf8();
    m_reader = fn_open(utf8.constData());
    return m_reader != nullptr;
}

void XlsxReader::close()
{
    closeSheet();
    if (m_reader && fn_close) { fn_close(m_reader); m_reader = nullptr; }
}

bool XlsxReader::openSheet(const QString &name, int flags)
{
    if (!m_reader || !fn_sheet_open) return false;
    closeSheet();
    QByteArray utf8 = name.isEmpty() ? QByteArray() : name.toUtf8();
    m_sheet = fn_sheet_open(m_reader, utf8.isEmpty() ? nullptr : utf8.constData(), flags);
    return m_sheet != nullptr;
}

void XlsxReader::closeSheet()
{
    if (m_sheet && fn_sheet_close) { fn_sheet_close(m_sheet); m_sheet = nullptr; }
}

bool XlsxReader::nextRow()
{
    return (m_sheet && fn_next_row) ? (fn_next_row(m_sheet) != 0) : false;
}

QString XlsxReader::nextCell()
{
    if (!m_sheet || !fn_next_cell) return {};
    char *cell = fn_next_cell(m_sheet);
    if (!cell) return {};
    QString result = QString::fromUtf8(cell);
    if (fn_free) fn_free(cell);
    return result;
}

QVector<QStringList> XlsxReader::readAll(const QString &sheetName)
{
    QVector<QStringList> rows;
    if (!openSheet(sheetName)) return rows;
    while (nextRow()) {
        QStringList row;
        QString cell;
        while (!(cell = nextCell()).isNull()) {
            row.append(cell);
        }
        rows.append(row);
    }
    closeSheet();
    return rows;
}

// ── XlsxWriter 静态成员 ────────────────────────────────

QLibrary XlsxWriter::s_lib;
bool XlsxWriter::s_loaded = false;
XlsxWriter::FnNew           XlsxWriter::fn_new = nullptr;
XlsxWriter::FnClose         XlsxWriter::fn_close = nullptr;
XlsxWriter::FnAddWorksheet  XlsxWriter::fn_add_worksheet = nullptr;
XlsxWriter::FnWriteString   XlsxWriter::fn_write_string = nullptr;
XlsxWriter::FnWriteNumber   XlsxWriter::fn_write_number = nullptr;

XlsxWriter::XlsxWriter() {}
XlsxWriter::~XlsxWriter() { close(); }

bool XlsxWriter::loadLibrary(const QString &dllPath)
{
    if (s_loaded) return true;
    s_lib.setFileName(dllPath);
    if (!s_lib.load()) return false;

    fn_new           = reinterpret_cast<FnNew>(s_lib.resolve("workbook_new"));
    fn_close         = reinterpret_cast<FnClose>(s_lib.resolve("workbook_close"));
    fn_add_worksheet = reinterpret_cast<FnAddWorksheet>(s_lib.resolve("workbook_add_worksheet"));
    fn_write_string  = reinterpret_cast<FnWriteString>(s_lib.resolve("worksheet_write_string"));
    fn_write_number  = reinterpret_cast<FnWriteNumber>(s_lib.resolve("worksheet_write_number"));

    s_loaded = (fn_new && fn_close);
    return s_loaded;
}

bool XlsxWriter::create(const QString &filename)
{
    if (!s_loaded || !fn_new) return false;
    close();
    QByteArray utf8 = filename.toUtf8();
    m_workbook = fn_new(utf8.constData());
    return m_workbook != nullptr;
}

void XlsxWriter::close()
{
    m_worksheet = nullptr;
    if (m_workbook && fn_close) { fn_close(m_workbook); m_workbook = nullptr; }
}

bool XlsxWriter::addWorksheet(const QString &name)
{
    if (!m_workbook || !fn_add_worksheet) return false;
    QByteArray utf8 = name.isEmpty() ? QByteArray() : name.toUtf8();
    m_worksheet = fn_add_worksheet(m_workbook, utf8.isEmpty() ? nullptr : utf8.constData());
    return m_worksheet != nullptr;
}

void XlsxWriter::writeString(int row, int col, const QString &value)
{
    if (!m_worksheet || !fn_write_string) return;
    QByteArray utf8 = value.toUtf8();
    fn_write_string(m_worksheet, static_cast<uint32_t>(row), static_cast<uint16_t>(col),
                    utf8.constData(), nullptr);
}

void XlsxWriter::writeNumber(int row, int col, double value)
{
    if (!m_worksheet || !fn_write_number) return;
    fn_write_number(m_worksheet, static_cast<uint32_t>(row), static_cast<uint16_t>(col),
                    value, nullptr);
}
