#include "imagezform.h"
#include "imzdata.h"
#include "iniconfig.h"
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QGroupBox>
#include <QFileDialog>
#include <QMessageBox>
#include <QPainter>
#include <QDir>
#include <QClipboard>
#include <QApplication>
#include <QBuffer>
#include <QDialog>
#include <QSpinBox>

#include <QResizeEvent>
#include <QMouseEvent>

ImagezForm::ImagezForm(QWidget *parent) : QWidget(parent)
{
    auto *mainLayout = new QVBoxLayout(this);

    // 顶部设置
    auto *topGroup = new QGroupBox(tr("文件"));
    auto *topLayout = new QHBoxLayout(topGroup);
    m_fileEdit = new QLineEdit;
    auto *btnRead = new QPushButton(tr("读取"));
    auto *btnReadFolder = new QPushButton(tr("读文件夹"));
    auto *btnDisplay = new QPushButton(tr("显示"));
    auto *btnSave = new QPushButton(tr("保存"));
    m_animCheck = new QCheckBox(tr("动画"));

    m_modeImz = new QRadioButton(tr("IMZ")); m_modeImz->setVisible(false);
    m_modePngFolder = new QRadioButton(tr("PNG文件夹")); m_modePngFolder->setChecked(true);
    m_modePngZip = new QRadioButton(tr("PNG压缩包"));

    topLayout->addWidget(m_fileEdit, 1);
    topLayout->addWidget(btnRead);
    topLayout->addWidget(btnReadFolder);
    topLayout->addWidget(btnDisplay);
    topLayout->addWidget(btnSave);
    topLayout->addWidget(m_animCheck);
    topLayout->addWidget(m_modeImz);
    topLayout->addWidget(m_modePngFolder);
    topLayout->addWidget(m_modePngZip);
    mainLayout->addWidget(topGroup);

    // 打包/解包
    auto *packGroup = new QGroupBox(tr("打包/解包"));
    auto *packLayout = new QHBoxLayout(packGroup);
    auto *btnPack = new QPushButton(tr("打包ZIP"));
    auto *btnUnpack = new QPushButton(tr("解包ZIP"));
    packLayout->addWidget(btnPack);
    packLayout->addWidget(btnUnpack);
    packLayout->addStretch();
    mainLayout->addWidget(packGroup);

    // 主显示区
    auto *centerLayout = new QHBoxLayout;
    m_imageLabel = new QLabel;
    m_imageLabel->setMinimumSize(640, 480);
    m_imageLabel->setContextMenuPolicy(Qt::CustomContextMenu);
    m_scrollBar = new QScrollBar(Qt::Vertical);
    centerLayout->addWidget(m_imageLabel, 1);
    centerLayout->addWidget(m_scrollBar);
    mainLayout->addLayout(centerLayout, 1);

    // 动画计时器
    m_animTimer = new QTimer(this);
    m_animTimer->setInterval(100);

    // 右键菜单
    m_contextMenu = new QMenu(this);
    m_contextMenu->addAction(tr("编辑"), this, &ImagezForm::onEditSprite);
    m_contextMenu->addAction(tr("复制"), this, &ImagezForm::onCopySprite);
    m_contextMenu->addAction(tr("粘贴"), this, &ImagezForm::onPasteSprite);
    m_contextMenu->addSeparator();
    m_contextMenu->addAction(tr("插入"), this, &ImagezForm::onInsertSprite);
    m_contextMenu->addAction(tr("删除"), this, &ImagezForm::onDeleteSprite);
    m_contextMenu->addSeparator();
    m_contextMenu->addAction(tr("导出全部PNG"), this, &ImagezForm::onExportAllPNG);
    m_contextMenu->addAction(tr("设置战斗帧数"), this, &ImagezForm::onSetFightFrames);

    connect(btnRead, &QPushButton::clicked, this, &ImagezForm::onRead);
    connect(btnReadFolder, &QPushButton::clicked, this, &ImagezForm::onReadFolder);
    connect(btnDisplay, &QPushButton::clicked, this, &ImagezForm::onDisplay);
    connect(btnSave, &QPushButton::clicked, this, &ImagezForm::onSave);
    connect(m_scrollBar, &QScrollBar::valueChanged, this, &ImagezForm::onScroll);
    connect(m_animTimer, &QTimer::timeout, this, &ImagezForm::onAnimate);
    connect(m_animCheck, &QCheckBox::toggled, [this](bool on) { on ? m_animTimer->start() : m_animTimer->stop(); });
    connect(m_imageLabel, &QLabel::customContextMenuRequested, this, &ImagezForm::onContextMenu);
    connect(btnPack, &QPushButton::clicked, this, &ImagezForm::onPack);
    connect(btnUnpack, &QPushButton::clicked, this, &ImagezForm::onUnpack);
}

