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
#include <QInputDialog>
#include <QSpinBox>
#include <limits>
#include <QDataStream>
#include <QCloseEvent>
#include <QSignalBlocker>

QByteArray REditWidget::stateBytes() const
{
    QByteArray bytes;
    QDataStream stream(&bytes, QIODevice::WriteOnly);
    stream << m_rFile.typeNumber << m_rFile.rType.size();
    for (const auto &type : m_rFile.rType) {
        stream << type.rData.size();
        for (const auto &record : type.rData) {
            stream << record.rDataLine.size();
            for (const auto &line : record.rDataLine) {
                stream << line.rArray.size();
                for (const auto &array : line.rArray) {
                    stream << array.dataArray.size();
                    for (const auto &field : array.dataArray) stream << field.dataType << field.dataLen << field.data;
                }
            }
        }
    }
    return bytes;
}

bool REditWidget::confirmDiscard()
{
    if (m_loadedSlot < 0 || stateBytes() == m_savedState) return true;
    auto answer = QMessageBox::question(this, tr("未保存修改"), tr("保存当前进度的修改？"),
        QMessageBox::Save | QMessageBox::Discard | QMessageBox::Cancel, QMessageBox::Cancel);
    if (answer == QMessageBox::Cancel) return false;
    if (answer == QMessageBox::Save) {
        onSave();
        return stateBytes() == m_savedState;
    }
    return true;
}

void REditWidget::closeEvent(QCloseEvent *event)
{
    if (confirmDiscard()) event->accept();
    else event->ignore();
}

bool REditWidget::applyFieldOperation(RDataSingle &field, int operation, const QString &text)
{
    if (operation < 0 || operation > 4) return false;
    if (field.dataType != 0) {
        if (operation != 0) return false;
        RFileIO::writeRDataStr(field, text);
        return true;
    }
    bool valid = false;
    qint64 operand = text.toLongLong(&valid);
    if (!valid || field.dataLen <= 0) return false;
    const qint64 minimum = (std::numeric_limits<qint64>::min)();
    const qint64 maximum = (std::numeric_limits<qint64>::max)();
    qint64 current = RFileIO::readRDataInt(field), result = operand;
    if (operation == 1) {
        if ((operand > 0 && current > maximum - operand) || (operand < 0 && current < minimum - operand)) return false;
        result = current + operand;
    } else if (operation == 2) {
        if ((operand < 0 && current > maximum + operand) || (operand > 0 && current < minimum + operand)) return false;
        result = current - operand;
    } else if (operation == 3) {
        if (current > 0 ? (operand > 0 ? current > maximum / operand : operand < minimum / current)
            : current < 0 && (operand > 0 ? current < minimum / operand : operand < 0 && current < maximum / operand)) return false;
        result = current * operand;
    } else if (operation == 4) {
        if (operand == 0 || (current == minimum && operand == -1)) return false;
        result = current / operand;
    }
    int bits = field.dataLen >= 8 ? 64 : field.dataLen >= 4 ? 32 : field.dataLen >= 2 ? 16 : 8;
    if (bits < 64 && (result < -(qint64(1) << (bits - 1)) || result >= (qint64(1) << (bits - 1)))) return false;
    RFileIO::writeRDataInt(field, result);
    return true;
}

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
    auto *btnFields = new QPushButton(tr("当前记录字段批量"), batchBox);
    batchLayout->addWidget(btnFields);
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
    m_recordList->setSelectionMode(QAbstractItemView::ExtendedSelection);
    connect(btnFields, &QPushButton::clicked, this, [this] {
        if (m_currentType < 0 || m_currentRecord < 0 || m_currentType >= m_rFile.rType.size()
            || m_currentRecord >= m_rFile.rType[m_currentType].rData.size()) return;
        auto &record = m_rFile.rType[m_currentType].rData[m_currentRecord];
        QVector<RDataSingle *> fields;
        for (auto &line : record.rDataLine)
            for (auto &array : line.rArray)
                for (auto &value : array.dataArray) fields.append(&value);
        if (fields.isEmpty()) return;
        QDialog dialog(this);
        dialog.setWindowTitle(tr("当前记录字段批量"));
        auto *layout = new QVBoxLayout(&dialog);
        auto *list = new QListWidget;
        for (int index = 0; index < fields.size(); ++index) {
            auto *item = new QListWidgetItem(QString::number(index) + " " + RFileIO::readRDataStr(*fields[index]), list);
            item->setFlags(item->flags() | Qt::ItemIsUserCheckable);
            item->setCheckState(Qt::Unchecked);
        }
        layout->addWidget(list);
        auto *range = new QHBoxLayout;
        auto *first = new QSpinBox;
        auto *last = new QSpinBox;
        first->setRange(0, fields.size() - 1);
        last->setRange(0, fields.size() - 1);
        last->setValue(fields.size() - 1);
        auto *selectRange = new QPushButton(tr("选择范围"));
        range->addWidget(first);
        range->addWidget(last);
        range->addWidget(selectRange);
        layout->addLayout(range);
        connect(selectRange, &QPushButton::clicked, &dialog, [=] {
            int begin = qMin(first->value(), last->value()), end = qMax(first->value(), last->value());
            for (int row = 0; row < list->count(); ++row)
                list->item(row)->setCheckState(row >= begin && row <= end ? Qt::Checked : Qt::Unchecked);
        });
        auto *select = new QHBoxLayout;
        for (int action = 0; action < 3; ++action) {
            auto *button = new QPushButton(QStringList{tr("全选"), tr("清空"), tr("反选")}[action]);
            select->addWidget(button);
            connect(button, &QPushButton::clicked, &dialog, [list, action] {
                for (int row = 0; row < list->count(); ++row)
                    list->item(row)->setCheckState(action == 0 || (action == 2 && list->item(row)->checkState() == Qt::Unchecked) ? Qt::Checked : Qt::Unchecked);
            });
        }
        layout->addLayout(select);
        auto *valueEdit = new QLineEdit;
        valueEdit->setText(m_editValue->text());
        auto *operation = new QComboBox;
        operation->addItems({tr("赋值"), tr("加"), tr("减"), tr("乘"), tr("除")});
        layout->addWidget(operation);
        layout->addWidget(valueEdit);
        auto *apply = new QPushButton(tr("执行"));
        layout->addWidget(apply);
        connect(apply, &QPushButton::clicked, &dialog, [&, this] {
            int mode = operation->currentIndex();
            QVector<RDataSingle> updated;
            QVector<int> selected;
            for (int index = 0; index < fields.size(); ++index) {
                if (list->item(index)->checkState() != Qt::Checked) continue;
                RDataSingle field = *fields[index];
                if (!applyFieldOperation(field, mode, valueEdit->text())) {
                    QMessageBox::warning(&dialog, tr("批量操作"), tr("字段 %1 的操作无效或结果超出范围，未修改任何字段").arg(index));
                    return;
                }
                selected.append(index);
                updated.append(field);
            }
            for (int index = 0; index < selected.size(); ++index) *fields[selected[index]] = updated[index];
            populateFields();
            dialog.accept();
        });
        dialog.resize(550, 650);
        dialog.exec();
    });
}

