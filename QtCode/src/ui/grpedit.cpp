#include "grpedit.h"
#include "grpdata.h"
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QPainter>
#include <QClipboard>
#include <QApplication>
#include <QMouseEvent>
#include <QBuffer>
#include <QMessageBox>
#include <QtEndian>
#include <QColorDialog>
#include <QWheelEvent>

GrpEdit::GrpEdit(QWidget *parent) : QWidget(parent)
{
    auto *mainLayout = new QHBoxLayout(this);

    // 左侧工具栏
    auto *toolPanel = new QVBoxLayout;
    auto *btnCopy = new QPushButton(tr("复制"));
    auto *btnPaste = new QPushButton(tr("粘贴"));
    auto *btnSave = new QPushButton(tr("保存"));
    auto *btnFlipH = new QPushButton(tr("水平翻转"));
    auto *btnFlipV = new QPushButton(tr("垂直翻转"));
    auto *btnRot90 = new QPushButton(tr("旋转90°"));
    auto *btnRot270 = new QPushButton(tr("旋转270°"));

    m_zoomCombo = new QComboBox;
    m_zoomCombo->addItems({"1x", "2x", "4x", "8x", "16x"});
    m_toolCombo = new QComboBox;
    m_toolCombo->addItems({tr("画笔"), tr("吸色"), tr("左吸色／右绘制"), tr("替换为透明色")});
    toolPanel->addWidget(m_toolCombo);

    m_xoffSpin = new QSpinBox; m_xoffSpin->setRange(-32768, 32767);
    m_yoffSpin = new QSpinBox; m_yoffSpin->setRange(-32768, 32767);
    m_widthSpin = new QSpinBox;
    m_heightSpin = new QSpinBox;
    m_widthSpin->setObjectName("canvasWidth");
    m_heightSpin->setObjectName("canvasHeight");
    m_widthSpin->setRange(1, 32767);
    m_heightSpin->setRange(1, 32767);
    auto *resizeCanvas = new QPushButton(tr("确认宽高"));
    resizeCanvas->setObjectName("resizeCanvas");
    auto *customColor = new QPushButton(tr("自定义颜色"));
    customColor->setObjectName("customColor");
    m_showOffset = new QCheckBox(tr("显示偏移"));
    m_showOffset->setChecked(true);
    toolPanel->addWidget(new QLabel(tr("画布宽度")));
    toolPanel->addWidget(m_widthSpin);
    toolPanel->addWidget(new QLabel(tr("画布高度")));
    toolPanel->addWidget(m_heightSpin);
    toolPanel->addWidget(resizeCanvas);
    toolPanel->addWidget(customColor);
    toolPanel->addWidget(m_showOffset);
    connect(m_showOffset, &QCheckBox::toggled, this, [this] { display(); });
    connect(customColor, &QPushButton::clicked, this, [this] {
        QColor color = QColorDialog::getColor(QColor::fromRgb(m_useCustomColor ? m_customColor : m_pal.value(m_curColor)), this);
        if (!color.isValid()) return;
        m_customColor = color.rgb();
        m_useCustomColor = true;
    });
    connect(resizeCanvas, &QPushButton::clicked, this, [this] {
        int width = m_widthSpin->value(), height = m_heightSpin->value();
        if (qint64(width) * height > 16777216) {
            QMessageBox::warning(this, tr("画布"), tr("画布超过像素预算，未修改图片")); return;
        }
        QImage canvas(width, height, QImage::Format_ARGB32);
        if (canvas.isNull()) return;
        canvas.fill(Qt::transparent);
        QPainter painter(&canvas);
        painter.drawImage(0, 0, m_bitmap);
        painter.end();
        m_bitmap = canvas;
        display();
    });

    toolPanel->addWidget(new QLabel(tr("缩放:")));
    toolPanel->addWidget(m_zoomCombo);
    toolPanel->addWidget(btnCopy);
    toolPanel->addWidget(btnPaste);
    toolPanel->addWidget(btnSave);
    toolPanel->addWidget(btnFlipH);
    toolPanel->addWidget(btnFlipV);
    toolPanel->addWidget(btnRot90);
    toolPanel->addWidget(btnRot270);
    toolPanel->addWidget(new QLabel(tr("X偏移:")));
    toolPanel->addWidget(m_xoffSpin);
    toolPanel->addWidget(new QLabel(tr("Y偏移:")));
    toolPanel->addWidget(m_yoffSpin);
    toolPanel->addStretch();

    // 中央：主图显示
    m_scroll = new QScrollArea;
    m_imageLabel = new QLabel;
    m_imageLabel->installEventFilter(this);
    m_imageLabel->setAlignment(Qt::AlignCenter);
    m_scroll->setWidget(m_imageLabel);
    m_scroll->setWidgetResizable(false);
    m_scroll->viewport()->installEventFilter(this);

    // 右侧：调色板
    m_paletteLabel = new QLabel;
    m_paletteLabel->setFixedSize(192, 192);
    m_paletteLabel->installEventFilter(this);

    auto *rightPanel = new QVBoxLayout;
    rightPanel->addWidget(new QLabel(tr("调色板")));
    rightPanel->addWidget(m_paletteLabel);
    rightPanel->addStretch();

    mainLayout->addLayout(toolPanel);
    mainLayout->addWidget(m_scroll, 1);
    mainLayout->addLayout(rightPanel);

    connect(m_zoomCombo, QOverload<int>::of(&QComboBox::currentIndexChanged), this, &GrpEdit::onZoomChanged);
    connect(btnCopy, &QPushButton::clicked, this, &GrpEdit::onCopy);
    connect(btnPaste, &QPushButton::clicked, this, &GrpEdit::onPaste);
    connect(btnSave, &QPushButton::clicked, this, &GrpEdit::onSave);
    connect(btnFlipH, &QPushButton::clicked, this, &GrpEdit::onFlipH);
    connect(btnFlipV, &QPushButton::clicked, this, &GrpEdit::onFlipV);
    connect(btnRot90, &QPushButton::clicked, this, &GrpEdit::onRotate90);
    connect(btnRot270, &QPushButton::clicked, this, &GrpEdit::onRotate270);
    connect(m_xoffSpin, QOverload<int>::of(&QSpinBox::valueChanged), [this](int) { display(); });
    connect(m_yoffSpin, QOverload<int>::of(&QSpinBox::valueChanged), [this](int) { display(); });
}

