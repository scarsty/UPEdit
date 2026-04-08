#include "mainmapedit.h"
#include "grpdata.h"
#include "mapdata.h"
#include "fileio.h"
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

    mainArea->removeWidget(m_scroll);
    mainArea->addWidget(mapPanel, 1);

    m_statusBar = new QStatusBar;
    mapLayout->addWidget(m_statusBar);

    connect(m_btnSave, &QPushButton::clicked, this, &MainMapEdit::onSaveMap);
    connect(btnExport, &QPushButton::clicked, this, &MainMapEdit::onExportImage);
    connect(m_hScroll, &QScrollBar::valueChanged, this, &MainMapEdit::onHScroll);
    connect(m_vScroll, &QScrollBar::valueChanged, this, &MainMapEdit::onVScroll);

    readMainMapFile();
    readMainMapGrp();
    if (m_mapData.num > 0 && !m_mapData.map.isEmpty()) {
        const Map &curMap = m_mapData.map[0];
        m_hScroll->setRange(0, qMax(0, curMap.x - m_viewW));
        m_vScroll->setRange(0, qMax(0, curMap.y - m_viewH));
        renderMap();
    }
}

void MainMapEdit::readMainMapFile()
{
    IniConfig &cfg = IniConfig::instance();

    // 固定 480×480, 5 层 (对应 Delphi 硬编码)
    const int W = 480, H = 480;
    m_mapData.num = 1;
    m_mapData.map.resize(1);
    Map &m = m_mapData.map[0];
    m.layerNum = 5;
    m.x = W;
    m.y = H;
    m.mapLayer.resize(5);

    // 5 层对应文件: earth, surface, building, buildx, buildy
    QString files[5] = { cfg.mEarth, cfg.mSurface, cfg.mBuilding, cfg.mBuildX, cfg.mBuildY };

    for (int l = 0; l < 5; ++l) {
        m.mapLayer[l].pic.resize(W);
        for (int x = 0; x < W; ++x)
            m.mapLayer[l].pic[x].resize(H, 0);

        QByteArray data = FileIO::readFileAll(cfg.gamePath + files[l]);
        if (data.isEmpty()) continue;

        const int16_t *p = reinterpret_cast<const int16_t *>(data.constData());
        int maxIdx = data.size() / 2;
        int idx = 0;

        // Delphi: for iy := 0 to 479 do fileread(grp, pic[iy][0], 480*2)
        // Delphi pic[y][x], Qt pic[x][y] — 按行读取后转置
        for (int y = 0; y < H && idx < maxIdx; ++y) {
            for (int x = 0; x < W && idx < maxIdx; ++x) {
                m.mapLayer[l].pic[x][y] = p[idx++];
            }
        }
    }
}

void MainMapEdit::readMainMapGrp()
{
    IniConfig &cfg = IniConfig::instance();
    // 主地图贴图使用 MMAPIDX/MMAPGRP (对应 Delphi MMapfileIDX/MMapfilegrp)
    GrpIO::readGrp(cfg.gamePath + cfg.mmapFileIdx,
                    cfg.gamePath + cfg.mmapFileGrp, m_grpPics);

    // 调色板使用全局 palette (对应 Delphi readMcol 读 palette)
    uint8_t pr[256], pg[256], pb[256];
    MapIO::readPalette(cfg.gamePath + cfg.palette, pr, pg, pb);

    m_tileCache.resize(m_grpPics.size());
    for (int i = 0; i < m_grpPics.size(); ++i) {
        if (m_grpPics[i].data.isEmpty()) continue;
        if (GrpIO::isPNG(m_grpPics[i])) {
            m_tileCache[i] = GrpIO::decodePNG(m_grpPics[i]);
        } else {
            m_tileCache[i] = GrpIO::decodeRLE(m_grpPics[i], pr, pg, pb);
        }
    }
}

