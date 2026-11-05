#include "pngimport.h"
#include "grpdata.h"
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QListWidget>
#include <QCheckBox>
#include <QFileDialog>
#include <QMessageBox>
#include <QDialog>
#include <QDialogButtonBox>
#include <QPainter>
#include <QColorDialog>
#include <QBuffer>
#include <QDataStream>
#include <QApplication>
#include <QMouseEvent>
#include <QIntValidator>
#include <QCloseEvent>
#include <QScopedValueRollback>
#include "fileio.h"
#include "iniconfig.h"

// ========= PNGImport =========

PNGImport::PNGImport(QWidget *parent) : QWidget(parent)
{
    auto *mainLayout = new QVBoxLayout(this);

    auto *topBar = new QHBoxLayout;
    m_colEdit = new QLineEdit; m_idxEdit = new QLineEdit; m_grpEdit = new QLineEdit;
    auto *btnCol = new QPushButton(tr("COL"));
    auto *btnIdx = new QPushButton(tr("IDX"));
    auto *btnGrp = new QPushButton(tr("GRP"));

    topBar->addWidget(m_colEdit, 1); topBar->addWidget(btnCol);
    topBar->addWidget(m_idxEdit, 1); topBar->addWidget(btnIdx);
    topBar->addWidget(m_grpEdit, 1); topBar->addWidget(btnGrp);
    mainLayout->addLayout(topBar);

    m_progress = new QProgressBar; m_progress->setVisible(false);
    mainLayout->addWidget(m_progress);

    auto *centerLayout = new QHBoxLayout;
    auto *btnPanel = new QVBoxLayout;
    auto *btnAdd = new QPushButton(tr("添加"));
    auto *btnModify = new QPushButton(tr("修改"));
    auto *btnDelete = new QPushButton(tr("删除"));
    auto *btnStart = new QPushButton(tr("开始导入"));
    btnPanel->addWidget(btnAdd);
    btnPanel->addWidget(btnModify);
    btnPanel->addWidget(btnDelete);
    btnPanel->addWidget(btnStart);
    btnPanel->addStretch();

    m_fileList = new QListWidget;
    m_fileList->setSelectionMode(QAbstractItemView::ExtendedSelection);
    centerLayout->addLayout(btnPanel);
    centerLayout->addWidget(m_fileList, 1);
    mainLayout->addLayout(centerLayout, 1);

    connect(btnCol, &QPushButton::clicked, this, &PNGImport::onOpenCol);
    connect(btnIdx, &QPushButton::clicked, this, &PNGImport::onOpenIdx);
    connect(btnGrp, &QPushButton::clicked, this, &PNGImport::onOpenGrp);
    connect(btnAdd, &QPushButton::clicked, this, &PNGImport::onAddFiles);
    connect(btnModify, &QPushButton::clicked, this, &PNGImport::onModifyEntry);
    connect(btnDelete, &QPushButton::clicked, this, &PNGImport::onDeleteEntry);
    connect(btnStart, &QPushButton::clicked, this, &PNGImport::onStartImport);
}

bool PNGImport::loadPalette(const QString &path)
{
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly)) return false;
    QByteArray data = file.readAll();
    if (file.error() != QFileDevice::NoError || data.size() < 768) return false;
    QVector<QRgb> palette(256);
    for (int i = 0; i < 256; ++i) {
        int r = (uint8_t)data[i * 3] << 2;
        int g = (uint8_t)data[i * 3 + 1] << 2;
        int b = (uint8_t)data[i * 3 + 2] << 2;
        palette[i] = qRgb(qMin(r, 255), qMin(g, 255), qMin(b, 255));
    }
    m_palette = palette;
    return true;
}

void PNGImport::onOpenCol()
{
    QString f = QFileDialog::getOpenFileName(this, tr("选择COL"), {}, "COL (*.col)");
    if (!f.isEmpty()) {
        if (loadPalette(f)) m_colEdit->setText(f);
        else QMessageBox::warning(this, tr("COL"), tr("调色板无法读取或不足 256 色"));
    }
}

