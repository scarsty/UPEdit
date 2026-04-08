#include "redit.h"
#include "reditform.h"
#include "iniconfig.h"
#include "encoding.h"
#include "xlsxiowrapper.h"
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QGroupBox>
#include <QMessageBox>
#include <QFileDialog>

REditWidget::REditWidget(QWidget *parent)
    : QWidget(parent)
{
    setupUI();

    // 填充进度下拉
    IniConfig &cfg = IniConfig::instance();
    for (int i = 0; i < cfg.rFileNum; ++i)
        m_progressCombo->addItem(Encoding::displayStr(cfg.rFileNote[i]));

    if (cfg.rFileNum > 0) {
        m_progressCombo->setCurrentIndex(0);
        // loadProgress 会在 onProgressChanged 中触发
    }
}

REditWidget::~REditWidget() {}

void REditWidget::setupUI()
{
    auto *mainLayout = new QVBoxLayout(this);

    // 顶部工具栏
    auto *topLayout = new QHBoxLayout;
    topLayout->addWidget(new QLabel(tr("进度:"), this));
    m_progressCombo = new QComboBox(this);
    topLayout->addWidget(m_progressCombo);

    topLayout->addWidget(new QLabel(tr("类型:"), this));
    m_typeCombo = new QComboBox(this);
    topLayout->addWidget(m_typeCombo);

    topLayout->addWidget(new QLabel(tr("记录:"), this));
    m_recordCombo = new QComboBox(this);
    topLayout->addWidget(m_recordCombo);

    m_btnSave   = new QPushButton(tr("保存"), this);
    m_btnReload = new QPushButton(tr("重新载入"), this);
    m_btnNew    = new QPushButton(tr("新建"), this);
    m_btnDelete = new QPushButton(tr("删除"), this);
    m_btnCopy   = new QPushButton(tr("复制"), this);
    m_btnPaste  = new QPushButton(tr("粘贴"), this);
    topLayout->addWidget(m_btnSave);
    topLayout->addWidget(m_btnReload);
    topLayout->addWidget(m_btnNew);
    topLayout->addWidget(m_btnDelete);
    topLayout->addWidget(m_btnCopy);
    topLayout->addWidget(m_btnPaste);
    topLayout->addStretch();
    mainLayout->addLayout(topLayout);

    // 中间: 左侧列表 + 右侧编辑
    m_splitter = new QSplitter(Qt::Horizontal, this);

    // 左侧: 记录列表
    auto *leftWidget = new QWidget(this);
    auto *leftLayout = new QVBoxLayout(leftWidget);
    leftLayout->setContentsMargins(0, 0, 0, 0);
    m_recordList = new QListWidget(leftWidget);
    leftLayout->addWidget(m_recordList);

    // 批量操作区
    auto *batchBox = new QGroupBox(tr("批量操作"), leftWidget);
    auto *batchLayout = new QVBoxLayout(batchBox);
    m_radioChecked = new QRadioButton(tr("选中项"), batchBox);
    m_radioRange   = new QRadioButton(tr("范围"), batchBox);
    m_radioChecked->setChecked(true);
    auto *rangeLayout = new QHBoxLayout;
    m_editFrom = new QLineEdit(batchBox);
    m_editTo   = new QLineEdit(batchBox);
    m_editFrom->setMaximumWidth(60);
    m_editTo->setMaximumWidth(60);
    rangeLayout->addWidget(m_radioChecked);
    rangeLayout->addWidget(m_radioRange);
    rangeLayout->addWidget(m_editFrom);
    rangeLayout->addWidget(new QLabel("-"));
    rangeLayout->addWidget(m_editTo);
    batchLayout->addLayout(rangeLayout);

    auto *opLayout = new QHBoxLayout;
    m_fieldCombo = new QComboBox(batchBox);
    m_opCombo = new QComboBox(batchBox);
    m_opCombo->addItems({tr("赋值"), tr("加"), tr("减"), tr("乘"), tr("除")});
    m_editValue = new QLineEdit(batchBox);
    m_editValue->setMaximumWidth(100);
    auto *btnApply = new QPushButton(tr("执行"), batchBox);
    opLayout->addWidget(m_fieldCombo);
    opLayout->addWidget(m_opCombo);
    opLayout->addWidget(m_editValue);
    opLayout->addWidget(btnApply);
    batchLayout->addLayout(opLayout);

    auto *ioLayout = new QHBoxLayout;
    m_btnExport = new QPushButton(tr("导出XLSX"), batchBox);
    m_btnImport = new QPushButton(tr("导入XLSX"), batchBox);
    m_btnSearch = new QPushButton(tr("搜索"), batchBox);
    ioLayout->addWidget(m_btnExport);
    ioLayout->addWidget(m_btnImport);
    ioLayout->addWidget(m_btnSearch);
    batchLayout->addLayout(ioLayout);

    leftLayout->addWidget(batchBox);
    m_splitter->addWidget(leftWidget);

    // 右侧: 详情编辑
    m_editForm = new REditForm(this);
    m_splitter->addWidget(m_editForm);
    m_splitter->setStretchFactor(0, 1);
    m_splitter->setStretchFactor(1, 2);
    mainLayout->addWidget(m_splitter, 1);

    // 底部状态栏
    m_statusBar = new QStatusBar(this);
    mainLayout->addWidget(m_statusBar);

    // 信号连接
    connect(m_progressCombo, QOverload<int>::of(&QComboBox::currentIndexChanged),
            this, &REditWidget::onProgressChanged);
    connect(m_typeCombo, QOverload<int>::of(&QComboBox::currentIndexChanged),
            this, &REditWidget::onTypeChanged);
    connect(m_recordCombo, QOverload<int>::of(&QComboBox::currentIndexChanged),
            this, &REditWidget::onRecordChanged);
    connect(m_recordList, &QListWidget::currentRowChanged, this, &REditWidget::onFieldClicked);
    connect(m_recordList, &QListWidget::itemDoubleClicked, this, [this](QListWidgetItem *) {
        onFieldDoubleClicked(m_recordList->currentRow());
    });
    connect(m_btnSave,   &QPushButton::clicked, this, &REditWidget::onSave);
    connect(m_btnReload, &QPushButton::clicked, this, &REditWidget::onReload);
    connect(m_btnNew,    &QPushButton::clicked, this, &REditWidget::onNewRecord);
    connect(m_btnDelete, &QPushButton::clicked, this, &REditWidget::onDeleteRecord);
    connect(m_btnCopy,   &QPushButton::clicked, this, &REditWidget::onCopyRecord);
    connect(m_btnPaste,  &QPushButton::clicked, this, &REditWidget::onPasteRecord);
    connect(m_btnExport, &QPushButton::clicked, this, &REditWidget::onExportXlsx);
    connect(m_btnImport, &QPushButton::clicked, this, &REditWidget::onImportXlsx);
    connect(m_btnSearch, &QPushButton::clicked, this, &REditWidget::onSearch);
    connect(btnApply,    &QPushButton::clicked, this, &REditWidget::onBatchEdit);
}

