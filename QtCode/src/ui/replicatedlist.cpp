#include "replicatedlist.h"
#include "iniconfig.h"
#include "rfile.h"
#include "encoding.h"
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QGroupBox>
#include <QDataStream>
#include <QMessageBox>
#include <QFile>
#include "fileio.h"
#include <QSignalBlocker>
#include <QIntValidator>

ReplicatedList::ReplicatedList(QWidget *parent) : QWidget(parent)
{
    auto *mainLayout = new QHBoxLayout(this);

    // 离队列表
    auto *leaveGroup = new QGroupBox(tr("离队列表"));
    auto *leaveLayout = new QVBoxLayout(leaveGroup);
    m_leaveScroll = new QScrollBar(Qt::Horizontal);
    m_leaveScroll->setRange(0, 99);
    m_leaveCombo = new QComboBox;
    m_leaveLabel = new QLabel;
    leaveLayout->addWidget(m_leaveLabel);
    leaveLayout->addWidget(m_leaveCombo);
    leaveLayout->addWidget(m_leaveScroll);
    leaveLayout->addStretch();
    mainLayout->addWidget(leaveGroup);

    // 效果列表
    auto *effectGroup = new QGroupBox(tr("效果列表"));
    auto *effectLayout = new QVBoxLayout(effectGroup);
    m_effectScroll = new QScrollBar(Qt::Horizontal);
    m_effectScroll->setRange(0, 199);
    m_effectEdit = new QLineEdit;
    m_effectLabel = new QLabel;
    effectLayout->addWidget(m_effectLabel);
    effectLayout->addWidget(m_effectEdit);
    effectLayout->addWidget(m_effectScroll);
    effectLayout->addStretch();
    mainLayout->addWidget(effectGroup);

    // 武器武功配合
    auto *matchGroup = new QGroupBox(tr("武器武功配合"));
    auto *matchLayout = new QVBoxLayout(matchGroup);
    m_matchScroll = new QScrollBar(Qt::Horizontal);
    m_matchScroll->setRange(0, 99);
    m_matchWeaponCombo = new QComboBox;
    m_matchSkillCombo = new QComboBox;
    m_matchValueEdit = new QLineEdit;
    matchLayout->addWidget(new QLabel(tr("武器:")));
    matchLayout->addWidget(m_matchWeaponCombo);
    matchLayout->addWidget(new QLabel(tr("武功:")));
    matchLayout->addWidget(m_matchSkillCombo);
    matchLayout->addWidget(new QLabel(tr("助成值:")));
    matchLayout->addWidget(m_matchValueEdit);
    matchLayout->addWidget(m_matchScroll);
    matchLayout->addStretch();
    mainLayout->addWidget(matchGroup);

    // 升级经验
    auto *expGroup = new QGroupBox(tr("升级经验"));
    auto *expLayout = new QVBoxLayout(expGroup);
    m_expScroll = new QScrollBar(Qt::Horizontal);
    m_expScroll->setRange(0, 99);
    m_expEdit = new QLineEdit;
    m_expLabel = new QLabel;
    expLayout->addWidget(m_expLabel);
    expLayout->addWidget(m_expEdit);
    expLayout->addWidget(m_expScroll);
    expLayout->addStretch();
    mainLayout->addWidget(expGroup);

    // 保存按钮
    auto *btnSave = new QPushButton(tr("保存"));
    mainLayout->addWidget(btnSave);

    connect(m_leaveScroll, &QScrollBar::valueChanged, this, &ReplicatedList::onLeaveScroll);
    connect(m_effectScroll, &QScrollBar::valueChanged, this, &ReplicatedList::onEffectScroll);
    connect(m_matchScroll, &QScrollBar::valueChanged, this, &ReplicatedList::onMatchScroll);
    connect(m_expScroll, &QScrollBar::valueChanged, this, &ReplicatedList::onExpScroll);
    connect(btnSave, &QPushButton::clicked, this, &ReplicatedList::onSave);

    loadData();
    auto fillNames = [this](QComboBox *combo, int type) {
        combo->addItem(tr("无"), -1);
        const auto &types = IniConfig::instance().rGlobals.rFile.rType;
        if (type < types.size())
            for (int index = 0; index < types[type].rData.size(); ++index)
                combo->addItem(QString::number(index) + " " + Encoding::displayStr(calRName(type, index)), index);
    };
    fillNames(m_leaveCombo, 1);
    fillNames(m_matchWeaponCombo, 2);
    fillNames(m_matchSkillCombo, 4);
    connect(m_leaveCombo, QOverload<int>::of(&QComboBox::activated), this, [this](int index) {
        m_leaveList[m_leaveScroll->value()] = m_leaveCombo->itemData(index).toInt();
    });
    connect(m_matchWeaponCombo, QOverload<int>::of(&QComboBox::activated), this, [this](int index) {
        m_matchList[m_matchScroll->value() * 3] = m_matchWeaponCombo->itemData(index).toInt();
    });
    connect(m_matchSkillCombo, QOverload<int>::of(&QComboBox::activated), this, [this](int index) {
        m_matchList[m_matchScroll->value() * 3 + 1] = m_matchSkillCombo->itemData(index).toInt();
    });
    for (auto *edit : {m_effectEdit, m_matchValueEdit, m_expEdit})
        edit->setValidator(new QIntValidator(SHRT_MIN, SHRT_MAX, edit));
    connect(m_effectEdit, &QLineEdit::textEdited, this, [this](const QString &text) {
        if (m_effectEdit->hasAcceptableInput()) m_effectList[m_effectScroll->value()] = text.toInt();
    });
    connect(m_matchValueEdit, &QLineEdit::textEdited, this, [this](const QString &text) {
        if (m_matchValueEdit->hasAcceptableInput()) m_matchList[m_matchScroll->value() * 3 + 2] = text.toInt();
    });
    connect(m_expEdit, &QLineEdit::textEdited, this, [this](const QString &text) {
        if (m_expEdit->hasAcceptableInput()) m_expList[m_expScroll->value()] = text.toInt();
    });
    displayLeave(0);
    displayMatch(0);
}