void GrpEdit::setPalette(const QVector<QRgb> &pal)
{
    m_pal = pal;
    drawPalette();
}

void GrpEdit::setSprite(const GrpPic &pic, const QVector<QRgb> &palette)
{
    m_pal = palette;
    m_keepPNG = GrpIO::isPNG(pic);
    decodeRLE8(pic);
    m_xmove = pic.xoff;
    m_ymove = pic.yoff;
    m_xoffSpin->setValue(m_xmove);
    m_yoffSpin->setValue(m_ymove);
    drawPalette();
    display();
}

void GrpEdit::decodeRLE8(const GrpPic &pic)
{
    int w = pic.width, h = pic.height;
    if (w <= 0 || h <= 0) { m_bitmap = QImage(); return; }

    uint8_t pr[256]{}, pg[256]{}, pb[256]{};
    for (int i = 0; i < 256 && i < m_pal.size(); ++i) {
        pr[i] = qRed(m_pal[i]); pg[i] = qGreen(m_pal[i]); pb[i] = qBlue(m_pal[i]);
    }

    if (GrpIO::isPNG(pic))
        m_bitmap = GrpIO::decodePNG(pic);
    else
        m_bitmap = GrpIO::decodeRLE(pic, pr, pg, pb);
}

QByteArray GrpEdit::encodeRLE8()
{
    if (m_bitmap.isNull()) return {};
    uint8_t pr[256]{}, pg[256]{}, pb[256]{};
    for (int i = 0; i < 256 && i < m_pal.size(); ++i) {
        pr[i] = qRed(m_pal[i]); pg[i] = qGreen(m_pal[i]); pb[i] = qBlue(m_pal[i]);
    }
    GrpPic result = GrpIO::encodeRLE(m_bitmap, pr, pg, pb);
    return result.data;
}

