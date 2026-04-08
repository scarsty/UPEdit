#include "cyhead.h"
#include "grpdata.h"
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QFileDialog>
#include <QMessageBox>
#include <QPainter>
#include <QProgressDialog>

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
    GrpIO::readGrp(m_idxEdit->text(), m_grpEdit->text(), m_heads);
    m_currentIndex = 0;
    drawPNG();
}

void CYHead::onSave()
{
    GrpIO::saveGrp(m_idxEdit->text(), m_grpEdit->text(), m_heads);
    QMessageBox::information(this, tr("保存"), tr("保存成功"));
}

void CYHead::drawPNG()
{
    m_indexLabel->setText(QString("%1/%2").arg(m_currentIndex + 1).arg(m_heads.size()));
    if (m_currentIndex < 0 || m_currentIndex >= m_heads.size()) return;

    const auto &pic = m_heads[m_currentIndex];
    QImage img;
    // 判断 PNG
    if (pic.data.size() > 4 && (uint8_t)pic.data[1] == 'P') {
        img.loadFromData(pic.data);
    } else {
        // RLE8 解码（无palette→黑白）
        if (pic.width > 0 && pic.height > 0) {
            uint8_t gr[256], gg[256], gb[256];
            for (int i = 0; i < 256; ++i) { gr[i] = gg[i] = gb[i] = (uint8_t)i; }
            img = GrpIO::decodeRLE(pic, gr, gg, gb);
        }
    }

    if (!img.isNull())
        m_imageLabel->setPixmap(QPixmap::fromImage(img));
}

void CYHead::onPrev() { if (m_currentIndex > 0) { m_currentIndex--; drawPNG(); } }
void CYHead::onNext() { if (m_currentIndex < m_heads.size() - 1) { m_currentIndex++; drawPNG(); } }
void CYHead::onPrev10() { m_currentIndex = qMax(0, m_currentIndex - 10); drawPNG(); }
void CYHead::onNext10() { m_currentIndex = qMin(m_heads.size() - 1, m_currentIndex + 10); drawPNG(); }

void CYHead::onReplacePNG()
{
    if (m_currentIndex < 0 || m_currentIndex >= m_heads.size()) return;
    QString f = QFileDialog::getOpenFileName(this, tr("选择PNG"), {}, "PNG (*.png)");
    if (f.isEmpty()) return;

    QFile file(f);
    if (!file.open(QIODevice::ReadOnly)) return;
    QImage img(f);
    m_heads[m_currentIndex].data = file.readAll();
    m_heads[m_currentIndex].width = img.width();
    m_heads[m_currentIndex].height = img.height();
    drawPNG();
}

void CYHead::onExportAll()
{
    QString dir = QFileDialog::getExistingDirectory(this, tr("选择导出路径"));
    if (dir.isEmpty()) return;

    QProgressDialog progress(tr("正在导出..."), tr("取消"), 0, m_heads.size(), this);
    progress.setWindowModality(Qt::WindowModal);

    for (int i = 0; i < m_heads.size(); ++i) {
        if (progress.wasCanceled()) break;
        const auto &pic = m_heads[i];
        QString fname = dir + "/" + tr("头像%1.png").arg(i);

        if (pic.data.size() > 4 && (uint8_t)pic.data[1] == 'P') {
            QFile f(fname);
            if (f.open(QIODevice::WriteOnly)) f.write(pic.data);
        } else if (pic.width > 0 && pic.height > 0) {
            uint8_t gr[256], gg[256], gb[256];
            for (int j = 0; j < 256; ++j) { gr[j] = gg[j] = gb[j] = (uint8_t)j; }
            QImage img = GrpIO::decodeRLE(pic, gr, gg, gb);
            img.save(fname);
        }
        progress.setValue(i + 1);
    }
}
