#include "setlanguage.h"
#include "iniconfig.h"
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QPushButton>
#include <QLabel>
#include <QSettings>

SetLanguage::SetLanguage(QWidget *parent) : QDialog(parent)
{
    setWindowTitle(tr("编码/语言设置"));
    auto *layout = new QVBoxLayout(this);

    // 游戏数据编码
    auto *dataGroup = new QGroupBox(tr("游戏数据编码"));
    auto *dataLayout = new QVBoxLayout(dataGroup);
    m_dataGBK = new QRadioButton(tr("GBK (简体前传)"));
    m_dataBIG5 = new QRadioButton(tr("BIG5 (繁体原版)"));
    m_dataUTF16 = new QRadioButton(tr("UNICODE (UTF-16LE)"));
    m_dataUTF8 = new QRadioButton(tr("UTF-8"));
    dataLayout->addWidget(m_dataGBK);
    dataLayout->addWidget(m_dataBIG5);
    dataLayout->addWidget(m_dataUTF16);
    dataLayout->addWidget(m_dataUTF8);
    layout->addWidget(dataGroup);

    // 对话编码
    auto *talkGroup = new QGroupBox(tr("对话数据编码"));
    auto *talkLayout = new QVBoxLayout(talkGroup);
    m_talkGBK = new QRadioButton(tr("GBK"));
    m_talkBIG5 = new QRadioButton(tr("BIG5"));
    m_talkUTF16 = new QRadioButton(tr("UNICODE"));
    m_talkUTF8 = new QRadioButton(tr("UTF-8"));
    talkLayout->addWidget(m_talkGBK);
    talkLayout->addWidget(m_talkBIG5);
    talkLayout->addWidget(m_talkUTF16);
    talkLayout->addWidget(m_talkUTF8);
    layout->addWidget(talkGroup);

    // 对话取反
    auto *invertGroup = new QGroupBox(tr("对话数据取反"));
    auto *invertLayout = new QHBoxLayout(invertGroup);
    m_invertYes = new QRadioButton(tr("是"));
    m_invertNo = new QRadioButton(tr("否"));
    invertLayout->addWidget(m_invertYes);
    invertLayout->addWidget(m_invertNo);
    layout->addWidget(invertGroup);

    // 自动更新
    auto *updateGroup = new QGroupBox(tr("自动更新"));
    auto *updateLayout = new QVBoxLayout(updateGroup);
    m_updateCheck = new QRadioButton(tr("检查更新"));
    m_updateSilent = new QRadioButton(tr("静默更新"));
    m_updateNone = new QRadioButton(tr("不检查"));
    updateLayout->addWidget(m_updateCheck);
    updateLayout->addWidget(m_updateSilent);
    updateLayout->addWidget(m_updateNone);
    layout->addWidget(updateGroup);

    // TileScale
    auto *scaleLayout = new QHBoxLayout;
    scaleLayout->addWidget(new QLabel(tr("TileScale (1-8):")));
    m_tileScaleEdit = new QLineEdit("1");
    scaleLayout->addWidget(m_tileScaleEdit);
    layout->addLayout(scaleLayout);

    // 按钮
    auto *btnRow = new QHBoxLayout;
    auto *btnOK = new QPushButton(tr("确定"));
    auto *btnCancel = new QPushButton(tr("取消"));
    btnRow->addStretch();
    btnRow->addWidget(btnOK);
    btnRow->addWidget(btnCancel);
    layout->addLayout(btnRow);

    // 初始化当前值
    IniConfig &cfg = IniConfig::instance();
    switch (cfg.dataCode) {
        case CodeGBK:     m_dataGBK->setChecked(true); break;
        case CodeBIG5:    m_dataBIG5->setChecked(true); break;
        case CodeUTF16LE: m_dataUTF16->setChecked(true); break;
        case CodeUTF8:    m_dataUTF8->setChecked(true); break;
    }
    switch (cfg.talkCode) {
        case CodeGBK:     m_talkGBK->setChecked(true); break;
        case CodeBIG5:    m_talkBIG5->setChecked(true); break;
        case CodeUTF16LE: m_talkUTF16->setChecked(true); break;
        case CodeUTF8:    m_talkUTF8->setChecked(true); break;
    }
    if (cfg.talkInvert) m_invertYes->setChecked(true);
    else m_invertNo->setChecked(true);
    m_tileScaleEdit->setText(QString::number(cfg.tileScale));

    connect(btnOK, &QPushButton::clicked, this, &SetLanguage::onConfirm);
    connect(btnCancel, &QPushButton::clicked, this, &QDialog::reject);
}

void SetLanguage::onConfirm()
{
    IniConfig &cfg = IniConfig::instance();

    if (m_dataGBK->isChecked()) cfg.dataCode = CodeGBK;
    else if (m_dataBIG5->isChecked()) cfg.dataCode = CodeBIG5;
    else if (m_dataUTF16->isChecked()) cfg.dataCode = CodeUTF16LE;
    else if (m_dataUTF8->isChecked()) cfg.dataCode = CodeUTF8;

    if (m_talkGBK->isChecked()) cfg.talkCode = CodeGBK;
    else if (m_talkBIG5->isChecked()) cfg.talkCode = CodeBIG5;
    else if (m_talkUTF16->isChecked()) cfg.talkCode = CodeUTF16LE;
    else if (m_talkUTF8->isChecked()) cfg.talkCode = CodeUTF8;

    cfg.talkInvert = m_invertYes->isChecked();
    cfg.tileScale = m_tileScaleEdit->text().toInt();
    if (cfg.tileScale < 1) cfg.tileScale = 1;
    if (cfg.tileScale > 8) cfg.tileScale = 8;

    // 保存到 INI
    QSettings ini(cfg.iniPath, QSettings::IniFormat);
    ini.beginGroup("run");
    ini.setValue("datacode", (int)cfg.dataCode);
    ini.setValue("talkcode", (int)cfg.talkCode);
    ini.setValue("talkinvert", cfg.talkInvert ? 1 : 0);
    ini.setValue("TileScale", cfg.tileScale);
    ini.endGroup();

    accept();
}