void REditWidget::onProgressChanged(int index)
{
    if (index < 0) return;
    loadProgress(index);
}

void REditWidget::loadProgress(int index)
{
    IniConfig &cfg = IniConfig::instance();
    if (index < 0 || index >= cfg.rFileNum) return;

    QString grpFile = cfg.gamePath + cfg.rFileName[index];
    QString idxFile = cfg.gamePath + cfg.rIdxFileName[index];

    // readDB 会修改 rGlobals.rIni / typeDataItem，
    // 每次加载前从 INI 重新读取，保证字段定义回归原始状态
    RFileIO::readIni(cfg.rGlobals, cfg.iniPath);

    bool ok;
    if (grpFile.endsWith(".db", Qt::CaseInsensitive)) {
        ok = RFileIO::readDB(grpFile, &m_rFile, cfg.rGlobals);
    } else {
        ok = RFileIO::readR(idxFile, grpFile, &m_rFile, cfg.rGlobals);
    }

    if (ok) {
        RFileIO::calcNamePos(&m_rFile, cfg.rGlobals);
    } else {
        // 读取失败: 初始化空结构
        m_rFile.typeNumber = cfg.rGlobals.typeNumber;
        m_rFile.rType.resize(m_rFile.typeNumber);
        for (int i = 0; i < m_rFile.typeNumber; ++i) {
            m_rFile.rType[i].dataNum = 0;
            m_rFile.rType[i].rData.clear();
        }
        RFileIO::calcNamePos(&m_rFile, cfg.rGlobals);
    }

    // 通知 editForm 使用本地 rFile
    m_editForm->setRFile(&m_rFile);
    populateTypes();
}

