#include "grplist.h"
#include "grpedit.h"
#include "pngimport.h"
#include <QDialog>
#include <QInputDialog>
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
#include <QColorDialog>
#include <QGroupBox>
#include <QSettings>
#include <QTemporaryFile>
#include <QDataStream>
#include <QCloseEvent>
#include <QApplication>
#include <QClipboard>
#include <QMimeData>

QByteArray GrpList::stateBytes() const
{
    QByteArray bytes;
    QDataStream stream(&bytes, QIODevice::WriteOnly);
    for (const auto &picture : m_grpPics)
        stream << picture.data << picture.xoff << picture.yoff;
    return bytes;
}

bool GrpList::savePictures()
{
    QString index = m_loadedIdx.isEmpty() ? m_idxEdit->text().trimmed() : m_loadedIdx;
    QString data = m_loadedGrp.isEmpty() ? m_grpEdit->text().trimmed() : m_loadedGrp;
    if (index.isEmpty() || data.isEmpty() || !GrpIO::saveGrp(index, data, m_grpPics)) {
        QMessageBox::warning(this, tr("保存"), tr("保存失败，原文件已保留"));
        return false;
    }
    m_loadedIdx = index;
    m_loadedGrp = data;
    m_savedState = stateBytes();
    return true;
}

bool GrpList::confirmDiscard()
{
    if (m_loadedIdx.isEmpty() || stateBytes() == m_savedState) return true;
    auto answer = QMessageBox::question(this, tr("未保存修改"), tr("保存图片组修改？"),
        QMessageBox::Save | QMessageBox::Discard | QMessageBox::Cancel, QMessageBox::Cancel);
    if (answer == QMessageBox::Save) return savePictures();
    return answer == QMessageBox::Discard;
}

