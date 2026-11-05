#include "imagezform.h"
#include "fileio.h"
#include <QMimeData>
#include "fightframeform.h"
#include "imzdata.h"
#include "iniconfig.h"
#include "ZipFile.h"
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
#include <QCloseEvent>
#include <QDialogButtonBox>
#include <QInputDialog>
#include <QListWidget>
#include <QScrollArea>
#include <QMouseEvent>
#include <functional>

class SpritePreviewLabel : public QLabel {
public:
    std::function<void(QPoint)> clicked;
protected:
    void mousePressEvent(QMouseEvent *event) override
    {
        if (event->button() == Qt::LeftButton && clicked) clicked(event->position().toPoint());
        else QLabel::mousePressEvent(event);
    }
};

QByteArray ImagezForm::stateBytes() const
{
    QByteArray bytes;
    QDataStream stream(&bytes, QIODevice::WriteOnly);
    stream << m_imz.pngNum << m_imz.metadata;
    for (const auto &sprite : m_imz.imzPng) {
        stream << sprite.fileNum << sprite.x << sprite.y << sprite.frameData.size();
        for (const auto &frame : sprite.frameData) stream << frame.data;
    }
    return bytes;
}

bool ImagezForm::confirmDiscard()
{
    if ((m_currentPath.isEmpty() && m_imz.imzPng.isEmpty()) || stateBytes() == m_savedState) return true;
    auto answer = QMessageBox::question(this, tr("未保存修改"), tr("保存图片修改？"),
        QMessageBox::Save | QMessageBox::Discard | QMessageBox::Cancel, QMessageBox::Cancel);
    if (answer == QMessageBox::Cancel) return false;
    if (answer == QMessageBox::Save) { onSave(); return stateBytes() == m_savedState; }
    return true;
}

void ImagezForm::closeEvent(QCloseEvent *event)
{
    if (confirmDiscard()) event->accept(); else event->ignore();
}

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
    m_imageLabel->setAlignment(Qt::AlignLeft | Qt::AlignTop);
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
    m_contextMenu->addAction(tr("从PNG插入"), this, [this] { insertPNG(false); });
    m_contextMenu->addAction(tr("从PNG追加"), this, [this] { insertPNG(true); });
    m_contextMenu->addAction(tr("删除"), this, &ImagezForm::onDeleteSprite);
    m_contextMenu->addAction(tr("追加贴图"), this, [this] {
        m_currentIndex = m_imz.imzPng.size();
        onInsertSprite();
    });
    m_contextMenu->addAction(tr("删除末尾贴图"), this, [this] {
        m_currentIndex = m_imz.imzPng.size() - 1;
        onDeleteSprite();
    });
    m_contextMenu->addAction(tr("设置总贴图数"), this, &ImagezForm::onSetSpriteCount);
    m_contextMenu->addAction(tr("批量偏移"), this, &ImagezForm::onBatchOffset);
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
    if (QFileInfo(path).isDir()) readImzFromFolder(path);
    else readImzFromFile(path);
    drawImz();
}

void ImagezForm::readImzFromFile(const QString &path)
{
    if (!confirmDiscard()) return;
    Imz loaded;
    if (!ImzIO::readImz(path, loaded)) {
        QMessageBox::warning(this, tr("打开"), tr("图片文件读取失败，当前会话未改变。"));
        return;
    }
    m_imz = loaded;
    m_savedState = stateBytes();
    m_currentPath = path;
    QFile source(path);
    m_legacyImz = source.open(QIODevice::ReadOnly) && !source.peek(4).startsWith("PK");
    m_fileEdit->setText(path);
    m_modePngZip->setChecked(true);
    m_modePngFolder->setChecked(false);
    m_originalFolderFiles.clear();
    updateScrollRange();
}

void ImagezForm::readImzFromFolder(const QString &dir)
{
    if (!confirmDiscard()) return;
    Imz loaded;
    if (!ImzIO::readImzFromFolder(dir, loaded)) {
        QMessageBox::warning(this, tr("打开"), tr("图片目录读取失败，当前会话未改变。"));
        return;
    }
    m_imz = loaded;
    m_savedState = stateBytes();
    m_currentPath = dir;
    m_legacyImz = false;
    m_fileEdit->setText(dir);
    m_modePngFolder->setChecked(true);
    m_modePngZip->setChecked(false);
    m_originalFolderFiles.clear();
    for (const auto &sprite : m_imz.imzPng)
        m_originalFolderFiles.append(QDir(dir).entryList({QString("%1.png").arg(sprite.fileNum),
            QString("%1_*.png").arg(sprite.fileNum)}, QDir::Files));
    updateScrollRange();
}