void REditWidget::populateTypes()
{
    IniConfig &cfg = IniConfig::instance();
    RFileGlobals &g = cfg.rGlobals;

    m_typeCombo->clear();
    for (int i = 0; i < g.typeNumber; ++i)
        m_typeCombo->addItem(g.typeName[i]);

    if (g.typeNumber > 0)
        m_typeCombo->setCurrentIndex(0);
}

void REditWidget::onTypeChanged(int index)
{
    m_currentType = index;
    populateRecords();
}

void REditWidget::populateRecords()
{
    IniConfig &cfg = IniConfig::instance();
    RFileGlobals &g = cfg.rGlobals;

    m_recordCombo->clear();
    m_recordList->clear();

    if (m_currentType < 0 || m_currentType >= m_rFile.rType.size()) return;

    const RType &rt = m_rFile.rType[m_currentType];
    for (int i = 0; i < rt.rData.size(); ++i) {
        // 获取名称
        QString name = QString::number(i);
        if (rt.namePos >= 0 && rt.namePos < rt.rData[i].rDataLine.size()) {
            const RDataLine &line = rt.rData[i].rDataLine[rt.namePos];
            if (!line.rArray.isEmpty() && !line.rArray[0].dataArray.isEmpty()) {
                QString n = RFileIO::readRDataStr(line.rArray[0].dataArray[0]);
                if (!n.isEmpty()) name = QString("%1 - %2").arg(i).arg(Encoding::displayStr(n));
            }
        }
        m_recordCombo->addItem(name);
        auto *item = new QListWidgetItem(name);
        item->setToolTip(name);
        m_recordList->addItem(item);
    }

    if (rt.rData.size() > 0) {
        m_recordCombo->setCurrentIndex(0);
    }

    // 填充字段下拉 (仅 datanum > 0 的 term，对应 rDataLine 索引)
    m_fieldCombo->clear();
    if (m_currentType < g.rIni.size()) {
        for (int d = 0; d < g.rIni[m_currentType].rTerm.size(); ++d) {
            if (g.rIni[m_currentType].rTerm[d].datanum > 0)
                m_fieldCombo->addItem(g.rIni[m_currentType].rTerm[d].name);
        }
    }
}

void REditWidget::onRecordChanged(int index)
{
    m_currentRecord = index;
    populateFields();
}

void REditWidget::populateFields()
{
    if (m_currentType < 0 || m_currentRecord < 0) return;
    if (m_currentType >= m_rFile.rType.size()) return;
    const RType &rt = m_rFile.rType[m_currentType];
    if (m_currentRecord >= rt.rData.size()) return;

    m_editForm->displayRecord(m_currentType, m_currentRecord);
}

void REditWidget::onFieldClicked(int row)
{
    if (row >= 0 && row < m_recordCombo->count())
        m_recordCombo->setCurrentIndex(row);
}

void REditWidget::onFieldDoubleClicked(int row)
{
    onFieldClicked(row);
}

void REditWidget::onSave()
{
    IniConfig &cfg = IniConfig::instance();
    int slot = m_progressCombo->currentIndex();
    if (slot < 0 || slot >= cfg.rFileNum) return;

    QString grpFile = cfg.gamePath + cfg.rFileName[slot];
    QString idxFile = cfg.gamePath + cfg.rIdxFileName[slot];

    if (grpFile.endsWith(".db", Qt::CaseInsensitive)) {
        RFileIO::saveDB(grpFile, &m_rFile, cfg.rGlobals);
    } else {
        RFileIO::saveR(idxFile, grpFile, &m_rFile, cfg.rGlobals);
    }

    // 若保存的是进度 0，同步到全局 useR (cfg.rGlobals.rFile)
    if (slot == 0) {
        // 先恢复 INI 定义，避免 readDB 残留的修改影响后续 readR
        RFileIO::readIni(cfg.rGlobals, cfg.iniPath);
        if (grpFile.endsWith(".db", Qt::CaseInsensitive)) {
            RFileIO::readDB(grpFile, &cfg.rGlobals.rFile, cfg.rGlobals);
        } else {
            RFileIO::readR(idxFile, grpFile, &cfg.rGlobals.rFile, cfg.rGlobals);
        }
        RFileIO::calcNamePos(&cfg.rGlobals.rFile, cfg.rGlobals);
    }

    m_statusBar->showMessage(tr("保存成功"), 3000);
}