void PNGImport::onOpenIdx()
{
    QString f = QFileDialog::getOpenFileName(this, tr("选择IDX"), {}, "IDX (*.idx)");
    if (!f.isEmpty()) m_idxEdit->setText(f);
}

void PNGImport::onOpenGrp()
{
    QString f = QFileDialog::getOpenFileName(this, tr("选择GRP"), {}, "GRP (*.grp)");
    if (!f.isEmpty()) m_grpEdit->setText(f);
}

void PNGImport::onAddFiles()
{
    QStringList files = QFileDialog::getOpenFileNames(this, tr("添加PNG"), {}, "PNG (*.png);;All (*.*)");
    for (const auto &f : files) {
        PNGEntry entry;
        entry.fileName = f;
        m_entries.append(entry);
        m_fileList->addItem(QFileInfo(f).fileName());
    }
}

void PNGImport::onModifyEntry()
{
    int row = m_fileList->currentRow();
    if (row < 0 || row >= m_entries.size()) return;

    QImage preview(m_entries[row].fileName);
    PNGImportModify dlg(preview, this);
    const auto &entry = m_entries[row];
    dlg.setOptions(entry.xOff, entry.yOff, entry.keepPNG, entry.transparent, QColor::fromRgb(entry.transColor));
    if (dlg.exec() == QDialog::Accepted) {
        for (int index = 0; index < m_entries.size(); ++index) {
            if (!dlg.applyAll() && index != row) continue;
            m_entries[index].xOff = dlg.xOffset();
            m_entries[index].yOff = dlg.yOffset();
            m_entries[index].keepPNG = dlg.keepPNG();
            m_entries[index].transparent = dlg.useTransColor();
            m_entries[index].transColor = dlg.transColor().rgb();
        }
    }
}

void PNGImport::onDeleteEntry()
{
    auto items = m_fileList->selectedItems();
    for (auto *item : items) {
        int row = m_fileList->row(item);
        m_entries.removeAt(row);
        delete m_fileList->takeItem(row);
    }
}

void PNGImport::onStartImport()
{
    if (m_entries.isEmpty() || m_idxEdit->text().isEmpty() || m_grpEdit->text().isEmpty()) return;

    // 加载现有 GRP
    QVector<GrpPic> grpPics;
    bool indexExists = QFile::exists(m_idxEdit->text()), dataExists = QFile::exists(m_grpEdit->text());
    if ((indexExists || dataExists) && (!indexExists || !dataExists || !GrpIO::readGrp(m_idxEdit->text(), m_grpEdit->text(), grpPics))) {
        QMessageBox::warning(this, tr("导入"), tr("现有 IDX/GRP 不完整或无法读取")); return;
    }

    m_progress->setVisible(true);
    m_progress->setRange(0, m_entries.size());

    for (int i = 0; i < m_entries.size(); ++i) {
        const auto &entry = m_entries[i];
        if (entry.xOff < SHRT_MIN || entry.xOff > SHRT_MAX || entry.yOff < SHRT_MIN || entry.yOff > SHRT_MAX) {
            m_progress->setVisible(false);
            QMessageBox::warning(this, tr("导入"), tr("图片偏移超出 int16 范围")); return;
        }
        QImage img(entry.fileName);
        if (img.isNull() || (!entry.keepPNG && m_palette.size() != 256)) {
            m_progress->setVisible(false);
            QMessageBox::warning(this, tr("导入"), tr("图片无效或未加载完整调色板：%1").arg(entry.fileName)); return;
        }
        img = img.convertToFormat(QImage::Format_ARGB32);
        if (entry.transparent) for (int row = 0; row < img.height(); ++row)
            for (int column = 0; column < img.width(); ++column)
                if ((img.pixel(column, row) & 0xffffff) == (entry.transColor & 0xffffff)) img.setPixelColor(column, row, Qt::transparent);

        GrpPic pic;
        pic.width = img.width();
        pic.height = img.height();
        pic.xoff = entry.xOff;
        pic.yoff = entry.yOff;

        if (entry.keepPNG) {
            // 保持原始 PNG 格式
            if (entry.xOff || entry.yOff) {
                m_progress->setVisible(false);
                QMessageBox::warning(this, tr("导入"), tr("原始 PNG 在 GRP 中不支持偏移；请改用 RLE 或将偏移归零")); return;
            }
            QBuffer buffer(&pic.data);
            if (!img.save(&buffer, "PNG")) { m_progress->setVisible(false); return; }
        } else {
            // 转 RLE8
            img = img.convertToFormat(QImage::Format_ARGB32);
            uint8_t pr[256]{}, pg[256]{}, pb[256]{};
            for (int j = 0; j < 256 && j < m_palette.size(); ++j) {
                pr[j] = qRed(m_palette[j]); pg[j] = qGreen(m_palette[j]); pb[j] = qBlue(m_palette[j]);
            }
            pic = GrpIO::encodeRLE(img, pr, pg, pb);
            if (pic.data.isEmpty()) {
                m_progress->setVisible(false);
                QMessageBox::warning(this, tr("导入"), tr("图片超出 RLE 行编码限制，请选择保留 PNG")); return;
            }
            pic.xoff = entry.xOff;
            pic.yoff = entry.yOff;
        }
        pic.size = pic.data.size();
        grpPics.append(pic);
        m_progress->setValue(i + 1);
    }

    bool saved = GrpIO::saveGrp(m_idxEdit->text(), m_grpEdit->text(), grpPics);
    m_progress->setVisible(false);
    if (!saved) { QMessageBox::warning(this, tr("导入"), tr("保存失败，未完成导入")); return; }
    QMessageBox::information(this, tr("导入"), tr("导入完成"));
}

