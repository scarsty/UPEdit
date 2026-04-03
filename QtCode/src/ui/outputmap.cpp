#include "outputmap.h"
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QPushButton>
#include <QLabel>
#include <QFontDialog>
#include <QColorDialog>
#include <QFileDialog>
#include <QMessageBox>

OutputMap::OutputMap(QWidget *parent) : QDialog(parent)
{
    setWindowTitle(tr("地图导出"));
    auto *layout = new QVBoxLayout(this);

    // 文字设置
    auto *textGroup = new QGroupBox(tr("文字设置"));
    auto *textLayout = new QHBoxLayout(textGroup);
    m_fontBtn = new QPushButton(tr("字体"));
    m_colorBtn = new QPushButton(tr("字色"));
    m_drawNamesCheck = new QCheckBox(tr("绘制场景名"));
    textLayout->addWidget(m_fontBtn);
    textLayout->addWidget(m_colorBtn);
    textLayout->addWidget(m_drawNamesCheck);
    layout->addWidget(textGroup);

    // 层选择
    m_groundCheck = new QCheckBox(tr("地面层")); m_groundCheck->setChecked(true);
    m_surfaceCheck = new QCheckBox(tr("表面层")); m_surfaceCheck->setChecked(true);
    m_buildingCheck = new QCheckBox(tr("建筑层")); m_buildingCheck->setChecked(true);
    auto *layerRow = new QHBoxLayout;
    layerRow->addWidget(m_groundCheck);
    layerRow->addWidget(m_surfaceCheck);
    layerRow->addWidget(m_buildingCheck);
    layout->addLayout(layerRow);

    // 文件/缩放
    auto *fileRow = new QHBoxLayout;
    m_fileEdit = new QLineEdit;
    m_zoomEdit = new QLineEdit("100");
    fileRow->addWidget(new QLabel(tr("文件名:")));
    fileRow->addWidget(m_fileEdit, 1);
    fileRow->addWidget(new QLabel(tr("缩放%:")));
    fileRow->addWidget(m_zoomEdit);
    layout->addLayout(fileRow);

    auto *btnExport = new QPushButton(tr("导出"));
    layout->addWidget(btnExport);

    m_logText = new QTextEdit;
    m_logText->setReadOnly(true);
    layout->addWidget(m_logText, 1);

    connect(m_fontBtn, &QPushButton::clicked, this, &OutputMap::onSelectFont);
    connect(m_colorBtn, &QPushButton::clicked, [this]() {
        QColor c = QColorDialog::getColor(m_mapColor, this);
        if (c.isValid()) m_mapColor = c;
    });
    connect(btnExport, &QPushButton::clicked, this, &OutputMap::onExport);
}

void OutputMap::onSelectFont()
{
    bool ok;
    QFont f = QFontDialog::getFont(&ok, m_mapFont, this);
    if (ok) m_mapFont = f;
}

void OutputMap::onExport()
{
    QString savePath = m_fileEdit->text();
    if (savePath.isEmpty()) {
        savePath = QFileDialog::getSaveFileName(this, tr("保存地图"), {}, "PNG (*.png);;BMP (*.bmp)");
        if (savePath.isEmpty()) return;
        m_fileEdit->setText(savePath);
    }

    m_logText->append(tr("开始导出地图..."));

    // TODO: 地图导出的实际渲染逻辑
    // 1. 创建大位图 (根据地图大小和TileScale)
    // 2. 加载调色板和精灵
    // 3. 逐层渲染(地面/表面/建筑, 按等距深度排序)
    // 4. 添加场景名文字
    // 5. 缩放
    // 6. 保存

    m_logText->append(tr("导出完成: %1").arg(savePath));
    QMessageBox::information(this, tr("导出"), tr("地图导出完成"));
}