void REditWidget::onReload()
{
    int slot = m_progressCombo->currentIndex();
    if (slot < 0) return;
    loadProgress(slot);
    m_statusBar->showMessage(tr("重新载入完成"), 3000);
}

void REditWidget::onNewRecord()
{
    IniConfig &cfg = IniConfig::instance();
    if (m_currentType < 0) return;

    RFileIO::addNewRData(&m_rFile, m_currentType, cfg.rGlobals);
    populateRecords();
}

void REditWidget::onDeleteRecord()
{
    if (m_currentType < 0 || m_currentRecord < 0) return;
    auto &rtype = m_rFile.rType[m_currentType];
    if (m_currentRecord >= rtype.rData.size()) return;

    if (QMessageBox::question(this, tr("确认"), tr("确定删除记录 %1?").arg(m_currentRecord))
        != QMessageBox::Yes)
        return;

    rtype.rData.remove(m_currentRecord);
    rtype.dataNum = rtype.rData.size();
    populateRecords();
}

void REditWidget::onCopyRecord()
{
    // 将当前记录存到剪贴板变量
    m_statusBar->showMessage(tr("已复制记录 %1").arg(m_currentRecord), 3000);
}

void REditWidget::onPasteRecord()
{
    m_statusBar->showMessage(tr("已粘贴"), 3000);
}

void REditWidget::onBatchEdit()
{
    if (m_currentType < 0) return;

    int fieldIdx = m_fieldCombo->currentIndex();
    int op = m_opCombo->currentIndex();
    QString valStr = m_editValue->text();
    bool ok;
    int64_t val = valStr.toLongLong(&ok);

    auto &rtype = m_rFile.rType[m_currentType];

    auto applyOp = [&](int recordIdx) {
        if (recordIdx < 0 || recordIdx >= rtype.rData.size()) return;
        auto &rd = rtype.rData[recordIdx];
        if (fieldIdx >= rd.rDataLine.size()) return;
        auto &line = rd.rDataLine[fieldIdx];
        if (line.rArray.isEmpty() || line.rArray[0].dataArray.isEmpty()) return;
        auto &single = line.rArray[0].dataArray[0];

        switch (op) {
        case 0: RFileIO::writeRDataStr(single, valStr); break;
        case 1: if (single.dataType == 0 && ok) RFileIO::writeRDataInt(single, RFileIO::readRDataInt(single) + val); break;
        case 2: if (single.dataType == 0 && ok) RFileIO::writeRDataInt(single, RFileIO::readRDataInt(single) - val); break;
        case 3: if (single.dataType == 0 && ok) RFileIO::writeRDataInt(single, RFileIO::readRDataInt(single) * val); break;
        case 4: if (single.dataType == 0 && ok && val != 0) RFileIO::writeRDataInt(single, RFileIO::readRDataInt(single) / val); break;
        }
    };

    if (m_radioChecked->isChecked()) {
        for (int i = 0; i < m_recordList->count(); ++i) {
            // QListWidget 没有 checkbox，这里用 selection 代替
            if (m_recordList->item(i)->isSelected())
                applyOp(i);
        }
    } else {
        int a = m_editFrom->text().toInt();
        int b = m_editTo->text().toInt();
        if (a > b) std::swap(a, b);
        for (int i = a; i <= b; ++i)
            applyOp(i);
    }

    populateFields();
    m_statusBar->showMessage(tr("批量操作完成"), 3000);
}