void ImagezForm::openImzFile(const QString &path)
{
    m_fileEdit->setText(path);
    m_currentPath = path;
    readImzFromFile(path);
    drawImz();
}

void ImagezForm::readImzFromFile(const QString &path)
{
    ImzIO::readImz(path, m_imz);
    updateScrollRange();
}

void ImagezForm::readImzFromFolder(const QString &dir)
{
    ImzIO::readImzFromFolder(dir, m_imz);
    updateScrollRange();
}

void ImagezForm::onRead()
{
    QString f = QFileDialog::getOpenFileName(this, tr("打开PNG压缩包"), {}, "ZIP (*.zip);;All (*.*)");
    if (f.isEmpty()) return;
    m_fileEdit->setText(f);
    m_currentPath = f;
    readImzFromFile(f);
    drawImz();
}

void ImagezForm::onReadFolder()
{
    QString d = QFileDialog::getExistingDirectory(this, tr("选择PNG文件夹"));
    if (d.isEmpty()) return;
    m_fileEdit->setText(d);
    m_currentPath = d;
    readImzFromFolder(d);
    drawImz();
}

void ImagezForm::onDisplay() { drawImz(); }

void ImagezForm::drawImz()
{
    if (m_imz.pngNum <= 0) return;

    static const int SQUARE_H = 100;
    static const int TITLE_H  = 10;

    int labelW = m_imageLabel->width();
    int labelH = m_imageLabel->height();
    if (labelW <= 0 || labelH <= 0) return;

    int squareW = labelW / m_cols;
    if (squareW < 10) squareW = 10;

    int visRows = labelH / SQUARE_H + 1;
    int startIdx = m_scrollOffset * m_cols;

    QImage canvas(m_cols * squareW, visRows * SQUARE_H, QImage::Format_ARGB32);
    canvas.fill(Qt::black);
    QPainter p(&canvas);
    p.setPen(Qt::white);
    p.setFont(QFont("SimSun", 8));

    for (int row = 0; row < visRows; ++row) {
        for (int col = 0; col < m_cols; ++col) {
            int idx = startIdx + row * m_cols + col;
            if (idx >= m_imz.pngNum) break;

            int cx = col * squareW;
            int cy = row * SQUARE_H;

            // 显示原始文件编号 (对应 GRP 列表的编号显示)
            p.drawText(cx + 2, cy + TITLE_H, QString::number(m_imz.imzPng[idx].fileNum));

            // 绘制边框
            p.drawRect(cx, cy, squareW - 1, SQUARE_H - 1);

            // 解码精灵
            QImage sprite = drawImzPNG(idx);
            if (!sprite.isNull()) {
                int drawAreaW = squareW - 4;
                int drawAreaH = SQUARE_H - TITLE_H - 4;
                if (sprite.width() <= drawAreaW && sprite.height() <= drawAreaH) {
                    p.drawImage(cx + 2, cy + TITLE_H + 2, sprite);
                } else {
                    QImage scaled = sprite.scaled(drawAreaW, drawAreaH, Qt::KeepAspectRatio, Qt::FastTransformation);
                    p.drawImage(cx + 2, cy + TITLE_H + 2, scaled);
                }
            }

            // 高亮选中
            if (idx == m_currentIndex) {
                p.save();
                p.setPen(QPen(Qt::red, 2));
                p.drawRect(cx + 1, cy + 1, squareW - 3, SQUARE_H - 3);
                p.restore();
            }
        }
    }

    m_imageLabel->setPixmap(QPixmap::fromImage(canvas));
}

void ImagezForm::updateScrollRange()
{
    int totalRows = (m_imz.pngNum + m_cols - 1) / m_cols;
    int visRows = m_imageLabel->height() / 100 + 1;
    m_scrollBar->setRange(0, qMax(0, totalRows - visRows));
}

void ImagezForm::resizeEvent(QResizeEvent *e)
{
    QWidget::resizeEvent(e);
    if (m_imz.pngNum > 0) {
        updateScrollRange();
        drawImz();
    }
}

