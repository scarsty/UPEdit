#include "picedit.h"
#include "fileio.h"
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QFileDialog>
#include <QMessageBox>
#include <QDataStream>
#include <QPainter>
#include <QClipboard>
#include <QApplication>

PicEdit::PicEdit(QWidget *parent) : QWidget(parent)
{
    auto *mainLayout = new QVBoxLayout(this);

    // 顶部工具栏
    auto *topBar = new QHBoxLayout;
    auto *btnOpen = new QPushButton(tr("打开"));
    m_indexSpin = new QSpinBox;
    auto *btnPrev = new QPushButton(tr("◀"));
    auto *btnNext = new QPushButton(tr("▶"));
    m_progress = new QProgressBar; m_progress->setVisible(false);

    topBar->addWidget(btnOpen);
    topBar->addWidget(new QLabel(tr("索引:")));
    topBar->addWidget(m_indexSpin);
    topBar->addWidget(btnPrev);
    topBar->addWidget(btnNext);
    topBar->addWidget(m_progress, 1);
    mainLayout->addLayout(topBar);

    // 缩略图带
    m_thumbLabel = new QLabel;
    m_thumbLabel->setFixedHeight(60);
    mainLayout->addWidget(m_thumbLabel);

    // 工具面板 + 主显示区
    auto *centerLayout = new QHBoxLayout;
    auto *toolPanel = new QVBoxLayout;
    m_xoffSpin = new QSpinBox; m_xoffSpin->setRange(-9999, 9999);
    m_yoffSpin = new QSpinBox; m_yoffSpin->setRange(-9999, 9999);
    auto *btnSave = new QPushButton(tr("保存文件"));
    auto *btnCopy = new QPushButton(tr("复制"));
    auto *btnPaste = new QPushButton(tr("粘贴"));
    auto *btnInsert = new QPushButton(tr("插入"));
    auto *btnDelete = new QPushButton(tr("删除"));
    auto *btnExportAll = new QPushButton(tr("全部导出"));

    toolPanel->addWidget(new QLabel(tr("X偏移:")));
    toolPanel->addWidget(m_xoffSpin);
    toolPanel->addWidget(new QLabel(tr("Y偏移:")));
    toolPanel->addWidget(m_yoffSpin);
    toolPanel->addWidget(btnSave);
    toolPanel->addWidget(btnCopy);
    toolPanel->addWidget(btnPaste);
    toolPanel->addWidget(btnInsert);
    toolPanel->addWidget(btnDelete);
    toolPanel->addWidget(btnExportAll);
    toolPanel->addStretch();

    m_scroll = new QScrollArea;
    m_imageLabel = new QLabel;
    m_scroll->setWidget(m_imageLabel);
    m_scroll->setWidgetResizable(false);

    centerLayout->addLayout(toolPanel);
    centerLayout->addWidget(m_scroll, 1);
    mainLayout->addLayout(centerLayout, 1);

    connect(btnOpen, &QPushButton::clicked, this, &PicEdit::onOpen);
    connect(btnSave, &QPushButton::clicked, this, &PicEdit::onSave);
    connect(btnPrev, &QPushButton::clicked, this, &PicEdit::onPrev);
    connect(btnNext, &QPushButton::clicked, this, &PicEdit::onNext);
    connect(btnCopy, &QPushButton::clicked, this, &PicEdit::onCopy);
    connect(btnPaste, &QPushButton::clicked, this, &PicEdit::onPaste);
    connect(btnInsert, &QPushButton::clicked, this, &PicEdit::onInsert);
    connect(btnDelete, &QPushButton::clicked, this, &PicEdit::onDelete);
    connect(btnExportAll, &QPushButton::clicked, this, &PicEdit::onExportAll);
    connect(m_indexSpin, QOverload<int>::of(&QSpinBox::valueChanged), this, &PicEdit::onIndexChanged);
}

void PicEdit::onOpen()
{
    QString f = QFileDialog::getOpenFileName(this, tr("打开PIC文件"), {}, "PIC (*.pic);;All (*.*)");
    if (!f.isEmpty()) openFile(f);
}

void PicEdit::openFile(const QString &path)
{
    m_filePath = path;
    readPicFile(path);
    m_indexSpin->setRange(0, qMax(0, m_pics.size() - 1));
    m_currentIndex = 0;
    m_indexSpin->setValue(0);
    displayCurrent();
    drawThumbnails();
}

void PicEdit::readPicFile(const QString &path)
{
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly)) return;
    QDataStream ds(&file);
    ds.setByteOrder(QDataStream::LittleEndian);

    int32_t count = 0;
    ds >> count;
    if (count <= 0 || count > 100000) return;

    QVector<int32_t> offsets(count + 1);
    for (int i = 0; i <= count; ++i) ds >> offsets[i];

    m_pics.resize(count);
    for (int i = 0; i < count; ++i) {
        file.seek(offsets[i]);
        int32_t xs, ys, bg;
        ds >> xs >> ys >> bg;
        m_pics[i].width = xs;
        m_pics[i].height = ys;
        m_pics[i].background = bg;

        int dataSize;
        if (i + 1 < count)
            dataSize = offsets[i + 1] - offsets[i] - 12;
        else
            dataSize = file.size() - offsets[i] - 12;

        if (dataSize > 0) {
            m_pics[i].data = file.read(dataSize);
            // Detect PNG/JPG
            if (m_pics[i].data.size() > 4) {
                uint8_t b1 = m_pics[i].data[0], b2 = m_pics[i].data[1];
                if (b1 == 0x89 && b2 == 'P') m_pics[i].picType = 1; // PNG
                else if (b1 == 0xFF && b2 == 0xD8) m_pics[i].picType = 2; // JPG
            }
        }
    }
}