void ImagezForm::onRead()
{
    QString f = QFileDialog::getOpenFileName(this, tr("打开PNG压缩包"), {}, "ZIP (*.zip);;All (*.*)");
    if (f.isEmpty()) return;
    readImzFromFile(f);
    drawImz();
}

void ImagezForm::onReadFolder()
{
    QString d = QFileDialog::getExistingDirectory(this, tr("选择PNG文件夹"));
    if (d.isEmpty()) return;
    readImzFromFolder(d);
    drawImz();
}

void ImagezForm::onDisplay() { drawImz(); }

void ImagezForm::drawImz()
{
    if (m_imz.pngNum <= 0) { m_imageLabel->clear(); return; }

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

    int idx = spriteIndexAt(pos);
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
    if (sprite.frameData.isEmpty()) return {};

    QImage img;
    img.loadFromData(sprite.frameData[m_animFrame % sprite.frameData.size()].data, "PNG");
    return img;
}

void ImagezForm::onSave()
{
    if (m_currentPath.isEmpty()) return;
    bool saved = m_modePngFolder->isChecked() ? ImzIO::saveFolder(m_currentPath, m_imz, m_originalFolderFiles)
        : ImzIO::saveImz(m_currentPath, m_imz);
    if (!saved) { QMessageBox::warning(this, tr("保存"), tr("保存失败")); return; }
    m_savedState = stateBytes();
    m_originalFolderFiles.clear();
    QMessageBox::information(this, tr("保存"), tr("保存成功"));
}

void ImagezForm::onScroll(int value) { m_scrollOffset = value; drawImz(); }

void ImagezForm::onAnimate()
{
    m_animFrame = (m_animFrame + 1) % 1000000;
    drawImz();
}

void ImagezForm::onContextMenu(const QPoint &pos)
{
    m_currentIndex = spriteIndexAt(pos);
    drawImz();
    m_contextMenu->exec(m_imageLabel->mapToGlobal(pos));
}

int ImagezForm::spriteIndexAt(const QPoint &position) const
{
    if (!m_imageLabel->rect().contains(position) || m_cols <= 0) return -1;
    int column = position.x() / qMax(10, m_imageLabel->width() / m_cols);
    if (column >= m_cols) return -1;
    int index = (m_scrollOffset + position.y() / 100) * m_cols + column;
    return index >= 0 && index < m_imz.imzPng.size() ? index : -1;
}

