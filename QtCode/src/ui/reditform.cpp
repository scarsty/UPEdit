#include "reditform.h"
#include "iniconfig.h"
#include "rfile.h"
#include "encoding.h"
#include <QHeaderView>

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
                m_table->setItem(row, 1, new QTableWidgetItem(value));

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