void PicEdit::displayCurrent()
{
    if (m_currentIndex < 0 || m_currentIndex >= m_pics.size()) return;
    const auto &pic = m_pics[m_currentIndex];

    QImage img;
    if (pic.picType == 1 || pic.picType == 2) {
        img.loadFromData(pic.data);
    } else {
        // Raw pixel data — simple display
        img = QImage(pic.width, pic.height, QImage::Format_ARGB32);
        img.fill(Qt::black);
        if (pic.data.size() >= pic.width * pic.height * 2) {
            for (int y = 0; y < pic.height; ++y) {
                for (int x = 0; x < pic.width; ++x) {
                    int off = (y * pic.width + x) * 2;
                    uint16_t c = (uint8_t)pic.data[off] | ((uint8_t)pic.data[off + 1] << 8);
                    int r = ((c >> 10) & 0x1F) << 3;
                    int g = ((c >> 5) & 0x1F) << 3;
                    int b = (c & 0x1F) << 3;
                    img.setPixelColor(x, y, QColor(r, g, b));
                }
            }
        }
    }

    if (!img.isNull()) {
        m_imageLabel->setPixmap(QPixmap::fromImage(img));
        m_imageLabel->resize(img.size());
    }
}

void PicEdit::drawThumbnails()
{
    int thumbW = 50, thumbH = 50;
    int count = qMin(m_pics.size(), 20);
    QImage canvas(count * thumbW, thumbH, QImage::Format_ARGB32);
    canvas.fill(Qt::darkGray);
    QPainter p(&canvas);

    int start = qMax(0, m_currentIndex - 10);
    for (int i = 0; i < count; ++i) {
        int idx = start + i;
        if (idx >= m_pics.size()) break;
        const auto &pic = m_pics[idx];
        QImage img;
        if (pic.picType >= 1) img.loadFromData(pic.data);
        if (!img.isNull()) {
            QImage s = img.scaled(thumbW - 4, thumbH - 4, Qt::KeepAspectRatio);
            p.drawImage(i * thumbW + 2, 2, s);
        }
        if (idx == m_currentIndex) {
            p.setPen(QPen(Qt::red, 2));
            p.drawRect(i * thumbW, 0, thumbW - 1, thumbH - 1);
        }
    }
    m_thumbLabel->setPixmap(QPixmap::fromImage(canvas));
}

void PicEdit::onSave()
{
    if (m_filePath.isEmpty() || m_pics.isEmpty()) return;
    QFile file(m_filePath);
    if (!file.open(QIODevice::WriteOnly)) return;
    QDataStream ds(&file);
    ds.setByteOrder(QDataStream::LittleEndian);

    int32_t count = m_pics.size();
    ds << count;

    // 计算偏移
    int32_t headerSize = 4 + (count + 1) * 4;
    QVector<int32_t> offsets(count + 1);
    int32_t pos = headerSize;
    for (int i = 0; i <= count; ++i) {
        offsets[i] = pos;
        if (i < count) pos += 12 + m_pics[i].data.size();
    }
    for (auto off : offsets) ds << off;

    for (const auto &pic : m_pics) {
        ds << (int32_t)pic.width << (int32_t)pic.height << (int32_t)pic.background;
        file.write(pic.data);
    }

    QMessageBox::information(this, tr("保存"), tr("保存成功"));
}

void PicEdit::onPrev() { if (m_currentIndex > 0) m_indexSpin->setValue(m_currentIndex - 1); }
void PicEdit::onNext() { if (m_currentIndex < m_pics.size() - 1) m_indexSpin->setValue(m_currentIndex + 1); }

void PicEdit::onIndexChanged(int val)
{
    m_currentIndex = val;
    displayCurrent();
    drawThumbnails();
}

void PicEdit::onCopy()
{
    if (m_currentIndex < 0 || m_currentIndex >= m_pics.size()) return;
    const auto *pix = m_imageLabel->pixmap();
    if (pix) QApplication::clipboard()->setImage(pix->toImage());
}

void PicEdit::onPaste() { /* 从剪贴板粘贴，转换后存入m_pics[m_currentIndex] */ }

void PicEdit::onInsert()
{
    if (m_currentIndex >= 0)
        m_pics.insert(m_currentIndex, PicData());
    m_indexSpin->setRange(0, qMax(0, m_pics.size() - 1));
    displayCurrent();
}

void PicEdit::onDelete()
{
    if (m_currentIndex >= 0 && m_currentIndex < m_pics.size()) {
        m_pics.removeAt(m_currentIndex);
        m_indexSpin->setRange(0, qMax(0, m_pics.size() - 1));
        if (m_currentIndex >= m_pics.size()) m_currentIndex = m_pics.size() - 1;
        displayCurrent();
    }
}

void PicEdit::onExportAll()
{
    QString dir = QFileDialog::getExistingDirectory(this, tr("选择导出路径"));
    if (dir.isEmpty()) return;
    m_progress->setVisible(true);
    m_progress->setRange(0, m_pics.size());

    QFile ka(dir + "/index.ka");
    ka.open(QIODevice::WriteOnly);
    QDataStream kds(&ka);
    kds.setByteOrder(QDataStream::LittleEndian);

    for (int i = 0; i < m_pics.size(); ++i) {
        const auto &pic = m_pics[i];
        QImage img;
        if (pic.picType >= 1)
            img.loadFromData(pic.data);
        if (!img.isNull())
            img.save(dir + "/" + QString::number(i) + ".png");
        kds << (int16_t)0 << (int16_t)0; // x, y offsets
        m_progress->setValue(i + 1);
    }
    m_progress->setVisible(false);
    QMessageBox::information(this, tr("导出"), tr("导出完成"));
}