void GrpList::closeEvent(QCloseEvent *event)
{
    if (confirmDiscard()) event->accept(); else event->ignore();
}

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

    // 背景和字体颜色选择 (对应 Delphi GroupBox1)
    {
        IniConfig &cfg = IniConfig::instance();
        // 从 INI 读取保存的颜色
        QTemporaryFile temporary;
        QString preparedPath;
        if (prepareIniPath(cfg.iniPath, temporary, preparedPath)) {
            QSettings ini(preparedPath, QSettings::IniFormat);
            int bgVal = ini.value("file/GRPListBackGround", -1).toInt();
            int txtVal = ini.value("file/GRPListTextCol", -1).toInt();
            if (bgVal >= 0) m_bgColor = QColor::fromRgb(bgVal & 0xFF, (bgVal >> 8) & 0xFF, (bgVal >> 16) & 0xFF);
            if (txtVal >= 0) m_textColor = QColor::fromRgb(txtVal & 0xFF, (txtVal >> 8) & 0xFF, (txtVal >> 16) & 0xFF);
        }
    }

    auto *colorGroup = new QGroupBox(tr("背景和字体颜色"));
    auto *colorLayout = new QVBoxLayout(colorGroup);
    auto *btnBgColor = new QPushButton(tr("更改背景色"));
    m_bgColorPanel = new QLabel;
    m_bgColorPanel->setFixedSize(60, 18);
    m_bgColorPanel->setAutoFillBackground(true);
    {
        QPalette pal = m_bgColorPanel->palette();
        pal.setColor(QPalette::Window, m_bgColor);
        m_bgColorPanel->setPalette(pal);
    }
    auto *btnTextColor = new QPushButton(tr("更改字体色"));
    m_textColorPanel = new QLabel;
    m_textColorPanel->setFixedSize(60, 18);
    m_textColorPanel->setAutoFillBackground(true);
    {
        QPalette pal = m_textColorPanel->palette();
        pal.setColor(QPalette::Window, m_textColor);
        m_textColorPanel->setPalette(pal);
    }
    colorLayout->addWidget(btnBgColor);
    colorLayout->addWidget(m_bgColorPanel);
    colorLayout->addWidget(btnTextColor);
    colorLayout->addWidget(m_textColorPanel);
    topBar->addWidget(colorGroup);

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
    m_contextMenu->addAction(tr("替换PNG并转RLE"), this, [this] { replacePNG(true); });
    m_contextMenu->addAction(tr("复制贴图"), this, &GrpList::onCopyCurrent);
    m_contextMenu->addAction(tr("粘贴贴图"), this, &GrpList::onPasteCurrent);
    m_contextMenu->addSeparator();
    m_contextMenu->addAction(tr("插入"), this, &GrpList::onInsertBefore);
    m_contextMenu->addAction(tr("删除"), this, &GrpList::onDeleteCurrent);
    m_contextMenu->addAction(tr("追加空贴图"), this, &GrpList::onAppend);
    m_contextMenu->addAction(tr("批量偏移"), this, &GrpList::onBatchOffset);
    m_contextMenu->addSeparator();
    m_contextMenu->addAction(tr("导出全部PNG"), this, &GrpList::onExportAllPNG);

    // 填充预设 GRP
    IniConfig &cfg = IniConfig::instance();
    for (int i = 0; i < cfg.grpListNum && i < cfg.grpListName.size(); ++i)
        m_presetCombo->addItem(cfg.grpListName[i]);
    // 战斗帧 GRP (对应 Delphi fightgrpnum)
    for (int i = 0; i < cfg.fightGrpNum; ++i)
        m_presetCombo->addItem(cfg.fightName + QString::number(i));

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
    connect(btnBgColor, &QPushButton::clicked, this, &GrpList::onBgColorPick);
    connect(btnTextColor, &QPushButton::clicked, this, &GrpList::onTextColorPick);
    connect(m_bgColorPanel, &QLabel::linkActivated, this, &GrpList::onBgColorPick);
    connect(m_textColorPanel, &QLabel::linkActivated, this, &GrpList::onTextColorPick);
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
    if (f.isEmpty()) return;
    if (!loadPalette(f)) {
        QMessageBox::warning(this, tr("调色板"), tr("COL 文件读取失败或不足 768 字节"));
        return;
    }
    m_colEdit->setText(f);
    displayGrpList();
}

bool GrpList::loadPalette(const QString &path)
{
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly)) return false;
    QByteArray data = file.readAll();
    if (file.error() != QFileDevice::NoError || data.size() < 768) return false;
    m_palette.resize(256);
    for (int i = 0; i < 256 && i * 3 + 2 < data.size(); ++i) {
        int r = (uint8_t)data[i * 3 + 0] << 2;
        int g = (uint8_t)data[i * 3 + 1] << 2;
        int b = (uint8_t)data[i * 3 + 2] << 2;
        m_palette[i] = qRgb(qMin(r, 255), qMin(g, 255), qMin(b, 255));
    }
    return true;
}

void GrpList::loadGrpFiles(const QString &idxPath, const QString &grpPath, const QString &colPath)
{
    m_idxEdit->setText(idxPath);
    m_grpEdit->setText(grpPath);
    if (!colPath.isEmpty()) m_colEdit->setText(colPath);
    onDisplay();
}

