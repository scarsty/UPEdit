#include "kdefedit.h"
#include "iniconfig.h"
#include "eventdata.h"
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QHeaderView>
#include <QFileDialog>
#include <QMessageBox>
#include <QDataStream>
#include <QLabel>
#include <QSettings>

KDEFEdit::KDEFEdit(QWidget *parent) : QWidget(parent)
{
    auto *mainLayout = new QVBoxLayout(this);

    // 顶部工具栏
    auto *topBar = new QHBoxLayout;
    m_sceneCombo = new QComboBox;
    auto *btnLoad = new QPushButton(tr("读取"));
    auto *btnSave = new QPushButton(tr("保存"));

    auto *btnAdd = new QPushButton(tr("添加指令"));
    auto *btnInsert = new QPushButton(tr("插入指令"));
    auto *btnDelete = new QPushButton(tr("删除指令"));
    auto *btnUp = new QPushButton(tr("上移"));
    auto *btnDown = new QPushButton(tr("下移"));
    auto *btnCopy = new QPushButton(tr("复制"));
    auto *btnPaste = new QPushButton(tr("粘贴"));

    topBar->addWidget(new QLabel(tr("场景:")));
    topBar->addWidget(m_sceneCombo, 1);
    topBar->addWidget(btnLoad);
    topBar->addWidget(btnSave);
    topBar->addWidget(btnAdd);
    topBar->addWidget(btnInsert);
    topBar->addWidget(btnDelete);
    topBar->addWidget(btnUp);
    topBar->addWidget(btnDown);
    topBar->addWidget(btnCopy);
    topBar->addWidget(btnPaste);
    mainLayout->addLayout(topBar);

    // 三栏: 事件列表 | 指令列表 | 参数编辑+预览
    auto *splitter = new QSplitter(Qt::Horizontal);

    m_eventTable = new QTableWidget;
    m_eventTable->setColumnCount(2);
    m_eventTable->setHorizontalHeaderLabels({tr("事件ID"), tr("指令数")});
    m_eventTable->setSelectionBehavior(QAbstractItemView::SelectRows);
    m_eventTable->horizontalHeader()->setStretchLastSection(true);

    m_instrTable = new QTableWidget;
    m_instrTable->setColumnCount(3);
    m_instrTable->setHorizontalHeaderLabels({tr("序号"), tr("指令码"), tr("指令名")});
    m_instrTable->setSelectionBehavior(QAbstractItemView::SelectRows);
    m_instrTable->horizontalHeader()->setStretchLastSection(true);

    auto *rightPanel = new QWidget;
    auto *rightLayout = new QVBoxLayout(rightPanel);
    m_paramTable = new QTableWidget;
    m_paramTable->setColumnCount(2);
    m_paramTable->setHorizontalHeaderLabels({tr("参数名"), tr("值")});
    m_paramTable->horizontalHeader()->setStretchLastSection(true);

    m_previewText = new QTextEdit;
    m_previewText->setReadOnly(true);
    m_previewText->setMaximumHeight(150);

    rightLayout->addWidget(new QLabel(tr("参数:")));
    rightLayout->addWidget(m_paramTable, 1);
    rightLayout->addWidget(new QLabel(tr("预览:")));
    rightLayout->addWidget(m_previewText);

    splitter->addWidget(m_eventTable);
    splitter->addWidget(m_instrTable);
    splitter->addWidget(rightPanel);
    splitter->setStretchFactor(0, 1);
    splitter->setStretchFactor(1, 2);
    splitter->setStretchFactor(2, 1);
    mainLayout->addWidget(splitter, 1);

    loadKDEFIni();

    connect(btnLoad, &QPushButton::clicked, this, &KDEFEdit::onLoadKDEF);
    connect(btnSave, &QPushButton::clicked, this, &KDEFEdit::onSaveKDEF);
    connect(m_eventTable, &QTableWidget::cellClicked, this, &KDEFEdit::onEventSelected);
    connect(m_instrTable, &QTableWidget::cellClicked, this, &KDEFEdit::onInstructionSelected);
    connect(btnAdd, &QPushButton::clicked, this, &KDEFEdit::onAddInstruction);
    connect(btnInsert, &QPushButton::clicked, this, &KDEFEdit::onInsertInstruction);
    connect(btnDelete, &QPushButton::clicked, this, &KDEFEdit::onDeleteInstruction);
    connect(btnUp, &QPushButton::clicked, this, &KDEFEdit::onMoveUp);
    connect(btnDown, &QPushButton::clicked, this, &KDEFEdit::onMoveDown);
    connect(btnCopy, &QPushButton::clicked, this, &KDEFEdit::onCopyInstruction);
    connect(btnPaste, &QPushButton::clicked, this, &KDEFEdit::onPasteInstruction);
}

