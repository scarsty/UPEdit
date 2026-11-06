#include "takein.h"
#include "grpedit.h"
#include <QBuffer>
#include <QDialog>
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
#include "fileio.h"
#include <QImageReader>
#include <QMouseEvent>

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
    m_frameSpin = new QSpinBox;
    m_frameSpin->setPrefix(tr("帧 "));
    m_frameSpin->setRange(0, 0);
    leftPanel->addWidget(m_frameSpin);
    m_allFrames = new QCheckBox(tr("导入全部帧"));
    leftPanel->addWidget(m_allFrames);
    leftPanel->addWidget(new QLabel(tr("宽:")));
    leftPanel->addWidget(m_widthEdit);
    leftPanel->addWidget(new QLabel(tr("高:")));
    leftPanel->addWidget(m_heightEdit);
    leftPanel->addWidget(new QLabel(tr("X偏移:")));
    leftPanel->addWidget(m_xoffEdit);
    leftPanel->addWidget(new QLabel(tr("Y偏移:")));
    leftPanel->addWidget(m_yoffEdit);
    leftPanel->addWidget(btnConfirm);
    m_cropX = new QSpinBox;
    m_cropY = new QSpinBox;
    m_cropX->setRange(0, 32767);
    m_cropY->setRange(0, 32767);
    leftPanel->addWidget(new QLabel(tr("裁剪起点 X")));
    leftPanel->addWidget(m_cropX);
    leftPanel->addWidget(new QLabel(tr("裁剪起点 Y")));
    leftPanel->addWidget(m_cropY);
    auto *cropImage = new QPushButton(tr("按起点及宽高裁剪"));
    leftPanel->addWidget(cropImage);
    connect(cropImage, &QPushButton::clicked, this, &TakeIn::onCropImage);
    leftPanel->addWidget(m_transCheck);
    leftPanel->addWidget(m_transColorEdit);
    leftPanel->addWidget(btnTransColor);
    leftPanel->addWidget(new QLabel(tr("目标GRP:")));
    leftPanel->addWidget(m_grpCombo);
    m_idxPath = new QLineEdit;
    m_grpPath = new QLineEdit;
    m_palettePath = new QLineEdit;
    auto addPath = [&](const QString &title, QLineEdit *edit) {
        auto *row = new QHBoxLayout;
        auto *browse = new QPushButton(title);
        row->addWidget(edit);
        row->addWidget(browse);
        leftPanel->addLayout(row);
        connect(browse, &QPushButton::clicked, this, [this, edit, title] {
            QString path = QFileDialog::getOpenFileName(this, title);
            if (!path.isEmpty()) edit->setText(path);
        });
    };
    addPath(tr("选择IDX"), m_idxPath);
    addPath(tr("选择GRP"), m_grpPath);
    addPath(tr("选择COL"), m_palettePath);
    connect(m_grpCombo, QOverload<int>::of(&QComboBox::currentIndexChanged), this, [this](int index) {
        auto &config = IniConfig::instance();
        if (index < 0 || index >= config.grpListIdx.size() || index >= config.grpListGrp.size()) return;
        m_idxPath->setText(config.gamePath + "/" + config.grpListIdx[index]);
        m_grpPath->setText(config.gamePath + "/" + config.grpListGrp[index]);
    });
    auto *editImage = new QPushButton(tr("编辑当前区域"));
    leftPanel->addWidget(editImage);
    connect(editImage, &QPushButton::clicked, this, &TakeIn::onEditImage);
    leftPanel->addWidget(btnImport);
    leftPanel->addStretch();

    auto *scroll = new QScrollArea;
    m_imageLabel = new QLabel;
    m_imageLabel->installEventFilter(this);
    scroll->setWidget(m_imageLabel);
    scroll->setWidgetResizable(false);

    m_progress = new QProgressBar; m_progress->setVisible(false);

    auto *rightLayout = new QVBoxLayout;
    rightLayout->addWidget(scroll, 1);
    rightLayout->addWidget(m_progress);

    auto *settingsPanel = new QWidget;
    settingsPanel->setLayout(leftPanel);
    auto *settingsScroll = new QScrollArea;
    settingsScroll->setWidget(settingsPanel);
    settingsScroll->setWidgetResizable(true);
    settingsScroll->setMinimumWidth(270);
    mainLayout->addWidget(settingsScroll);
    mainLayout->addLayout(rightLayout, 1);

    connect(btnOpen, &QPushButton::clicked, this, &TakeIn::onOpenImage);
    connect(btnImport, &QPushButton::clicked, this, &TakeIn::onImportToGrp);
    connect(btnTransColor, &QPushButton::clicked, this, &TakeIn::onSetTransColor);
    connect(btnConfirm, &QPushButton::clicked, this, &TakeIn::onConfirmSize);
    connect(m_frameSpin, QOverload<int>::of(&QSpinBox::valueChanged), this, [this](int frame) {
        if (frame < 0 || frame >= m_frames.size()) return;
        m_sourceImage = m_frames[frame];
        m_widthEdit->setText(QString::number(m_sourceImage.width()));
        m_heightEdit->setText(QString::number(m_sourceImage.height()));
        displayImage();
    });
}