void GrpList::onDisplay()
{
    if (!confirmDiscard()) return;
    QString idxPath = m_idxEdit->text().trimmed();
    QString grpPath = m_grpEdit->text().trimmed();
    if (idxPath.isEmpty() || grpPath.isEmpty()) return;

    if (!GrpIO::readGrp(idxPath, grpPath, m_grpPics)) {
        QMessageBox::warning(this, tr("打开"), tr("图片组索引或数据无效，保留当前列表")); return;
    }

    m_loadedIdx = idxPath;
    m_loadedGrp = grpPath;
    m_savedState = stateBytes();
    if (!m_colEdit->text().isEmpty()) loadPalette(m_colEdit->text());

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

    if (index < cfg.grpListNum) {
        // 常规 GRP 文件
        QString idxPath = cfg.gamePath + "/" + cfg.grpListIdx[index];
        QString grpPath = cfg.gamePath + "/" + cfg.grpListGrp[index];
        m_idxEdit->setText(idxPath);
        m_grpEdit->setText(grpPath);
    } else {
        // 战斗帧 GRP (对应 Delphi fightidx/fightgrp with *** replacement)
        int fightIndex = index - cfg.grpListNum;
        QString nameStr;
        if (fightIndex < 10) nameStr = "00" + QString::number(fightIndex);
        else if (fightIndex < 100) nameStr = "0" + QString::number(fightIndex);
        else nameStr = QString::number(fightIndex);

        QString idxPath = cfg.gamePath + "/" + QString(cfg.fightIdx).replace("***", nameStr);
        QString grpPath = cfg.gamePath + "/" + QString(cfg.fightGrp).replace("***", nameStr);
        m_idxEdit->setText(idxPath);
        m_grpEdit->setText(grpPath);
    }

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
            if (secIdx >= 0 && secIdx < sec.num && secIdx < sec.beginNum.size() && secIdx < sec.endNum.size()) {
                m_beginPic = sec.beginNum[secIdx];
                m_endPic = (sec.endNum[secIdx] == -2) ? m_grpPics.size() - 1 : sec.endNum[secIdx];
            }
        }
    }

    if (m_grpPics.isEmpty()) {
        m_beginPic = 0;
        m_endPic = -1;
    } else {
        m_beginPic = qBound(0, m_beginPic, int(m_grpPics.size()) - 1);
        m_endPic = qBound(m_beginPic, m_endPic, int(m_grpPics.size()) - 1);
    }
    m_scrollOffset = 0;
    m_nowPic = m_endPic >= m_beginPic ? m_beginPic : -1;
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
        for (int i = 0; i < sec.num && i < sec.tag.size() && i < sec.beginNum.size() && i < sec.endNum.size(); ++i) {
            m_sectionCombo->addItem(sec.tag[i]);
        }
    }
    m_sectionCombo->blockSignals(false);
}

void GrpList::displayGrpList()
{
    if (m_grpPics.isEmpty()) { m_imageLabel->clear(); return; }

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
    if (col >= m_cols) return;
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
    if (!savePictures()) return;
    QMessageBox::information(this, tr("保存"), tr("保存成功"));
}

void GrpList::onScroll(int value)
{
    m_scrollOffset = value;
    displayGrpList();
}

void GrpList::onContextMenu(const QPoint &pos)
{
    if (!m_imageLabel->rect().contains(pos)) return;
    int squareW = m_imageLabel->width() / m_cols;
    if (squareW < 10) squareW = 10;
    int col = pos.x() / squareW, row = pos.y() / SQUARE_H;
    if (col >= m_cols) return;
    int idx = m_beginPic + (m_scrollOffset + row) * m_cols + col;
    if (idx >= m_beginPic && idx <= m_endPic && idx < m_grpPics.size())
        m_nowPic = idx;
    else
        m_nowPic = -1;
    m_contextMenu->exec(m_imageLabel->mapToGlobal(pos));
}

void GrpList::onEditCurrent()
{
    if (m_nowPic < 0 || m_nowPic >= m_grpPics.size()) return;
    int index = m_nowPic;
    QDialog dialog(this);
    dialog.setWindowTitle(tr("编辑贴图 %1").arg(index));
    dialog.resize(900, 650);
    auto *layout = new QVBoxLayout(&dialog);
    auto *editor = new GrpEdit(&dialog);
    editor->setSprite(m_grpPics[index], m_palette);
    layout->addWidget(editor);
    connect(editor, &GrpEdit::spriteModified, &dialog, [this, index, &dialog](const GrpPic &picture) {
        m_grpPics[index] = picture;
        displayGrpList();
        dialog.accept();
    });
    dialog.exec();
}