void ImagezForm::onEditSprite()
{
    if (m_currentIndex < 0 || m_currentIndex >= m_imz.imzPng.size()) return;
    ImzPng &ip = m_imz.imzPng[m_currentIndex];
    ImzPng working = ip;

    QImage img = drawImzPNG(m_currentIndex);

    QDialog dlg(this);
    dlg.setWindowTitle(tr("编辑偏移 - %1").arg(ip.fileNum));
    auto *lay = new QVBoxLayout(&dlg);

    auto *imgLabel = new SpritePreviewLabel;
    imgLabel->setObjectName("spritePreview");
    auto *previewScroll = new QScrollArea;
    previewScroll->setWidget(imgLabel);
    auto *thumbnails = new QListWidget;
    thumbnails->setObjectName("spriteFrames");
    thumbnails->setViewMode(QListView::IconMode);
    thumbnails->setFlow(QListView::LeftToRight);
    thumbnails->setWrapping(false);
    thumbnails->setIconSize(QSize(64, 64));
    thumbnails->setFixedHeight(104);
    auto *frameSpin = new QSpinBox;
    frameSpin->setRange(0, qMax(0, working.frameData.size() - 1));
    frameSpin->setValue(m_animFrame % qMax(1, working.frameData.size()));
    auto *frameRow = new QHBoxLayout;
    frameRow->addWidget(new QLabel(tr("帧")));
    frameRow->addWidget(frameSpin);
    for (const auto &title : {tr("插入"), tr("追加"), tr("替换"), tr("删除"), tr("导出")})
        frameRow->addWidget(new QPushButton(title));
    auto *formLay = new QHBoxLayout;
    auto *xSpin = new QSpinBox; xSpin->setRange(-32768, 32767); xSpin->setValue(ip.x);
    auto *ySpin = new QSpinBox; ySpin->setRange(-32768, 32767); ySpin->setValue(ip.y);
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

    lay->addWidget(thumbnails);
    lay->addWidget(previewScroll, 1);
    lay->addLayout(frameRow);
    lay->addLayout(formLay);
    lay->addLayout(btnBox);

    // 绘制带红色十字的预览
    auto updatePreview = [&]() {
        QSignalBlocker blocker(thumbnails);
        thumbnails->clear();
        for (int frame = 0; frame < working.frameData.size(); ++frame) {
            auto *item = new QListWidgetItem(QIcon(QPixmap::fromImage(QImage::fromData(working.frameData[frame].data))), QString::number(frame));
            thumbnails->addItem(item);
        }
        thumbnails->setCurrentRow(frameSpin->value());
        bool hasFrame = !working.frameData.isEmpty();
        frameSpin->setEnabled(hasFrame);
        for (int operation = 2; operation < 5; ++operation)
            frameRow->itemAt(operation + 2)->widget()->setEnabled(hasFrame && (operation != 3 || working.frameData.size() > 1));
        img = frameSpin->value() < working.frameData.size() ? QImage::fromData(working.frameData[frameSpin->value()].data) : QImage();
        QImage preview = img.copy();
        if (preview.isNull()) {
            preview = QImage(160, 100, QImage::Format_ARGB32);
            preview.fill(Qt::transparent);
        }
        QPainter p(&preview);
        int ox = xSpin->value(), oy = ySpin->value();
        p.setPen(QPen(Qt::red, 1));
        p.drawLine(ox - 10, oy, ox + 10, oy);
        p.drawLine(ox, oy - 10, ox, oy + 10);
        p.end();
        imgLabel->setPixmap(QPixmap::fromImage(preview));
        imgLabel->setFixedSize(preview.size());
    };
    updatePreview();
    imgLabel->clicked = [&](QPoint position) {
        if (img.isNull() || !img.rect().contains(position)) return;
        xSpin->setValue(position.x());
        ySpin->setValue(position.y());
    };
    connect(thumbnails, &QListWidget::currentRowChanged, &dlg, [frameSpin](int row) {
        if (row >= 0) frameSpin->setValue(row);
    });
    connect(frameSpin, QOverload<int>::of(&QSpinBox::valueChanged), &dlg, [&](int) { updatePreview(); });
    for (int operation = 0; operation < 5; ++operation) {
        auto *button = qobject_cast<QPushButton *>(frameRow->itemAt(operation + 2)->widget());
        connect(button, &QPushButton::clicked, &dlg, [&, operation] {
            int index = frameSpin->value();
            if (operation == 3) {
                if (working.frameData.size() <= 1) return;
                working.frameData.removeAt(index);
            } else if (operation == 4) {
                QString path = QFileDialog::getSaveFileName(&dlg, tr("导出帧"), {}, "PNG (*.png)");
                if (!path.isEmpty() && !FileIO::writeFileAll(path, working.frameData[index].data))
                    QMessageBox::warning(&dlg, tr("导出"), tr("写入失败"));
                return;
            } else {
                QString path = QFileDialog::getOpenFileName(&dlg, tr("选择帧图片"), {}, "PNG (*.png)");
                if (path.isEmpty()) return;
                QByteArray bytes = FileIO::readFileAll(path);
                if (QImage::fromData(bytes, "PNG").isNull()) { QMessageBox::warning(&dlg, tr("图片"), tr("PNG 无效")); return; }
                if (operation == 2) working.frameData[index].data = bytes;
                else {
                    if (operation == 1) index = working.frameData.size();
                    working.frameData.insert(index, {});
                    working.frameData[index].data = bytes;
                }
            }
            frameSpin->setRange(0, working.frameData.size() - 1);
            frameSpin->setValue(qMin(index, working.frameData.size() - 1));
            updatePreview();
        });
    }

    connect(xSpin, QOverload<int>::of(&QSpinBox::valueChanged), [&](int) { updatePreview(); });
    connect(ySpin, QOverload<int>::of(&QSpinBox::valueChanged), [&](int) { updatePreview(); });
    connect(btnOk, &QPushButton::clicked, &dlg, &QDialog::accept);
    connect(btnCancel, &QPushButton::clicked, &dlg, &QDialog::reject);

    dlg.resize(qMax(400, img.width() + 40), qMax(300, img.height() + 120));
    if (dlg.exec() == QDialog::Accepted) {
        ip = working;
        ip.x = (int16_t)xSpin->value();
        ip.y = (int16_t)ySpin->value();
        ip.frame = ip.frameData.size();
        ip.frameLen.resize(ip.frame);
        ip.len = 0;
        for (int frame = 0; frame < ip.frame; ++frame) {
            ip.frameLen[frame] = ip.frameData[frame].data.size();
            ip.len += ip.frameLen[frame];
        }
        drawImz();
    }
}