void GrpEdit::display()
{
    if (m_bitmap.isNull()) return;
    m_widthSpin->setValue(m_bitmap.width());
    m_heightSpin->setValue(m_bitmap.height());
    int z = 1 << m_zoomCombo->currentIndex();
    while (z > 1 && qint64(m_bitmap.width()) * m_bitmap.height() * z * z > 67108864)
        z /= 2;
    {
        QSignalBlocker blocker(m_zoomCombo);
        int index = 0;
        for (int scale = z; scale > 1; scale /= 2) ++index;
        m_zoomCombo->setCurrentIndex(index);
    }

    // 绘制带红色十字偏移指示的预览
    QImage preview = m_bitmap.scaled(m_bitmap.width() * z, m_bitmap.height() * z, Qt::KeepAspectRatio, Qt::FastTransformation);
    QPainter p(&preview);
    int ox = m_xoffSpin->value() * z, oy = m_yoffSpin->value() * z;
    p.setPen(QPen(Qt::red, 1));
    if (m_showOffset->isChecked()) {
        p.drawLine(ox - 10, oy, ox + 10, oy);
        p.drawLine(ox, oy - 10, ox, oy + 10);
    }
    p.end();

    m_imageLabel->setPixmap(QPixmap::fromImage(preview));
    m_imageLabel->resize(preview.size());
}

void GrpEdit::drawPalette()
{
    QImage palImg(192, 192, QImage::Format_RGB32);
    palImg.fill(Qt::black);
    QPainter p(&palImg);
    for (int i = 0; i < 256; ++i) {
        int x = (i % 16) * 12, y = (i / 16) * 12;
        QColor c = (i < m_pal.size()) ? QColor::fromRgb(m_pal[i]) : Qt::black;
        p.fillRect(x, y, 12, 12, c);
        p.setPen(Qt::gray);
        p.drawRect(x, y, 11, 11);
    }
    m_paletteLabel->setPixmap(QPixmap::fromImage(palImg));
}

void GrpEdit::onZoomChanged(int) { display(); }

void GrpEdit::onCopy()
{
    if (!m_bitmap.isNull())
        QApplication::clipboard()->setImage(m_bitmap);
}

void GrpEdit::onPaste()
{
    QImage img = QApplication::clipboard()->image();
    if (!img.isNull()) {
        m_bitmap = img.convertToFormat(QImage::Format_ARGB32);
        display();
    }
}

void GrpEdit::onSave()
{
    if (m_bitmap.isNull()) return;
    GrpPic pic;
    pic.width = m_bitmap.width();
    pic.height = m_bitmap.height();
    pic.xoff = m_xoffSpin->value();
    pic.yoff = m_yoffSpin->value();
    if (m_keepPNG) {
        if (pic.xoff || pic.yoff) {
            QMessageBox::warning(this, tr("保存"), tr("GRP 中的原始 PNG 不存储偏移；请将偏移设为零"));
            return;
        }
        QBuffer buffer(&pic.data);
        if (!m_bitmap.save(&buffer, "PNG")) return;
    } else {
        pic.data = encodeRLE8();
        if (pic.data.size() < 8) { QMessageBox::warning(this, tr("保存"), tr("图片超出 RLE 行编码限制")); return; }
        qToLittleEndian<qint16>(pic.xoff, pic.data.data() + 4);
        qToLittleEndian<qint16>(pic.yoff, pic.data.data() + 6);
    }
    pic.size = pic.data.size();
    emit spriteModified(pic);
}

void GrpEdit::onFlipH()
{
    m_bitmap = m_bitmap.mirrored(true, false);
    display();
}