void KDEFEdit::loadKDEFIni()
{
    IniConfig &cfg = IniConfig::instance();
    // 从 kdef 目录加载事件指令定义
    // 每个指令有: code, name, param_names[]
    // 格式: code=name,param1,param2,...
    QSettings ini(cfg.iniPath, QSettings::IniFormat);
    ini.beginGroup("KDEF");

    int count = ini.value("typenum", 0).toInt();
    for (int i = 0; i < count; ++i) {
        QString val = ini.value(QString("data(%1)").arg(i)).toString();
        QStringList parts = val.split(',', Qt::SkipEmptyParts);
        if (parts.isEmpty()) continue;

        KDEFInstrDef def;
        def.code = i;
        def.name = parts[0].trimmed();
        for (int p = 1; p < parts.size(); ++p)
            def.paramNames.append(parts[p].trimmed());
        m_instrDefs.append(def);
    }

    ini.endGroup();
}

void KDEFEdit::readKDEFFile()
{
    IniConfig &cfg = IniConfig::instance();
    int sceneIndex = m_sceneCombo->currentIndex();
    if (sceneIndex < 0) return;

    QString kdefPath = cfg.gamePath + "/" + cfg.kdefPath;
    QFile file(kdefPath);
    if (!file.open(QIODevice::ReadOnly)) return;
    QDataStream ds(&file);
    ds.setByteOrder(QDataStream::LittleEndian);

    m_events.clear();

    // KDEF 格式: 事件以 int16_t 序列表示，-1 为事件结束标记
    // 每个指令: code, param1, param2, ... (固定参数个数由code决定)
    // 整体数据按场景切分

    QVector<int16_t> allData;
    while (!ds.atEnd()) {
        int16_t val;
        ds >> val;
        allData.append(val);
    }

    // 解析为事件
    int pos = 0;
    int eventId = 0;
    while (pos < allData.size()) {
        KDEFEvent evt;
        evt.eventId = eventId++;

        while (pos < allData.size()) {
            int16_t code = allData[pos++];
            if (code == -1) break; // 事件结束标记

            KDEFInstruction instr;
            instr.code = code;
            int paramCount = getParamCount(code);
            for (int p = 0; p < paramCount && pos < allData.size(); ++p)
                instr.params.append(allData[pos++]);

            evt.instructions.append(instr);
        }
        m_events.append(evt);
    }
}

void KDEFEdit::onLoadKDEF()
{
    readKDEFFile();
    displayEventList();
}

void KDEFEdit::displayEventList()
{
    m_eventTable->setRowCount(m_events.size());
    for (int i = 0; i < m_events.size(); ++i) {
        auto *idItem = new QTableWidgetItem(QString::number(m_events[i].eventId));
        idItem->setFlags(idItem->flags() & ~Qt::ItemIsEditable);
        m_eventTable->setItem(i, 0, idItem);

        auto *cntItem = new QTableWidgetItem(QString::number(m_events[i].instructions.size()));
        cntItem->setFlags(cntItem->flags() & ~Qt::ItemIsEditable);
        m_eventTable->setItem(i, 1, cntItem);
    }
}

void KDEFEdit::displayInstructions(int eventIndex)
{
    m_currentEvent = eventIndex;
    if (eventIndex < 0 || eventIndex >= m_events.size()) return;

    const auto &evt = m_events[eventIndex];
    m_instrTable->setRowCount(evt.instructions.size());

    for (int i = 0; i < evt.instructions.size(); ++i) {
        const auto &instr = evt.instructions[i];
        m_instrTable->setItem(i, 0, new QTableWidgetItem(QString::number(i)));
        m_instrTable->setItem(i, 1, new QTableWidgetItem(QString::number(instr.code)));
        m_instrTable->setItem(i, 2, new QTableWidgetItem(getKDEFName(instr.code)));
        for (int c = 0; c < 3; ++c)
            m_instrTable->item(i, c)->setFlags(m_instrTable->item(i, c)->flags() & ~Qt::ItemIsEditable);
    }
}

void KDEFEdit::displayInstructionDetail(int instrIndex)
{
    m_currentInstr = instrIndex;
    if (m_currentEvent < 0 || m_currentEvent >= m_events.size()) return;
    const auto &evt = m_events[m_currentEvent];
    if (instrIndex < 0 || instrIndex >= evt.instructions.size()) return;

    const auto &instr = evt.instructions[instrIndex];
    m_paramTable->setRowCount(instr.params.size());

    for (int p = 0; p < instr.params.size(); ++p) {
        QString pname = getParamName(instr.code, p);
        auto *nameItem = new QTableWidgetItem(pname);
        nameItem->setFlags(nameItem->flags() & ~Qt::ItemIsEditable);
        m_paramTable->setItem(p, 0, nameItem);
        m_paramTable->setItem(p, 1, new QTableWidgetItem(QString::number(instr.params[p])));
    }

    // 预览文本
    QString preview = getKDEFName(instr.code) + "(";
    for (int p = 0; p < instr.params.size(); ++p) {
        if (p > 0) preview += ", ";
        preview += getParamName(instr.code, p) + "=" + QString::number(instr.params[p]);
    }
    preview += ")";
    m_previewText->setText(preview);
}