void ImagezForm::onCopySprite()
{
    if (m_currentIndex < 0 || m_currentIndex >= m_imz.imzPng.size()) return;
    QImage img = drawImzPNG(m_currentIndex);
    {
        const auto &sprite = m_imz.imzPng[m_currentIndex];
        QByteArray bytes;
        QDataStream stream(&bytes, QIODevice::WriteOnly);
        stream << qint16(sprite.x) << qint16(sprite.y) << qint32(sprite.frameData.size());
        for (const auto &frame : sprite.frameData) stream << frame.data;
        auto *mime = new QMimeData;
        if (!img.isNull()) mime->setImageData(img);
        mime->setData("application/x-upedit-sprite", bytes);
        QApplication::clipboard()->setMimeData(mime);
    }
}

void ImagezForm::onPasteSprite()
{
    if (m_currentIndex < 0 || m_currentIndex >= m_imz.imzPng.size()) return;
    const QMimeData *mime = QApplication::clipboard()->mimeData();
    if (mime->hasFormat("application/x-upedit-sprite")) {
        QDataStream stream(mime->data("application/x-upedit-sprite"));
        ImzPng sprite;
        qint16 x, y;
        qint32 count;
        stream >> x >> y >> count;
        if (stream.status() != QDataStream::Ok || count < 0 || count > 10000) return;
        sprite.x = x; sprite.y = y;
        sprite.fileNum = m_imz.imzPng[m_currentIndex].fileNum;
        sprite.frame = count;
        sprite.frameData.resize(count);
        sprite.frameLen.resize(count);
        for (int index = 0; index < count; ++index) {
            stream >> sprite.frameData[index].data;
            if (stream.status() != QDataStream::Ok || QImage::fromData(sprite.frameData[index].data, "PNG").isNull()) return;
            sprite.frameLen[index] = sprite.frameData[index].data.size();
            sprite.len += sprite.frameLen[index];
        }
        if (stream.status() != QDataStream::Ok || !stream.atEnd()) return;
        m_imz.imzPng[m_currentIndex] = sprite;
        drawImz();
        return;
    }
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
        auto &frames = m_imz.imzPng[m_currentIndex].frameData;
        frames[m_animFrame % frames.size()].data = pngData;
        auto &sprite = m_imz.imzPng[m_currentIndex];
        sprite.frame = sprite.frameData.size();
        sprite.frameLen.resize(sprite.frame);
        sprite.len = 0;
        for (int frame = 0; frame < sprite.frame; ++frame) {
            sprite.frameLen[frame] = sprite.frameData[frame].data.size();
            sprite.len += sprite.frameLen[frame];
        }
    }
    drawImz();
}

void ImagezForm::onDeleteSprite()
{
    if (m_currentIndex < 0 || m_currentIndex >= m_imz.imzPng.size()) return;
    m_imz.imzPng.removeAt(m_currentIndex);
    if (m_legacyImz)
        for (int index = 0; index < m_imz.imzPng.size(); ++index) m_imz.imzPng[index].fileNum = index;
    m_imz.pngNum = m_imz.imzPng.size();
    m_currentIndex = qMin(m_currentIndex, m_imz.pngNum - 1);
    updateScrollRange();
    drawImz();
}

void ImagezForm::insertPNG(bool append)
{
    QString path = QFileDialog::getOpenFileName(this, tr("选择PNG贴图"), {}, "PNG (*.png)");
    if (path.isEmpty()) return;
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly)) {
        QMessageBox::warning(this, tr("插入"), tr("无法读取PNG")); return;
    }
    QByteArray bytes = file.readAll();
    if (file.error() != QFileDevice::NoError || QImage::fromData(bytes, "PNG").isNull()) {
        QMessageBox::warning(this, tr("插入"), tr("PNG无效，未修改贴图")); return;
    }
    m_currentIndex = append ? m_imz.imzPng.size() : qBound(0, m_currentIndex, int(m_imz.imzPng.size()));
    onInsertSprite();
    auto &sprite = m_imz.imzPng[m_currentIndex];
    sprite.frameData[0].data = bytes;
    sprite.frameLen = {int(bytes.size())};
    sprite.len = bytes.size();
    drawImz();
}

