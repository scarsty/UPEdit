#include "grplist.h"
#include "grpdata.h"
#include "fileio.h"
#include "iniconfig.h"
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QLineEdit>
#include <QFileDialog>
#include <QPainter>
#include <QMouseEvent>
#include <QMessageBox>

GrpList::GrpList(QWidget *parent) : QWidget(parent)
{
    auto *mainLayout = new QVBoxLayout(this);

    // 顶部工具栏
    auto *topBar = new QHBoxLayout;
    m_idxEdit = new QLineEdit; m_grpEdit = new QLineEdit; m_colEdit = new QLineEdit;
    auto *btnIdx = new QPushButton(tr("IDX"));
    auto *btnGrp = new QPushButton(tr("GRP"));
    auto *btnCol = new QPushButton(tr("COL"));
    auto *btnDisplay = new QPushButton(tr("显示"));
    auto *btnSave = new QPushButton(tr("保存"));
    m_presetCombo = new QComboBox;
    m_progress = new QProgressBar; m_progress->setVisible(false);

    topBar->addWidget(m_idxEdit, 1);
    topBar->addWidget(btnIdx);
    topBar->addWidget(m_grpEdit, 1);
    topBar->addWidget(btnGrp);
    topBar->addWidget(m_colEdit);
    topBar->addWidget(btnCol);
    topBar->addWidget(m_presetCombo);
    topBar->addWidget(btnDisplay);
    topBar->addWidget(btnSave);
    mainLayout->addLayout(topBar);
    mainLayout->addWidget(m_progress);

    // 主显示区
    auto *centerLayout = new QHBoxLayout;
    m_imageLabel = new QLabel;
    m_imageLabel->setMinimumSize(640, 480);
    m_imageLabel->setAlignment(Qt::AlignTop | Qt::AlignLeft);
    m_imageLabel->setContextMenuPolicy(Qt::CustomContextMenu);
    m_scrollBar = new QScrollBar(Qt::Vertical);
    centerLayout->addWidget(m_imageLabel, 1);
    centerLayout->addWidget(m_scrollBar);
    mainLayout->addLayout(centerLayout, 1);

    // 右键菜单
    m_contextMenu = new QMenu(this);
    m_contextMenu->addAction(tr("编辑"), this, &GrpList::onEditCurrent);
    m_contextMenu->addAction(tr("替换PNG"), this, &GrpList::onReplacePNG);
    m_contextMenu->addSeparator();
    m_contextMenu->addAction(tr("插入"), this, &GrpList::onInsertBefore);
    m_contextMenu->addAction(tr("删除"), this, &GrpList::onDeleteCurrent);
    m_contextMenu->addSeparator();
    m_contextMenu->addAction(tr("导出全部PNG"), this, &GrpList::onExportAllPNG);

    // 填充预设 GRP
    IniConfig &cfg = IniConfig::instance();
    for (auto &s : cfg.grpSections) m_presetCombo->addItem(s.name);

    connect(btnIdx, &QPushButton::clicked, this, &GrpList::onOpenIdx);
    connect(btnGrp, &QPushButton::clicked, this, &GrpList::onOpenGrp);
    connect(btnCol, &QPushButton::clicked, this, &GrpList::onOpenCol);
    connect(btnDisplay, &QPushButton::clicked, this, &GrpList::onDisplay);
    connect(btnSave, &QPushButton::clicked, this, &GrpList::onSave);
    connect(m_scrollBar, &QScrollBar::valueChanged, this, &GrpList::onScroll);
    connect(m_imageLabel, &QLabel::customContextMenuRequested, this, &GrpList::onContextMenu);
}

void GrpList::onOpenIdx()
{
    QString f = QFileDialog::getOpenFileName(this, tr("选择IDX文件"), {}, "IDX (*.idx)");
    if (!f.isEmpty()) m_idxEdit->setText(f);
}

void GrpList::onOpenGrp()
{
    QString f = QFileDialog::getOpenFileName(this, tr("选择GRP文件"), {}, "GRP (*.grp)");
    if (!f.isEmpty()) m_grpEdit->setText(f);
}

void GrpList::onOpenCol()
{
    QString f = QFileDialog::getOpenFileName(this, tr("选择COL文件"), {}, "COL (*.col)");
    if (!f.isEmpty()) { m_colEdit->setText(f); loadPalette(f); }
}

void GrpList::loadPalette(const QString &path)
{
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly)) return;
    QByteArray data = file.readAll();
    m_palette.resize(256);
    for (int i = 0; i < 256 && i * 3 + 2 < data.size(); ++i) {
        int r = (uint8_t)data[i * 3 + 0] << 2;
        int g = (uint8_t)data[i * 3 + 1] << 2;
        int b = (uint8_t)data[i * 3 + 2] << 2;
        m_palette[i] = qRgb(qMin(r, 255), qMin(g, 255), qMin(b, 255));
    }
}

void GrpList::loadGrpFiles(const QString &idxPath, const QString &grpPath, const QString &colPath)
{
    m_idxEdit->setText(idxPath);
    m_grpEdit->setText(grpPath);
    if (!colPath.isEmpty()) { m_colEdit->setText(colPath); loadPalette(colPath); }
    onDisplay();
}

void GrpList::onDisplay()
{
    QString idxPath = m_idxEdit->text().trimmed();
    QString grpPath = m_grpEdit->text().trimmed();
    if (idxPath.isEmpty() || grpPath.isEmpty()) return;

    m_grpPics = GrpData::loadGrpIdx(idxPath, grpPath);
    m_scrollBar->setRange(0, qMax(0, (int)m_grpPics.size() / m_cols - 5));
    m_scrollOffset = 0;
    displayGrpList();
}

