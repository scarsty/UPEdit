#include "mainmapedit.h"
#include "grpdata.h"
#include "mapdata.h"
#include "iniconfig.h"
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QPainter>
#include <QFileDialog>
#include <QMessageBox>

MainMapEdit::MainMapEdit(QWidget *parent) : IsoMapEditor(parent)
{
    m_layerCombo->clear();
    m_layerCombo->addItems({tr("地面"), tr("表面"), tr("建筑"), tr("引用建筑"), tr("全部")});

    auto *leftLayout = static_cast<QVBoxLayout*>(layout()->itemAt(0)->layout());
    auto *btnExport = new QPushButton(tr("导出图片"));
    leftLayout->addWidget(btnExport);

    // 添加滚动条
    auto *mainArea = static_cast<QHBoxLayout*>(layout());
    auto *mapPanel = new QWidget;
    auto *mapLayout = new QVBoxLayout(mapPanel);
    mapLayout->setContentsMargins(0, 0, 0, 0);

    m_hScroll = new QScrollBar(Qt::Horizontal);
    m_vScroll = new QScrollBar(Qt::Vertical);

    auto *innerLayout = new QHBoxLayout;
    innerLayout->addWidget(m_scroll, 1);
    innerLayout->addWidget(m_vScroll);
    mapLayout->addLayout(innerLayout, 1);
    mapLayout->addWidget(m_hScroll);

    // 替换原来的scroll
    mainArea->removeWidget(m_scroll);
    mainArea->addWidget(mapPanel, 1);

    m_statusBar = new QStatusBar;
    mapLayout->addWidget(m_statusBar);

    connect(m_btnSave, &QPushButton::clicked, this, &MainMapEdit::onSaveMap);
    connect(btnExport, &QPushButton::clicked, this, &MainMapEdit::onExportImage);
    connect(m_hScroll, &QScrollBar::valueChanged, this, &MainMapEdit::onHScroll);
    connect(m_vScroll, &QScrollBar::valueChanged, this, &MainMapEdit::onVScroll);

    // 初始化
    readMainMapFile();
    readMainMapGrp();
    if (m_mapData.mapCount > 0) {
        m_hScroll->setRange(0, qMax(0, m_mapData.xSize - m_viewW));
        m_vScroll->setRange(0, qMax(0, m_mapData.ySize - m_viewH));
        renderMap();
    }
}

void MainMapEdit::readMainMapFile()
{
    IniConfig &cfg = IniConfig::instance();
    m_mapData = MapData::loadMap(cfg.gamePath + "/" + cfg.mainMapIdxFile,
                                 cfg.gamePath + "/" + cfg.mainMapGrpFile);
}

void MainMapEdit::readMainMapGrp()
{
    IniConfig &cfg = IniConfig::instance();
    m_grpPics = GrpData::loadGrpIdx(cfg.mainMapTileIdxFile, cfg.mainMapTileGrpFile);
    MapData::loadPalette(cfg.mainMapPalettePath, m_palette);

    m_tileCache.resize(m_grpPics.size());
    for (int i = 0; i < m_grpPics.size(); ++i) {
        const auto &pic = m_grpPics[i];
        if (pic.data.isEmpty() || pic.width <= 0 || pic.height <= 0) continue;
        m_tileCache[i] = QImage(pic.width, pic.height, QImage::Format_ARGB32);
        m_tileCache[i].fill(Qt::transparent);
        GrpData::decodeRLE8(pic.data, pic.width, pic.height, m_palette, m_tileCache[i]);
    }
}

void MainMapEdit::renderMap()
{
    if (m_mapData.mapCount == 0) return;

    int tw = tileW(), th = tileH(), pad = tilePadding();
    int imgW = (m_viewW + m_viewH) * tw + pad * 2;
    int imgH = (m_viewW + m_viewH) * th + pad * 2;

    m_mapImage = QImage(imgW, imgH, QImage::Format_ARGB32);
    m_mapImage.fill(QColor(0, 50, 0));
    QPainter p(&m_mapImage);

    int layer = m_layerCombo->currentIndex();
    int startLayer = (layer == 4) ? 0 : layer;
    int endLayer = (layer == 4) ? qMin(m_mapData.layerNum, (int)m_mapData.layers.size()) : layer + 1;

    for (int ly = startLayer; ly < endLayer; ++ly) {
        if (ly >= m_mapData.layers.size()) break;
        const auto &layerData = m_mapData.layers[ly];
        for (int vy = 0; vy < m_viewH; ++vy) {
            for (int vx = 0; vx < m_viewW; ++vx) {
                int ix = m_viewX + vx, iy = m_viewY + vy;
                if (ix >= m_mapData.xSize || iy >= m_mapData.ySize) continue;

                int tileId = layerData.tiles[iy * m_mapData.xSize + ix];
                if (tileId < 0 || tileId >= m_tileCache.size()) continue;
                if (m_tileCache[tileId].isNull()) continue;

                int xoff = (tileId < m_grpPics.size()) ? m_grpPics[tileId].xoff : 0;
                int yoff = (tileId < m_grpPics.size()) ? m_grpPics[tileId].yoff : 0;

                // 使用相对视口坐标计算屏幕位置
                int sx = (vx - vy) * tw / 2 + pad;
                int sy = (vx + vy) * th / 2 + pad;
                p.drawImage(sx - xoff, sy - yoff, m_tileCache[tileId]);
            }
        }
    }

    if (m_selIsoX >= m_viewX && m_selIsoY >= m_viewY) {
        int vx = m_selIsoX - m_viewX, vy = m_selIsoY - m_viewY;
        int sx = (vx - vy) * tw / 2 + pad;
        int sy = (vx + vy) * th / 2 + pad;
        QPolygon diamond;
        diamond << QPoint(sx, sy - th) << QPoint(sx + tw, sy)
                << QPoint(sx, sy + th) << QPoint(sx - tw, sy);
        p.setPen(QPen(Qt::red, 2));
        p.drawPolygon(diamond);
    }

    m_mapLabel->setPixmap(QPixmap::fromImage(m_mapImage));
    m_mapLabel->resize(m_mapImage.size());
}

void MainMapEdit::onTileClicked(int ix, int iy, Qt::MouseButton btn)
{
    // 将屏幕坐标转为世界坐标
    ix += m_viewX;
    iy += m_viewY;

    int layer = m_layerCombo->currentIndex();
    if (layer >= 4) return; // "全部"层不编辑

    if (layer >= m_mapData.layers.size()) return;
    if (ix < 0 || ix >= m_mapData.xSize || iy < 0 || iy >= m_mapData.ySize) return;

    if (m_selectedTileId >= 0 && btn == Qt::LeftButton) {
        m_mapData.layers[layer].tiles[iy * m_mapData.xSize + ix] = m_selectedTileId;
        renderMap();
    }
}

void MainMapEdit::onHScroll(int value) { m_viewX = value; renderMap(); }
void MainMapEdit::onVScroll(int value) { m_viewY = value; renderMap(); }

void MainMapEdit::onSaveMap()
{
    IniConfig &cfg = IniConfig::instance();
    MapData::saveMap(cfg.gamePath + "/" + cfg.mainMapIdxFile,
                     cfg.gamePath + "/" + cfg.mainMapGrpFile, m_mapData);
    QMessageBox::information(this, tr("保存"), tr("主地图保存成功"));
}

void MainMapEdit::onExportImage()
{
    if (m_mapImage.isNull()) return;
    QString f = QFileDialog::getSaveFileName(this, tr("导出地图图片"), {}, "PNG (*.png);;BMP (*.bmp)");
    if (!f.isEmpty()) m_mapImage.save(f);
}