void MainMapEdit::renderMap()
{
    if (m_mapData.num == 0 || m_mapData.map.isEmpty()) return;
    const Map &curMap = m_mapData.map[0];

    int tw = tileW(), th = tileH(), pad = tilePadding();
    int imgW = (m_viewW + m_viewH) * tw + pad * 2;
    int imgH = (m_viewW + m_viewH) * th + pad * 2;

    m_mapImage = QImage(imgW, imgH, QImage::Format_ARGB32);
    m_mapImage.fill(QColor(0, 50, 0));
    QPainter p(&m_mapImage);

    int layer = m_layerCombo->currentIndex();
    int startLayer = (layer == 4) ? 0 : layer;
    int endLayer = (layer == 4) ? qMin(curMap.layerNum, (int)curMap.mapLayer.size()) : layer + 1;

    for (int ly = startLayer; ly < endLayer; ++ly) {
        if (ly >= curMap.mapLayer.size()) break;
        const auto &layerData = curMap.mapLayer[ly];
        for (int vy = 0; vy < m_viewH; ++vy) {
            for (int vx = 0; vx < m_viewW; ++vx) {
                int ix = m_viewX + vx, iy = m_viewY + vy;
                if (ix >= curMap.x || iy >= curMap.y) continue;
                if (ix >= layerData.pic.size()) continue;
                if (iy >= layerData.pic[ix].size()) continue;

                int tileId = layerData.pic[ix][iy] / 2;  // Delphi: pic[iy][ix] div 2
                if (tileId < 0 || tileId >= m_tileCache.size()) continue;
                if (m_tileCache[tileId].isNull()) continue;

                int xoff = (tileId < m_grpPics.size()) ? m_grpPics[tileId].xoff : 0;
                int yoff = (tileId < m_grpPics.size()) ? m_grpPics[tileId].yoff : 0;

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
    ix += m_viewX;
    iy += m_viewY;

    int layer = m_layerCombo->currentIndex();
    if (layer >= 4) return;

    if (m_mapData.map.isEmpty()) return;
    Map &curMap = m_mapData.map[0];
    if (layer < 0 || layer >= curMap.mapLayer.size()) return;
    if (ix < 0 || ix >= curMap.x || iy < 0 || iy >= curMap.y) return;

    if (m_selectedTileId >= 0 && btn == Qt::LeftButton) {
        curMap.mapLayer[layer].pic[ix][iy] = m_selectedTileId;
        renderMap();
    }
}

void MainMapEdit::onHScroll(int value) { m_viewX = value; renderMap(); }
void MainMapEdit::onVScroll(int value) { m_viewY = value; renderMap(); }

void MainMapEdit::onSaveMap()
{
    IniConfig &cfg = IniConfig::instance();
    if (m_mapData.map.isEmpty()) return;
    const Map &m = m_mapData.map[0];

    // 逐层写回 5 个独立文件 (对应 Delphi 按行写入)
    QString files[5] = { cfg.mEarth, cfg.mSurface, cfg.mBuilding, cfg.mBuildX, cfg.mBuildY };
    for (int l = 0; l < 5 && l < m.mapLayer.size(); ++l) {
        QByteArray data(m.x * m.y * 2, '\0');
        int16_t *p = reinterpret_cast<int16_t *>(data.data());
        int idx = 0;
        for (int y = 0; y < m.y; ++y) {
            for (int x = 0; x < m.x; ++x) {
                if (x < m.mapLayer[l].pic.size() && y < m.mapLayer[l].pic[x].size())
                    p[idx++] = m.mapLayer[l].pic[x][y];
                else
                    p[idx++] = 0;
            }
        }
        FileIO::writeFileAll(cfg.gamePath + files[l], data);
    }
    QMessageBox::information(this, tr("保存"), tr("主地图保存成功"));
}

void MainMapEdit::onExportImage()
{
    if (m_mapImage.isNull()) return;
    QString f = QFileDialog::getSaveFileName(this, tr("导出地图图片"), {}, "PNG (*.png);;BMP (*.bmp)");
    if (!f.isEmpty()) m_mapImage.save(f);
}