void KDEFEdit::onEventSelected(int row, int)
{
    displayInstructions(row);
}

void KDEFEdit::onInstructionSelected(int row, int)
{
    displayInstructionDetail(row);
}

void KDEFEdit::onSaveKDEF()
{
    // 从参数表回写
    if (m_currentEvent >= 0 && m_currentInstr >= 0) {
        auto &instr = m_events[m_currentEvent].instructions[m_currentInstr];
        for (int p = 0; p < instr.params.size(); ++p) {
            auto *item = m_paramTable->item(p, 1);
            if (item) instr.params[p] = item->text().toShort();
        }
    }

    IniConfig &cfg = IniConfig::instance();
    QString kdefPath = cfg.gamePath + "/" + cfg.kdefPath;
    QFile file(kdefPath);
    if (!file.open(QIODevice::WriteOnly)) return;
    QDataStream ds(&file);
    ds.setByteOrder(QDataStream::LittleEndian);

    for (const auto &evt : m_events) {
        for (const auto &instr : evt.instructions) {
            ds << (int16_t)instr.code;
            for (int16_t param : instr.params) ds << param;
        }
        ds << (int16_t)(-1); // 事件结束标记
    }

    QMessageBox::information(this, tr("保存"), tr("KDEF保存成功"));
}

void KDEFEdit::onAddInstruction()
{
    if (m_currentEvent < 0 || m_currentEvent >= m_events.size()) return;
    KDEFInstruction instr;
    instr.code = 0;
    m_events[m_currentEvent].instructions.append(instr);
    displayInstructions(m_currentEvent);
}

void KDEFEdit::onInsertInstruction()
{
    if (m_currentEvent < 0 || m_currentInstr < 0) return;
    KDEFInstruction instr;
    instr.code = 0;
    m_events[m_currentEvent].instructions.insert(m_currentInstr, instr);
    displayInstructions(m_currentEvent);
}

void KDEFEdit::onDeleteInstruction()
{
    if (m_currentEvent < 0 || m_currentInstr < 0) return;
    auto &instrs = m_events[m_currentEvent].instructions;
    if (m_currentInstr < instrs.size()) {
        instrs.removeAt(m_currentInstr);
        displayInstructions(m_currentEvent);
        m_paramTable->setRowCount(0);
    }
}

void KDEFEdit::onMoveUp()
{
    if (m_currentEvent < 0 || m_currentInstr <= 0) return;
    auto &instrs = m_events[m_currentEvent].instructions;
    std::swap(instrs[m_currentInstr], instrs[m_currentInstr - 1]);
    m_currentInstr--;
    displayInstructions(m_currentEvent);
}

void KDEFEdit::onMoveDown()
{
    if (m_currentEvent < 0 || m_currentInstr < 0) return;
    auto &instrs = m_events[m_currentEvent].instructions;
    if (m_currentInstr >= instrs.size() - 1) return;
    std::swap(instrs[m_currentInstr], instrs[m_currentInstr + 1]);
    m_currentInstr++;
    displayInstructions(m_currentEvent);
}

void KDEFEdit::onCopyInstruction()
{
    if (m_currentEvent < 0 || m_currentInstr < 0) return;
    const auto &instrs = m_events[m_currentEvent].instructions;
    if (m_currentInstr < instrs.size()) {
        m_clipboard.clear();
        m_clipboard.append(instrs[m_currentInstr]);
    }
}

void KDEFEdit::onPasteInstruction()
{
    if (m_currentEvent < 0 || m_clipboard.isEmpty()) return;
    auto &instrs = m_events[m_currentEvent].instructions;
    int pos = (m_currentInstr >= 0) ? m_currentInstr + 1 : instrs.size();
    for (const auto &instr : m_clipboard)
        instrs.insert(pos++, instr);
    displayInstructions(m_currentEvent);
}

QString KDEFEdit::getKDEFName(int code) const
{
    for (const auto &def : m_instrDefs)
        if (def.code == code) return def.name;
    return QString("Unknown_%1").arg(code);
}

int KDEFEdit::getParamCount(int code) const
{
    for (const auto &def : m_instrDefs)
        if (def.code == code) return def.paramNames.size();
    return 0;
}

QString KDEFEdit::getParamName(int code, int paramIndex) const
{
    for (const auto &def : m_instrDefs)
        if (def.code == code && paramIndex < def.paramNames.size())
            return def.paramNames[paramIndex];
    return QString("P%1").arg(paramIndex);
}
