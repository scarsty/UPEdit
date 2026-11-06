#include "kdefedit.h"
#include "picedit.h"
#include <QSpinBox>
#include "iniconfig.h"
#include "eventdata.h"
#include "mapdata.h"
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QHeaderView>
#include <QFileDialog>
#include <QMessageBox>
#include <QDataStream>
#include <QLabel>
#include <QSettings>
#include <QTemporaryFile>
#include <QRegularExpression>
#include <QInputDialog>
#include <QSignalBlocker>
#include <QDialog>
#include <QDialogButtonBox>
#include <QListWidget>
#include <QtEndian>
#include "fileio.h"
#include "encoding.h"
#include <QCloseEvent>
#include <QTimer>
#include <QLineEdit>

QByteArray KDEFEdit::stateBytes() const
{
    QByteArray bytes;
    QDataStream stream(&bytes, QIODevice::WriteOnly);
    stream << m_events.size();
    for (const auto &event : m_events) {
        stream << event.instructions.size();
        for (const auto &instruction : event.instructions) stream << instruction.code << instruction.params;
    }
    return bytes;
}

bool KDEFEdit::confirmDiscard()
{
    if (stateBytes() == m_savedState || (!m_loaded && m_events.isEmpty())) return true;
    auto answer = QMessageBox::question(this, tr("未保存修改"), tr("保存事件修改？"),
        QMessageBox::Save | QMessageBox::Discard | QMessageBox::Cancel, QMessageBox::Cancel);
    if (answer == QMessageBox::Cancel) return false;
    if (answer == QMessageBox::Save) { onSaveKDEF(); return stateBytes() == m_savedState; }
    return true;
}

void KDEFEdit::closeEvent(QCloseEvent *event)
{
    if (confirmDiscard()) event->accept(); else event->ignore();
}

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

    m_sceneCombo->hide();
    auto *btnTalk = new QPushButton(tr("对话文本"));
    auto *btnNewEvent = new QPushButton(tr("新增事件"));
    auto *btnCopyEvent = new QPushButton(tr("复制事件"));
    auto *btnPasteEvent = new QPushButton(tr("覆盖当前事件"));
    auto *btnDeleteEvent = new QPushButton(tr("删除末尾事件"));
    auto *btnExportEvent = new QPushButton(tr("导出事件文本"));
    topBar->addWidget(btnTalk);
    auto *btnNames = new QPushButton(tr("姓名文本"));
    topBar->addWidget(btnNames);
    connect(btnNames, &QPushButton::clicked, this, [this] { editTextRecords(true); });
    topBar->addWidget(btnNewEvent);
    topBar->addWidget(btnCopyEvent);
    topBar->addWidget(btnPasteEvent);
    topBar->addWidget(btnDeleteEvent);
    topBar->addWidget(btnExportEvent);
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
    connect(m_eventTable, &QTableWidget::currentCellChanged, this, [this](int row, int, int, int) { displayInstructions(row); });
    connect(m_instrTable, &QTableWidget::currentCellChanged, this, [this](int row, int, int, int) { displayInstructionDetail(row); });
    connect(btnAdd, &QPushButton::clicked, this, &KDEFEdit::onAddInstruction);
    connect(btnInsert, &QPushButton::clicked, this, &KDEFEdit::onInsertInstruction);
    connect(btnDelete, &QPushButton::clicked, this, &KDEFEdit::onDeleteInstruction);
    connect(btnUp, &QPushButton::clicked, this, &KDEFEdit::onMoveUp);
    connect(btnDown, &QPushButton::clicked, this, &KDEFEdit::onMoveDown);
    connect(btnCopy, &QPushButton::clicked, this, &KDEFEdit::onCopyInstruction);
    connect(btnPaste, &QPushButton::clicked, this, &KDEFEdit::onPasteInstruction);
    connect(btnTalk, &QPushButton::clicked, this, &KDEFEdit::editTalks);
    connect(btnExportEvent, &QPushButton::clicked, this, [this] {
        QString path = QFileDialog::getSaveFileName(this, tr("导出事件文本"), {}, "Text (*.txt)");
        if (path.isEmpty()) return;
        QString text;
        for (const auto &event : m_events) {
            text += QString("[Event %1]\n").arg(event.eventId);
            for (int index = 0; index < event.instructions.size(); ++index) {
                const auto &instruction = event.instructions[index];
                text += QString::number(index) + ": " + QString::number(instruction.code) + " " + getKDEFName(instruction.code);
                for (int parameter : instruction.params) text += " " + QString::number(parameter);
                text += '\n';
            }
            text += '\n';
        }
        if (!FileIO::writeFileAll(path, text.toUtf8())) QMessageBox::warning(this, tr("导出"), tr("无法写入事件文本"));
    });
    connect(btnNewEvent, &QPushButton::clicked, this, [this] {
        KDEFEvent event;
        event.eventId = m_events.size();
        m_events.append(event);
        displayEventList();
        displayInstructions(event.eventId);
    });
    connect(btnCopyEvent, &QPushButton::clicked, this, [this] {
        if (m_currentEvent < 0 || m_currentEvent >= m_events.size()) return;
        auto event = m_events[m_currentEvent];
        m_eventClipboard = event;
        m_hasEventClipboard = true;
        event.eventId = m_events.size();
        for (auto &instruction : event.instructions) instruction.identity = m_nextIdentity++;
        m_events.append(event);
        displayEventList();
        displayInstructions(event.eventId);
    });
    connect(btnPasteEvent, &QPushButton::clicked, this, &KDEFEdit::onPasteEvent);
    connect(btnDeleteEvent, &QPushButton::clicked, this, [this] {
        if (m_events.isEmpty()) return;
        if (QMessageBox::question(this, tr("删除事件"), tr("删除末尾事件？请先确认场景中没有引用该编号。")) != QMessageBox::Yes) return;
        m_events.removeLast();
        displayEventList();
        displayInstructions(m_events.size() - 1);
    });
    connect(m_paramTable, &QTableWidget::cellChanged, this, [this](int row, int column) {
        if (column != 1 || m_currentEvent < 0 || m_currentEvent >= m_events.size()) return;
        auto &instructions = m_events[m_currentEvent].instructions;
        if (m_currentInstr < 0 || m_currentInstr >= instructions.size() || row >= instructions[m_currentInstr].params.size()) return;
        bool valid = false;
        int value = m_paramTable->item(row, column)->text().toInt(&valid);
        if (!valid || value < SHRT_MIN || value > SHRT_MAX) {
            QSignalBlocker blocker(m_paramTable);
            m_paramTable->item(row, column)->setText(QString::number(instructions[m_currentInstr].params[row]));
            return;
        }
        instructions[m_currentInstr].params[row] = value;
    });
}