// ========= PNGImportModify =========

PNGImportModify::PNGImportModify(const QImage &preview, QWidget *parent)
    : QDialog(parent), m_preview(preview)
{
    setWindowTitle(tr("PNG导入设置"));
    auto *layout = new QVBoxLayout(this);

    m_previewLabel = new QLabel;
    m_previewLabel->setFixedSize(400, 400);
    m_previewLabel->installEventFilter(this);
    layout->addWidget(m_previewLabel);

    auto *form = new QHBoxLayout;
    m_xEdit = new QLineEdit("0");
    m_yEdit = new QLineEdit("0");
    m_xEdit->setValidator(new QIntValidator(SHRT_MIN, SHRT_MAX, m_xEdit));
    m_yEdit->setValidator(new QIntValidator(SHRT_MIN, SHRT_MAX, m_yEdit));
    form->addWidget(new QLabel("X:")); form->addWidget(m_xEdit);
    form->addWidget(new QLabel("Y:")); form->addWidget(m_yEdit);
    layout->addLayout(form);

    m_applyAllCheck = new QCheckBox(tr("应用到全部"));
    m_keepPNGCheck = new QCheckBox(tr("保持原始PNG"));
    m_transCheck = new QCheckBox(tr("设置透明色"));
    m_colorBtn = new QPushButton(tr("选择颜色"));
    layout->addWidget(m_applyAllCheck);
    layout->addWidget(m_keepPNGCheck);
    auto *transLayout = new QHBoxLayout;
    transLayout->addWidget(m_transCheck);
    transLayout->addWidget(m_colorBtn);
    layout->addLayout(transLayout);

    auto *buttons = new QDialogButtonBox(QDialogButtonBox::Ok | QDialogButtonBox::Cancel);
    layout->addWidget(buttons);

    connect(buttons, &QDialogButtonBox::accepted, this, [this] {
        if (m_xEdit->hasAcceptableInput() && m_yEdit->hasAcceptableInput()) accept();
    });
    connect(buttons, &QDialogButtonBox::rejected, this, &QDialog::reject);
    connect(m_colorBtn, &QPushButton::clicked, [this]() {
        QColor c = QColorDialog::getColor(m_transCol, this);
        if (c.isValid()) m_transCol = c;
    });

    drawOffset();
    connect(m_xEdit, &QLineEdit::textChanged, this, [this] { drawOffset(); });
    connect(m_yEdit, &QLineEdit::textChanged, this, [this] { drawOffset(); });
}