void GrpList::displayGrpList()
{
    if (m_grpPics.isEmpty()) return;

    int cellW = 80, cellH = 80;
    int startRow = m_scrollOffset;
    int visRows = m_imageLabel->height() / cellH + 1;
    int totalVisible = visRows * m_cols;

    QImage canvas(m_cols * cellW, visRows * cellH, QImage::Format_ARGB32);
    canvas.fill(m_bgColor);
    QPainter p(&canvas);
    p.setPen(m_textColor);

    for (int i = 0; i < totalVisible; ++i) {
        int idx = (startRow * m_cols) + i;
        if (idx >= m_grpPics.size()) break;

        int cx = (i % m_cols) * cellW, cy = (i / m_cols) * cellH;

        // 解码并绘制精灵
        QImage sprite = decodeSprite(idx);
        if (!sprite.isNull()) {
            QImage scaled = sprite.scaled(cellW - 4, cellH - 16, Qt::KeepAspectRatio, Qt::FastTransformation);
            p.drawImage(cx + 2, cy + 2, scaled);
        }
        p.drawText(cx + 2, cy + cellH - 4, QString::number(idx));
    }

    m_imageLabel->setPixmap(QPixmap::fromImage(canvas));
}

QImage GrpList::decodeSprite(int index)
{
    if (index < 0 || index >= m_grpPics.size()) return {};
    const GrpPic &pic = m_grpPics[index];
    if (pic.data.isEmpty() || pic.width <= 0 || pic.height <= 0) return {};

    // Check PNG
    if (pic.data.size() > 8 && (uint8_t)pic.data[1] == 'P' && (uint8_t)pic.data[2] == 'N' && (uint8_t)pic.data[3] == 'G') {
        QImage img;
        img.loadFromData(pic.data);
        return img;
    }

    QImage img(pic.width, pic.height, QImage::Format_ARGB32);
    img.fill(Qt::transparent);
    GrpData::decodeRLE8(pic.data, pic.width, pic.height, m_palette, img);
    return img;
}

void GrpList::onSave()
{
    QString idxPath = m_idxEdit->text().trimmed();
    QString grpPath = m_grpEdit->text().trimmed();
    if (idxPath.isEmpty() || grpPath.isEmpty()) return;

    GrpData::saveGrpIdx(idxPath, grpPath, m_grpPics);
    QMessageBox::information(this, tr("保存"), tr("保存成功"));
}

void GrpList::onScroll(int value)
{
    m_scrollOffset = value;
    displayGrpList();
}

void GrpList::onContextMenu(const QPoint &pos)
{
    // 计算点击的精灵索引
    int cellW = 80, cellH = 80;
    int col = pos.x() / cellW, row = pos.y() / cellH;
    m_nowPic = (m_scrollOffset + row) * m_cols + col;
    if (m_nowPic >= m_grpPics.size()) m_nowPic = -1;
    m_contextMenu->exec(m_imageLabel->mapToGlobal(pos));
}

void GrpList::onEditCurrent()
{
    if (m_nowPic >= 0 && m_nowPic < m_grpPics.size())
        emit editSprite(m_nowPic);
}

void GrpList::onDeleteCurrent()
{
    if (m_nowPic >= 0 && m_nowPic < m_grpPics.size()) {
        m_grpPics.removeAt(m_nowPic);
        displayGrpList();
    }
}

void GrpList::onInsertBefore()
{
    if (m_nowPic >= 0 && m_nowPic <= m_grpPics.size()) {
        m_grpPics.insert(m_nowPic, GrpPic());
        displayGrpList();
    }
}

void GrpList::onReplacePNG()
{
    if (m_nowPic < 0 || m_nowPic >= m_grpPics.size()) return;
    QString f = QFileDialog::getOpenFileName(this, tr("选择PNG"), {}, "PNG (*.png)");
    if (f.isEmpty()) return;
    QFile file(f);
    if (!file.open(QIODevice::ReadOnly)) return;
    QByteArray data = file.readAll();
    QImage img; img.loadFromData(data, "PNG");
    m_grpPics[m_nowPic].data = data;
    m_grpPics[m_nowPic].width = img.width();
    m_grpPics[m_nowPic].height = img.height();
    displayGrpList();
}

void GrpList::onExportAllPNG()
{
    QString dir = QFileDialog::getExistingDirectory(this, tr("选择导出目录"));
    if (dir.isEmpty()) return;
    m_progress->setVisible(true);
    m_progress->setRange(0, m_grpPics.size());

    for (int i = 0; i < m_grpPics.size(); ++i) {
        QImage img = decodeSprite(i);
        if (!img.isNull())
            img.save(dir + "/" + QString::number(i) + ".png");
        m_progress->setValue(i + 1);
    }
    // Write index.ka (2B x + 2B y per sprite)
    QFile ka(dir + "/index.ka");
    if (ka.open(QIODevice::WriteOnly)) {
        QDataStream ds(&ka);
        ds.setByteOrder(QDataStream::LittleEndian);
        for (const auto &pic : m_grpPics) {
            ds << (int16_t)pic.xoff << (int16_t)pic.yoff;
        }
    }

    m_progress->setVisible(false);
    QMessageBox::information(this, tr("导出"), tr("导出完成"));
}

void GrpList::onBatchOffset() { /* 批量偏移设置 */ }