void ImagezForm::onInsertSprite()
{
    if (m_currentIndex < 0) m_currentIndex = m_imz.imzPng.size();
    ImzPng newSprite;
    int nextId = 0;
    for (const auto &sprite : m_imz.imzPng) nextId = qMax(nextId, sprite.fileNum + 1);
    newSprite.fileNum = nextId;
    newSprite.frame = 1;
    newSprite.frameData.resize(1);
    QImage blank(1, 1, QImage::Format_ARGB32);
    blank.fill(Qt::transparent);
    newSprite.frameData[0].data = ImzIO::encodePng(blank);
    newSprite.frameLen = {int(newSprite.frameData[0].data.size())};
    newSprite.len = newSprite.frameLen[0];
    m_imz.imzPng.insert(m_currentIndex, newSprite);
    if (m_legacyImz)
        for (int index = 0; index < m_imz.imzPng.size(); ++index) m_imz.imzPng[index].fileNum = index;
    m_imz.pngNum = m_imz.imzPng.size();
    updateScrollRange();
    drawImz();
}

void ImagezForm::onExportAllPNG()
{
    QString dir = QFileDialog::getExistingDirectory(this, tr("选择导出路径"));
    if (dir.isEmpty()) return;

    if (!ImzIO::saveFolder(dir, m_imz)) { QMessageBox::warning(this, tr("导出"), tr("导出失败")); return; }
    QMessageBox::information(this, tr("导出"), tr("导出完成"));
}

bool ImagezForm::applyBatchOffset(int first, int last, int axis, int operation, int value)
{
    if (first > last) qSwap(first, last);
    if (first < 0 || last >= m_imz.imzPng.size() || axis < 0 || axis > 2
        || operation < 0 || operation > 4 || (operation == 4 && value == 0)) return false;
    auto pictures = m_imz.imzPng;
    for (int index = first; index <= last; ++index) {
        for (int component = 0; component < 2; ++component) {
            if (axis != 2 && component != axis) continue;
            qint64 result = component == 0 ? pictures[index].x : pictures[index].y;
            switch (operation) {
            case 0: result = value; break;
            case 1: result += value; break;
            case 2: result -= value; break;
            case 3: result *= value; break;
            case 4: result /= value; break;
            }
            if (result < -32768 || result > 32767) return false;
            if (component == 0) pictures[index].x = int(result);
            else pictures[index].y = int(result);
        }
    }
    m_imz.imzPng = pictures;
    drawImz();
    return true;
}

void ImagezForm::onBatchOffset()
{
    if (m_imz.imzPng.isEmpty()) return;
    QDialog dialog(this);
    dialog.setWindowTitle(tr("批量偏移"));
    auto *layout = new QVBoxLayout(&dialog);
    auto *first = new QSpinBox;
    auto *last = new QSpinBox;
    first->setRange(0, m_imz.imzPng.size() - 1);
    last->setRange(0, m_imz.imzPng.size() - 1);
    last->setValue(m_imz.imzPng.size() - 1);
    auto *axis = new QComboBox;
    axis->addItems({tr("X"), tr("Y"), tr("X 和 Y")});
    auto *operation = new QComboBox;
    operation->addItems({tr("赋值"), tr("加"), tr("减"), tr("乘"), tr("除")});
    auto *value = new QSpinBox;
    value->setRange(-32768, 32767);
    for (auto *widget : QList<QWidget *>{new QLabel(tr("起始列表位置")), first,
        new QLabel(tr("结束列表位置")), last, axis, operation, value}) layout->addWidget(widget);
    auto *buttons = new QDialogButtonBox(QDialogButtonBox::Ok | QDialogButtonBox::Cancel);
    layout->addWidget(buttons);
    connect(buttons, &QDialogButtonBox::rejected, &dialog, &QDialog::reject);
    connect(buttons, &QDialogButtonBox::accepted, &dialog, [&] {
        if (!applyBatchOffset(first->value(), last->value(), axis->currentIndex(), operation->currentIndex(), value->value())) {
            QMessageBox::warning(&dialog, tr("批量偏移"), tr("运算越界或除数为零，未修改任何贴图")); return;
        }
        dialog.accept();
    });
    dialog.exec();
}