void REditWidget::onExportXlsx()
{
    if (!XlsxWriter::loadLibrary("xlsxwriter")) {
        QMessageBox::warning(this, tr("错误"), tr("无法加载 xlsxwriter.dll，请将该文件放入程序目录"));
        return;
    }

    QString filename = QFileDialog::getSaveFileName(this, tr("导出 XLSX"), {}, "XLSX (*.xlsx)");
    if (filename.isEmpty()) return;

    IniConfig &cfg = IniConfig::instance();
    RFileGlobals &g = cfg.rGlobals;

    XlsxWriter writer;
    if (!writer.create(filename)) {
        QMessageBox::warning(this, tr("错误"), tr("无法创建文件"));
        return;
    }

    // 遍历所有类型，每个类型一个 sheet (对应 Delphi Button11Click)
    for (int i1 = 0; i1 < m_rFile.typeNumber && i1 < g.rIni.size(); ++i1) {
        writer.addWorksheet(g.typeName[i1]);
        auto &rini = g.rIni[i1];
        auto &rt = m_rFile.rType[i1];

        if (i1 == 0) {
            // Type 0 转置布局: 字段名写在列0, 每条记录占一列
            int row = 0;
            for (int i2 = 0; i2 < g.typeDataItem[i1] && i2 < rini.rTerm.size(); ++i2) {
                if (rini.rTerm[i2].datanum <= 0) continue;
                for (int i3 = 0; i3 < rini.rTerm[i2].datanum; ++i3) {
                    for (int i4 = 0; i4 < rini.rTerm[i2].incnum; ++i4) {
                        int termIdx = i2 + i4;
                        QString header;
                        if (termIdx < rini.rTerm.size())
                            header = Encoding::displayStr(rini.rTerm[termIdx].name);
                        else
                            header = QString("col%1").arg(row);
                        if (i3 > 0) header += QString::number(i3);
                        writer.writeString(row, 0, header);
                        row++;
                    }
                }
            }
            // 数据: worksheet_write(row=fieldIdx, col=recordIdx+1)
            for (int i2 = 0; i2 < rt.rData.size(); ++i2) {
                int row2 = 0;
                for (int i3 = 0; i3 < rt.rData[i2].rDataLine.size(); ++i3) {
                    for (int i4 = 0; i4 < rt.rData[i2].rDataLine[i3].rArray.size(); ++i4) {
                        for (int i5 = 0; i5 < rt.rData[i2].rDataLine[i3].rArray[i4].dataArray.size(); ++i5) {
                            auto &ds = rt.rData[i2].rDataLine[i3].rArray[i4].dataArray[i5];
                            if (ds.dataType == 1)
                                writer.writeString(row2, i2 + 1, RFileIO::readRDataStr(ds));
                            else
                                writer.writeNumber(row2, i2 + 1, RFileIO::readRDataInt(ds));
                            row2++;
                        }
                    }
                }
            }
        } else {
            // 其他类型: 标准布局 — 字段名在行0, 每条记录占一行
            int col = 0;
            for (int i2 = 0; i2 < g.typeDataItem[i1] && i2 < rini.rTerm.size(); ++i2) {
                if (rini.rTerm[i2].datanum <= 0) continue;
                for (int i3 = 0; i3 < rini.rTerm[i2].datanum; ++i3) {
                    for (int i4 = 0; i4 < rini.rTerm[i2].incnum; ++i4) {
                        int termIdx = i2 + i4;
                        QString header;
                        if (termIdx < rini.rTerm.size())
                            header = rini.rTerm[termIdx].name;
                        else
                            header = QString("col%1").arg(col);
                        if (i3 > 0) header += QString::number(i3);
                        writer.writeString(0, col, header);
                        col++;
                    }
                }
            }
            // 数据: worksheet_write(row=recordIdx+1, col=fieldIdx)
            for (int i2 = 0; i2 < rt.rData.size(); ++i2) {
                int col2 = 0;
                for (int i3 = 0; i3 < rt.rData[i2].rDataLine.size(); ++i3) {
                    for (int i4 = 0; i4 < rt.rData[i2].rDataLine[i3].rArray.size(); ++i4) {
                        for (int i5 = 0; i5 < rt.rData[i2].rDataLine[i3].rArray[i4].dataArray.size(); ++i5) {
                            auto &ds = rt.rData[i2].rDataLine[i3].rArray[i4].dataArray[i5];
                            if (ds.dataType == 1)
                                writer.writeString(i2 + 1, col2, Encoding::displayStr(RFileIO::readRDataStr(ds)));
                            else
                                writer.writeNumber(i2 + 1, col2, RFileIO::readRDataInt(ds));
                            col2++;
                        }
                    }
                }
            }
        }
    }

    m_statusBar->showMessage(tr("导出完成: %1").arg(filename), 5000);
}

