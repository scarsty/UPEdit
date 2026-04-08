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
#include <QResizeEvent>
#include <QMessageBox>

static const int SQUARE_H = 100;
static const int TITLE_H  = 10;

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
    m_sectionCombo = new QComboBox;
    m_progress = new QProgressBar; m_progress->setVisible(false);

    topBar->addWidget(m_presetCombo);
    topBar->addWidget(m_sectionCombo);
    topBar->addWidget(m_idxEdit, 1);
    topBar->addWidget(btnIdx);
    topBar->addWidget(m_grpEdit, 1);
    topBar->addWidget(btnGrp);
    topBar->addWidget(m_colEdit);
    topBar->addWidget(btnCol);
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
    for (int i = 0; i < cfg.grpListNum && i < cfg.grpListName.size(); ++i)
        m_presetCombo->addItem(cfg.grpListName[i]);

    // 加载调色板
    if (!cfg.palette.isEmpty()) {
        QString colPath = cfg.gamePath + "/" + cfg.palette;
        if (QFile::exists(colPath)) {
            m_colEdit->setText(colPath);
            loadPalette(colPath);
        }
    }

    connect(btnIdx, &QPushButton::clicked, this, &GrpList::onOpenIdx);
    connect(btnGrp, &QPushButton::clicked, this, &GrpList::onOpenGrp);
    connect(btnCol, &QPushButton::clicked, this, &GrpList::onOpenCol);
    connect(btnDisplay, &QPushButton::clicked, this, &GrpList::onDisplay);
    connect(btnSave, &QPushButton::clicked, this, &GrpList::onSave);
    connect(m_scrollBar, &QScrollBar::valueChanged, this, &GrpList::onScroll);
    connect(m_imageLabel, &QLabel::customContextMenuRequested, this, &GrpList::onContextMenu);
    connect(m_presetCombo, QOverload<int>::of(&QComboBox::currentIndexChanged), this, &GrpList::onPresetChanged);
    connect(m_sectionCombo, QOverload<int>::of(&QComboBox::currentIndexChanged), this, &GrpList::onSectionChanged);
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

    m_grpPics.clear();
    GrpIO::readGrp(idxPath, grpPath, m_grpPics);

    m_beginPic = 0;
    m_endPic = m_grpPics.size() - 1;
    m_scrollOffset = 0;
    m_nowPic = m_beginPic;

    updateSectionCombo();

    int totalInRange = m_endPic - m_beginPic + 1;
    int totalRows = (totalInRange + m_cols - 1) / m_cols;
    int visRows = m_imageLabel->height() / SQUARE_H + 1;
    m_scrollBar->setRange(0, qMax(0, totalRows - visRows));
    m_scrollBar->setValue(0);

    displayGrpList();
}

void GrpList::onPresetChanged(int index)
{
    if (index < 0) return;
    IniConfig &cfg = IniConfig::instance();
    if (index >= cfg.grpListNum) return;

    QString idxPath = cfg.gamePath + "/" + cfg.grpListIdx[index];
    QString grpPath = cfg.gamePath + "/" + cfg.grpListGrp[index];
    m_idxEdit->setText(idxPath);
    m_grpEdit->setText(grpPath);

    onDisplay();
}

void GrpList::onSectionChanged(int index)
{
    if (index <= 0) {
        // "全部"
        m_beginPic = 0;
        m_endPic = m_grpPics.size() - 1;
    } else {
        int presetIdx = m_presetCombo->currentIndex();
        IniConfig &cfg = IniConfig::instance();
        if (presetIdx >= 0 && presetIdx < cfg.grpListSection.size()) {
            int secIdx = index - 1; // 减去"全部"项
            const auto &sec = cfg.grpListSection[presetIdx];
            if (secIdx >= 0 && secIdx < sec.num) {
                m_beginPic = sec.beginNum[secIdx];
                m_endPic = (sec.endNum[secIdx] == -2) ? m_grpPics.size() - 1 : sec.endNum[secIdx];
            }
        }
    }

    m_scrollOffset = 0;
    m_nowPic = m_beginPic;
    int totalInRange = m_endPic - m_beginPic + 1;
    int totalRows = (totalInRange + m_cols - 1) / m_cols;
    int visRows = m_imageLabel->height() / SQUARE_H + 1;
    m_scrollBar->setRange(0, qMax(0, totalRows - visRows));
    m_scrollBar->setValue(0);
    displayGrpList();
}

void GrpList::updateSectionCombo()
{
    m_sectionCombo->blockSignals(true);
    m_sectionCombo->clear();
    m_sectionCombo->addItem(tr("全部"));

    int presetIdx = m_presetCombo->currentIndex();
    IniConfig &cfg = IniConfig::instance();
    if (presetIdx >= 0 && presetIdx < cfg.grpListSection.size()) {
        const auto &sec = cfg.grpListSection[presetIdx];
        for (int i = 0; i < sec.num; ++i) {
            m_sectionCombo->addItem(sec.tag[i]);
        }
    }
    m_sectionCombo->blockSignals(false);
}