void ImagezForm::onSetSpriteCount()
{
    bool accepted = false;
    int count = QInputDialog::getInt(this, tr("设置总贴图数"), tr("数量"), m_imz.imzPng.size(), 0, 100000, 1, &accepted);
    if (!accepted || count == m_imz.imzPng.size()) return;
    if (count < m_imz.imzPng.size()) {
        if (QMessageBox::question(this, tr("缩减贴图"), tr("删除超出新数量的末尾贴图？")) != QMessageBox::Yes) return;
        m_imz.imzPng.resize(count);
    } else {
        int nextId = 0;
        for (const auto &sprite : m_imz.imzPng) nextId = qMax(nextId, sprite.fileNum + 1);
        while (m_imz.imzPng.size() < count) {
            ImzPng sprite;
            sprite.fileNum = nextId++;
            m_imz.imzPng.append(sprite);
        }
    }
    if (m_legacyImz)
        for (int index = 0; index < count; ++index) m_imz.imzPng[index].fileNum = index;
    m_imz.pngNum = count;
    m_currentIndex = qMin(m_currentIndex, count - 1);
    updateScrollRange();
    drawImz();
}

void ImagezForm::onSetFightFrames()
{
    FightFrameForm dialog(this);
    QString content = QString::fromLocal8Bit(m_imz.metadata.value("fightframe.txt"));
    if (QFileInfo(m_currentPath).isDir()) {
        QFile file(QDir(m_currentPath).filePath("fightframe.txt"));
        if (file.open(QIODevice::ReadOnly)) content = QString::fromLocal8Bit(file.readAll());
    } else if (!m_currentPath.isEmpty()) {
        ZipFile zip;
        zip.openRead(m_currentPath.toLocal8Bit().toStdString());
        if (zip.opened()) {
            std::string raw = zip.readFile("fightframe.txt");
            content = QString::fromLocal8Bit(raw.data(), static_cast<int>(raw.size()));
        }
    }
    dialog.setContent(content);
    if (dialog.exec() == QDialog::Accepted)
    {
        QByteArray data = dialog.content().toLocal8Bit();
        bool saved = false;
        if (QFileInfo(m_currentPath).isDir()) {
            saved = FileIO::writeFileAll(QDir(m_currentPath).filePath("fightframe.txt"), data);
        } else if (!m_currentPath.isEmpty()) {
            Imz updated;
            if (ImzIO::readImz(m_currentPath, updated)) {
                updated.metadata.insert("fightframe.txt", data);
                saved = ImzIO::saveImz(m_currentPath, updated);
            }
        }
        if (saved) {
            bool wasClean = stateBytes() == m_savedState;
            m_imz.metadata.insert("fightframe.txt", data);
            if (wasClean) m_savedState = stateBytes();
        }
        if (saved) QMessageBox::information(this, tr("战斗帧"), tr("战斗帧设置已保存"));
        else QMessageBox::warning(this, tr("战斗帧"), tr("战斗帧文件保存失败"));
    }
}

void ImagezForm::onPack()
{
    QString src = QFileDialog::getExistingDirectory(this, tr("选择PNG文件夹"));
    if (src.isEmpty()) return;
    QString dst = QFileDialog::getSaveFileName(this, tr("保存ZIP"), {}, "ZIP (*.zip);;IMZ (*.imz)");
    if (dst.isEmpty()) return;

    Imz imz;
    if (!ImzIO::readImzFromFolder(src, imz) || !ImzIO::saveImz(dst, imz)) {
        QMessageBox::warning(this, tr("打包"), tr("打包失败")); return;
    }
    QMessageBox::information(this, tr("打包"), tr("打包完成"));
}

void ImagezForm::onUnpack()
{
    QString src = QFileDialog::getOpenFileName(this, tr("打开ZIP/IMZ"), {}, "ZIP (*.zip);;IMZ (*.imz)");
    if (src.isEmpty()) return;
    QString dst = QFileDialog::getExistingDirectory(this, tr("选择输出目录"));
    if (dst.isEmpty()) return;

    Imz imz;
    if (!ImzIO::readImz(src, imz) || !ImzIO::saveFolder(dst, imz)) {
        QMessageBox::warning(this, tr("解包"), tr("解包失败")); return;
    }
    QMessageBox::information(this, tr("解包"), tr("解包完成"));
}
