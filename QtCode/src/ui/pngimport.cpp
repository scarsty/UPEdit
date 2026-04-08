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

void PNGImport::loadPalette(const QString &path)
{
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly)) return;
    QByteArray data = file.readAll();
    m_palette.resize(256);
    for (int i = 0; i < 256 && i * 3 + 2 < data.size(); ++i) {
        int r = (uint8_t)data[i * 3] << 2;
        int g = (uint8_t)data[i * 3 + 1] << 2;
        int b = (uint8_t)data[i * 3 + 2] << 2;
        m_palette[i] = qRgb(qMin(r, 255), qMin(g, 255), qMin(b, 255));
    }
}

void PNGImport::onOpenCol()
{
    QString f = QFileDialog::getOpenFileName(this, tr("选择COL"), {}, "COL (*.col)");
    if (!f.isEmpty()) { m_colEdit->setText(f); loadPalette(f); }
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
    if (dlg.exec() == QDialog::Accepted) {
        m_entries[row].xOff = dlg.xOffset();
        m_entries[row].yOff = dlg.yOffset();
        m_entries[row].keepPNG = dlg.keepPNG();
        m_entries[row].transparent = dlg.useTransColor();
        if (dlg.useTransColor())
            m_entries[row].transColor = dlg.transColor().rgb();
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
    if (m_idxEdit->text().isEmpty() || m_grpEdit->text().isEmpty()) return;

    // 加载现有 GRP
    QVector<GrpPic> grpPics;
    GrpIO::readGrp(m_idxEdit->text(), m_grpEdit->text(), grpPics);

    m_progress->setVisible(true);
    m_progress->setRange(0, m_entries.size());

    for (int i = 0; i < m_entries.size(); ++i) {
        const auto &entry = m_entries[i];
        QImage img(entry.fileName);
        if (img.isNull()) continue;

        GrpPic pic;
        pic.width = img.width();
        pic.height = img.height();
        pic.xoff = entry.xOff;
        pic.yoff = entry.yOff;

        if (entry.keepPNG) {
            // 保持原始 PNG 格式
            QFile f(entry.fileName);
            if (f.open(QIODevice::ReadOnly)) pic.data = f.readAll();
        } else {
            // 转 RLE8
            img = img.convertToFormat(QImage::Format_ARGB32);
            uint8_t pr[256]{}, pg[256]{}, pb[256]{};
            for (int j = 0; j < 256 && j < m_palette.size(); ++j) {
                pr[j] = qRed(m_palette[j]); pg[j] = qGreen(m_palette[j]); pb[j] = qBlue(m_palette[j]);
            }
            pic = GrpIO::encodeRLE(img, pr, pg, pb);
            pic.xoff = entry.xOff;
            pic.yoff = entry.yOff;
        }
        grpPics.append(pic);
        m_progress->setValue(i + 1);
    }

    GrpIO::saveGrp(m_idxEdit->text(), m_grpEdit->text(), grpPics);
    m_progress->setVisible(false);
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
    layout->addWidget(m_previewLabel);

    auto *form = new QHBoxLayout;
    m_xEdit = new QLineEdit("0");
    m_yEdit = new QLineEdit("0");
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

    connect(buttons, &QDialogButtonBox::accepted, this, &QDialog::accept);
    connect(buttons, &QDialogButtonBox::rejected, this, &QDialog::reject);
    connect(m_colorBtn, &QPushButton::clicked, [this]() {
        QColor c = QColorDialog::getColor(m_transCol, this);
        if (c.isValid()) m_transCol = c;
    });

    drawOffset();
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

    int x = m_xEdit->text().toInt(), y = m_yEdit->text().toInt();
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
    QString dir = m_pathEdit->text();
    if (dir.isEmpty() || m_pics.isEmpty()) return;

    m_running = true;
    m_progress->setRange(0, m_pics.size());

    QFile ka(dir + "/index.ka");
    ka.open(QIODevice::WriteOnly);
    QDataStream ds(&ka);
    ds.setByteOrder(QDataStream::LittleEndian);

    for (int i = 0; i < m_pics.size() && m_running; ++i) {
        const auto &pic = m_pics[i];
        // 判断是否为 PNG
        bool isPNG = pic.data.size() > 4 && (uint8_t)pic.data[1] == 'P' && (uint8_t)pic.data[2] == 'N';

        if (isPNG) {
            QFile f(dir + "/" + QString::number(i) + ".png");
            if (f.open(QIODevice::WriteOnly)) f.write(pic.data);
        } else if (pic.width > 0 && pic.height > 0) {
            uint8_t pr[256]{}, pg[256]{}, pb[256]{};
            for (int j = 0; j < 256 && j < m_palette.size(); ++j) {
                pr[j] = qRed(m_palette[j]); pg[j] = qGreen(m_palette[j]); pb[j] = qBlue(m_palette[j]);
            }
            QImage img = GrpIO::decodeRLE(pic, pr, pg, pb);
            img.save(dir + "/" + QString::number(i) + ".png");
        }

        ds << (int16_t)pic.xoff << (int16_t)pic.yoff;
        m_progress->setValue(i + 1);
        m_statusLabel->setText(tr("正在导出 %1/%2").arg(i + 1).arg(m_pics.size()));
        QApplication::processEvents();
    }

    m_running = false;
    m_statusLabel->setText(tr("导出完成"));
}

void PNGExport::onStop() { m_running = false; }
