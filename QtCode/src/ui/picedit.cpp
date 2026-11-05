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
#include <QBuffer>
#include <QSignalBlocker>
#include <QMouseEvent>
#include <QInputDialog>
#include <QDir>
#include <QtEndian>
#include <limits>
#include <QCloseEvent>

QByteArray PicEdit::stateBytes() const
{
    return encodeFile(m_pics);
}

bool PicEdit::confirmDiscard()
{
    if (stateBytes() == m_savedState) return true;
    auto answer = QMessageBox::question(this, tr("未保存修改"), tr("保存图片文件修改？"),
        QMessageBox::Save | QMessageBox::Discard | QMessageBox::Cancel, QMessageBox::Cancel);
    if (answer == QMessageBox::Cancel) return false;
    if (answer == QMessageBox::Save) {
        onSave();
        return stateBytes() == m_savedState;
    }
    return true;
}

void PicEdit::closeEvent(QCloseEvent *event)
{
    if (confirmDiscard()) event->accept(); else event->ignore();
}

PicEdit::PicEdit(QWidget *parent) : QWidget(parent)
{
    m_savedState = stateBytes();
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
    m_thumbLabel->setAlignment(Qt::AlignLeft | Qt::AlignTop);
    m_thumbLabel->installEventFilter(this);
    mainLayout->addWidget(m_thumbLabel);

    // 工具面板 + 主显示区
    auto *centerLayout = new QHBoxLayout;
    auto *toolPanel = new QVBoxLayout;
    m_xoffSpin = new QSpinBox; m_xoffSpin->setRange(INT_MIN, INT_MAX);
    m_yoffSpin = new QSpinBox; m_yoffSpin->setRange(INT_MIN, INT_MAX);
    m_backgroundCheck = new QCheckBox(tr("黑色背景"));
    auto *btnAppend = new QPushButton(tr("追加图片"));
    auto *btnExport = new QPushButton(tr("导出当前图片"));
    auto *btnBatch = new QPushButton(tr("批量设置偏移"));
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
    toolPanel->addWidget(m_backgroundCheck);
    toolPanel->addWidget(btnBatch);
    toolPanel->addWidget(btnSave);
    toolPanel->addWidget(btnCopy);
    toolPanel->addWidget(btnPaste);
    toolPanel->addWidget(btnInsert);
    toolPanel->addWidget(btnAppend);
    toolPanel->addWidget(btnDelete);
    toolPanel->addWidget(btnExportAll);
    toolPanel->addWidget(btnExport);
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
    connect(m_xoffSpin, QOverload<int>::of(&QSpinBox::valueChanged), this, [this] { updateMetadata(); });
    connect(m_yoffSpin, QOverload<int>::of(&QSpinBox::valueChanged), this, [this] { updateMetadata(); });
    connect(m_backgroundCheck, &QCheckBox::toggled, this, [this] { updateMetadata(); });
    connect(btnAppend, &QPushButton::clicked, this, [this] { insertImage(true); });
    connect(btnBatch, &QPushButton::clicked, this, [this] {
        if (m_pics.isEmpty()) return;
        bool accepted = false;
        int first = QInputDialog::getInt(this, tr("批量偏移"), tr("起始编号"), 0, 0, m_pics.size() - 1, 1, &accepted);
        if (!accepted) return;
        int last = QInputDialog::getInt(this, tr("批量偏移"), tr("结束编号"), m_pics.size() - 1, first, m_pics.size() - 1, 1, &accepted);
        if (!accepted) return;
        for (int index = first; index <= last; ++index) {
            m_pics[index].xoff = m_xoffSpin->value();
            m_pics[index].yoff = m_yoffSpin->value();
        }
    });
    connect(btnExport, &QPushButton::clicked, this, [this] {
        if (m_currentIndex < 0 || m_currentIndex >= m_pics.size()) return;
        const auto &picture = m_pics[m_currentIndex];
        bool png = picture.data.startsWith(QByteArray::fromHex("89504e470d0a1a0a"));
        QString path = QFileDialog::getSaveFileName(this, tr("导出图片"), {}, png ? "PNG (*.png)" : "JPEG (*.jpg)");
        if (!path.isEmpty() && !FileIO::writeFileAll(path, picture.data))
            QMessageBox::warning(this, tr("导出"), tr("写入图片失败"));
    });
}