bool TakeIn::eventFilter(QObject *watched, QEvent *event)
{
    if (watched != m_imageLabel) return QWidget::eventFilter(watched, event);
    if (event->type() == QEvent::MouseButtonPress) {
        auto *mouse = static_cast<QMouseEvent *>(event);
        if (mouse->button() == Qt::LeftButton) m_cropStart = mouse->position().toPoint();
    } else if (event->type() == QEvent::MouseButtonRelease) {
        auto *mouse = static_cast<QMouseEvent *>(event);
        if (mouse->button() == Qt::LeftButton && m_cropStart.x() >= 0) {
            QPoint end = mouse->position().toPoint();
            QPoint first(qMin(m_cropStart.x(), end.x()), qMin(m_cropStart.y(), end.y()));
            QPoint last(qMax(m_cropStart.x(), end.x()), qMax(m_cropStart.y(), end.y()));
            QRect crop = QRect(first, last).intersected(m_sourceImage.rect());
            bool dragged = end != m_cropStart;
            m_cropStart = QPoint(-1, -1);
            if (!crop.isEmpty() && dragged) {
                if (m_allFrames->isChecked())
                    for (QImage &frame : m_frames) frame = frame.copy(crop);
                m_sourceImage = m_sourceImage.copy(crop);
                m_widthEdit->setText(QString::number(crop.width()));
                m_heightEdit->setText(QString::number(crop.height()));
                displayImage();
            }
            return true;
        }
    }
    return QWidget::eventFilter(watched, event);
}

void TakeIn::onEditImage()
{
    if (m_sourceImage.isNull()) return;
    QDialog dialog(this);
    dialog.setWindowTitle(tr("编辑当前区域"));
    auto *layout = new QVBoxLayout(&dialog);
    auto *editor = new GrpEdit(&dialog);
    GrpPic picture;
    QBuffer buffer(&picture.data);
    if (!m_sourceImage.save(&buffer, "PNG")) return;
    picture.width = m_sourceImage.width();
    picture.height = m_sourceImage.height();
    picture.size = picture.data.size();
    QVector<QRgb> colors;
    auto &config = IniConfig::instance();
    QByteArray palette = FileIO::readFileAll(m_palettePath->text().isEmpty() ? config.gamePath + "/" + config.palette : m_palettePath->text());
    if (palette.size() >= 768)
        for (int index = 0; index < 256; ++index)
            colors.append(qRgb(qMin(255, int(quint8(palette[index * 3])) * 4),
                qMin(255, int(quint8(palette[index * 3 + 1])) * 4), qMin(255, int(quint8(palette[index * 3 + 2])) * 4)));
    editor->setSprite(picture, colors);
    layout->addWidget(editor);
    auto *cancel = new QPushButton(tr("取消"));
    layout->addWidget(cancel);
    connect(cancel, &QPushButton::clicked, &dialog, &QDialog::reject);
    QImage result;
    connect(editor, &GrpEdit::spriteModified, &dialog, [&](const GrpPic &saved) {
        result = QImage::fromData(saved.data, "PNG");
        if (!result.isNull()) dialog.accept();
    });
    dialog.resize(900, 750);
    if (dialog.exec() != QDialog::Accepted || result.isNull()) return;
    m_sourceImage = result;
    m_widthEdit->setText(QString::number(result.width()));
    m_heightEdit->setText(QString::number(result.height()));
    displayImage();
}

