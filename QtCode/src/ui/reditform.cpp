#include "reditform.h"
#include "iniconfig.h"
#include "rfile.h"
#include "encoding.h"
#include <QHeaderView>
#include <QInputDialog>

REditForm::REditForm(QWidget *parent)
    : QWidget(parent)
{
    auto *layout = new QVBoxLayout(this);
    layout->setContentsMargins(0, 0, 0, 0);

    m_table = new QTableWidget(this);
    m_table->setColumnCount(4);
    m_table->setHorizontalHeaderLabels({tr("字段"), tr("值"), tr("备注"), tr("引用")});
    m_table->horizontalHeader()->setStretchLastSection(true);
    m_table->setColumnWidth(0, 120);
    m_table->setColumnWidth(1, 200);
    m_table->setColumnWidth(2, 150);
    m_table->verticalHeader()->setDefaultSectionSize(24);
    layout->addWidget(m_table);

    connect(m_table, &QTableWidget::cellChanged, this, &REditForm::onCellChanged);
    connect(m_table, &QTableWidget::cellDoubleClicked, this, &REditForm::onCellDoubleClicked);
}

void REditForm::displayRecord(int typeIndex, int recordIndex)
{
    m_updating = true;
    m_typeIndex = typeIndex;
    m_recordIndex = recordIndex;

    IniConfig &cfg = IniConfig::instance();
    RFileGlobals &g = cfg.rGlobals;

    m_table->setRowCount(0);

    if (!m_pRFile) { m_updating = false; return; }
    if (typeIndex < 0 || typeIndex >= m_pRFile->rType.size()) { m_updating = false; return; }
    const RType &rt = m_pRFile->rType[typeIndex];
    if (recordIndex < 0 || recordIndex >= rt.rData.size()) { m_updating = false; return; }
    const RData &rd = rt.rData[recordIndex];

    // 计算总行数
    int totalRows = 0;
    for (int d = 0; d < rd.rDataLine.size(); ++d) {
        const auto &line = rd.rDataLine[d];
        for (int dn = 0; dn < line.rArray.size(); ++dn)
            totalRows += line.rArray[dn].dataArray.size();
    }
    m_table->setRowCount(totalRows);

    // Delphi displayR 中使用 temp2 跟踪 rDataLine 对应的 rTerm 基索引
    int row = 0;
    int temp2 = 0; // 当前 rTerm 基索引

    for (int d = 0; d < rd.rDataLine.size(); ++d) {
        const auto &line = rd.rDataLine[d];

        // 找到该 rDataLine 对应的 rTerm 基索引
        // temp2 在外层循环中自增 incnum
        int incNum = (!line.rArray.isEmpty()) ? line.rArray[0].incNum : 1;

        for (int dn = 0; dn < line.rArray.size(); ++dn) {
            const RArray &arr = line.rArray[dn];
            for (int inc = 0; inc < arr.dataArray.size(); ++inc) {
                const RDataSingle &single = arr.dataArray[inc];

                // 用 temp2 + inc 获取对应 rTerm
                int termIdx = temp2 + inc;
                QString fieldName;
                QString noteStr;
                int16_t quote = -1;

                if (typeIndex < g.rIni.size() && termIdx < g.rIni[typeIndex].rTerm.size()) {
                    const RTermini &term = g.rIni[typeIndex].rTerm[termIdx];
                    fieldName = term.name;
                    noteStr = term.note;
                    quote = term.quote;
                    if (line.len > 1)
                        fieldName += QString::number(dn);
                } else {
                    fieldName = QString("field_%1_%2").arg(d).arg(inc);
                }

                auto *nameItem = new QTableWidgetItem(fieldName);
                nameItem->setFlags(nameItem->flags() & ~Qt::ItemIsEditable);
                m_table->setItem(row, 0, nameItem);

                // 值
                QString value = RFileIO::readRDataStr(single);
                auto *valueItem = new QTableWidgetItem(value);
                valueItem->setToolTip(value);
                m_table->setItem(row, 1, valueItem);

                // 备注
                auto *noteItem = new QTableWidgetItem(noteStr);
                noteItem->setFlags(noteItem->flags() & ~Qt::ItemIsEditable);
                m_table->setItem(row, 2, noteItem);

                // 引用
                QString ref;
                if (quote >= 0 && single.dataType == 0) {
                    int64_t refIdx = RFileIO::readRDataInt(single);
                    if (quote < m_pRFile->rType.size()) {
                        const RType &refType = m_pRFile->rType[quote];
                        if (refIdx >= 0 && refIdx < refType.rData.size() && refType.namePos >= 0
                            && refType.namePos < refType.rData[refIdx].rDataLine.size()) {
                            const auto &refLine = refType.rData[refIdx].rDataLine[refType.namePos];
                            if (!refLine.rArray.isEmpty() && !refLine.rArray[0].dataArray.isEmpty())
                                ref = Encoding::displayStr(RFileIO::readRDataStr(refLine.rArray[0].dataArray[0]));
                        }
                    }
                }
                auto *refItem = new QTableWidgetItem(ref);
                refItem->setFlags(refItem->flags() & ~Qt::ItemIsEditable);
                refItem->setToolTip(ref);
                m_table->setItem(row, 3, refItem);

                row++;
            }
        }

        temp2 += incNum;
    }

    m_updating = false;
}