void PicEdit::onOpen()
{
    QString f = QFileDialog::getOpenFileName(this, tr("打开PIC文件"), {}, "PIC (*.pic);;All (*.*)");
    if (!f.isEmpty()) openFile(f);
}

void PicEdit::openFile(const QString &path)
{
    if (!confirmDiscard()) return;
    QVector<PicData> pictures;
    if (!decodeFile(FileIO::readFileAll(path), pictures)) {
        QMessageBox::warning(this, tr("打开"), tr("PIC 文件无效或已损坏"));
        return;
    }
    m_filePath = path;
    m_pics = pictures;
    m_savedState = stateBytes();
    m_indexSpin->setRange(0, qMax(0, m_pics.size() - 1));
    m_currentIndex = 0;
    m_indexSpin->setValue(0);
    displayCurrent();
    drawThumbnails();
}

bool PicEdit::decodeFile(const QByteArray &bytes, QVector<PicData> &pictures)
{
    if (bytes.size() < 4) return false;
    qint32 count = qFromLittleEndian<qint32>(bytes.constData());
    if (count < 0 || count > 100000 || qint64(count) * 4 + 4 > bytes.size()) return false;
    QVector<PicData> decoded;
    qint64 begin = 4 + qint64(count) * 4;
    for (int index = 0; index < count; ++index) {
        qint32 end = qFromLittleEndian<qint32>(bytes.constData() + 4 + index * 4);
        if (end < begin + 12 || end > bytes.size()) return false;
        PicData picture;
        picture.xoff = qFromLittleEndian<qint32>(bytes.constData() + begin);
        picture.yoff = qFromLittleEndian<qint32>(bytes.constData() + begin + 4);
        picture.background = qFromLittleEndian<qint32>(bytes.constData() + begin + 8);
        picture.data = bytes.mid(begin + 12, end - begin - 12);
        decoded.append(picture);
        begin = end;
    }
    if (begin != bytes.size()) return false;
    pictures = decoded;
    return true;
}

QByteArray PicEdit::encodeFile(const QVector<PicData> &pictures)
{
    if (pictures.size() > 100000) return {};
    qint64 end = 4 + qint64(pictures.size()) * 4;
    QByteArray result;
    QDataStream stream(&result, QIODevice::WriteOnly);
    stream.setByteOrder(QDataStream::LittleEndian);
    stream << qint32(pictures.size());
    for (const auto &picture : pictures) {
        end += 12 + picture.data.size();
        if (end > INT_MAX) return {};
        stream << qint32(end);
    }
    for (const auto &picture : pictures) {
        stream << picture.xoff << picture.yoff << picture.background;
        stream.writeRawData(picture.data.constData(), picture.data.size());
    }
    return stream.status() == QDataStream::Ok ? result : QByteArray();
}

void PicEdit::displayCurrent()
{
    QSignalBlocker indexBlock(m_indexSpin), xBlock(m_xoffSpin), yBlock(m_yoffSpin), bgBlock(m_backgroundCheck);
    m_indexSpin->setRange(0, qMax(0, m_pics.size() - 1));
    m_indexSpin->setValue(qMax(0, m_currentIndex));
    if (m_currentIndex < 0 || m_currentIndex >= m_pics.size()) {
        m_imageLabel->clear();
        m_imageLabel->resize(1, 1);
        return;
    }
    const auto &pic = m_pics[m_currentIndex];
    m_xoffSpin->setValue(pic.xoff);
    m_yoffSpin->setValue(pic.yoff);
    m_backgroundCheck->setChecked(pic.background == 1);
    m_imageLabel->setStyleSheet(pic.background == 1 ? "background: black" : "background: white");
    QImage img = QImage::fromData(pic.data);
    m_imageLabel->clear();
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
        img.loadFromData(pic.data);
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
    QString path = QFileDialog::getSaveFileName(this, tr("保存PIC文件"), m_filePath, "PIC (*.pic)");
    if (path.isEmpty()) return;
    QByteArray bytes = encodeFile(m_pics);
    if (bytes.isEmpty() || !FileIO::writeFileAll(path, bytes)) {
        QMessageBox::warning(this, tr("保存"), tr("保存失败，原文件未替换"));
        return;
    }
    m_filePath = path;
    m_savedState = stateBytes();
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
    QPixmap pix = m_imageLabel->pixmap();
    if (!pix.isNull()) QApplication::clipboard()->setImage(pix.toImage());
}