void GrpEdit::onFlipV()
{
    m_bitmap = m_bitmap.mirrored(false, true);
    display();
}

void GrpEdit::onRotate90()
{
    QTransform t; t.rotate(90);
    m_bitmap = m_bitmap.transformed(t);
    display();
}

void GrpEdit::onRotate270()
{
    QTransform t; t.rotate(270);
    m_bitmap = m_bitmap.transformed(t);
    display();
}

void GrpEdit::onPaletteClicked(const QPoint &pos)
{
    m_useCustomColor = false;
    int col = pos.x() / 12, row = pos.y() / 12;
    m_curColor = row * 16 + col;
    if (m_curColor >= 256) m_curColor = 255;
}

void GrpEdit::onImageClicked(const QPoint &position)
{
    if (!m_bitmap.rect().contains(position)) return;
    m_bitmap = m_bitmap.convertToFormat(QImage::Format_ARGB32);
    m_bitmap.setPixelColor(position, QColor::fromRgb(m_useCustomColor ? m_customColor : m_pal.value(m_curColor, qRgb(0, 0, 0))));
    display();
}

bool GrpEdit::eventFilter(QObject *watched, QEvent *event)
{
    if (event->type() == QEvent::Wheel && (watched == m_imageLabel || watched == m_scroll->viewport())) {
        auto *wheel = static_cast<QWheelEvent *>(event);
        int delta = wheel->angleDelta().y();
        if (delta) m_zoomCombo->setCurrentIndex(qBound(0, m_zoomCombo->currentIndex() + (delta > 0 ? 1 : -1), m_zoomCombo->count() - 1));
        event->accept();
        return true;
    }
    if (event->type() != QEvent::MouseButtonPress && event->type() != QEvent::MouseMove)
        return QWidget::eventFilter(watched, event);
    auto *mouse = static_cast<QMouseEvent *>(event);
    if (event->type() == QEvent::MouseMove && mouse->buttons() == Qt::NoButton) return false;
    if (watched == m_paletteLabel) {
        onPaletteClicked(mouse->position().toPoint());
        return true;
    }
    if (watched != m_imageLabel) return false;
    QPoint pixel = mouse->position().toPoint() / (1 << m_zoomCombo->currentIndex());
    if (!m_bitmap.rect().contains(pixel)) return true;
    auto button = event->type() == QEvent::MouseMove ? mouse->buttons() : Qt::MouseButtons(mouse->button());
    int mode = m_toolCombo->currentIndex();
    if (mode == 1 || (mode == 2 && button.testFlag(Qt::LeftButton))) {
        QRgb color = m_bitmap.pixel(pixel);
        int best = 0, distance = INT_MAX;
        for (int index = 0; index < m_pal.size(); ++index) {
            QRgb candidate = m_pal[index];
            int delta = qAbs(qRed(color) - qRed(candidate)) + qAbs(qGreen(color) - qGreen(candidate)) + qAbs(qBlue(color) - qBlue(candidate));
            if (delta < distance) { best = index; distance = delta; }
        }
        m_curColor = best;
        m_useCustomColor = false;
    } else if (mode == 3) {
        QRgb selected = m_bitmap.pixel(pixel);
        m_bitmap = m_bitmap.convertToFormat(QImage::Format_ARGB32);
        for (int row = 0; row < m_bitmap.height(); ++row)
            for (int column = 0; column < m_bitmap.width(); ++column)
                if (m_bitmap.pixel(column, row) == selected) m_bitmap.setPixelColor(column, row, Qt::transparent);
        display();
    } else {
        onImageClicked(pixel);
    }
    return true;
}

GrpPic GrpEdit::resultSprite() const
{
    GrpPic pic;
    pic.width = m_bitmap.width();
    pic.height = m_bitmap.height();
    pic.xoff = m_xoffSpin->value();
    pic.yoff = m_yoffSpin->value();
    // 注意: 此处不encode, 调用者在需要时使用
    return pic;
}