void KDEFEdit::loadKDEFIni()
{
    IniConfig &cfg = IniConfig::instance();
    QTemporaryFile temporary;
    QString path;
    if (!prepareIniPath(cfg.iniPath, temporary, path)) return;
    QSettings ini(path, QSettings::IniFormat);
    auto value = [&ini](const QString &key) {
        QVariant entry = ini.value(key);
        return entry.metaType().id() == QMetaType::QStringList ? entry.toStringList().join(',') : entry.toString();
    };
    m_instrDefs.clear();
    int count = qBound(0, ini.value("KdefAttrib/number", 0).toInt(), 32768);
    for (int i = 0; i < count; ++i) {
        QStringList parts = value(QString("KdefAttrib/attrib%1").arg(i)).split(QRegularExpression("\\s+"), Qt::SkipEmptyParts);
        KDEFInstrDef def;
        def.code = i;
        if (parts.size() < 6) { m_instrDefs.append(def); continue; }
        bool valid = false;
        def.code = parts[0].toInt(&valid, 16);
        int words = parts[1].toInt();
        if (!valid || words < 1 || words > 256) {
            def.code = i;
            m_instrDefs.append(def);
            continue;
        }
        def.name = parts.mid(5).join(' ');
        def.guide = value(QString("KdefAttrib/guidestring%1").arg(i));
        QStringList quoteTypes = value(QString("KdefAttrib/guidequotetype%1").arg(i)).split(QRegularExpression("\\s+"), Qt::SkipEmptyParts);
        QStringList quoteCounts = value(QString("KdefAttrib/guidequotecount%1").arg(i)).split(QRegularExpression("\\s+"), Qt::SkipEmptyParts);
        for (int parameter = 1; parameter < words; ++parameter) {
            def.quoteTypes.append(quoteTypes.value(parameter).toInt());
            def.quoteCounts.append(quoteCounts.value(parameter).toInt());
        }
        QStringList labels = value(QString("KdefAttrib/guidelabel%1").arg(i)).split(QRegularExpression("\\s+"), Qt::SkipEmptyParts);
        for (int parameter = 1; parameter < words; ++parameter)
            def.paramNames.append(labels.value(parameter, QString("P%1").arg(parameter)));
        if (parts[2].toInt() == 1) {
            def.yesJump = parts[3].toInt() - 1;
            def.noJump = parts[4].toInt() - 1;
        }
        m_instrDefs.append(def);
    }
    m_guideChoices.clear();
    int comboCount = qBound(0, ini.value("KdefAttrib/GuideComboBoxAmount", 0).toInt(), 10000);
    for (int index = 0; index < comboCount; ++index) {
        QVector<QPair<int, QString>> choices;
        auto parts = value(QString("KdefAttrib/GuideComboBox%1").arg(index)).split(QRegularExpression("\\s+"), Qt::SkipEmptyParts);
        for (int entry = 0; entry + 1 < parts.size(); entry += 2) choices.append(qMakePair(parts[entry].toInt(), parts[entry + 1]));
        m_guideChoices.append(choices);
    }
    m_subInstructions.clear();
    int subCount = qBound(0, ini.value("kdef50/num", 0).toInt(), 32768);
    for (int index = 0; index < subCount; ++index)
        m_subInstructions.append(ini.contains(QString("kdef50/sub%1").arg(index))
            ? value(QString("kdef50/sub%1").arg(index)) : value("kdef50/other"));
    m_warChoices = {{-2, tr("保持不变")}, {-1, tr("无")}};
    qint64 recordSize = 0, nameOffset = -1;
    int nameLength = 0;
    bool validLayout = true;
    int fieldCount = ini.value("W_Modify/typedataitem", 0).toInt();
    if (fieldCount <= 0 || fieldCount > 32768) validLayout = false;
    for (int field = 0; validLayout && field < fieldCount; ++field) {
        auto parts = value(QString("W_Modify/data(%1)").arg(field)).split(QRegularExpression("\\s+"), Qt::SkipEmptyParts);
        if (parts.size() < 7) { validLayout = false; break; }
        bool countValid = false, repeatValid = false, lengthValid = false;
        int count = parts[0].toInt(&countValid), repeat = parts[1].toInt(&repeatValid), length = parts[2].toInt(&lengthValid);
        if (!countValid || !repeatValid || !lengthValid || count < 0 || repeat < 0 || length < 0
            || count > SHRT_MAX || repeat > SHRT_MAX || length > SHRT_MAX) { validLayout = false; break; }
        qint64 fieldSize = qint64(count) * repeat * length;
        if (nameOffset < 0 && parts[4].toInt() == 1 && parts[3].toInt() == 1 && fieldSize > 0) {
            nameOffset = recordSize;
            nameLength = length;
        }
        recordSize += fieldSize;
        if (recordSize > INT_MAX) validLayout = false;
    }
    if (validLayout && recordSize > 0 && !cfg.warData.isEmpty()) {
        QFile warFile(cfg.gamePath + "/" + cfg.warData);
        if (warFile.open(QIODevice::ReadOnly) && warFile.size() % recordSize == 0
            && warFile.size() / recordSize <= SHRT_MAX + 1) {
            for (int record = 0; record < warFile.size() / recordSize; ++record) {
                QString name;
                if (nameOffset >= 0) {
                    if (!warFile.seek(record * recordSize + nameOffset)) break;
                    auto bytes = warFile.read(nameLength);
                    if (bytes.size() != nameLength) break;
                    name = Encoding::readOutStrWithCode(bytes.constData(), bytes.size(), cfg.dataCode);
                }
                m_warChoices.append(qMakePair(record, name));
            }
        }
    }
}

bool KDEFEdit::decodeRecords(const QByteArray &index, const QByteArray &data, QVector<QByteArray> &records)
{
    if (index.size() % 4) return false;
    QVector<QByteArray> decoded;
    qint32 begin = 0;
    for (int offset = 0; offset < index.size(); offset += 4) {
        qint32 end = qFromLittleEndian<qint32>(index.constData() + offset);
        if (end < begin || end > data.size()) return false;
        decoded.append(data.mid(begin, end - begin));
        begin = end;
    }
    if (begin != data.size()) return false;
    records = decoded;
    return true;
}

bool KDEFEdit::encodeRecords(const QVector<QByteArray> &records, QByteArray &index, QByteArray &data)
{
    index.clear();
    data.clear();
    QDataStream stream(&index, QIODevice::WriteOnly);
    stream.setByteOrder(QDataStream::LittleEndian);
    for (const auto &record : records) {
        if (qint64(data.size()) + record.size() > INT_MAX) return false;
        data.append(record);
        stream << qint32(data.size());
    }
    return stream.status() == QDataStream::Ok;
}

void KDEFEdit::readKDEFFile()
{
    IniConfig &cfg = IniConfig::instance();
    QVector<QByteArray> records;
    QString indexPath = cfg.gamePath + "/" + cfg.kdefIdx, dataPath = cfg.gamePath + "/" + cfg.kdefGrp;
    if (cfg.kdefIdx.isEmpty() || cfg.kdefGrp.isEmpty() || !QFile::exists(indexPath) || !QFile::exists(dataPath)
        || !decodeRecords(FileIO::readFileAll(indexPath), FileIO::readFileAll(dataPath), records)) {
        QMessageBox::warning(this, tr("读取"), tr("KDEF IDX/GRP 不存在或偏移无效"));
        return;
    }
    QVector<KDEFEvent> events;
    for (const auto &record : records) {
        if (record.size() % 2) { QMessageBox::warning(this, tr("读取"), tr("KDEF 事件字节数不是偶数")); return; }
        KDEFEvent evt;
        evt.eventId = events.size();
        int position = 0;
        while (position < record.size()) {
            KDEFInstruction instr;
            instr.code = qFromLittleEndian<qint16>(record.constData() + position);
            position += 2;
            int count = getParamCount(instr.code);
            if (count * 2 > record.size() - position) { QMessageBox::warning(this, tr("读取"), tr("KDEF 指令参数被截断或配置不匹配")); return; }
            for (int parameter = 0; parameter < count; ++parameter, position += 2)
                instr.params.append(qFromLittleEndian<qint16>(record.constData() + position));
            instr.identity = m_nextIdentity++;
            evt.instructions.append(instr);
        }
        events.append(evt);
    }
    m_events = events;
    m_savedState = stateBytes();
    m_loaded = true;
    m_currentEvent = m_currentInstr = -1;
    m_instrTable->setRowCount(0);
    m_paramTable->setRowCount(0);
}