void PicEdit::onPaste()
{
    QImage image = QApplication::clipboard()->image();
    if (image.isNull() || m_currentIndex < 0 || m_currentIndex >= m_pics.size()) return;
    QByteArray bytes;
    QBuffer buffer(&bytes);
    if (!image.save(&buffer, "PNG")) return;
    m_pics[m_currentIndex] = PicData{0, 0, 0, bytes};
    displayCurrent();
    drawThumbnails();
}

void PicEdit::onInsert()
{
    insertImage(false);
}

void PicEdit::onDelete()
{
    if (m_currentIndex >= 0 && m_currentIndex < m_pics.size()) {
        m_pics.removeAt(m_currentIndex);
        m_indexSpin->setRange(0, qMax(0, m_pics.size() - 1));
        if (m_currentIndex >= m_pics.size()) m_currentIndex = m_pics.size() - 1;
        displayCurrent();
        drawThumbnails();
    }
}

void PicEdit::onExportAll()
{
    QString dir = QFileDialog::getExistingDirectory(this, tr("选择导出路径"));
    if (dir.isEmpty()) return;
    m_progress->setVisible(true);
    m_progress->setRange(0, m_pics.size());

    QByteArray metadata;
    QDataStream kds(&metadata, QIODevice::WriteOnly);
    kds.setByteOrder(QDataStream::LittleEndian);
    QMap<QString, QByteArray> files;

    for (int i = 0; i < m_pics.size(); ++i) {
        const auto &pic = m_pics[i];
        if (pic.xoff < SHRT_MIN || pic.xoff > SHRT_MAX || pic.yoff < SHRT_MIN || pic.yoff > SHRT_MAX) {
            m_progress->setVisible(false);
            QMessageBox::warning(this, tr("导出"), tr("偏移超出 index.ka 的16位范围"));
            return;
        }
        QString extension = pic.data.startsWith(QByteArray::fromHex("89504e470d0a1a0a")) ? ".png" : ".jpg";
        files.insert(QDir(dir).filePath(QString::number(i) + extension), pic.data);
        kds << qint16(pic.xoff) << qint16(pic.yoff);
        m_progress->setValue(i + 1);
    }
    m_progress->setVisible(false);
    files.insert(QDir(dir).filePath("index.ka"), metadata);
    if (!FileIO::writeFiles(files)) {
        QMessageBox::warning(this, tr("导出"), tr("写入失败"));
        return;
    }
    QMessageBox::information(this, tr("导出"), tr("导出完成"));
}

void PicEdit::insertImage(bool append)
{
    QString path = QFileDialog::getOpenFileName(this, tr("插入图片"), {}, "Images (*.png *.jpg *.jpeg *.bmp)");
    if (path.isEmpty()) return;
    QByteArray bytes = FileIO::readFileAll(path);
    QImage image = QImage::fromData(bytes);
    if (image.isNull()) {
        QMessageBox::warning(this, tr("插入"), tr("图片无法解码"));
        return;
    }
    if (!bytes.startsWith(QByteArray::fromHex("89504e470d0a1a0a")) && !bytes.startsWith(QByteArray::fromHex("ffd8"))) {
        bytes.clear();
        QBuffer buffer(&bytes);
        if (!image.save(&buffer, "PNG")) return;
    }
    int position = append ? m_pics.size() : qBound(0, m_currentIndex, m_pics.size());
    m_pics.insert(position, PicData{0, 0, 0, bytes});
    m_currentIndex = position;
    displayCurrent();
    drawThumbnails();
}

void PicEdit::updateMetadata()
{
    if (m_currentIndex < 0 || m_currentIndex >= m_pics.size()) return;
    auto &picture = m_pics[m_currentIndex];
    picture.xoff = m_xoffSpin->value();
    picture.yoff = m_yoffSpin->value();
    if (sender() == m_backgroundCheck)
        picture.background = m_backgroundCheck->isChecked() ? 1 : 0;
    displayCurrent();
}

bool PicEdit::eventFilter(QObject *watched, QEvent *event)
{
    if (watched == m_thumbLabel && event->type() == QEvent::MouseButtonPress) {
        auto *mouse = static_cast<QMouseEvent *>(event);
        int offset = int(mouse->position().x()) / 50;
        int index = qMax(0, m_currentIndex - 10) + offset;
        if (mouse->position().x() >= 0 && mouse->position().y() < 50 && offset < 20 && index < m_pics.size())
            m_indexSpin->setValue(index);
        return true;
    }
    return QWidget::eventFilter(watched, event);
}