void GrpList::displayGrpList()
{
    if (m_grpPics.isEmpty()) return;

    int labelW = m_imageLabel->width();
    int labelH = m_imageLabel->height();
    if (labelW <= 0 || labelH <= 0) return;

    int squareW = labelW / m_cols;
    if (squareW < 10) squareW = 10;

    int visRows = labelH / SQUARE_H + 1;
    int startIdx = m_beginPic + m_scrollOffset * m_cols;

    QImage canvas(m_cols * squareW, visRows * SQUARE_H, QImage::Format_ARGB32);
    canvas.fill(m_bgColor);
    QPainter p(&canvas);
    p.setPen(m_textColor);
    p.setFont(QFont("SimSun", 8));

    for (int row = 0; row < visRows; ++row) {
        for (int col = 0; col < m_cols; ++col) {
            int idx = startIdx + row * m_cols + col;
            if (idx > m_endPic || idx >= m_grpPics.size()) break;

            int cx = col * squareW;
            int cy = row * SQUARE_H;

            // 绘制编号
            p.drawText(cx + 2, cy + TITLE_H, QString::number(idx));

            // 绘制边框
            p.drawRect(cx, cy, squareW - 1, SQUARE_H - 1);

            // 解码精灵
            QImage sprite = decodeSprite(idx);
            if (!sprite.isNull()) {
                int drawAreaW = squareW - 4;
                int drawAreaH = SQUARE_H - TITLE_H - 4;
                if (sprite.width() <= drawAreaW && sprite.height() <= drawAreaH) {
                    // 原尺寸绘制
                    p.drawImage(cx + 2, cy + TITLE_H + 2, sprite);
                } else {
                    // 缩放绘制
                    QImage scaled = sprite.scaled(drawAreaW, drawAreaH, Qt::KeepAspectRatio, Qt::FastTransformation);
                    p.drawImage(cx + 2, cy + TITLE_H + 2, scaled);
                }
            }

            // 高亮选中
            if (idx == m_nowPic) {
                p.save();
                p.setPen(QPen(Qt::red, 2));
                p.drawRect(cx + 1, cy + 1, squareW - 3, SQUARE_H - 3);
                p.restore();
            }
        }
    }

    m_imageLabel->setPixmap(QPixmap::fromImage(canvas));
}

void GrpList::resizeEvent(QResizeEvent *e)
{
    QWidget::resizeEvent(e);
    if (!m_grpPics.isEmpty()) {
        int totalInRange = m_endPic - m_beginPic + 1;
        int totalRows = (totalInRange + m_cols - 1) / m_cols;
        int visRows = m_imageLabel->height() / SQUARE_H + 1;
        m_scrollBar->setRange(0, qMax(0, totalRows - visRows));
        displayGrpList();
    }
}

void GrpList::mousePressEvent(QMouseEvent *e)
{
    // 将点击坐标映射到 imageLabel
    QPoint pos = m_imageLabel->mapFrom(this, e->pos());
    if (!m_imageLabel->rect().contains(pos)) {
        QWidget::mousePressEvent(e);
        return;
    }

    int squareW = m_imageLabel->width() / m_cols;
    if (squareW < 10) squareW = 10;

    int col = pos.x() / squareW;
    int row = pos.y() / SQUARE_H;
    int idx = m_beginPic + (m_scrollOffset + row) * m_cols + col;
    if (idx >= m_beginPic && idx <= m_endPic && idx < m_grpPics.size()) {
        m_nowPic = idx;
        displayGrpList();
    }
    QWidget::mousePressEvent(e);
}

QImage GrpList::decodeSprite(int index)
{
    if (index < 0 || index >= m_grpPics.size()) return {};
    const GrpPic &pic = m_grpPics[index];
    if (pic.data.isEmpty() || pic.width <= 0 || pic.height <= 0) return {};

    // Check PNG
    if (GrpIO::isPNG(pic)) {
        return GrpIO::decodePNG(pic);
    }

    uint8_t pr[256]{}, pg[256]{}, pb[256]{};
    for (int i = 0; i < 256 && i < m_palette.size(); ++i) {
        pr[i] = qRed(m_palette[i]); pg[i] = qGreen(m_palette[i]); pb[i] = qBlue(m_palette[i]);
    }
    return GrpIO::decodeRLE(pic, pr, pg, pb);
}

void GrpList::onSave()
{
    QString idxPath = m_idxEdit->text().trimmed();
    QString grpPath = m_grpEdit->text().trimmed();
    if (idxPath.isEmpty() || grpPath.isEmpty()) return;

    GrpIO::saveGrp(idxPath, grpPath, m_grpPics);
    QMessageBox::information(this, tr("保存"), tr("保存成功"));
}

void GrpList::onScroll(int value)
{
    m_scrollOffset = value;
    displayGrpList();
}

void GrpList::onContextMenu(const QPoint &pos)
{
    int squareW = m_imageLabel->width() / m_cols;
    if (squareW < 10) squareW = 10;
    int col = pos.x() / squareW, row = pos.y() / SQUARE_H;
    int idx = m_beginPic + (m_scrollOffset + row) * m_cols + col;
    if (idx >= m_beginPic && idx <= m_endPic && idx < m_grpPics.size())
        m_nowPic = idx;
    else
        m_nowPic = -1;
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