void REditWidget::onProgressChanged(int index)
{
    if (index < 0) return;
    if (index == m_loadedSlot) return;
    if (!confirmDiscard()) {
        QSignalBlocker blocker(m_progressCombo);
        m_progressCombo->setCurrentIndex(m_loadedSlot);
        return;
    }
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
    RFileGlobals globals = cfg.rGlobals;
    RFileIO::readIni(globals, cfg.iniPath);
    RFile loaded;

    bool ok;
    if (grpFile.endsWith(".db", Qt::CaseInsensitive)) {
        ok = RFileIO::readDB(grpFile, &loaded, globals);
    } else {
        ok = RFileIO::readR(idxFile, grpFile, &loaded, globals);
    }

    if (ok) {
        RFileIO::calcNamePos(&loaded, globals);
    } else {
        QSignalBlocker blocker(m_progressCombo);
        m_progressCombo->setCurrentIndex(m_loadedSlot);
        m_statusBar->showMessage(tr("读取失败，保留当前工作数据"));
        return;
    }
    m_rFile = loaded;
    cfg.rGlobals = globals;
    m_loadedSlot = index;
    m_savedState = stateBytes();

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
    int slot = m_loadedSlot;
    if (slot < 0 || slot >= cfg.rFileNum) return;

    QString grpFile = cfg.gamePath + cfg.rFileName[slot];
    QString idxFile = cfg.gamePath + cfg.rIdxFileName[slot];

    bool saved = grpFile.endsWith(".db", Qt::CaseInsensitive)
        ? RFileIO::saveDB(grpFile, &m_rFile, cfg.rGlobals)
        : RFileIO::saveR(idxFile, grpFile, &m_rFile, cfg.rGlobals);
    if (!saved) {
        QMessageBox::warning(this, tr("保存"), tr("保存失败，原始数据未替换"));
        return;
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

    m_savedState = stateBytes();
    m_statusBar->showMessage(tr("保存成功"), 3000);
}

void REditWidget::onReload()
{
    int slot = m_progressCombo->currentIndex();
    if (slot < 0) return;
    if (!confirmDiscard()) return;
    loadProgress(slot);
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
    if (m_currentType < 0 || m_currentType >= m_rFile.rType.size()
        || m_currentRecord < 0 || m_currentRecord >= m_rFile.rType[m_currentType].rData.size()) {
        m_statusBar->showMessage(tr("没有可复制的记录"), 3000);
        return;
    }
    m_copiedRecord = m_rFile.rType[m_currentType].rData[m_currentRecord];
    m_copiedType = m_currentType;
    m_hasCopiedRecord = true;
    m_statusBar->showMessage(tr("已复制记录 %1").arg(m_currentRecord), 3000);
}

void REditWidget::onPasteRecord()
{
    if (!m_hasCopiedRecord || m_currentType < 0 || m_currentType >= m_rFile.rType.size()) {
        m_statusBar->showMessage(tr("没有可粘贴的记录"), 3000);
        return;
    }
    auto &type = m_rFile.rType[m_currentType];
    if (m_copiedType != m_currentType) {
        QMessageBox::warning(this, tr("粘贴"), tr("只能粘贴相同类型的记录"));
        return;
    }
    RFile candidate;
    candidate.rType.resize(m_rFile.rType.size());
    RFileIO::addNewRData(&candidate, m_currentType, IniConfig::instance().rGlobals);
    if (!candidate.rType[m_currentType].rData.isEmpty()) {
        const auto &expected = candidate.rType[m_currentType].rData.last();
        bool compatible = expected.rDataLine.size() == m_copiedRecord.rDataLine.size();
        for (int line = 0; compatible && line < expected.rDataLine.size(); ++line) {
            const auto &target = expected.rDataLine[line].rArray;
            const auto &source = m_copiedRecord.rDataLine[line].rArray;
            compatible = target.size() == source.size();
            for (int array = 0; compatible && array < target.size(); ++array) {
                compatible = target[array].dataArray.size() == source[array].dataArray.size();
                for (int item = 0; compatible && item < target[array].dataArray.size(); ++item)
                    compatible = target[array].dataArray[item].dataLen == source[array].dataArray[item].dataLen
                        && target[array].dataArray[item].dataType == source[array].dataArray[item].dataType;
            }
        }
        if (!compatible) {
            QMessageBox::warning(this, tr("粘贴"), tr("复制记录与当前进度的数据结构不一致"));
            return;
        }
    }
    type.rData.append(m_copiedRecord);
    type.dataNum = type.rData.size();
    populateRecords();
    m_recordCombo->setCurrentIndex(type.rData.size() - 1);
    m_statusBar->showMessage(tr("已粘贴记录"), 3000);
}

void REditWidget::onBatchEdit()
{
    if (m_currentType < 0 || m_currentType >= m_rFile.rType.size()) return;

    int fieldIdx = m_fieldCombo->currentIndex();
    int op = m_opCombo->currentIndex();
    QString valStr = m_editValue->text();
    RType rtype = m_rFile.rType[m_currentType];
    bool valid = true;

    auto applyOp = [&](int recordIdx) {
        if (recordIdx < 0 || recordIdx >= rtype.rData.size()) return;
        auto &rd = rtype.rData[recordIdx];
        if (fieldIdx < 0 || fieldIdx >= rd.rDataLine.size()) { valid = false; return; }
        auto &line = rd.rDataLine[fieldIdx];
        for (auto &array : line.rArray)
            for (auto &single : array.dataArray)
                if (!applyFieldOperation(single, op, valStr)) valid = false;
    };

    if (m_radioChecked->isChecked()) {
        for (int i = 0; i < m_recordList->count(); ++i) {
            // QListWidget 没有 checkbox，这里用 selection 代替
            if (m_recordList->item(i)->isSelected())
                applyOp(i);
        }
    } else {
        bool fromValid, toValid;
        int a = m_editFrom->text().toInt(&fromValid);
        int b = m_editTo->text().toInt(&toValid);
        if (!fromValid || !toValid || a < 0 || b < 0 || a >= rtype.rData.size() || b >= rtype.rData.size()) {
            QMessageBox::warning(this, tr("批量操作"), tr("记录范围无效")); return;
        }
        if (a > b) std::swap(a, b);
        for (int i = a; i <= b; ++i)
            applyOp(i);
    }

    if (!valid) {
        QMessageBox::warning(this, tr("批量操作"), tr("操作无效或结果超出字段范围，未修改任何记录")); return;
    }
    m_rFile.rType[m_currentType] = rtype;
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
            int recordCount = 0;
            for (const auto &row : rows) recordCount = qMax(recordCount, row.size() - 1);
            for (int record = 0; record < recordCount; ++record) RFileIO::addNewRData(&m_rFile, i1, g);

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
    bool ok = false;
    QString text = QInputDialog::getText(this, tr("搜索"), tr("名称或字段值:"), QLineEdit::Normal, {}, &ok);
    if (!ok || text.isEmpty()) return;
    int first = m_radioRange->isChecked() ? m_editFrom->text().toInt() : 0;
    int last = m_radioRange->isChecked() ? m_editTo->text().toInt() : m_recordCombo->count() - 1;
    if (m_currentType < 0 || m_currentType >= m_rFile.rType.size()) return;
    const auto &type = m_rFile.rType[m_currentType];
    first = qMax(0, first);
    last = qMin(last, type.rData.size() - 1);
    for (int record = first; record <= last; ++record) {
        const auto &data = type.rData[record];
        bool found = false;
        for (const auto &line : data.rDataLine)
            for (const auto &array : line.rArray)
                for (const auto &value : array.dataArray)
                    if (RFileIO::readRDataStr(value).contains(text, Qt::CaseInsensitive)) found = true;
        if (found) {
            m_recordCombo->setCurrentIndex(record);
            m_statusBar->showMessage(tr("找到记录 %1").arg(record), 3000);
            return;
        }
    }
    m_statusBar->showMessage(tr("未找到匹配记录"), 3000);
}

void REditWidget::onSearchRange()
{
    onSearch();
}