void ReplicatedList::loadData()
{
    IniConfig &cfg = IniConfig::instance();
    auto readSmallIntFile = [&](const QString &name, int count) -> QVector<int16_t> {
        QFile file(cfg.gamePath + "/" + name);
        QVector<int16_t> data(count, 0);
        if (file.open(QIODevice::ReadOnly)) {
            QDataStream ds(&file);
            ds.setByteOrder(QDataStream::LittleEndian);
            for (int i = 0; i < count && !ds.atEnd(); ++i) ds >> data[i];
        }
        return data;
    };

    m_leaveList = readSmallIntFile(cfg.leaveListFile, 100);
    m_effectList = readSmallIntFile(cfg.effectListFile, 200);
    m_matchList = readSmallIntFile(cfg.matchListFile, 300);
    m_expList = readSmallIntFile(cfg.expListFile, 100);

    if (!m_leaveList.isEmpty()) displayLeave(0);
    if (!m_effectList.isEmpty()) displayEffect(0);
    if (!m_matchList.isEmpty()) displayMatch(0);
    if (!m_expList.isEmpty()) displayExp(0);
}

void ReplicatedList::displayLeave(int index)
{
    if (index >= m_leaveList.size()) return;
    m_leaveLabel->setText(tr("离队 [%1]").arg(index));
    // 显示人物名称
    m_leaveCombo->setCurrentIndex(m_leaveCombo->findData(m_leaveList[index]));
}

void ReplicatedList::displayEffect(int index)
{
    if (index >= m_effectList.size()) return;
    m_effectLabel->setText(tr("效果 [%1]").arg(index));
    m_effectEdit->setText(QString::number(m_effectList[index]));
}

void ReplicatedList::displayMatch(int index)
{
    int base = index * 3;
    if (base + 2 >= m_matchList.size()) return;
    m_matchWeaponCombo->setCurrentIndex(m_matchWeaponCombo->findData(m_matchList[base]));
    m_matchSkillCombo->setCurrentIndex(m_matchSkillCombo->findData(m_matchList[base + 1]));
    m_matchValueEdit->setText(QString::number(m_matchList[base + 2]));
}

void ReplicatedList::displayExp(int index)
{
    if (index >= m_expList.size()) return;
    m_expLabel->setText(tr("经验 [%1]").arg(index));
    m_expEdit->setText(QString::number(m_expList[index]));
}

void ReplicatedList::onLeaveScroll(int val) { displayLeave(val); }
void ReplicatedList::onEffectScroll(int val) { displayEffect(val); }
void ReplicatedList::onMatchScroll(int val) { displayMatch(val); }
void ReplicatedList::onExpScroll(int val) { displayExp(val); }

void ReplicatedList::onSave()
{
    IniConfig &cfg = IniConfig::instance();
    QMap<QString, QByteArray> files;
    bool valid = true;
    auto writeSmallIntFile = [&](const QString &name, const QVector<int16_t> &data) {
        QString path = cfg.gamePath + "/" + name;
        if (name.isEmpty() || files.contains(path)) { valid = false; return; }
        QByteArray bytes;
        QDataStream stream(&bytes, QIODevice::WriteOnly);
        stream.setByteOrder(QDataStream::LittleEndian);
        for (auto value : data) stream << value;
        files.insert(path, bytes);
    };

    writeSmallIntFile(cfg.leaveListFile, m_leaveList);
    writeSmallIntFile(cfg.effectListFile, m_effectList);
    writeSmallIntFile(cfg.matchListFile, m_matchList);
    writeSmallIntFile(cfg.expListFile, m_expList);
    if (!valid || !FileIO::writeFiles(files)) {
        QMessageBox::warning(this, tr("保存"), tr("路径未配置、重复或写入失败，未完成保存"));
        return;
    }
    QMessageBox::information(this, tr("保存"), tr("保存成功"));
}

QString ReplicatedList::calRName(int typeIndex, int dataIndex)
{
    IniConfig &cfg = IniConfig::instance();
    RFileGlobals &g = cfg.rGlobals;
    if (typeIndex < g.rFile.rType.size() && dataIndex >= 0 && dataIndex < g.rFile.rType[typeIndex].rData.size()) {
        int namePos = g.rFile.rType[typeIndex].namePos;
        if (namePos >= 0 && namePos < g.rFile.rType[typeIndex].rData[dataIndex].rDataLine.size()) {
            const auto &line = g.rFile.rType[typeIndex].rData[dataIndex].rDataLine[namePos];
            if (!line.rArray.isEmpty() && !line.rArray[0].dataArray.isEmpty())
                return RFileIO::readRDataStr(line.rArray[0].dataArray[0]);
        }
    }
    return QString::number(dataIndex);
}