void REditForm::onCellChanged(int row, int column)
{
    if (m_updating || column != 1) return;
    if (!m_pRFile) return;

    if (m_typeIndex < 0 || m_recordIndex < 0) return;
    auto &rt = m_pRFile->rType[m_typeIndex];
    if (m_recordIndex >= rt.rData.size()) return;
    auto &rd = rt.rData[m_recordIndex];

    // 找到对应的 RDataSingle
    int curRow = 0;
    for (int d = 0; d < rd.rDataLine.size(); ++d) {
        auto &line = rd.rDataLine[d];
        for (int dn = 0; dn < line.rArray.size(); ++dn) {
            for (int inc = 0; inc < line.rArray[dn].dataArray.size(); ++inc) {
                if (curRow == row) {
                    QString newVal = m_table->item(row, column)->text();
                    RFileIO::writeRDataStr(line.rArray[dn].dataArray[inc], newVal);
                    return;
                }
                curRow++;
            }
        }
    }
}

REditForm::RowInfo REditForm::rowToInfo(int row) const
{
    RowInfo info;
    if (!m_pRFile || m_typeIndex < 0 || m_recordIndex < 0) return info;
    const auto &rt = m_pRFile->rType[m_typeIndex];
    if (m_recordIndex >= rt.rData.size()) return info;
    const auto &rd = rt.rData[m_recordIndex];

    IniConfig &cfg = IniConfig::instance();
    int curRow = 0;
    int temp2 = 0;
    for (int d = 0; d < rd.rDataLine.size(); ++d) {
        const auto &line = rd.rDataLine[d];
        int incNum = (!line.rArray.isEmpty()) ? line.rArray[0].incNum : 1;
        for (int dn = 0; dn < line.rArray.size(); ++dn) {
            for (int inc = 0; inc < line.rArray[dn].dataArray.size(); ++inc) {
                if (curRow == row) {
                    info.dataLineIdx = d;
                    info.arrayIdx = dn;
                    info.dataIdx = inc;
                    int termIdx = temp2 + inc;
                    if (m_typeIndex < cfg.rGlobals.rIni.size() &&
                        termIdx < cfg.rGlobals.rIni[m_typeIndex].rTerm.size())
                        info.quote = cfg.rGlobals.rIni[m_typeIndex].rTerm[termIdx].quote;
                    return info;
                }
                curRow++;
            }
        }
        temp2 += incNum;
    }
    return info;
}

void REditForm::onCellDoubleClicked(int row, int /*column*/)
{
    if (!m_pRFile || m_typeIndex < 0 || m_recordIndex < 0) return;
    auto &rt = m_pRFile->rType[m_typeIndex];
    if (m_recordIndex >= rt.rData.size()) return;
    auto &rd = rt.rData[m_recordIndex];

    RowInfo info = rowToInfo(row);
    if (info.dataLineIdx < 0) return;

    auto &single = rd.rDataLine[info.dataLineIdx].rArray[info.arrayIdx].dataArray[info.dataIdx];

    if (info.quote >= 0 && single.dataType == 0) {
        // 引用字段: 弹出选择对话框 (匹配 Delphi Form6)
        if (info.quote >= m_pRFile->rType.size()) return;
        const RType &refType = m_pRFile->rType[info.quote];

        QStringList items;
        items << "-1";
        for (int i = 0; i < refType.rData.size(); ++i) {
            QString name;
            if (refType.namePos >= 0 && refType.namePos < refType.rData[i].rDataLine.size()) {
                const auto &nl = refType.rData[i].rDataLine[refType.namePos];
                if (!nl.rArray.isEmpty() && !nl.rArray[0].dataArray.isEmpty())
                    name = Encoding::displayStr(RFileIO::readRDataStr(nl.rArray[0].dataArray[0]));
            }
            items << QString("%1 %2").arg(i).arg(name);
        }

        int curVal = static_cast<int>(RFileIO::readRDataInt(single));
        int curIdx = curVal + 1; // Delphi: ComboBox index = value + 1 (because "-1" is at index 0)
        if (curIdx < 0 || curIdx >= items.size()) curIdx = 0;

        IniConfig &cfg = IniConfig::instance();
        QString typeName = (info.quote < cfg.rGlobals.typeName.size())
                           ? cfg.rGlobals.typeName[info.quote] : QString::number(info.quote);

        bool ok;
        QString selected = QInputDialog::getItem(this, tr("选择引用"), typeName, items, curIdx, false, &ok);
        if (ok) {
            int idx = items.indexOf(selected);
            RFileIO::writeRDataInt(single, idx - 1);
            displayRecord(m_typeIndex, m_recordIndex);
        }
    } else {
        // 非引用字段: 弹出编辑对话框 (匹配 Delphi InputBox)
        QString curVal = RFileIO::readRDataStr(single);
        bool ok;
        QString title = (single.dataType == 0) ? tr("修改数值") : tr("修改字符串");
        QString newVal = QInputDialog::getText(this, title, tr("修改此项:"), QLineEdit::Normal, curVal, &ok);
        if (ok && !newVal.isEmpty()) {
            RFileIO::writeRDataStr(single, newVal);
            displayRecord(m_typeIndex, m_recordIndex);
        }
    }
}
