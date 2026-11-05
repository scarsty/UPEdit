#include "cyhead.h"
#include "grpdata.h"
#include "iniconfig.h"
#include "fileio.h"
#include <QBuffer>
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QFileDialog>
#include <QMessageBox>
#include <QPainter>
#include <QProgressDialog>
#include <QDataStream>
#include <QCloseEvent>
#include <QScopedValueRollback>

QByteArray CYHead::stateBytes() const
{
    QByteArray bytes;
    QDataStream stream(&bytes, QIODevice::WriteOnly);
    for (const auto &picture : m_heads)
        stream << picture.data << picture.xoff << picture.yoff;
    return bytes;
}

bool CYHead::saveHeads()
{
    const QString index = m_loadedIdx.isEmpty() ? m_idxEdit->text() : m_loadedIdx;
    const QString data = m_loadedGrp.isEmpty() ? m_grpEdit->text() : m_loadedGrp;
    if (!GrpIO::saveGrp(index, data, m_heads)) {
        QMessageBox::warning(this, tr("保存"), tr("保存失败，原文件未替换")); return false;
    }
    m_loadedIdx = index;
    m_loadedGrp = data;
    m_savedState = stateBytes();
    return true;
}

bool CYHead::confirmDiscard()
{
    if (stateBytes() == m_savedState) return true;
    auto answer = QMessageBox::question(this, tr("未保存修改"), tr("保存头像修改？"),
        QMessageBox::Save | QMessageBox::Discard | QMessageBox::Cancel, QMessageBox::Cancel);
    if (answer == QMessageBox::Save) return saveHeads();
    return answer == QMessageBox::Discard;
}

void CYHead::closeEvent(QCloseEvent *event)
{
    if (m_exporting) { event->ignore(); return; }
    if (confirmDiscard()) event->accept(); else event->ignore();
}

CYHead::CYHead(QWidget *parent) : QWidget(parent)
{
    auto *mainLayout = new QVBoxLayout(this);

    // 顶部文件选择
    auto *topBar = new QHBoxLayout;
    m_idxEdit = new QLineEdit;
    m_grpEdit = new QLineEdit;
    auto *btnIdx = new QPushButton(tr("IDX"));
    auto *btnGrp = new QPushButton(tr("GRP"));
    auto *btnLoad = new QPushButton(tr("打开"));
    auto *btnSave = new QPushButton(tr("保存"));

    topBar->addWidget(m_idxEdit, 1); topBar->addWidget(btnIdx);
    topBar->addWidget(m_grpEdit, 1); topBar->addWidget(btnGrp);
    topBar->addWidget(btnLoad); topBar->addWidget(btnSave);
    mainLayout->addLayout(topBar);

    // 左侧导航 + 右侧显示
    auto *centerLayout = new QHBoxLayout;
    auto *navPanel = new QVBoxLayout;
    m_indexLabel = new QLabel(tr("0/0"));
    auto *btnPrev = new QPushButton(tr("◀"));
    auto *btnNext = new QPushButton(tr("▶"));
    auto *btnPrev10 = new QPushButton(tr("◀◀ (-10)"));
    auto *btnNext10 = new QPushButton(tr("▶▶ (+10)"));
    auto *btnReplace = new QPushButton(tr("替换PNG"));
    auto *btnExport = new QPushButton(tr("导出全部PNG"));

    navPanel->addWidget(m_indexLabel);
    navPanel->addWidget(btnPrev);
    navPanel->addWidget(btnNext);
    navPanel->addWidget(btnPrev10);
    navPanel->addWidget(btnNext10);
    navPanel->addWidget(btnReplace);
    navPanel->addWidget(btnExport);
    navPanel->addStretch();

    m_imageLabel = new QLabel;
    m_imageLabel->setMinimumSize(200, 200);
    m_imageLabel->setAlignment(Qt::AlignCenter);

    centerLayout->addLayout(navPanel);
    centerLayout->addWidget(m_imageLabel, 1);
    mainLayout->addLayout(centerLayout, 1);

    connect(btnIdx, &QPushButton::clicked, this, &CYHead::onOpenIdx);
    connect(btnGrp, &QPushButton::clicked, this, &CYHead::onOpenGrp);
    connect(btnLoad, &QPushButton::clicked, this, &CYHead::onLoad);
    connect(btnSave, &QPushButton::clicked, this, &CYHead::onSave);
    connect(btnPrev, &QPushButton::clicked, this, &CYHead::onPrev);
    connect(btnNext, &QPushButton::clicked, this, &CYHead::onNext);
    connect(btnPrev10, &QPushButton::clicked, this, &CYHead::onPrev10);
    connect(btnNext10, &QPushButton::clicked, this, &CYHead::onNext10);
    connect(btnReplace, &QPushButton::clicked, this, &CYHead::onReplacePNG);
    connect(btnExport, &QPushButton::clicked, this, &CYHead::onExportAll);
}

void CYHead::onOpenIdx()
{
    QString f = QFileDialog::getOpenFileName(this, tr("选择IDX"), {}, "IDX (*.idx)");
    if (!f.isEmpty()) m_idxEdit->setText(f);
}

void CYHead::onOpenGrp()
{
    QString f = QFileDialog::getOpenFileName(this, tr("选择GRP"), {}, "GRP (*.grp)");
    if (!f.isEmpty()) m_grpEdit->setText(f);
}