void GrpList::onDeleteCurrent()
{
    if (m_nowPic >= 0 && m_nowPic < m_grpPics.size()) {
        m_grpPics.removeAt(m_nowPic);
        onSectionChanged(m_sectionCombo->currentIndex());
    }
}

void GrpList::onInsertBefore()
{
    if (m_nowPic >= 0 && m_nowPic <= m_grpPics.size()) {
        m_grpPics.insert(m_nowPic, GrpPic());
        onSectionChanged(m_sectionCombo->currentIndex());
    }
}

void GrpList::onReplacePNG()
{
    replacePNG(false);
}

void GrpList::replacePNG(bool rle)
{
    if (m_nowPic < 0 || m_nowPic >= m_grpPics.size()) return;
    QString f = QFileDialog::getOpenFileName(this, tr("选择PNG"), {}, "PNG (*.png)");
    if (f.isEmpty()) return;
    QFile file(f);
    if (!file.open(QIODevice::ReadOnly)) return;
    QByteArray data = file.readAll();
    QImage img; img.loadFromData(data, "PNG");
    if (file.error() != QFileDevice::NoError || img.isNull()) { QMessageBox::warning(this, tr("替换"), tr("PNG 文件无效")); return; }
    if (rle) {
        if (m_palette.size() != 256) {
            QMessageBox::warning(this, tr("替换"), tr("转 RLE 需要完整的 256 色调色板")); return;
        }
        uint8_t red[256]{}, green[256]{}, blue[256]{};
        for (int index = 0; index < 256; ++index) {
            red[index] = qRed(m_palette[index]);
            green[index] = qGreen(m_palette[index]);
            blue[index] = qBlue(m_palette[index]);
        }
        img = img.convertToFormat(QImage::Format_ARGB32);
        QRgb transparent = IniConfig::instance().usualTrans & 0xffffff;
        for (int row = 0; row < img.height(); ++row)
            for (int column = 0; column < img.width(); ++column)
                if ((img.pixel(column, row) & 0xffffff) == transparent)
                    img.setPixelColor(column, row, Qt::transparent);
        GrpPic picture = GrpIO::encodeRLE(img, red, green, blue);
        if (picture.data.isEmpty()) {
            QMessageBox::warning(this, tr("替换"), tr("图片超出 RLE 编码范围")); return;
        }
        m_grpPics[m_nowPic] = picture;
        displayGrpList();
        return;
    }
    m_grpPics[m_nowPic].data = data;
    m_grpPics[m_nowPic].size = data.size();
    m_grpPics[m_nowPic].xoff = 0;
    m_grpPics[m_nowPic].yoff = 0;
    m_grpPics[m_nowPic].width = img.width();
    m_grpPics[m_nowPic].height = img.height();
    displayGrpList();
}

void GrpList::onCopyCurrent()
{
    if (m_nowPic < 0 || m_nowPic >= m_grpPics.size()) return;
    const auto &picture = m_grpPics[m_nowPic];
    QByteArray bytes;
    QDataStream stream(&bytes, QIODevice::WriteOnly);
    stream << quint32(1) << picture.data << picture.xoff << picture.yoff << picture.width << picture.height;
    auto *mime = new QMimeData;
    mime->setData("application/x-upedit-grp-record", bytes);
    QApplication::clipboard()->setMimeData(mime);
}