void TakeIn::onOpenImage()
{
    QString f = QFileDialog::getOpenFileName(this, tr("打开图片"), {},
        "Images (*.png *.jpg *.bmp *.gif);;All (*.*)");
    if (f.isEmpty()) return;
    openImage(f);
}

void TakeIn::openImage(const QString &path)
{
    QImageReader reader(path);
    QVector<QImage> frames;
    qint64 pixels = 0;
    while (reader.canRead() && frames.size() < 10000) {
        QImage frame = reader.read();
        if (frame.isNull()) { QMessageBox::warning(this, tr("打开"), reader.errorString()); return; }
        pixels += qint64(frame.width()) * frame.height();
        if (pixels > 67108864) { QMessageBox::warning(this, tr("打开"), tr("图片帧总量过大")); return; }
        frames.append(frame.convertToFormat(QImage::Format_ARGB32));
        if (!reader.supportsAnimation()) break;
    }
    if (frames.isEmpty()) return;
    m_frames = frames;
    m_frameSpin->setRange(0, frames.size() - 1);
    m_frameSpin->setValue(0);
    m_sourceImage = frames[0];

    m_sourceImage = m_sourceImage.convertToFormat(QImage::Format_ARGB32);
    m_widthEdit->setText(QString::number(m_sourceImage.width()));
    m_heightEdit->setText(QString::number(m_sourceImage.height()));
    displayImage();
}

