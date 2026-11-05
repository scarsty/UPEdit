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
    auto *btnDeleteEvent = new QPushButton(tr("删除末尾事件"));
    auto *btnExportEvent = new QPushButton(tr("导出事件文本"));
    topBar->addWidget(btnTalk);
    topBar->addWidget(btnNewEvent);
    topBar->addWidget(btnCopyEvent);
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
        event.eventId = m_events.size();
        for (auto &instruction : event.instructions) instruction.identity = m_nextIdentity++;
        m_events.append(event);
        displayEventList();
        displayInstructions(event.eventId);
    });
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
    int count = ini.value("KdefAttrib/number", 0).toInt();
    for (int i = 0; i < count; ++i) {
        QStringList parts = value(QString("KdefAttrib/attrib%1").arg(i)).split(QRegularExpression("\\s+"), Qt::SkipEmptyParts);
        if (parts.size() < 6) continue;
        KDEFInstrDef def;
        bool valid = false;
        def.code = parts[0].toInt(&valid, 16);
        int words = parts[1].toInt();
        if (!valid || words < 1 || words > 256) continue;
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
        m_subInstructions.append(value(QString("kdef50/sub%1").arg(index)));
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
        auto *nameItem = new QTableWidgetItem(pname);
        nameItem->setFlags(nameItem->flags() & ~Qt::ItemIsEditable);
        m_paramTable->setItem(p, 0, nameItem);
        m_paramTable->setItem(p, 1, new QTableWidgetItem(QString::number(instr.params[p])));
        QVector<QPair<int, QString>> choices;
        int quoteType = definition ? definition->quoteTypes.value(p) : 0;
        int quoteCount = definition ? definition->quoteCounts.value(p) : -1;
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
                choices = {{-2, tr("保持不变")}, {-1, tr("无")}};
                const auto &type = file.rType[quoteCount];
                for (int record = 0; record < type.rData.size(); ++record) {
                    QString name;
                    const auto &lines = type.rData[record].rDataLine;
                    if (type.namePos >= 0 && type.namePos < lines.size() && !lines[type.namePos].rArray.isEmpty()
                        && !lines[type.namePos].rArray[0].dataArray.isEmpty()) name = RFileIO::readRDataStr(lines[type.namePos].rArray[0].dataArray[0]);
                    choices.append({record, name});
                }
            }
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
        if (!choices.isEmpty()) {
            auto *combo = new QComboBox;
            combo->setEditable(true);
            for (const auto &choice : choices) combo->addItem(QString::number(choice.first) + " " + choice.second, choice.first);
            int selected = combo->findData(instr.params[p]);
            if (selected >= 0) combo->setCurrentIndex(selected);
            else combo->setEditText(QString::number(instr.params[p]));
            m_paramTable->setCellWidget(p, 1, combo);
            connect(combo, &QComboBox::currentTextChanged, this, [this, combo, p, instrIndex, eventIndex = m_currentEvent](const QString &text) {
                bool valid = false;
                int value = text.section(' ', 0, 0).toInt(&valid);
                if (!valid || value < SHRT_MIN || value > SHRT_MAX || eventIndex != m_currentEvent || instrIndex != m_currentInstr) return;
                m_events[eventIndex].instructions[instrIndex].params[p] = value;
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
    if (m_currentEvent < 0 || m_currentInstr < 0) return;
    const auto &instrs = m_events[m_currentEvent].instructions;
    if (m_currentInstr < instrs.size()) {
        m_clipboard.clear();
        m_clipboard.append(instrs[m_currentInstr]);
        m_clipboardEvent = m_currentEvent;
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
        for (auto instruction : m_clipboard) {
            int originalIdentity = instruction.identity;
            QVector<Jump> copiedJumps;
            for (const auto &definition : m_instrDefs) if (definition.code == instruction.code)
                for (int parameter : {definition.yesJump, definition.noJump}) {
                    if (parameter < 0 || parameter >= instruction.params.size() || instruction.params[parameter] == 0) continue;
                    bool found = false;
                    if (m_clipboardEvent == m_currentEvent)
                        for (const auto &jump : jumps)
                            if (jump.source == originalIdentity && jump.parameter == parameter) {
                                copiedJumps.append(jump); found = true; break;
                            }
                    if (!found) {
                        QMessageBox::warning(this, tr("粘贴"), tr("复制指令的跳转目标无法确定，请在原事件中重新复制")); return;
                    }
                }
            instruction.identity = m_nextIdentity++;
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
    auto &config = IniConfig::instance();
    QString indexPath = config.gamePath + "/" + config.talkIdx, dataPath = config.gamePath + "/" + config.talkGrp;
    QVector<QByteArray> records;
    if (config.talkIdx.isEmpty() || config.talkGrp.isEmpty() || !QFile::exists(indexPath) || !QFile::exists(dataPath)
        || !decodeRecords(FileIO::readFileAll(indexPath), FileIO::readFileAll(dataPath), records)) {
        QMessageBox::warning(this, tr("对话"), tr("对话 IDX/GRP 不存在或无效")); return;
    }
    QDialog dialog(this);
    dialog.setWindowTitle(tr("对话文本"));
    dialog.resize(750, 600);
    auto *layout = new QVBoxLayout(&dialog);
    auto *list = new QListWidget;
    auto *edit = new QTextEdit;
    auto *add = new QPushButton(tr("追加对话"));
    auto *remove = new QPushButton(tr("删除末尾对话"));
    auto *buttons = new QDialogButtonBox(QDialogButtonBox::Save | QDialogButtonBox::Cancel);
    layout->addWidget(list);
    layout->addWidget(edit);
    layout->addWidget(add);
    layout->addWidget(remove);
    layout->addWidget(buttons);
    QStringList texts;
    for (auto bytes : records) {
        if (config.talkInvert == 0) for (char &value : bytes) {
            value = char(quint8(value) ^ 0xff);
            if (quint8(value) == 0xff) value = 0;
        }
        texts.append(Encoding::readOutStrWithCode(bytes.constData(), bytes.size(), config.talkCode));
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
    connect(buttons, &QDialogButtonBox::accepted, &dialog, [&, this] {
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
            Encoding::writeInStrWithCode(texts[row], bytes.data(), bytes.size(), config.talkCode);
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