void GrpList::onPasteCurrent()
{
    if (m_nowPic < 0 || m_nowPic >= m_grpPics.size()) return;
    QByteArray bytes = QApplication::clipboard()->mimeData()->data("application/x-upedit-grp-record");
    if (bytes.isEmpty()) return;
    QDataStream stream(bytes);
    quint32 version = 0;
    GrpPic picture;
    stream >> version >> picture.data >> picture.xoff >> picture.yoff >> picture.width >> picture.height;
    if (version != 1 || stream.status() != QDataStream::Ok || !stream.atEnd()
        || picture.xoff < -32768 || picture.xoff > 32767 || picture.yoff < -32768 || picture.yoff > 32767) return;
    picture.size = picture.data.size();
    if (!picture.data.isEmpty()) {
        uint8_t colors[256]{};
        QImage decoded = GrpIO::isPNG(picture) ? GrpIO::decodePNG(picture)
            : GrpIO::decodeRLE(picture, colors, colors, colors);
        if (decoded.isNull()) return;
        picture.width = decoded.width();
        picture.height = decoded.height();
    }
    m_grpPics[m_nowPic] = picture;
    displayGrpList();
}

void GrpList::onAppend()
{
    m_grpPics.append(GrpPic());
    onSectionChanged(m_sectionCombo->currentIndex());
}

void GrpList::onExportAllPNG()
{
    if (m_grpPics.isEmpty()) return;
    PNGExport dialog(this);
    dialog.startExport(m_grpPics, m_palette);
    dialog.exec();
}

void GrpList::onBatchOffset()
{
    if (m_grpPics.isEmpty()) return;
    bool accepted = false;
    int first = QInputDialog::getInt(this, tr("批量偏移"), tr("起始编号"), 0, 0, m_grpPics.size() - 1, 1, &accepted);
    if (!accepted) return;
    int last = QInputDialog::getInt(this, tr("批量偏移"), tr("结束编号"), m_grpPics.size() - 1, first, m_grpPics.size() - 1, 1, &accepted);
    if (!accepted) return;
    int xoff = QInputDialog::getInt(this, tr("批量偏移"), tr("X偏移"), 0, SHRT_MIN, SHRT_MAX, 1, &accepted);
    if (!accepted) return;
    int yoff = QInputDialog::getInt(this, tr("批量偏移"), tr("Y偏移"), 0, SHRT_MIN, SHRT_MAX, 1, &accepted);
    if (!accepted) return;
    for (int index = first; index <= last; ++index) {
        if (GrpIO::isPNG(m_grpPics[index])) {
            QMessageBox::warning(this, tr("偏移"), tr("所选范围包含不支持偏移的原始 PNG，请缩小范围"));
            return;
        }
    }
    for (int index = first; index <= last; ++index) {
        m_grpPics[index].xoff = xoff;
        m_grpPics[index].yoff = yoff;
    }
    displayGrpList();
}

void GrpList::onBgColorPick()
{
    QColor color = QColorDialog::getColor(m_bgColor, this, tr("选择背景色"));
    if (color.isValid()) {
        int iniColor = color.red() | (color.green() << 8) | (color.blue() << 16);
        if (!saveFileSettings(IniConfig::instance().iniPath, {{"GRPListBackGround", iniColor}})) {
            QMessageBox::warning(this, tr("背景色"), tr("设置保存失败，未修改颜色。"));
            return;
        }
        m_bgColor = color;
        QPalette pal = m_bgColorPanel->palette();
        pal.setColor(QPalette::Window, m_bgColor);
        m_bgColorPanel->setPalette(pal);
        displayGrpList();
    }
}

void GrpList::onTextColorPick()
{
    QColor color = QColorDialog::getColor(m_textColor, this, tr("选择字体色"));
    if (color.isValid()) {
        int iniColor = color.red() | (color.green() << 8) | (color.blue() << 16);
        if (!saveFileSettings(IniConfig::instance().iniPath, {{"GRPListTextCol", iniColor}})) {
            QMessageBox::warning(this, tr("字体色"), tr("设置保存失败，未修改颜色。"));
            return;
        }
        m_textColor = color;
        QPalette pal = m_textColorPanel->palette();
        pal.setColor(QPalette::Window, m_textColor);
        m_textColorPanel->setPalette(pal);
        displayGrpList();
    }
}
