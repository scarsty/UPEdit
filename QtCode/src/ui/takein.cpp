#include "takein.h"
#include "grpdata.h"
#include "mapdata.h"
#include "iniconfig.h"
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QScrollArea>
#include <QLabel>
#include <QLineEdit>
#include <QCheckBox>
#include <QComboBox>
#include <QProgressBar>
#include <QPushButton>
#include <QFileDialog>
#include <QMessageBox>
#include <QPainter>
#include <QColorDialog>

TakeIn::TakeIn(QWidget *parent) : QWidget(parent)
{
    auto *mainLayout = new QHBoxLayout(this);

    auto *leftPanel = new QVBoxLayout;
    auto *btnOpen = new QPushButton(tr("打开图片"));
    auto *btnImport = new QPushButton(tr("导入GRP"));
    m_widthEdit = new QLineEdit("0");
    m_heightEdit = new QLineEdit("0");
    m_xoffEdit = new QLineEdit("0");
    m_yoffEdit = new QLineEdit("0");
    auto *btnConfirm = new QPushButton(tr("确认尺寸"));

    m_transCheck = new QCheckBox(tr("启用透明色"));
    m_transColorEdit = new QLineEdit("000000");
    auto *btnTransColor = new QPushButton(tr("选择透明色"));

    m_grpCombo = new QComboBox;
    IniConfig &cfg = IniConfig::instance();
    // 用 grpListName 填充下拉框
    for (int i = 0; i < cfg.grpListNum && i < cfg.grpListName.size(); ++i)
        m_grpCombo->addItem(cfg.grpListName[i]);

    leftPanel->addWidget(btnOpen);
    leftPanel->addWidget(new QLabel(tr("宽:")));
    leftPanel->addWidget(m_widthEdit);
    leftPanel->addWidget(new QLabel(tr("高:")));
    leftPanel->addWidget(m_heightEdit);
    leftPanel->addWidget(new QLabel(tr("X偏移:")));
    leftPanel->addWidget(m_xoffEdit);
    leftPanel->addWidget(new QLabel(tr("Y偏移:")));
    leftPanel->addWidget(m_yoffEdit);
    leftPanel->addWidget(btnConfirm);
    leftPanel->addWidget(m_transCheck);
    leftPanel->addWidget(m_transColorEdit);
    leftPanel->addWidget(btnTransColor);
    leftPanel->addWidget(new QLabel(tr("目标GRP:")));
    leftPanel->addWidget(m_grpCombo);
    leftPanel->addWidget(btnImport);
    leftPanel->addStretch();

    auto *scroll = new QScrollArea;
    m_imageLabel = new QLabel;
    scroll->setWidget(m_imageLabel);
    scroll->setWidgetResizable(false);

    m_progress = new QProgressBar; m_progress->setVisible(false);

    auto *rightLayout = new QVBoxLayout;
    rightLayout->addWidget(scroll, 1);
    rightLayout->addWidget(m_progress);

    mainLayout->addLayout(leftPanel);
    mainLayout->addLayout(rightLayout, 1);

    connect(btnOpen, &QPushButton::clicked, this, &TakeIn::onOpenImage);
    connect(btnImport, &QPushButton::clicked, this, &TakeIn::onImportToGrp);
    connect(btnTransColor, &QPushButton::clicked, this, &TakeIn::onSetTransColor);
    connect(btnConfirm, &QPushButton::clicked, this, &TakeIn::onConfirmSize);
}

void TakeIn::onOpenImage()
{
    QString f = QFileDialog::getOpenFileName(this, tr("打开图片"), {},
        "Images (*.png *.jpg *.bmp *.gif);;All (*.*)");
    if (f.isEmpty()) return;

    m_sourceImage.load(f);
    if (m_sourceImage.isNull()) return;

    m_sourceImage = m_sourceImage.convertToFormat(QImage::Format_ARGB32);
    m_widthEdit->setText(QString::number(m_sourceImage.width()));
    m_heightEdit->setText(QString::number(m_sourceImage.height()));
    displayImage();
}

void TakeIn::displayImage()
{
    if (m_sourceImage.isNull()) return;
    m_imageLabel->setPixmap(QPixmap::fromImage(m_sourceImage));
    m_imageLabel->resize(m_sourceImage.size());
}

void TakeIn::onSetTransColor()
{
    QColor c = QColorDialog::getColor(QColor::fromRgb(m_transColor), this);
    if (c.isValid()) {
        m_transColor = c.rgb();
        m_transColorEdit->setText(QString("%1").arg(m_transColor & 0xFFFFFF, 6, 16, QChar('0')));
    }
}

void TakeIn::onConfirmSize()
{
    int w = m_widthEdit->text().toInt();
    int h = m_heightEdit->text().toInt();
    if (w > 0 && h > 0 && !m_sourceImage.isNull()) {
        QImage cropped = m_sourceImage.copy(0, 0, w, h);
        m_imageLabel->setPixmap(QPixmap::fromImage(cropped));
        m_imageLabel->resize(cropped.size());
    }
}

void TakeIn::onImportToGrp()
{
    if (m_sourceImage.isNull()) return;

    int xoff = m_xoffEdit->text().toInt();
    int yoff = m_yoffEdit->text().toInt();

    int grpIdx = m_grpCombo->currentIndex();
    IniConfig &cfg = IniConfig::instance();
    if (grpIdx < 0 || grpIdx >= cfg.grpListNum) return;
    if (grpIdx >= cfg.grpListIdx.size() || grpIdx >= cfg.grpListGrp.size()) return;

    QString idxPath = cfg.gamePath + "/" + cfg.grpListIdx[grpIdx];
    QString grpPath = cfg.gamePath + "/" + cfg.grpListGrp[grpIdx];

    // 读取已有 GRP
    QVector<GrpPic> pics;
    GrpIO::readGrp(idxPath, grpPath, pics);

    // 用 encodeRLE 生成新精灵
    GrpPic newPic = GrpIO::encodeRLE(m_sourceImage, m_palR, m_palG, m_palB);
    newPic.xoff = xoff;
    newPic.yoff = yoff;
    pics.append(newPic);

    // 保存
    GrpIO::saveGrp(idxPath, grpPath, pics);
    QMessageBox::information(this, tr("导入"), tr("导入完成，新索引: %1").arg(pics.size() - 1));
}