void ImagezForm::mousePressEvent(QMouseEvent *e)
{
    QPoint pos = m_imageLabel->mapFrom(this, e->pos());
    if (!m_imageLabel->rect().contains(pos)) {
        QWidget::mousePressEvent(e);
        return;
    }

    int squareW = m_imageLabel->width() / m_cols;
    if (squareW < 10) squareW = 10;
    static const int SQUARE_H = 100;

    int col = pos.x() / squareW;
    int row = pos.y() / SQUARE_H;
    int idx = (m_scrollOffset + row) * m_cols + col;
    if (idx >= 0 && idx < m_imz.pngNum) {
        m_currentIndex = idx;
        drawImz();
    }
    QWidget::mousePressEvent(e);
}

QImage ImagezForm::drawImzPNG(int index)
{
    if (index < 0 || index >= m_imz.imzPng.size()) return {};
    const auto &sprite = m_imz.imzPng[index];
    if (sprite.frameData.isEmpty() || sprite.frameData[0].data.isEmpty()) return {};

    QImage img;
    img.loadFromData(sprite.frameData[0].data, "PNG");
    return img;
}

void ImagezForm::onSave()
{
    if (m_currentPath.isEmpty()) return;
    if (m_modeImz->isChecked()) {
        ImzIO::saveImz(m_currentPath, m_imz);
    } else if (m_modePngFolder->isChecked()) {
        QDir dir(m_currentPath);
        dir.mkpath(".");
        // Save each PNG to folder individually
        for (int i = 0; i < m_imz.imzPng.size(); ++i) {
            const auto &sp = m_imz.imzPng[i];
            if (!sp.frameData.isEmpty() && !sp.frameData[0].data.isEmpty()) {
                QFile f(m_currentPath + "/" + QString::number(i) + ".png");
                if (f.open(QIODevice::WriteOnly)) f.write(sp.frameData[0].data);
            }
        }
    }
    QMessageBox::information(this, tr("保存"), tr("保存成功"));
}

void ImagezForm::onScroll(int value) { m_scrollOffset = value; drawImz(); }

void ImagezForm::onAnimate()
{
    m_animFrame++;
    drawImz();
}

void ImagezForm::onContextMenu(const QPoint &pos)
{
    int cellW = 80, cellH = 80;
    int col = pos.x() / cellW, row = pos.y() / cellH;
    m_currentIndex = (m_scrollOffset + row) * m_cols + col;
    if (m_currentIndex >= m_imz.pngNum) m_currentIndex = -1;
    m_contextMenu->exec(m_imageLabel->mapToGlobal(pos));
}

void ImagezForm::onEditSprite()
{
    if (m_currentIndex < 0 || m_currentIndex >= m_imz.imzPng.size()) return;
    ImzPng &ip = m_imz.imzPng[m_currentIndex];

    QImage img = drawImzPNG(m_currentIndex);
    if (img.isNull()) return;

    QDialog dlg(this);
    dlg.setWindowTitle(tr("编辑偏移 - %1").arg(ip.fileNum));
    auto *lay = new QVBoxLayout(&dlg);

    auto *imgLabel = new QLabel;
    auto *formLay = new QHBoxLayout;
    auto *xSpin = new QSpinBox; xSpin->setRange(-9999, 9999); xSpin->setValue(ip.x);
    auto *ySpin = new QSpinBox; ySpin->setRange(-9999, 9999); ySpin->setValue(ip.y);
    formLay->addWidget(new QLabel(tr("X偏移:")));
    formLay->addWidget(xSpin);
    formLay->addWidget(new QLabel(tr("Y偏移:")));
    formLay->addWidget(ySpin);

    auto *btnBox = new QHBoxLayout;
    auto *btnOk = new QPushButton(tr("确定"));
    auto *btnCancel = new QPushButton(tr("取消"));
    btnBox->addStretch();
    btnBox->addWidget(btnOk);
    btnBox->addWidget(btnCancel);

    lay->addWidget(imgLabel, 1);
    lay->addLayout(formLay);
    lay->addLayout(btnBox);

    // 绘制带红色十字的预览
    auto updatePreview = [&]() {
        QImage preview = img.copy();
        QPainter p(&preview);
        int ox = xSpin->value(), oy = ySpin->value();
        p.setPen(QPen(Qt::red, 1));
        p.drawLine(ox - 10, oy, ox + 10, oy);
        p.drawLine(ox, oy - 10, ox, oy + 10);
        p.end();
        imgLabel->setPixmap(QPixmap::fromImage(preview));
    };
    updatePreview();

    connect(xSpin, QOverload<int>::of(&QSpinBox::valueChanged), [&](int) { updatePreview(); });
    connect(ySpin, QOverload<int>::of(&QSpinBox::valueChanged), [&](int) { updatePreview(); });
    connect(btnOk, &QPushButton::clicked, &dlg, &QDialog::accept);
    connect(btnCancel, &QPushButton::clicked, &dlg, &QDialog::reject);

    dlg.resize(qMax(400, img.width() + 40), qMax(300, img.height() + 120));
    if (dlg.exec() == QDialog::Accepted) {
        ip.x = (int16_t)xSpin->value();
        ip.y = (int16_t)ySpin->value();
        drawImz();
    }
}