void PNGImportModify::setOptions(int x, int y, bool png, bool transparent, QColor color)
{
    m_xEdit->setText(QString::number(x));
    m_yEdit->setText(QString::number(y));
    m_keepPNGCheck->setChecked(png);
    m_transCheck->setChecked(transparent);
    m_transCol = color;
    drawOffset();
}

bool PNGImportModify::eventFilter(QObject *watched, QEvent *event)
{
    if (watched == m_previewLabel && event->type() == QEvent::MouseButtonPress && !m_preview.isNull()) {
        auto *mouse = static_cast<QMouseEvent *>(event);
        double scale = qMin(380.0 / m_preview.width(), 380.0 / m_preview.height());
        m_xEdit->setText(QString::number(qRound((mouse->position().x() - 10) / scale)));
        m_yEdit->setText(QString::number(qRound((mouse->position().y() - 10) / scale)));
        return true;
    }
    return QDialog::eventFilter(watched, event);
}

void PNGImportModify::drawOffset()
{
    QImage canvas(400, 400, QImage::Format_ARGB32);
    canvas.fill(Qt::lightGray);
    QPainter p(&canvas);

    if (!m_preview.isNull()) {
        QImage scaled = m_preview.scaled(380, 380, Qt::KeepAspectRatio);
        p.drawImage(10, 10, scaled);
    }

    double scale = m_preview.isNull() ? 1.0 : qMin(380.0 / m_preview.width(), 380.0 / m_preview.height());
    int x = qRound(m_xEdit->text().toInt() * scale), y = qRound(m_yEdit->text().toInt() * scale);
    p.setPen(QPen(Qt::red, 2));
    p.drawLine(x + 10, 0, x + 10, 400);
    p.drawLine(0, y + 10, 400, y + 10);

    m_previewLabel->setPixmap(QPixmap::fromImage(canvas));
}

int PNGImportModify::xOffset() const { return m_xEdit->text().toInt(); }
int PNGImportModify::yOffset() const { return m_yEdit->text().toInt(); }
bool PNGImportModify::applyAll() const { return m_applyAllCheck->isChecked(); }
bool PNGImportModify::keepPNG() const { return m_keepPNGCheck->isChecked(); }
bool PNGImportModify::useTransColor() const { return m_transCheck->isChecked(); }
QColor PNGImportModify::transColor() const { return m_transCol; }

// ========= PNGExport =========

PNGExport::PNGExport(QWidget *parent) : QDialog(parent)
{
    setWindowTitle(tr("PNG批量导出"));
    auto *layout = new QVBoxLayout(this);

    auto *pathRow = new QHBoxLayout;
    m_pathEdit = new QLineEdit;
    auto *btnPath = new QPushButton(tr("选择路径"));
    pathRow->addWidget(m_pathEdit, 1);
    pathRow->addWidget(btnPath);
    layout->addLayout(pathRow);

    m_progress = new QProgressBar;
    layout->addWidget(m_progress);

    m_statusLabel = new QLabel;
    layout->addWidget(m_statusLabel);

    auto *btnRow = new QHBoxLayout;
    auto *btnStart = new QPushButton(tr("开始"));
    auto *btnStop = new QPushButton(tr("停止"));
    auto *btnClose = new QPushButton(tr("关闭"));
    btnRow->addWidget(btnStart);
    btnRow->addWidget(btnStop);
    btnRow->addWidget(btnClose);
    layout->addLayout(btnRow);

    connect(btnPath, &QPushButton::clicked, this, &PNGExport::onSelectPath);
    connect(btnStart, &QPushButton::clicked, this, &PNGExport::onStart);
    connect(btnStop, &QPushButton::clicked, this, &PNGExport::onStop);
    connect(btnClose, &QPushButton::clicked, this, &QDialog::close);
}