void TakeIn::displayImage()
{
    if (m_sourceImage.isNull()) return;
    if (m_frameSpin->value() >= 0 && m_frameSpin->value() < m_frames.size())
        m_frames[m_frameSpin->value()] = m_sourceImage;
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

void TakeIn::onCropImage()
{
    if (m_sourceImage.isNull()) return;
    bool widthValid, heightValid;
    int width = m_widthEdit->text().toInt(&widthValid);
    int height = m_heightEdit->text().toInt(&heightValid);
    QRect crop(m_cropX->value(), m_cropY->value(), width, height);
    if (!widthValid || !heightValid || width <= 0 || height <= 0 || width > 32767 || height > 32767
        || !m_sourceImage.rect().contains(crop)) {
        QMessageBox::warning(this, tr("裁剪"), tr("裁剪区域必须位于图片内且宽高为正整数")); return;
    }
    if (m_allFrames->isChecked())
        for (const QImage &frame : m_frames)
            if (!frame.rect().contains(crop)) {
                QMessageBox::warning(this, tr("裁剪"), tr("部分帧不包含此区域，未修改图片")); return;
            }
    QImage result = m_sourceImage.copy(crop);
    if (result.isNull()) return;
    if (m_allFrames->isChecked())
        for (QImage &frame : m_frames) frame = frame.copy(crop);
    m_sourceImage = result;
    m_cropX->setValue(0);
    m_cropY->setValue(0);
    displayImage();
}

void TakeIn::onConfirmSize()
{
    if (m_sourceImage.isNull()) return;
    bool validWidth, validHeight;
    int width = m_widthEdit->text().toInt(&validWidth);
    int height = m_heightEdit->text().toInt(&validHeight);
    if (!validWidth || !validHeight || width <= 0 || height <= 0
        || width > SHRT_MAX || height > SHRT_MAX || qint64(width) * height > 67108864) {
        QMessageBox::warning(this, tr("尺寸"), tr("尺寸必须是有效正整数，单边不超过 32767，总像素不超过 67108864"));
        return;
    }
    QImage cropped = m_sourceImage.copy(0, 0, width, height);
    if (cropped.isNull()) {
        QMessageBox::warning(this, tr("尺寸"), tr("无法分配图片内存")); return;
    }
    m_sourceImage = cropped;
    if (m_allFrames->isChecked())
        for (QImage &frame : m_frames) frame = frame.copy(0, 0, width, height);
    displayImage();
}

void TakeIn::onImportToGrp()
{
    if (m_sourceImage.isNull()) return;

    int xoff = m_xoffEdit->text().toInt();
    int yoff = m_yoffEdit->text().toInt();
    bool validX, validY;
    xoff = m_xoffEdit->text().toInt(&validX);
    yoff = m_yoffEdit->text().toInt(&validY);
    if (!validX || !validY || xoff < SHRT_MIN || xoff > SHRT_MAX || yoff < SHRT_MIN || yoff > SHRT_MAX) {
        QMessageBox::warning(this, tr("导入"), tr("偏移必须是 16 位整数")); return;
    }

    int grpIdx = m_grpCombo->currentIndex();
    IniConfig &cfg = IniConfig::instance();
    QString idxPath = m_idxPath->text(), grpPath = m_grpPath->text();
    if (idxPath.isEmpty() || grpPath.isEmpty()) {
        if (grpIdx < 0 || grpIdx >= cfg.grpListIdx.size() || grpIdx >= cfg.grpListGrp.size()) return;
        if (idxPath.isEmpty()) idxPath = cfg.gamePath + "/" + cfg.grpListIdx[grpIdx];
        if (grpPath.isEmpty()) grpPath = cfg.gamePath + "/" + cfg.grpListGrp[grpIdx];
    }

    // 读取已有 GRP
    QVector<GrpPic> pics;
    if ((QFile::exists(idxPath) || QFile::exists(grpPath)) && !GrpIO::readGrp(idxPath, grpPath, pics)) {
        QMessageBox::warning(this, tr("导入"), tr("读取目标图片组失败")); return;
    }
    QByteArray palette = FileIO::readFileAll(m_palettePath->text().isEmpty() ? cfg.gamePath + "/" + cfg.palette : m_palettePath->text());
    if (palette.size() < 768) { QMessageBox::warning(this, tr("导入"), tr("游戏调色板无效")); return; }
    for (int index = 0; index < 256; ++index) {
        m_palR[index] = qMin(255, int(uint8_t(palette[index * 3])) * 4);
        m_palG[index] = qMin(255, int(uint8_t(palette[index * 3 + 1])) * 4);
        m_palB[index] = qMin(255, int(uint8_t(palette[index * 3 + 2])) * 4);
    }
    QVector<QImage> images = m_allFrames->isChecked() && !m_frames.isEmpty() ? m_frames : QVector<QImage>{m_sourceImage};
    for (QImage &image : images) {
        if (m_transCheck->isChecked()) {
            bool validColor;
            uint color = m_transColorEdit->text().toUInt(&validColor, 16);
            if (!validColor || color > 0xffffff) { QMessageBox::warning(this, tr("导入"), tr("透明色必须是六位 RGB 十六进制值")); return; }
            for (int row = 0; row < image.height(); ++row)
                for (int column = 0; column < image.width(); ++column)
                    if ((image.pixel(column, row) & 0xffffff) == color) image.setPixel(column, row, 0);
        }
        GrpPic newPic = GrpIO::encodeRLE(image, m_palR, m_palG, m_palB);
        if (newPic.data.isEmpty()) { QMessageBox::warning(this, tr("导入"), tr("图片超出 RLE 行编码限制，请裁剪或使用 PNG 导入")); return; }
        newPic.xoff = xoff;
        newPic.yoff = yoff;
        pics.append(newPic);
    }

    // 保存
    if (!GrpIO::saveGrp(idxPath, grpPath, pics)) { QMessageBox::warning(this, tr("导入"), tr("保存失败")); return; }
    QMessageBox::information(this, tr("导入"), tr("导入完成，新索引: %1").arg(pics.size() - 1));
}