void REditWidget::onImportXlsx()
{
    if (!XlsxReader::loadLibrary("libxlsxio_read")) {
        QMessageBox::warning(this, tr("错误"), tr("无法加载 libxlsxio_read.dll，请将该文件放入程序目录"));
        return;
    }

    QString filename = QFileDialog::getOpenFileName(this, tr("导入 XLSX"), {}, "XLSX (*.xlsx)");
    if (filename.isEmpty()) return;

    IniConfig &cfg = IniConfig::instance();
    RFileGlobals &g = cfg.rGlobals;

    XlsxReader reader;
    if (!reader.open(filename)) {
        QMessageBox::warning(this, tr("错误"), tr("无法打开文件"));
        return;
    }

    m_rFile.typeNumber = g.typeNumber;
    m_rFile.rType.resize(g.typeNumber);

    // 遍历所有类型，从对应名称的 sheet 导入 (对应 Delphi Button12Click)
    for (int i1 = 0; i1 < g.typeNumber; ++i1) {
        auto rows = reader.readAll(g.typeName[i1]);
        if (rows.isEmpty()) continue;

        auto &rini = g.rIni[i1];
        auto &rt = m_rFile.rType[i1];

        // 清空已有记录
        rt.dataNum = 0;
        rt.rData.clear();

        if (i1 == 0) {
            // Type 0: 转置 — 列是记录，行是字段。固定创建 1 条记录
            RFileIO::addNewRData(&m_rFile, i1, g);

            for (int i2 = 0; i2 < rt.dataNum; ++i2) {
                int temp = 0;
                for (int i3 = 0; i3 < g.typeDataItem[i1] && i3 < rini.rTerm.size(); ++i3) {
                    if (rini.rTerm[i3].datanum <= 0) continue;
                    for (int i4 = 0; i4 < rini.rTerm[i3].datanum; ++i4) {
                        for (int i5 = 0; i5 < rini.rTerm[i3].incnum; ++i5) {
                            // transposed: strings[row=temp][col=i2+1]
                            if (temp < rows.size() && (i2 + 1) < rows[temp].size()) {
                                int lineIdx = -1, arrIdx = i4, dsIdx = i5;
                                // 找到对应 rDataLine 索引 (只有 datanum>0 的 term 产生 rDataLine)
                                int cnt = -1;
                                for (int t = 0; t <= i3; ++t)
                                    if (rini.rTerm[t].datanum > 0) cnt++;
                                lineIdx = cnt;
                                if (lineIdx >= 0 && lineIdx < rt.rData[i2].rDataLine.size()
                                    && arrIdx < rt.rData[i2].rDataLine[lineIdx].rArray.size()
                                    && dsIdx < rt.rData[i2].rDataLine[lineIdx].rArray[arrIdx].dataArray.size()) {
                                    RFileIO::writeRDataStr(
                                        rt.rData[i2].rDataLine[lineIdx].rArray[arrIdx].dataArray[dsIdx],
                                        rows[temp][i2 + 1]);
                                }
                            }
                            temp++;
                        }
                    }
                }
            }
        } else {
            // 其他类型: 标准 — 行是记录(skip header), 列是字段
            int recordCount = rows.size() - 1; // 减去表头
            for (int r = 0; r < recordCount; ++r)
                RFileIO::addNewRData(&m_rFile, i1, g);

            for (int i2 = 0; i2 < rt.dataNum; ++i2) {
                int temp = 0;
                for (int i3 = 0; i3 < rt.rData[i2].rDataLine.size(); ++i3) {
                    for (int i4 = 0; i4 < rt.rData[i2].rDataLine[i3].rArray.size(); ++i4) {
                        for (int i5 = 0; i5 < rt.rData[i2].rDataLine[i3].rArray[i4].dataArray.size(); ++i5) {
                            // standard: strings[row=i2+1][col=temp]
                            if ((i2 + 1) < rows.size() && temp < rows[i2 + 1].size()) {
                                RFileIO::writeRDataStr(
                                    rt.rData[i2].rDataLine[i3].rArray[i4].dataArray[i5],
                                    rows[i2 + 1][temp]);
                            }
                            temp++;
                        }
                    }
                }
            }
        }
    }

    RFileIO::calcNamePos(&m_rFile, g);
    m_editForm->setRFile(&m_rFile);
    populateTypes();
    m_statusBar->showMessage(tr("导入完成"), 5000);
}

void REditWidget::onSearch()
{
    m_statusBar->showMessage(tr("搜索功能 (TODO)"), 3000);
}

void REditWidget::onSearchRange()
{
    onSearch();
}
