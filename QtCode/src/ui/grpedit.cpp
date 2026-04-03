#include "grpedit.h"
#include "grpdata.h"
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QPainter>
#include <QClipboard>
#include <QApplication>
#include <QMouseEvent>

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

    m_xoffSpin = new QSpinBox; m_xoffSpin->setRange(-9999, 9999);
    m_yoffSpin = new QSpinBox; m_yoffSpin->setRange(-9999, 9999);

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
    m_imageLabel->setAlignment(Qt::AlignCenter);
    m_scroll->setWidget(m_imageLabel);
    m_scroll->setWidgetResizable(false);

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
}

void GrpEdit::setPalette(const QVector<QRgb> &pal)
{
    m_pal = pal;
    drawPalette();
}

void GrpEdit::setSprite(const GrpPic &pic, const QVector<QRgb> &palette)
{
    m_pal = palette;
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
    m_bitmap = QImage(w, h, QImage::Format_ARGB32);
    m_bitmap.fill(Qt::transparent);

    GrpData::decodeRLE8(pic.data, w, h, m_pal, m_bitmap);
}

QByteArray GrpEdit::encodeRLE8()
{
    if (m_bitmap.isNull()) return {};
    return GrpData::encodeRLE8(m_bitmap, m_pal);
}

void GrpEdit::display()
{
    if (m_bitmap.isNull()) return;
    int z = 1 << m_zoomCombo->currentIndex();
    QImage scaled = m_bitmap.scaled(m_bitmap.width() * z, m_bitmap.height() * z, Qt::KeepAspectRatio, Qt::FastTransformation);
    m_imageLabel->setPixmap(QPixmap::fromImage(scaled));
    m_imageLabel->resize(scaled.size());
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
    GrpPic pic;
    pic.width = m_bitmap.width();
    pic.height = m_bitmap.height();
    pic.xoff = m_xoffSpin->value();
    pic.yoff = m_yoffSpin->value();
    pic.data = encodeRLE8();
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
    int col = pos.x() / 12, row = pos.y() / 12;
    m_curColor = row * 16 + col;
    if (m_curColor >= 256) m_curColor = 255;
}

void GrpEdit::onImageClicked(const QPoint &) { /* 绘制模式 */ }

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