void ImagezForm::onCopySprite()
{
    if (m_currentIndex < 0 || m_currentIndex >= m_imz.imzPng.size()) return;
    QImage img = drawImzPNG(m_currentIndex);
    if (!img.isNull()) QApplication::clipboard()->setImage(img);
}

void ImagezForm::onPasteSprite()
{
    if (m_currentIndex < 0) return;
    QImage img = QApplication::clipboard()->image();
    if (img.isNull()) return;

    // 将 QImage 转为 PNG 数据
    QByteArray pngData;
    QBuffer buf(&pngData);
    buf.open(QIODevice::WriteOnly);
    img.save(&buf, "PNG");

    if (m_currentIndex < m_imz.imzPng.size()) {
        if (m_imz.imzPng[m_currentIndex].frameData.isEmpty())
            m_imz.imzPng[m_currentIndex].frameData.resize(1);
        m_imz.imzPng[m_currentIndex].frameData[0].data = pngData;
    }
    drawImz();
}

void ImagezForm::onDeleteSprite()
{
    if (m_currentIndex < 0 || m_currentIndex >= m_imz.imzPng.size()) return;
    m_imz.imzPng.removeAt(m_currentIndex);
    m_imz.pngNum = m_imz.imzPng.size();
    drawImz();
}

void ImagezForm::onInsertSprite()
{
    if (m_currentIndex < 0) m_currentIndex = m_imz.imzPng.size();
    ImzPng newSprite;
    m_imz.imzPng.insert(m_currentIndex, newSprite);
    m_imz.pngNum = m_imz.imzPng.size();
    drawImz();
}

void ImagezForm::onExportAllPNG()
{
    QString dir = QFileDialog::getExistingDirectory(this, tr("选择导出路径"));
    if (dir.isEmpty()) return;

    // 写 index.ka
    QFile ka(dir + "/index.ka");
    ka.open(QIODevice::WriteOnly);
    QDataStream ds(&ka);
    ds.setByteOrder(QDataStream::LittleEndian);

    for (int i = 0; i < m_imz.imzPng.size(); ++i) {
        const auto &sprite = m_imz.imzPng[i];
        if (!sprite.frameData.isEmpty() && !sprite.frameData[0].data.isEmpty()) {
            QFile f(dir + "/" + QString::number(i) + ".png");
            if (f.open(QIODevice::WriteOnly))
                f.write(sprite.frameData[0].data);
        }
        ds << sprite.x << sprite.y;
    }
    QMessageBox::information(this, tr("导出"), tr("导出完成"));
}

void ImagezForm::onSetFightFrames() { /* TODO: 打开 FightFrameForm 对话框 */ }

void ImagezForm::onPack()
{
    QString src = QFileDialog::getExistingDirectory(this, tr("选择PNG文件夹"));
    if (src.isEmpty()) return;
    QString dst = QFileDialog::getSaveFileName(this, tr("保存ZIP"), {}, "ZIP (*.zip);;IMZ (*.imz)");
    if (dst.isEmpty()) return;

    Imz imz;
    ImzIO::readImzFromFolder(src, imz);
    ImzIO::saveImz(dst, imz);
    QMessageBox::information(this, tr("打包"), tr("打包完成"));
}

void ImagezForm::onUnpack()
{
    QString src = QFileDialog::getOpenFileName(this, tr("打开ZIP/IMZ"), {}, "ZIP (*.zip);;IMZ (*.imz)");
    if (src.isEmpty()) return;
    QString dst = QFileDialog::getExistingDirectory(this, tr("选择输出目录"));
    if (dst.isEmpty()) return;

    Imz imz;
    ImzIO::readImz(src, imz);
    // Save each PNG to folder
    for (int i = 0; i < imz.imzPng.size(); ++i) {
        const auto &sp = imz.imzPng[i];
        if (!sp.frameData.isEmpty() && !sp.frameData[0].data.isEmpty()) {
            QFile f(dst + "/" + QString::number(i) + ".png");
            if (f.open(QIODevice::WriteOnly)) f.write(sp.frameData[0].data);
        }
    }
    QMessageBox::information(this, tr("解包"), tr("解包完成"));
}