void PNGExport::startExport(const QVector<GrpPic> &pics, const QVector<QRgb> &palette)
{
    if (m_exporting) return;
    m_pics = pics;
    m_palette = palette;
    show();
}

void PNGExport::onSelectPath()
{
    QString d = QFileDialog::getExistingDirectory(this, tr("选择导出路径"));
    if (!d.isEmpty()) m_pathEdit->setText(d);
}

void PNGExport::onStart()
{
    if (m_exporting) return;
    QString dir = m_pathEdit->text();
    if (dir.isEmpty() || m_pics.isEmpty()) return;
    QString indexName = IniConfig::instance().imzIndexFileName;
    if (indexName.isEmpty() || indexName == "." || indexName == ".."
        || indexName.contains('/') || indexName.contains('\\') || indexName.contains(':')
        || indexName.endsWith('.') || indexName.endsWith(' ')
        || indexName.endsWith(".png", Qt::CaseInsensitive)) {
        m_statusLabel->setText(tr("索引文件名无效")); return;
    }

    QScopedValueRollback<bool> exporting(m_exporting, true);
    m_running = true;
    m_progress->setRange(0, m_pics.size());

    QByteArray metadata;
    QDataStream ds(&metadata, QIODevice::WriteOnly);
    ds.setByteOrder(QDataStream::LittleEndian);
    QMap<QString, QByteArray> files;

    for (int i = 0; i < m_pics.size() && m_running; ++i) {
        const auto &pic = m_pics[i];
        if (pic.xoff < SHRT_MIN || pic.xoff > SHRT_MAX || pic.yoff < SHRT_MIN || pic.yoff > SHRT_MAX) {
            m_running = false; m_statusLabel->setText(tr("偏移超出索引范围")); return;
        }
        QByteArray bytes;
        if (GrpIO::isPNG(pic)) {
            if (QImage::fromData(pic.data, "PNG").isNull()) {
                m_running = false; m_statusLabel->setText(tr("PNG图片无效")); return;
            }
            bytes = pic.data;
        } else if (pic.width > 0 && pic.height > 0) {
            if (m_palette.size() != 256) {
                m_running = false; m_statusLabel->setText(tr("需要完整的 256 色调色板")); return;
            }
            uint8_t pr[256]{}, pg[256]{}, pb[256]{};
            for (int j = 0; j < 256 && j < m_palette.size(); ++j) {
                pr[j] = qRed(m_palette[j]); pg[j] = qGreen(m_palette[j]); pb[j] = qBlue(m_palette[j]);
            }
            QImage img = GrpIO::decodeRLE(pic, pr, pg, pb);
            QBuffer buffer(&bytes);
            if (img.isNull() || !img.save(&buffer, "PNG")) {
                m_running = false; m_statusLabel->setText(tr("图片解码失败")); return;
            }
        }
        if (bytes.isEmpty() && !pic.data.isEmpty()) {
            m_running = false; m_statusLabel->setText(tr("图片数据无效")); return;
        }
        if (!bytes.isEmpty()) files.insert(QDir(dir).filePath(QString::number(i) + ".png"), bytes);
        ds << (int16_t)pic.xoff << (int16_t)pic.yoff;
        m_progress->setValue(i + 1);
        m_statusLabel->setText(tr("正在导出 %1/%2").arg(i + 1).arg(m_pics.size()));
        QApplication::processEvents();
    }

    bool completed = m_running && ds.status() == QDataStream::Ok;
    if (completed) {
        files.insert(QDir(dir).filePath(indexName), metadata);
        completed = FileIO::writeFiles(files);
    }
    m_running = false;
    m_statusLabel->setText(completed ? tr("导出完成") : tr("导出中止或索引写入失败"));
}

void PNGExport::onStop() { m_running = false; }

void PNGExport::reject()
{
    m_running = false;
    QDialog::reject();
}

void PNGExport::closeEvent(QCloseEvent *event)
{
    m_running = false;
    QDialog::closeEvent(event);
}