void CYHead::onLoad()
{
    if (m_exporting) return;
    if (!confirmDiscard()) return;
    QVector<GrpPic> pictures;
    if (!GrpIO::readGrp(m_idxEdit->text(), m_grpEdit->text(), pictures)) {
        QMessageBox::warning(this, tr("打开"), tr("读取图片组失败")); return;
    }
    const auto &config = IniConfig::instance();
    QByteArray palette = FileIO::readFileAll(config.gamePath + "/" + config.palette);
    bool paletteReady = palette.size() >= 768;
    if (!paletteReady) {
        for (const auto &picture : pictures) if (!picture.data.isEmpty() && !GrpIO::isPNG(picture)) {
            QMessageBox::warning(this, tr("调色板"), tr("RLE 头像需要有效的游戏调色板（至少 768 字节）")); return;
        }
    } else for (int index = 0; index < 256; ++index) {
        m_red[index] = qMin(255, int(uint8_t(palette[index * 3])) * 4);
        m_green[index] = qMin(255, int(uint8_t(palette[index * 3 + 1])) * 4);
        m_blue[index] = qMin(255, int(uint8_t(palette[index * 3 + 2])) * 4);
    }
    m_paletteReady = paletteReady;
    m_heads = pictures;
    m_loadedIdx = m_idxEdit->text();
    m_loadedGrp = m_grpEdit->text();
    m_savedState = stateBytes();
    m_currentIndex = 0;
    drawPNG();
}

void CYHead::onSave()
{
    if (!saveHeads()) return;
    QMessageBox::information(this, tr("保存"), tr("保存成功"));
}

void CYHead::drawPNG()
{
    m_imageLabel->clear();
    m_indexLabel->setText(QString("%1/%2").arg(m_heads.isEmpty() ? 0 : m_currentIndex + 1).arg(m_heads.size()));
    if (m_currentIndex < 0 || m_currentIndex >= m_heads.size()) return;

    QImage img = imageFor(m_heads[m_currentIndex]);

    if (!img.isNull())
        m_imageLabel->setPixmap(QPixmap::fromImage(img));
}

QImage CYHead::imageFor(const GrpPic &picture) const
{
    if (GrpIO::isPNG(picture)) return GrpIO::decodePNG(picture);
    return m_paletteReady ? GrpIO::decodeRLE(picture, m_red, m_green, m_blue) : QImage();
}

void CYHead::onPrev() { if (m_currentIndex > 0) { m_currentIndex--; drawPNG(); } }
void CYHead::onNext() { if (m_currentIndex < m_heads.size() - 1) { m_currentIndex++; drawPNG(); } }
void CYHead::onPrev10() { m_currentIndex = qMax(0, m_currentIndex - 10); drawPNG(); }
void CYHead::onNext10() { m_currentIndex = qMin(m_heads.size() - 1, m_currentIndex + 10); drawPNG(); }

void CYHead::onReplacePNG()
{
    if (m_exporting) return;
    if (m_currentIndex < 0 || m_currentIndex >= m_heads.size()) return;
    QString f = QFileDialog::getOpenFileName(this, tr("选择PNG"), {}, "PNG (*.png)");
    if (f.isEmpty()) return;

    QFile file(f);
    if (!file.open(QIODevice::ReadOnly)) return;
    QByteArray bytes = file.readAll();
    QImage img = QImage::fromData(bytes, "PNG");
    if (file.error() != QFileDevice::NoError || img.isNull()) {
        QMessageBox::warning(this, tr("替换"), tr("无效的 PNG 图片")); return;
    }
    m_heads[m_currentIndex].data = bytes;
    m_heads[m_currentIndex].width = img.width();
    m_heads[m_currentIndex].height = img.height();
    m_heads[m_currentIndex].size = m_heads[m_currentIndex].data.size();
    m_heads[m_currentIndex].xoff = m_heads[m_currentIndex].yoff = 0;
    drawPNG();
}

void CYHead::onExportAll()
{
    if (m_exporting) return;
    QScopedValueRollback<bool> exporting(m_exporting, true);
    QString dir = QFileDialog::getExistingDirectory(this, tr("选择导出路径"));
    if (dir.isEmpty()) return;

    QProgressDialog progress(tr("正在导出..."), tr("取消"), 0, m_heads.size(), this);
    progress.setWindowModality(Qt::WindowModal);
    QMap<QString, QByteArray> files;

    for (int i = 0; i < m_heads.size(); ++i) {
        if (progress.wasCanceled()) return;
        const auto &pic = m_heads[i];
        if (pic.data.isEmpty()) { progress.setValue(i + 1); continue; }
        QString fname = dir + "/" + tr("头像%1.png").arg(i);

        QImage image = imageFor(pic);
        QByteArray bytes;
        QBuffer buffer(&bytes);
        if (image.isNull() || !image.save(&buffer, "PNG")) {
            QMessageBox::warning(this, tr("导出"), tr("导出头像 %1 失败").arg(i)); return;
        }
        files.insert(fname, bytes);
        progress.setValue(i + 1);
    }
    if (progress.wasCanceled()) return;
    if (!FileIO::writeFiles(files)) QMessageBox::warning(this, tr("导出"), tr("导出失败，原文件未替换"));
}
