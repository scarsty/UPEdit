#include "outputmap.h"
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QPushButton>
#include <QLabel>
#include <QFontDialog>
#include <QColorDialog>
#include <QFileDialog>
#include <QMessageBox>
#include <QImage>
#include <QFileInfo>
#include <QPainter>
#include "mapdata.h"
#include "iniconfig.h"
#include "encoding.h"

void OutputMap::setMapData(const Map &map, const QVector<QImage> &tiles, const QVector<GrpPic> &pictures, int scale)
{
    m_map = map;
    m_tiles = tiles;
    m_pictures = pictures;
    m_scale = scale;
}

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

    bool ok = false;
    int zoom = m_zoomEdit->text().toInt(&ok);
    if (!ok || zoom <= 0) {
        QMessageBox::warning(this, tr("导出"), tr("缩放必须是正整数"));
        return;
    }

    QImage image = MapIO::renderMainMap(m_map, m_tiles, m_pictures, m_groundCheck->isChecked(),
        m_surfaceCheck->isChecked(), m_buildingCheck->isChecked(), m_scale, zoom);
    if (image.isNull()) {
        QString reason = m_map.mapLayer.isEmpty() ? tr("没有地图数据，请从地图编辑器打开导出窗口")
            : tr("地图尺寸或缩放超限，或内存不足，请降低缩放比例");
        m_logText->append(tr("导出失败: %1").arg(reason));
        QMessageBox::warning(this, tr("导出"), reason);
        return;
    }

    if (m_drawNamesCheck->isChecked()) {
        QPainter painter(&image);
        painter.setFont(m_mapFont);
        painter.setPen(m_mapColor.isValid() ? m_mapColor : QColor(Qt::white));
        const auto &types = IniConfig::instance().rGlobals.rFile.rType;
        if (types.size() > 3) {
            const auto &type = types[3];
            for (const auto &record : type.rData) {
                auto field = [&](int index) -> const RDataSingle * {
                    if (index < 0 || index >= record.rDataLine.size()) return nullptr;
                    const auto &line = record.rDataLine[index];
                    if (line.rArray.isEmpty() || line.rArray[0].dataArray.isEmpty()) return nullptr;
                    return &line.rArray[0].dataArray[0];
                };
                const auto *name = field(type.namePos), *x = field(6), *y = field(7);
                if (!name || !x || !y) continue;
                int column = int(RFileIO::readRDataInt(*x)), row = int(RFileIO::readRDataInt(*y));
                if (column <= 0 || row <= 0) continue;
                double factor = zoom / 100.0;
                int originX = ((m_map.x + m_map.y) * 18 + 80) * m_scale / 2 + 18 * m_scale;
                painter.drawText(QPointF((originX + (column - row) * 18 * m_scale) * factor,
                    (30 * m_scale + (column + row) * 9 * m_scale) * factor), Encoding::displayStr(RFileIO::readRDataStr(*name)));
            }
        }
    }
    if (savePath.endsWith(".bmp", Qt::CaseInsensitive)) {
        QImage opaque(image.size(), QImage::Format_RGB32);
        opaque.fill(Qt::black);
        QPainter painter(&opaque);
        painter.drawImage(0, 0, image);
        painter.end();
        image = opaque;
    }
    if (!image.save(savePath)) {
        m_logText->append(tr("导出失败: %1").arg(savePath));
        QMessageBox::warning(this, tr("导出"), tr("无法写入文件"));
        return;
    }
    m_logText->append(tr("导出完成: %1").arg(QFileInfo(savePath).absoluteFilePath()));
    accept();
}