void KDEFEdit::onLoadKDEF()
{
    if (!confirmDiscard()) return;
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

void KDEFEdit::onPasteEvent()
{
    if (!m_hasEventClipboard || m_currentEvent < 0 || m_currentEvent >= m_events.size()) return;
    if (QMessageBox::question(this, tr("覆盖事件"), tr("确认用复制的事件覆盖当前事件？"),
        QMessageBox::Yes | QMessageBox::Cancel, QMessageBox::Cancel) != QMessageBox::Yes) return;
    int destination = m_currentEvent;
    auto replacement = m_eventClipboard;
    replacement.eventId = m_events[destination].eventId;
    for (auto &instruction : replacement.instructions) instruction.identity = m_nextIdentity++;
    m_events[destination] = replacement;
    displayEventList();
    displayInstructions(destination);
}

void KDEFEdit::displayInstructions(int eventIndex)
{
    m_currentEvent = eventIndex;
    m_currentInstr = -1;
    m_paramTable->setRowCount(0);
    m_instrTable->setRowCount(0);
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
    QSignalBlocker blocker(m_paramTable);
    m_currentInstr = instrIndex;
    if (m_currentEvent < 0 || m_currentEvent >= m_events.size()) return;
    const auto &evt = m_events[m_currentEvent];
    if (instrIndex < 0 || instrIndex >= evt.instructions.size()) return;

    const auto &instr = evt.instructions[instrIndex];
    m_paramTable->setRowCount(instr.params.size());
    const KDEFInstrDef *definition = nullptr;
    for (const auto &candidate : m_instrDefs) if (candidate.code == instr.code) { definition = &candidate; break; }

    for (int p = 0; p < instr.params.size(); ++p) {
        m_paramTable->removeCellWidget(p, 1);
        QString pname = getParamName(instr.code, p);
        int subInstruction = instr.code == 50 && !instr.params.isEmpty() ? instr.params[0] : -1;
        if (subInstruction == 0) {
            if (p == 1) pname = tr("变量");
            if (p == 2) pname = tr("数值");
        } else if (subInstruction == 1 || subInstruction == 2) {
            const QStringList labels = {tr("子指令"), tr("变量标志"), tr("操作数位宽"),
                tr("数组/字符串变量"), tr("下标"), tr("值")};
            if (p < labels.size()) pname = labels[p];
        } else if (subInstruction == 3) {
            const QStringList labels = {tr("子指令"), tr("右操作数为变量"), tr("运算"), tr("目标变量"), tr("左变量"), tr("右操作数")};
            if (p < labels.size()) pname = labels[p];
        } else if (subInstruction == 4) {
            const QStringList labels = {tr("子指令"), tr("右操作数为变量"), tr("条件"), tr("变量 A"), tr("操作数 B")};
            if (p < labels.size()) pname = labels[p];
        }
        const QMap<int, QStringList> labels50 = {
            {8, {tr("变量标志"), tr("对话编号"), tr("字符串变量")}},
            {9, {tr("变量标志"), tr("格式字符串变量"), tr("目标字符串变量"), tr("数值")}},
            {10, {tr("字符串变量"), tr("返回长度变量")}},
            {11, {tr("目标字符串变量"), tr("字符串变量 A"), tr("字符串变量 B")}},
            {12, {tr("变量标志"), tr("空格数量"), tr("字符串变量")}},
            {16, {tr("变量标志"), tr("R 类别"), tr("记录编号"), tr("属性字节偏移"), tr("数值")}},
            {17, {tr("变量标志"), tr("R 类别"), tr("记录编号"), tr("属性字节偏移"), tr("返回值变量")}},
            {18, {tr("变量标志"), tr("队伍位置"), tr("数值")}},
            {19, {tr("变量标志"), tr("队伍位置"), tr("返回值变量")}},
            {20, {tr("变量标志"), tr("物品编号"), tr("返回数量变量")}},
            {21, {tr("变量标志"), tr("场景编号"), tr("事件编号"), tr("事件属性"), tr("数值")}},
            {22, {tr("变量标志"), tr("场景编号"), tr("事件编号"), tr("事件属性"), tr("返回值变量")}},
            {23, {tr("变量标志"), tr("场景编号"), tr("图层"), tr("X"), tr("Y"), tr("数值")}},
            {24, {tr("变量标志"), tr("场景编号"), tr("图层"), tr("X"), tr("Y"), tr("返回值变量")}},
            {25, {tr("变量标志"), tr("操作数位宽"), tr("地址低字"), tr("地址高字"), tr("偏移"), tr("数值")}},
            {26, {tr("变量标志"), tr("操作数位宽"), tr("地址低字"), tr("地址高字"), tr("偏移"), tr("返回值变量")}},
            {27, {tr("变量标志"), tr("R 类别"), tr("记录编号"), tr("目标字符串变量")}},
            {28, {tr("返回战斗序号变量")}},
            {29, {tr("变量标志"), tr("战斗序号"), tr("步数"), tr("返回目标变量"), tr("动画显示")}},
            {30, {tr("变量标志"), tr("战斗序号"), tr("属性偏移"), tr("返回值变量")}},
            {31, {tr("变量标志"), tr("战斗序号"), tr("属性偏移"), tr("数值")}},
            {32, {tr("变量标志"), tr("指令偏移"), tr("变量编号")}},
            {33, {tr("变量标志"), tr("字符串变量"), tr("X"), tr("Y"), tr("颜色")}},
            {34, {tr("变量标志"), tr("X"), tr("Y"), tr("宽度"), tr("高度"), tr("透明度")}},
            {35, {tr("返回键值变量"), tr("返回鼠标 X 变量"), tr("返回鼠标 Y 变量")}},
            {36, {tr("变量标志"), tr("字符串变量"), tr("X"), tr("Y"), tr("颜色")}},
            {37, {tr("变量标志"), tr("延时时间")}},
            {38, {tr("变量标志"), tr("随机数范围"), tr("返回值变量")}},
            {39, {tr("变量标志"), tr("菜单项数"), tr("菜单数组变量"), tr("返回值变量"), tr("X"), tr("Y")}},
            {40, {tr("变量标志/最大显示项数"), tr("菜单项数"), tr("菜单数组变量"), tr("返回值变量"), tr("X"), tr("Y")}},
            {41, {tr("变量标志"), tr("图片类别"), tr("X"), tr("Y"), tr("图片编号")}},
            {42, {tr("变量标志"), tr("X"), tr("Y")}},
            {43, {tr("变量标志"), tr("事件编号"), tr("参数 0"), tr("参数 1"), tr("参数 2"), tr("参数 3")}},
            {44, {tr("变量标志"), tr("人物战斗序号"), tr("动作类型"), tr("武功动画类型")}},
            {45, {tr("变量标志"), tr("数值")}},
            {46, {tr("变量标志"), tr("起点 X"), tr("起点 Y"), tr("宽度"), tr("高度"), tr("数值")}},
            {47, {tr("变量标志"), tr("人物战斗序号")}},
            {48, {tr("起始变量编号"), tr("变量个数")}}
        };
        if (p > 0 && labels50.contains(subInstruction) && p <= labels50[subInstruction].size())
            pname = labels50[subInstruction][p - 1];
        auto *nameItem = new QTableWidgetItem(pname);
        nameItem->setFlags(nameItem->flags() & ~Qt::ItemIsEditable);
        m_paramTable->setItem(p, 0, nameItem);
        m_paramTable->setItem(p, 1, new QTableWidgetItem(QString::number(instr.params[p])));
        QVector<QPair<int, QString>> choices;
        int quoteType = definition ? definition->quoteTypes.value(p) : 0;
        QVector<PicEdit::PicData> portraits;
        if (instr.code == 44 && instr.params.size() == 7 && p == 0) {
            const auto &config = IniConfig::instance();
            if (!config.headPicName.isEmpty()
                && PicEdit::decodeFile(FileIO::readFileAll(config.gamePath + "/" + config.headPicName), portraits))
                for (int index = 0; index < portraits.size() && index <= SHRT_MAX; ++index)
                    choices.append({index, tr("头像")});
        }
        int quoteCount = definition ? definition->quoteCounts.value(p) : -1;
        if (instr.code == 44 && instr.params.size() == 7) {
            if (p == 1) quoteType = 3;
            if (p == 2) {
                quoteType = 4;
                choices.append({-2, tr("默认姓名")});
            }
        }
        if (instr.code == 45 && instr.params.size() == 3) {
            if (p == 0) choices = {{0, tr("人物")}, {1, tr("物品")}, {2, tr("场景")}, {3, tr("武功")}};
            if (p == 1) { quoteType = 1; quoteCount = instr.params[0] + 1; }
            if (p == 2) quoteType = 4;
        }
        if (instr.code == 46 && instr.params.size() == 2 && p == 0) quoteType = 3;
        if (instr.code == 47 && instr.params.size() == 3 && p == 0) { quoteType = 1; quoteCount = 2; }
        switch (instr.code) {
        case 1:
            if (p == 0) quoteType = 3;
            if (p == 1) { quoteType = 1; quoteCount = 1; }
            break;
        case 4:
        case 43:
            if (p == 0) { quoteType = 1; quoteCount = 2; }
            break;
        case 3:
            if (p == 0 || p == 1 || p == 3) { quoteType = 1; quoteCount = 3; }
            break;
        case 6:
            if (p == 0) quoteType = 2;
            break;
        case 0x30:
        case 0x31:
            if (p == 0) { quoteType = 1; quoteCount = 1; }
            break;
        case 39:
            if (p == 0) { quoteType = 1; quoteCount = 3; }
            break;
        case 2:
        case 0x12:
        case 0x20:
            if (p == 0) { quoteType = 1; quoteCount = 2; }
            break;
        case 0x0a:
        case 0x15:
        case 0x17:
        case 0x1c:
        case 0x1d:
        case 0x21:
        case 0x22:
        case 0x23:
            if (p == 0) { quoteType = 1; quoteCount = 1; }
            if (instr.code == 0x21 && p == 1) { quoteType = 1; quoteCount = 4; }
            if (instr.code == 0x23 && p == 2) { quoteType = 1; quoteCount = 4; }
            break;
        case 36:
            if (p == 0) choices = {{0, tr("男")}, {1, tr("女")}, {2, tr("未知")}, {256, tr("JMP=0")}};
            break;
        case 40:
            if (p == 0) choices = {{0, tr("向上")}, {1, tr("向右")}, {2, tr("向左")}, {3, tr("向下")}};
            break;
        case 0x11:
        case 0x1a:
        case 0x26:
            if (p == 0) { quoteType = 1; quoteCount = 3; }
            break;
        case 0x29:
            if (p == 0) { quoteType = 1; quoteCount = 1; }
            if (p == 1) { quoteType = 1; quoteCount = 2; }
            break;
        default:
            break;
        }
        int flags = instr.params.value(1);
        if (subInstruction == 8 && p == 2 && !(flags & 1)) quoteType = 3;
        if (subInstruction == 20 && p == 2 && !(flags & 1)) { quoteType = 1; quoteCount = 2; }
        if (subInstruction >= 21 && subInstruction <= 24 && p == 2 && !(flags & 1)) { quoteType = 1; quoteCount = 3; }
        if ((subInstruction == 16 || subInstruction == 17 || subInstruction == 27) && p == 3 && !(flags & 1)) {
            quoteType = 1;
            quoteCount = instr.params.value(2) + 1;
        }
        if (definition && (definition->yesJump == p || definition->noJump == p)) {
            int sourceEnd = 0, targetOffset = 0;
            for (int index = 0; index <= instrIndex; ++index) sourceEnd += 1 + evt.instructions[index].params.size();
            for (int target = 0; target <= evt.instructions.size(); ++target) {
                int relative = targetOffset - sourceEnd;
                if (relative >= SHRT_MIN && relative <= SHRT_MAX)
                    choices.append(qMakePair(relative, target == evt.instructions.size() ? tr("事件末尾") : tr("指令 %1").arg(target)));
                if (target < evt.instructions.size()) targetOffset += 1 + evt.instructions[target].params.size();
            }
        } else if (quoteType == 1) {
            const auto &file = IniConfig::instance().rGlobals.rFile;
            if (quoteCount >= 0 && quoteCount < file.rType.size()) {
                bool sceneSentinel = (instr.code == 3 && (p == 1 || p == 3)) || instr.code == 0x1a || instr.code == 0x26;
                choices = sceneSentinel ? QVector<QPair<int, QString>>{{-2, tr("当前场景")}, {-1, tr("无")}}
                    : QVector<QPair<int, QString>>{{-2, tr("保持不变")}, {-1, tr("无")}};
                const auto &type = file.rType[quoteCount];
                for (int record = 0; record < type.rData.size(); ++record) {
                    QString name;
                    const auto &lines = type.rData[record].rDataLine;
                    if (type.namePos >= 0 && type.namePos < lines.size() && !lines[type.namePos].rArray.isEmpty()
                        && !lines[type.namePos].rArray[0].dataArray.isEmpty()) name = RFileIO::readRDataStr(lines[type.namePos].rArray[0].dataArray[0]);
                    choices.append({record, name});
                }
            }
        } else if (quoteType == 2) {
            choices = m_warChoices;
        } else if (quoteType == 3 || quoteType == 4) {
            const auto &config = IniConfig::instance();
            QString indexPath = quoteType == 3 ? config.talkIdx : config.nameIdx;
            QString dataPath = quoteType == 3 ? config.talkGrp : config.nameGrp;
            QVector<QByteArray> records;
            if (!indexPath.isEmpty() && !dataPath.isEmpty()
                && decodeRecords(FileIO::readFileAll(config.gamePath + "/" + indexPath),
                    FileIO::readFileAll(config.gamePath + "/" + dataPath), records)) {
                for (int record = 0; record < records.size() && record <= SHRT_MAX; ++record) {
                    auto bytes = records[record];
                    if (config.talkInvert == 0) for (char &byte : bytes) {
                        byte = char(quint8(byte) ^ 0xff);
                        if (quint8(byte) == 0xff) byte = 0;
                    }
                    choices.append({record, Encoding::readOutStrWithCode(bytes.constData(), bytes.size(), config.talkCode).left(120)});
                }
            }
        } else if (quoteType == 5 && quoteCount >= 0 && quoteCount < m_guideChoices.size()) choices = m_guideChoices[quoteCount];
        if (instr.code == 50 && p == 0)
            for (int sub = 0; sub < m_subInstructions.size(); ++sub) choices.append({sub, m_subInstructions[sub]});
        if ((subInstruction == 1 || subInstruction == 2) && p == 1) {
            choices = {{0, tr("直接数值")}, {1, tr("下标为变量")}};
            if (subInstruction == 1) {
                choices.append(qMakePair(2, tr("值为变量")));
                choices.append(qMakePair(3, tr("下标和值均为变量")));
            }
        }
        if ((subInstruction == 1 || subInstruction == 2) && p == 2)
            choices = {{0, tr("16位数")}, {1, tr("8位字节")}};
        if (p == 1) {
            const QMap<int, int> flagMasks = {{3, 1}, {4, 1}, {8, 1}, {9, 1}, {12, 1},
                {16, 7}, {17, 3}, {18, 3}, {19, 1}, {20, 1}, {21, 15}, {22, 7}, {23, 31},
                {24, 15}, {25, 3}, {26, 1}, {27, 1}, {29, 3}, {30, 3}, {31, 7}, {32, 1},
                {33, 7}, {34, 31}, {36, 7}, {37, 1}, {38, 1}, {39, 7},
                {41, 7}, {42, 3}, {43, 31}, {44, 7}, {45, 1}, {46, 31}, {47, 1}};
            int mask = flagMasks.value(subInstruction);
            if (mask) {
                choices.clear();
                for (int flags = 0; flags <= mask; ++flags)
                    choices.append(qMakePair(flags, flags == 0 ? tr("直接数值")
                        : tr("变量标志 0b%1").arg(QString::number(flags, 2))));
                if (subInstruction == 3 || subInstruction == 4)
                    choices = {{0, tr("直接数值")}, {1, tr("右操作数为变量")}};
            }
        }
        if (subInstruction == 3 && p == 2)
            choices = {{0, "+"}, {1, "-"}, {2, "*"}, {3, "/"}, {4, "mod"}};
        if (subInstruction == 4 && p == 2)
            choices = {{0, "A < B"}, {1, "A <= B"}, {2, "A = B"}, {3, "A != B"},
                {4, "A >= B"}, {5, "A > B"}, {6, "JMP = 0"}, {7, "JMP = 1"}};
        if ((subInstruction == 16 || subInstruction == 17) && p == 4 && !(flags & 2)) {
            choices.clear();
            const auto &globals = IniConfig::instance().rGlobals;
            int type = instr.params.value(2) + 1;
            if (type >= 0 && type < globals.rIni.size()) {
                const auto &terms = globals.rIni[type].rTerm;
                qint64 offset = 0;
                for (int term = 0; term < terms.size() && offset <= SHRT_MAX; ++term)
                    for (int array = 0; array < terms[term].datanum && offset <= SHRT_MAX; ++array)
                        for (int part = 0; part < terms[term].incnum && offset <= SHRT_MAX; ++part) {
                            if (term + part >= terms.size() || terms[term + part].datalen <= 0) break;
                            choices.append(qMakePair(int(offset), terms[term + part].name + QString("[%1]").arg(array)));
                            offset += terms[term + part].datalen;
                        }
            }
        }
        if ((subInstruction == 21 || subInstruction == 22) && p == 4 && !(flags & 4)) {
            choices.clear();
            const auto &fields = IniConfig::instance().dIni.attrib;
            for (int field = 0; field < fields.size() && field <= SHRT_MAX; ++field)
                choices.append(qMakePair(field, fields[field]));
        }
        if (!choices.isEmpty()) {
            auto *combo = new QComboBox;
            combo->setEditable(true);
            for (const auto &choice : choices) combo->addItem(QString::number(choice.first) + " " + choice.second, choice.first);
            if (!portraits.isEmpty()) {
                combo->setObjectName("kdefPortrait");
                combo->setIconSize(QSize(64, 64));
                for (int index = 0; index < combo->count(); ++index) {
                    int portrait = combo->itemData(index).toInt();
                    if (portrait >= 0 && portrait < portraits.size()) {
                        QImage image = QImage::fromData(portraits[portrait].data);
                        if (!image.isNull()) combo->setItemIcon(index, QPixmap::fromImage(image.scaled(64, 64, Qt::KeepAspectRatio, Qt::SmoothTransformation)));
                    }
                }
            }
            int selected = combo->findData(instr.params[p]);
            if (selected >= 0) combo->setCurrentIndex(selected);
            else combo->setEditText(QString::number(instr.params[p]));
            m_paramTable->setCellWidget(p, 1, combo);
            connect(combo, &QComboBox::currentTextChanged, this, [this, combo, p, instrIndex, eventIndex = m_currentEvent](const QString &text) {
                bool valid = false;
                int value = text.section(' ', 0, 0).toInt(&valid);
                if (!valid || value < SHRT_MIN || value > SHRT_MAX || eventIndex != m_currentEvent || instrIndex != m_currentInstr) return;
                m_events[eventIndex].instructions[instrIndex].params[p] = value;
                int code = m_events[eventIndex].instructions[instrIndex].code;
                if ((p <= 2 && code == 50) || (p == 0 && code == 45))
                    QTimer::singleShot(0, this, [this, eventIndex, instrIndex] {
                        if (m_currentEvent == eventIndex && m_currentInstr == instrIndex)
                            displayInstructionDetail(instrIndex);
                    });
            });
        }
        if (((subInstruction == 33 || subInstruction == 36) && p == 5 && !(flags & 4))
            || (instr.code == 44 && instr.params.size() == 7 && p == 5)
            || (instr.code == 46 && instr.params.size() == 2 && p == 1)) {
            auto *container = new QWidget;
            auto *layout = new QHBoxLayout(container);
            layout->setContentsMargins(0, 0, 0, 0);
            uint8_t red[256]{}, green[256]{}, blue[256]{};
            const auto &config = IniConfig::instance();
            MapIO::readPalette(config.gamePath + "/" + config.palette, red, green, blue);
            auto *foreground = new QComboBox;
            auto *background = new QComboBox;
            foreground->setObjectName("kdefForeground");
            background->setObjectName("kdefBackground");
            foreground->setToolTip(tr("前景调色板索引"));
            background->setToolTip(tr("背景调色板索引"));
            for (int color = 0; color < 256; ++color) {
                QPixmap swatch(16, 16);
                swatch.fill(QColor(red[color], green[color], blue[color]));
                foreground->addItem(QIcon(swatch), QString::number(color), color);
                background->addItem(QIcon(swatch), QString::number(color), color);
            }
            foreground->setCurrentIndex(quint16(instr.params[p]) & 0xff);
            background->setCurrentIndex(quint16(instr.params[p]) >> 8);
            layout->addWidget(foreground);
            layout->addWidget(background);
            m_paramTable->setCellWidget(p, 1, container);
            auto update = [this, foreground, background, p, instrIndex, eventIndex = m_currentEvent] {
                if (eventIndex != m_currentEvent || instrIndex != m_currentInstr) return;
                m_events[eventIndex].instructions[instrIndex].params[p]
                    = qint16(foreground->currentIndex() | (background->currentIndex() << 8));
            };
            connect(foreground, &QComboBox::currentIndexChanged, this, update);
            connect(background, &QComboBox::currentIndexChanged, this, update);
        }
        if (subInstruction == 40 && p == 1) {
            auto *container = new QWidget;
            auto *layout = new QHBoxLayout(container);
            layout->setContentsMargins(0, 0, 0, 0);
            auto *variables = new QComboBox;
            variables->setObjectName("kdef40Flags");
            for (int value = 0; value < 8; ++value)
                variables->addItem(tr("变量标志 %1").arg(value), value);
            variables->setCurrentIndex(quint16(instr.params[p]) & 7);
            auto *extra = new QSpinBox;
            extra->setObjectName("kdef40Extra");
            extra->setRange(0, 255);
            extra->setPrefix(tr("最大显示项数 "));
            extra->setValue(quint16(instr.params[p]) >> 8);
            layout->addWidget(variables);
            layout->addWidget(extra);
            m_paramTable->setCellWidget(p, 1, container);
            auto update = [this, variables, extra, instrIndex, eventIndex = m_currentEvent] {
                if (eventIndex != m_currentEvent || instrIndex != m_currentInstr) return;
                auto &value = m_events[eventIndex].instructions[instrIndex].params[1];
                value = qint16((quint16(value) & 0x00f8) | variables->currentData().toInt() | (extra->value() << 8));
            };
            connect(variables, &QComboBox::currentIndexChanged, this, update);
            connect(extra, &QSpinBox::valueChanged, this, update);
        }
        if ((subInstruction == 25 || subInstruction == 26) && p == 3 && instr.params.size() > 4) {
            auto *address = new QLineEdit;
            quint32 value = quint16(instr.params[3]) | (quint32(quint16(instr.params[4])) << 16);
            address->setText(QString("0x%1").arg(value, 8, 16, QLatin1Char('0')));
            m_paramTable->item(p, 0)->setText(tr("32位内存地址"));
            auto *container = new QWidget;
            auto *layout = new QHBoxLayout(container);
            layout->setContentsMargins(0, 0, 0, 0);
            layout->addWidget(address);
            const auto &memory = IniConfig::instance().memoryList;
            if (!memory.addr.isEmpty()) {
                auto *presets = new QComboBox;
                presets->setObjectName("kdefMemoryPresets");
                presets->addItem(tr("常用地址"));
                for (int index = 0; index < memory.addr.size(); ++index)
                    presets->addItem(QString("0x%1 %2").arg(memory.addr[index], 8, 16, QLatin1Char('0'))
                        .arg(memory.note.value(index)), memory.addr[index]);
                layout->addWidget(presets);
                connect(presets, &QComboBox::activated, this, [presets, address](int index) {
                    if (index <= 0) return;
                    address->setText(QString("0x%1").arg(presets->itemData(index).toUInt(), 8, 16, QLatin1Char('0')));
                    QMetaObject::invokeMethod(address, "editingFinished", Qt::DirectConnection);
                });
            }
            m_paramTable->setCellWidget(p, 1, container);
            connect(address, &QLineEdit::editingFinished, this, [this, address, instrIndex, eventIndex = m_currentEvent] {
                if (eventIndex != m_currentEvent || instrIndex != m_currentInstr) return;
                bool valid = false;
                QString text = address->text().trimmed();
                if (text.startsWith("0x", Qt::CaseInsensitive)) text.remove(0, 2);
                quint32 value = text.toUInt(&valid, 16);
                if (!valid) return;
                auto &parameters = m_events[eventIndex].instructions[instrIndex].params;
                parameters[3] = qint16(value & 0xffff);
                parameters[4] = qint16(value >> 16);
                QSignalBlocker blocker(m_paramTable);
                if (auto *item = m_paramTable->item(4, 1)) item->setText(QString::number(parameters[4]));
            });
        }
    }

    // 预览文本
    QString preview = getKDEFName(instr.code) + "(";
    for (int p = 0; p < instr.params.size(); ++p) {
        if (p > 0) preview += ", ";
        preview += getParamName(instr.code, p) + "=" + QString::number(instr.params[p]);
    }
    preview += ")";
    if (definition && !definition->guide.isEmpty()) preview += "\n" + definition->guide;
    if (instr.code == 50 && !instr.params.isEmpty()) preview += "\n" + m_subInstructions.value(instr.params[0]);
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
    IniConfig &cfg = IniConfig::instance();
    QVector<QByteArray> records;
    for (const auto &evt : m_events) {
        QByteArray bytes;
        QDataStream ds(&bytes, QIODevice::WriteOnly);
        ds.setByteOrder(QDataStream::LittleEndian);
        for (const auto &instr : evt.instructions) {
            ds << (int16_t)instr.code;
            for (int16_t param : instr.params) ds << param;
        }
        records.append(bytes);
    }
    QByteArray index, data;
    if (cfg.kdefIdx.isEmpty() || cfg.kdefGrp.isEmpty() || cfg.kdefIdx == cfg.kdefGrp || !encodeRecords(records, index, data)
        || !FileIO::writeFiles({{cfg.gamePath + "/" + cfg.kdefIdx, index}, {cfg.gamePath + "/" + cfg.kdefGrp, data}})) {
        QMessageBox::warning(this, tr("保存"), tr("KDEF 保存失败"));
        return;
    }
    QMessageBox::information(this, tr("保存"), tr("KDEF保存成功"));
    m_savedState = stateBytes();
    m_loaded = true;
}

void KDEFEdit::onAddInstruction()
{
    mutateInstructions(0);
}

void KDEFEdit::onInsertInstruction()
{
    mutateInstructions(1);
}

void KDEFEdit::onDeleteInstruction()
{
    mutateInstructions(2);
}

void KDEFEdit::onMoveUp()
{
    mutateInstructions(3);
}

void KDEFEdit::onMoveDown()
{
    mutateInstructions(4);
}

void KDEFEdit::onCopyInstruction()
{
    if (m_currentEvent < 0 || m_currentEvent >= m_events.size()) return;
    const auto &instrs = m_events[m_currentEvent].instructions;
    QList<int> rows;
    for (const auto &index : m_instrTable->selectionModel()->selectedRows()) rows.append(index.row());
    if (rows.isEmpty() && m_currentInstr >= 0) rows.append(m_currentInstr);
    std::sort(rows.begin(), rows.end());
    QVector<KDEFInstruction> copied;
    for (int row : rows) {
        if (row >= 0 && row < instrs.size()) copied.append(instrs[row]);
    }
    if (!copied.isEmpty()) {
        m_clipboard = copied;
        m_clipboardEvent = m_currentEvent;
        m_clipboardTargets.clear();
        QMap<int, int> positions;
        int offset = 0;
        for (const auto &instruction : instrs) {
            positions.insert(offset, instruction.identity);
            offset += 1 + instruction.params.size();
        }
        positions.insert(offset, -1);
        offset = 0;
        for (const auto &instruction : instrs) {
            int end = offset + 1 + instruction.params.size();
            for (const auto &definition : m_instrDefs) if (definition.code == instruction.code)
                for (int parameter : {definition.yesJump, definition.noJump}) {
                    if (parameter < 0 || parameter >= instruction.params.size() || instruction.params[parameter] == 0) continue;
                    int target = end + instruction.params[parameter];
                    if (positions.contains(target))
                        m_clipboardTargets[instruction.identity].insert(parameter, positions[target]);
                }
            offset = end;
        }
    }
}

void KDEFEdit::onPasteInstruction()
{
    mutateInstructions(5);
}

void KDEFEdit::mutateInstructions(int operation)
{
    if (m_currentEvent < 0 || m_currentEvent >= m_events.size()) return;
    auto original = m_events[m_currentEvent].instructions;
    auto changed = original;
    int selected = m_currentInstr;
    if (operation >= 2 && operation <= 4 && (selected < 0 || selected >= changed.size())) return;
    struct Jump { int source, parameter, target; };
    QVector<Jump> jumps;
    QMap<int, int> identities;
    int offset = 0;
    for (const auto &instruction : original) {
        identities.insert(offset, instruction.identity);
        offset += 1 + instruction.params.size();
    }
    identities.insert(offset, -1);
    offset = 0;
    for (const auto &instruction : original) {
        for (const auto &definition : m_instrDefs) if (definition.code == instruction.code) {
            for (int parameter : {definition.yesJump, definition.noJump}) {
                if (parameter < 0 || parameter >= instruction.params.size() || instruction.params[parameter] == 0) continue;
                int targetOffset = offset + 1 + instruction.params.size() + instruction.params[parameter];
                if (!identities.contains(targetOffset)) {
                    QMessageBox::warning(this, tr("跳转"), tr("现有跳转不指向指令边界，拒绝结构修改"));
                    return;
                }
                jumps.append({instruction.identity, parameter, identities[targetOffset]});
            }
        }
        offset += 1 + instruction.params.size();
    }
    if (operation == 0 || operation == 1) {
        QStringList choices;
        for (const auto &definition : m_instrDefs) choices.append(QString::number(definition.code) + " " + definition.name);
        choices.append(tr("-1 结束"));
        bool accepted = false;
        QString choice = QInputDialog::getItem(this, tr("选择指令"), tr("指令"), choices, 0, false, &accepted);
        if (!accepted) return;
        KDEFInstruction instruction;
        instruction.code = choice.section(' ', 0, 0).toInt();
        instruction.params.fill(0, getParamCount(instruction.code));
        instruction.identity = m_nextIdentity++;
        selected = operation == 0 ? changed.size() : qBound(0, selected, changed.size());
        changed.insert(selected, instruction);
    } else if (operation == 2) {
        int removed = changed[selected].identity;
        for (const auto &jump : jumps) if (jump.target == removed && jump.source != removed) {
            QMessageBox::warning(this, tr("删除"), tr("该指令是跳转目标，请先修改引用")); return;
        }
        changed.removeAt(selected);
    } else if (operation == 3 || operation == 4) {
        int destination = selected + (operation == 3 ? -1 : 1);
        if (destination < 0 || destination >= changed.size()) return;
        changed.swapItemsAt(selected, destination);
        selected = destination;
    } else {
        selected = selected < 0 ? changed.size() : selected + 1;
        QMap<int, int> copiedIdentities;
        for (const auto &instruction : m_clipboard)
            copiedIdentities.insert(instruction.identity, m_nextIdentity++);
        for (auto instruction : m_clipboard) {
            int originalIdentity = instruction.identity;
            QVector<Jump> copiedJumps;
            for (const auto &definition : m_instrDefs) if (definition.code == instruction.code)
                for (int parameter : {definition.yesJump, definition.noJump}) {
                    if (parameter < 0 || parameter >= instruction.params.size() || instruction.params[parameter] == 0) continue;
                    bool found = false;
                    auto savedTargets = m_clipboardTargets.value(originalIdentity);
                    if (m_clipboard.size() > 1 && savedTargets.contains(parameter)
                        && copiedIdentities.contains(savedTargets[parameter])) {
                        copiedJumps.append({originalIdentity, parameter, copiedIdentities[savedTargets[parameter]]});
                        found = true;
                    }
                    if (!found && m_clipboardEvent == m_currentEvent)
                        for (const auto &jump : jumps)
                            if (jump.source == originalIdentity && jump.parameter == parameter) {
                                copiedJumps.append(jump); found = true; break;
                            }
                    if (!found) {
                        QStringList targets;
                        for (int target = 0; target < original.size(); ++target)
                            targets.append(tr("指令 %1: %2").arg(target).arg(getKDEFName(original[target].code)));
                        targets.append(tr("事件末尾"));
                        bool accepted = false;
                        QString target = QInputDialog::getItem(this, tr("选择粘贴跳转目标"),
                            getParamName(instruction.code, parameter), targets, 0, false, &accepted);
                        if (!accepted) return;
                        int targetIndex = targets.indexOf(target);
                        if (targetIndex < 0) return;
                        copiedJumps.append({originalIdentity, parameter,
                            targetIndex == original.size() ? -1 : original[targetIndex].identity});
                    }
                }
            instruction.identity = copiedIdentities[originalIdentity];
            for (auto jump : copiedJumps) {
                jump.source = instruction.identity;
                jumps.append(jump);
            }
            changed.insert(selected++, instruction);
        }
    }
    QMap<int, int> positions;
    offset = 0;
    for (const auto &instruction : changed) {
        positions.insert(instruction.identity, offset);
        offset += 1 + instruction.params.size();
    }
    positions.insert(-1, offset);
    for (auto &instruction : changed) for (const auto &jump : jumps) if (jump.source == instruction.identity) {
        int relative = positions[jump.target] - positions[instruction.identity] - 1 - instruction.params.size();
        if (relative < SHRT_MIN || relative > SHRT_MAX) {
            QMessageBox::warning(this, tr("跳转"), tr("跳转超出16位范围，修改已取消")); return;
        }
        instruction.params[jump.parameter] = relative;
    }
    m_events[m_currentEvent].instructions = changed;
    displayInstructions(m_currentEvent);
    if (!changed.isEmpty()) {
        selected = qBound(0, selected, changed.size() - 1);
        m_instrTable->selectRow(selected);
        displayInstructionDetail(selected);
    }
}

void KDEFEdit::editTalks()
{
    editTextRecords(false);
}

void KDEFEdit::editTextRecords(bool names)
{
    auto &config = IniConfig::instance();
    QString indexName = names ? config.nameIdx : config.talkIdx;
    QString dataName = names ? config.nameGrp : config.talkGrp;
    QString indexPath = config.gamePath + "/" + indexName, dataPath = config.gamePath + "/" + dataName;
    QVector<QByteArray> records;
    bool plainText = !names && dataName.endsWith(".txt", Qt::CaseInsensitive);
    QByteArray plainBytes;
    QByteArray lineEnding("\n");
    if (plainText && QFile::exists(dataPath)) {
        plainBytes = FileIO::readFileAll(dataPath);
        if (plainBytes.contains("\r\n")) lineEnding = "\r\n";
        for (QByteArray line : plainBytes.split('\n')) {
            if (line.endsWith('\r')) line.chop(1);
            records.append(line);
        }
    }
    if ((plainText && records.isEmpty()) || (!plainText && (indexName.isEmpty() || dataName.isEmpty() || !QFile::exists(indexPath) || !QFile::exists(dataPath)
        || !decodeRecords(FileIO::readFileAll(indexPath), FileIO::readFileAll(dataPath), records)))) {
        QMessageBox::warning(this, tr("文本"), tr("文本 IDX/GRP 不存在或无效")); return;
    }
    QDialog dialog(this);
    dialog.setWindowTitle(names ? tr("姓名文本") : tr("对话文本"));
    dialog.resize(750, 600);
    auto *layout = new QVBoxLayout(&dialog);
    auto *list = new QListWidget;
    auto *edit = new QTextEdit;
    auto *add = new QPushButton(names ? tr("追加姓名") : tr("追加对话"));
    auto *remove = new QPushButton(names ? tr("删除末尾姓名") : tr("删除末尾对话"));
    auto *arrange = new QPushButton(tr("重排星号"));
    auto *exportTalk = new QPushButton(tr("导出全部对话"));
    auto *arrangeWidth = new QSpinBox;
    arrangeWidth->setObjectName("talkArrangeWidth");
    arrange->setObjectName("talkArrange");
    exportTalk->setObjectName("talkExport");
    arrangeWidth->setRange(0, 32767);
    QTemporaryFile settingsFile;
    QString settingsPath;
    if (prepareIniPath(config.iniPath, settingsFile, settingsPath)) {
        QSettings settings(settingsPath, QSettings::IniFormat);
        arrangeWidth->setValue(settings.value("KDEF/talkarrange", 0).toInt());
    }
    auto *buttons = new QDialogButtonBox(QDialogButtonBox::Save | QDialogButtonBox::Cancel);
    layout->addWidget(list);
    layout->addWidget(edit);
    layout->addWidget(add);
    layout->addWidget(remove);
    auto *arrangeRow = new QHBoxLayout;
    arrangeRow->addWidget(new QLabel(tr("每行字符数")));
    arrangeRow->addWidget(arrangeWidth);
    arrangeRow->addWidget(arrange);
    arrangeRow->addWidget(exportTalk);
    layout->addLayout(arrangeRow);
    if (names) {
        remove->hide();
        for (int index = 0; index < arrangeRow->count(); ++index)
            if (auto *widget = arrangeRow->itemAt(index)->widget()) widget->hide();
    }
    layout->addWidget(buttons);
    QStringList texts;
    for (auto bytes : records) {
        if (!plainText && config.talkInvert == 0) for (char &value : bytes) {
            value = char(quint8(value) ^ 0xff);
            if (quint8(value) == 0xff) value = 0;
        }
        texts.append(plainText ? QString::fromUtf8(bytes) : Encoding::readOutStrWithCode(bytes.constData(), bytes.size(), config.talkCode));
        list->addItem(QString::number(texts.size() - 1) + " " + texts.last().left(60));
    }
    connect(list, &QListWidget::currentRowChanged, &dialog, [edit, &texts](int row) {
        QSignalBlocker blocker(edit);
        edit->setPlainText(row >= 0 && row < texts.size() ? texts[row] : QString());
    });
    connect(edit, &QTextEdit::textChanged, &dialog, [list, edit, &texts] {
        int row = list->currentRow();
        if (row < 0 || row >= texts.size()) return;
        texts[row] = edit->toPlainText();
        list->item(row)->setText(QString::number(row) + " " + texts[row].left(60));
    });
    connect(add, &QPushButton::clicked, &dialog, [list, &texts] {
        texts.append(QString()); list->addItem(QString::number(texts.size() - 1)); list->setCurrentRow(texts.size() - 1);
    });
    connect(remove, &QPushButton::clicked, &dialog, [list, &texts, &dialog] {
        if (texts.isEmpty() || QMessageBox::question(&dialog, tr("删除"), tr("删除末尾对话？请确认事件没有引用它。")) != QMessageBox::Yes) return;
        delete list->takeItem(texts.size() - 1); texts.removeLast();
    });
    connect(buttons, &QDialogButtonBox::rejected, &dialog, &QDialog::reject);
    connect(arrange, &QPushButton::clicked, &dialog, [&, edit, arrangeWidth] {
        int width = arrangeWidth->value();
        if (!saveTalkArrange(config.iniPath, width)) {
            QMessageBox::warning(&dialog, tr("重排"), tr("配置保存失败，对话未修改")); return;
        }
        QString source = edit->toPlainText();
        source.remove('*');
        QString arranged;
        for (int index = 0; index < source.size(); ++index) {
            arranged += source[index];
            if (width > 0 && (index + 1) % width == 0) arranged += '*';
        }
        edit->setPlainText(arranged);
    });
    connect(exportTalk, &QPushButton::clicked, &dialog, [&] {
        QString path = QFileDialog::getSaveFileName(&dialog, tr("导出全部对话"), {}, "Text (*.txt)");
        if (path.isEmpty()) return;
        QString text = tr("对话文件 总数：%1\r\n\r\n").arg(texts.size());
        for (int row = 0; row < texts.size(); ++row)
            text += QString::number(row) + ":" + texts[row] + "\r\n\r\n";
        QStringEncoder encoder(QStringConverter::Utf16LE);
        QByteArray bytes = QByteArray::fromHex("fffe") + encoder(text);
        if (!FileIO::writeFileAll(path, bytes))
            QMessageBox::warning(&dialog, tr("导出"), tr("无法写入对话文本"));
    });
    connect(buttons, &QDialogButtonBox::accepted, &dialog, [&, this] {
        if (plainText) {
            QByteArray bytes;
            bool unchanged = texts.size() == records.size();
            for (int row = 0; row < texts.size(); ++row) {
                if (texts[row].contains('\n') || texts[row].contains('\r')) {
                    QMessageBox::warning(&dialog, tr("保存"), tr("逐行对话中不能包含换行符"));
                    return;
                }
                if (row > 0) bytes.append(lineEnding);
                bytes.append(texts[row].toUtf8());
                unchanged = unchanged && texts[row].toUtf8() == records.value(row);
            }
            if (!FileIO::writeFileAll(dataPath, unchanged ? plainBytes : bytes)) {
                QMessageBox::warning(&dialog, tr("保存"), tr("对话保存失败"));
                return;
            }
            dialog.accept();
            return;
        }
        QVector<QByteArray> encoded;
        for (int row = 0; row < texts.size(); ++row) {
            QByteArray bytes;
            QByteArray original = row < records.size() ? records[row] : QByteArray();
            if (config.talkInvert == 0) for (char &value : original) {
                value = char(quint8(value) ^ 0xff); if (quint8(value) == 0xff) value = 0;
            }
            if (row < records.size() && Encoding::readOutStrWithCode(original.constData(), original.size(), config.talkCode) == texts[row]) {
                encoded.append(records[row]); continue;
            }
            bytes.resize(Encoding::encodedByteLengthWithCode(texts[row], config.talkCode) + (config.talkCode == 2 ? 2 : 1));
            bytes.fill(0);
            if (!Encoding::writeInStrWithCode(texts[row], bytes.data(), bytes.size(), config.talkCode)) {
                QMessageBox::warning(&dialog, tr("保存"), tr("对话 %1 包含当前编码无法保存的字符").arg(row));
                return;
            }
            if (config.talkInvert == 0) for (char &value : bytes) {
                value = char(quint8(value) ^ 0xff); if (quint8(value) == 0xff) value = 0;
            }
            encoded.append(bytes);
        }
        QByteArray index, data;
        if (!encodeRecords(encoded, index, data) || !FileIO::writeFiles({{indexPath, index}, {dataPath, data}})) {
            QMessageBox::warning(this, tr("保存"), tr("对话保存失败")); return;
        }
        dialog.accept();
        if (names) displayInstructionDetail(m_instrTable->currentRow());
    });
    if (!texts.isEmpty()) list->setCurrentRow(0);
    dialog.exec();
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
