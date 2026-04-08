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
#include <QResizeEvent>
#include <QMouseEvent>
#include <algorithm>

MainMapEdit::MainMapEdit(QWidget *parent) : IsoMapEditor(parent)
{
    // ── 左侧面板 ─────────────────────────────────────────
    m_layerCombo->clear();
    m_layerCombo->addItems({tr("未选择"), tr("地面"), tr("表面"), tr("建筑"), tr("引用建筑"), tr("全部")});

    auto *leftLayout = static_cast<QVBoxLayout*>(layout()->itemAt(0)->layout());

    auto *btnExport  = new QPushButton(tr("导出地图"));
    auto *btnImport  = new QPushButton(tr("导入图块"));
    auto *btnExBlock = new QPushButton(tr("导出图块"));
    btnExport->setMaximumWidth(200);
    btnImport->setMaximumWidth(200);
    btnExBlock->setMaximumWidth(200);
    leftLayout->addWidget(btnExport);
    leftLayout->addWidget(btnImport);
    leftLayout->addWidget(btnExBlock);

    m_chkMore = new QCheckBox(tr("更多设置"));
    leftLayout->addWidget(m_chkMore);

    // 当前贴图预览 GroupBox (对应 Delphi GroupBox1)
    auto *tileGroup = new QGroupBox(tr("当前贴图"));
    auto *tileLayout = new QVBoxLayout(tileGroup);

    auto addTileRow = [&](const QString &label, QLabel *&valLabel, QLabel *&imgLabel) {
        auto *h = new QHBoxLayout;
        auto *lbl = new QLabel(label);
        valLabel = new QLabel;
        h->addWidget(lbl);
        h->addWidget(valLabel);
        tileLayout->addLayout(h);
        imgLabel = new QLabel;
        imgLabel->setFixedSize(85, 50);
        imgLabel->setFrameStyle(QFrame::Panel | QFrame::Sunken);
        imgLabel->setAlignment(Qt::AlignCenter);
        tileLayout->addWidget(imgLabel);
    };

    addTileRow(tr("当前地面"), m_lblEarthVal, m_imgEarth);
    addTileRow(tr("当前表面"), m_lblSurfVal, m_imgSurf);
    addTileRow(tr("当前建筑"), m_lblBuildVal, m_imgBuild);
    addTileRow(tr("引用建筑"), m_lblRefBuildVal, m_imgRefBuild);
    tileGroup->setFixedWidth(200);
    leftLayout->addWidget(tileGroup);

    m_morePanel = new QWidget;
    m_morePanel->setVisible(false);
    leftLayout->addWidget(m_morePanel);
    leftLayout->addStretch();

    // ── 右侧地图区 ───────────────────────────────────────
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

    // 禁用 QScrollArea 内部滚动条，地图滚动由外部 m_hScroll/m_vScroll 控制
    m_scroll->setHorizontalScrollBarPolicy(Qt::ScrollBarAlwaysOff);
    m_scroll->setVerticalScrollBarPolicy(Qt::ScrollBarAlwaysOff);

    m_statusBar = new QStatusBar;
    mapLayout->addWidget(m_statusBar);

    mainArea->removeWidget(m_scroll);
    mainArea->addWidget(mapPanel, 1);

    // ── 定时器 (对应 Delphi Timer1, 25ms) ────────────────
    m_timer = new QTimer(this);
    m_timer->setInterval(25);

    // ── 信号连接 ──────────────────────────────────────────
    connect(m_btnSave, &QPushButton::clicked, this, &MainMapEdit::onSaveMap);
    connect(btnExport, &QPushButton::clicked, this, &MainMapEdit::onExportImage);
    connect(btnImport, &QPushButton::clicked, this, &MainMapEdit::onImportBlock);
    connect(btnExBlock, &QPushButton::clicked, this, &MainMapEdit::onExportBlock);
    connect(m_hScroll, &QScrollBar::valueChanged, this, &MainMapEdit::onHScroll);
    connect(m_vScroll, &QScrollBar::valueChanged, this, &MainMapEdit::onVScroll);
    connect(m_timer, &QTimer::timeout, this, &MainMapEdit::onTimerTick);
    connect(m_chkMore, &QCheckBox::toggled, this, &MainMapEdit::onMoreSettings);
    connect(m_layerCombo, QOverload<int>::of(&QComboBox::currentIndexChanged), [this](int idx){
        m_layer = idx - 1;
        m_needUpdate = true;
    });

    // ── 加载数据 ──────────────────────────────────────────
    readMainMapFile();
    readMainMapGrp();
    if (m_mapData.num > 0 && !m_mapData.map.isEmpty()) {
        const Map &curMap = m_mapData.map[0];
        int maxDim = qMax(curMap.x, curMap.y);
        m_hScroll->setRange(0, maxDim - 1);
        m_vScroll->setRange(0, maxDim - 1);
        m_hScroll->setValue(maxDim / 2);
        m_vScroll->setValue(maxDim / 2);
        m_timer->start();
        m_needUpdate = true;
        renderMap();
    }
}

void MainMapEdit::resizeEvent(QResizeEvent *e)
{
    IsoMapEditor::resizeEvent(e);
    m_needUpdate = true;
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
        // pic[y][x] — 与 Delphi pic[iy][ix] 一致
        m.mapLayer[l].pic.resize(H);
        for (int y = 0; y < H; ++y)
            m.mapLayer[l].pic[y].resize(W, 0);

        QByteArray data = FileIO::readFileAll(cfg.gamePath + files[l]);
        if (data.isEmpty()) continue;

        const int16_t *p = reinterpret_cast<const int16_t *>(data.constData());
        int maxIdx = data.size() / 2;
        int idx = 0;

        // Delphi: for iy := 0 to 479 do fileread(grp, pic[iy][0], 480*2)
        for (int y = 0; y < H && idx < maxIdx; ++y) {
            for (int x = 0; x < W && idx < maxIdx; ++x) {
                m.mapLayer[l].pic[y][x] = p[idx++];
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

    int tw = tileW(), th = tileH();

    // 使用 m_scroll 的可视区域大小 (对应 Delphi ScrollBox1.ClientWidth/Height)
    int viewW = m_scroll->viewport()->width();
    int viewH = m_scroll->viewport()->height();
    if (viewW < 100) viewW = 800;
    if (viewH < 100) viewH = 600;

    // 中心坐标算法 (对应 Delphi):
    // MX = ScrollBar1.Position + ScrollBar2.Position - Y div 2
    // MY = ScrollBar2.Position - ScrollBar1.Position + Y div 2
    int hPos = m_hScroll->value();
    int vPos = m_vScroll->value();
    int CX = hPos + vPos - curMap.y / 2;
    int CY = vPos - hPos + curMap.y / 2;

    int imgW = viewW + tw * 2;
    int imgH = viewH + th * 2;
    m_mapImage = QImage(imgW, imgH, QImage::Format_ARGB32);
    m_mapImage.fill(Qt::black);
    QPainter p(&m_mapImage);

    int layer = m_layer;   // -1=未选择, 0=地面, 1=表面, 2=建筑, 3=引用建筑, 4=全部
    // 引用建筑 (layers 3-4) 是编辑元数据, 不参与渲染
    int startLayer, endLayer;
    if (layer < 0 || layer >= 3) { startLayer = 0; endLayer = 3; }
    else { startLayer = layer; endLayer = layer + 1; }

    // 计算可见范围: 屏幕坐标 sx = viewW/2 + (ix-CX-(iy-CY))*tw
    //                         sy = viewH/2 + (ix-CX+(iy-CY))*th
    // 令 rx=ix-CX, ry=iy-CY => d=rx+ry 为对角线编号
    // sy = viewH/2 + d*th  => d 范围: [-viewH/(2*th)-2, viewH/(2*th)+2]
    // sx = viewW/2 + (rx-ry)*tw => rx-ry 范围: [-viewW/(2*tw)-2, viewW/(2*tw)+2]
    int dMin = -(viewH / (2 * th)) - 2;
    int dMax =  (viewH / (2 * th)) + 2;
    int tRng = viewW / (2 * tw) + 2;  // (rx-ry) 的半径

    // 用于建筑层排序的辅助 lambda
    auto tileScreen = [&](int ix, int iy) -> QPoint {
        return {viewW / 2 + (ix - CX - (iy - CY)) * tw,
                viewH / 2 + (ix - CX + (iy - CY)) * th};
    };

    // === 地面 + 表面 层 : 按对角线 d=ix+iy 递增遍历 ===
    for (int ly = startLayer; ly < endLayer && ly < 2; ++ly) {
        if (ly >= (int)curMap.mapLayer.size()) break;
        const auto &layerData = curMap.mapLayer[ly];
        for (int d = dMin; d <= dMax; ++d) {
            for (int t = -tRng; t <= tRng; ++t) {
                // rx = (d+t)/2, ry = (d-t)/2 — 仅 d+t 同奇偶时有效
                if (((d + t) & 1) != 0) continue;
                int rx = (d + t) / 2, ry = (d - t) / 2;
                int ix = CX + rx, iy = CY + ry;
                if (ix < 0 || ix >= curMap.x || iy < 0 || iy >= curMap.y) continue;
                if (iy >= layerData.pic.size() || ix >= layerData.pic[iy].size()) continue;

                int tileId = layerData.pic[iy][ix] / 2;
                if (tileId <= 0 || tileId >= m_tileCache.size()) continue;
                if (m_tileCache[tileId].isNull()) continue;

                int xoff = (tileId < m_grpPics.size()) ? m_grpPics[tileId].xoff : 0;
                int yoff = (tileId < m_grpPics.size()) ? m_grpPics[tileId].yoff : 0;

                QPoint sp = tileScreen(ix, iy);
                p.drawImage(sp.x() - xoff, sp.y() - yoff, m_tileCache[tileId]);
            }
        }
    }

    // === 建筑层 (收集后按深度排序) ===
    if (startLayer <= 2 && endLayer > 2 && 2 < (int)curMap.mapLayer.size()) {
        struct BuildItem { int ix, iy, tileId, center; };
        QVector<BuildItem> items;

        const auto &bldLayer = curMap.mapLayer[2];
        for (int d = dMin; d <= dMax; ++d) {
            for (int t = -tRng; t <= tRng; ++t) {
                if (((d + t) & 1) != 0) continue;
                int rx = (d + t) / 2, ry = (d - t) / 2;
                int ix = CX + rx, iy = CY + ry;
                if (ix < 0 || ix >= curMap.x || iy < 0 || iy >= curMap.y) continue;
                if (iy >= bldLayer.pic.size() || ix >= bldLayer.pic[iy].size()) continue;

                int tileId = bldLayer.pic[iy][ix] / 2;
                if (tileId <= 0 || tileId >= m_tileCache.size()) continue;
                if (m_tileCache[tileId].isNull()) continue;

                QPoint sp = tileScreen(ix, iy);
                int center = sp.y() + m_tileCache[tileId].height();
                items.append({ix, iy, tileId, center});
            }
        }

        // 冒泡排序 (匹配 Delphi)
        for (int i = 0; i < items.size() - 1; ++i) {
            for (int j = i + 1; j < items.size(); ++j) {
                if (items[j].center < items[i].center)
                    std::swap(items[i], items[j]);
            }
        }

        for (auto &b : items) {
            int xoff = (b.tileId < m_grpPics.size()) ? m_grpPics[b.tileId].xoff : 0;
            int yoff = (b.tileId < m_grpPics.size()) ? m_grpPics[b.tileId].yoff : 0;
            QPoint sp = tileScreen(b.ix, b.iy);
            p.drawImage(sp.x() - xoff, sp.y() - yoff, m_tileCache[b.tileId]);
        }
    }

    // === 光标高亮 ===
    if (m_hoverIX >= 0 && m_hoverIY >= 0) {
        QPoint sp = tileScreen(m_hoverIX, m_hoverIY);
        QPolygon diamond;
        diamond << QPoint(sp.x(), sp.y() - th) << QPoint(sp.x() + tw, sp.y())
                << QPoint(sp.x(), sp.y() + th) << QPoint(sp.x() - tw, sp.y());
        p.setPen(QPen(Qt::red, 2));
        p.drawPolygon(diamond);
    }

    m_mapLabel->setPixmap(QPixmap::fromImage(m_mapImage));
    m_mapLabel->resize(m_mapImage.size());
}

void MainMapEdit::onTileClicked(int /*ix*/, int /*iy*/, Qt::MouseButton btn)
{
    // 使用 hover 坐标 (通过 timer 实时追踪)
    int ix = m_hoverIX;
    int iy = m_hoverIY;
    if (ix < 0 || iy < 0) return;

    if (m_mapData.map.isEmpty()) return;
    Map &curMap = m_mapData.map[0];
    if (ix >= curMap.x || iy >= curMap.y) return;

    int layer = m_layer;
    if (layer < 0 || layer > 3) return;

    if (layer >= (int)curMap.mapLayer.size()) return;

    if (btn == Qt::RightButton && m_selectedTileId >= 0) {
        // 右键放置选定贴图
        curMap.mapLayer[layer].pic[iy][ix] = m_selectedTileId * 2;
        m_needUpdate = true;
    } else if (btn == Qt::LeftButton) {
        // 左键拾取当前贴图
        m_selectedTileId = curMap.mapLayer[layer].pic[iy][ix] / 2;
        updateTilePreview();
    }
}

void MainMapEdit::onHScroll(int) { m_needUpdate = true; }
void MainMapEdit::onVScroll(int) { m_needUpdate = true; }

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
                if (y < m.mapLayer[l].pic.size() && x < m.mapLayer[l].pic[y].size())
                    p[idx++] = m.mapLayer[l].pic[y][x];
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

void MainMapEdit::onImportBlock()
{
    // TODO: 导入图块
    QMessageBox::information(this, tr("提示"), tr("导入图块功能尚未实现"));
}

void MainMapEdit::onExportBlock()
{
    // TODO: 导出图块
    QMessageBox::information(this, tr("提示"), tr("导出图块功能尚未实现"));
}

void MainMapEdit::onMoreSettings(bool checked)
{
    m_morePanel->setVisible(checked);
}

QPoint MainMapEdit::mapToScreen(int ix, int iy) const
{
    if (m_mapData.map.isEmpty()) return {};
    const Map &curMap = m_mapData.map[0];
    int tw = tileW(), th = tileH();
    int viewW = m_scroll->viewport()->width();
    int viewH = m_scroll->viewport()->height();
    int hPos = m_hScroll->value();
    int vPos = m_vScroll->value();
    int CX = hPos + vPos - curMap.y / 2;
    int CY = vPos - hPos + curMap.y / 2;
    int sx = viewW / 2 + (ix - CX - (iy - CY)) * tw;
    int sy = viewH / 2 + (ix - CX + (iy - CY)) * th;
    return {sx, sy};
}

QPoint MainMapEdit::screenToMapRel(int sx, int sy) const
{
    if (m_mapData.map.isEmpty()) return {-1, -1};
    const Map &curMap = m_mapData.map[0];
    int tw = tileW(), th = tileH();
    int viewW = m_scroll->viewport()->width();
    int viewH = m_scroll->viewport()->height();
    int hPos = m_hScroll->value();
    int vPos = m_vScroll->value();
    int CX = hPos + vPos - curMap.y / 2;
    int CY = vPos - hPos + curMap.y / 2;

    // 反算: sx = vw/2 + (rx-ry)*tw, sy = vh/2 + (rx+ry)*th
    // dx/tw = rx-ry, dy/th = rx+ry
    double dx = sx - viewW / 2.0;
    double dy = sy - viewH / 2.0;
    double fi = (dx / tw + dy / th) / 2.0 + CX;
    double fj = (dy / th - dx / tw) / 2.0 + CY;
    int ix = (int)qRound(fi);
    int iy = (int)qRound(fj);
    if (ix < 0 || ix >= curMap.x || iy < 0 || iy >= curMap.y)
        return {-1, -1};
    return {ix, iy};
}

void MainMapEdit::onTimerTick()
{
    // 获取鼠标在 m_mapLabel 上的位置
    QPoint pos = m_mapLabel->mapFromGlobal(QCursor::pos());
    QPoint mp = screenToMapRel(pos.x(), pos.y());

    if (mp.x() != m_hoverIX || mp.y() != m_hoverIY) {
        m_hoverIX = mp.x();
        m_hoverIY = mp.y();
        m_needUpdate = true;

        // 更新贴图预览
        updateTilePreview();
    }

    if (m_hoverIX >= 0 && m_hoverIY >= 0)
        m_statusBar->showMessage(tr("坐标: (%1, %2)").arg(m_hoverIX).arg(m_hoverIY));

    if (m_needUpdate) {
        m_needUpdate = false;
        renderMap();
    }
}

void MainMapEdit::updateTilePreview()
{
    if (m_mapData.map.isEmpty()) return;
    const Map &curMap = m_mapData.map[0];
    int ix = m_hoverIX, iy = m_hoverIY;
    if (ix < 0 || iy < 0 || ix >= curMap.x || iy >= curMap.y) return;

    auto showTile = [&](int layerIdx, QLabel *valLbl, QLabel *imgLbl) {
        if (layerIdx >= (int)curMap.mapLayer.size()) return;
        const auto &layer = curMap.mapLayer[layerIdx];
        if (iy >= layer.pic.size() || ix >= layer.pic[iy].size()) return;
        int tileId = layer.pic[iy][ix] / 2;
        if (tileId == 0) {
            valLbl->clear();
            imgLbl->clear();
            return;
        }
        valLbl->setText(QString::number(tileId));
        if (tileId >= 0 && tileId < m_tileCache.size() && !m_tileCache[tileId].isNull()) {
            imgLbl->setPixmap(QPixmap::fromImage(m_tileCache[tileId]).scaled(
                imgLbl->size(), Qt::KeepAspectRatio, Qt::SmoothTransformation));
        } else {
            imgLbl->clear();
        }
    };

    showTile(0, m_lblEarthVal, m_imgEarth);
    showTile(1, m_lblSurfVal, m_imgSurf);
    showTile(2, m_lblBuildVal, m_imgBuild);

    // 引用建筑: 使用 buildx/buildy 层的值作为偏移
    if (3 < (int)curMap.mapLayer.size() && 4 < (int)curMap.mapLayer.size()) {
        const auto &bxLayer = curMap.mapLayer[3];
        const auto &byLayer = curMap.mapLayer[4];
        if (iy < bxLayer.pic.size() && ix < bxLayer.pic[iy].size() &&
            iy < byLayer.pic.size() && ix < byLayer.pic[iy].size()) {
            int bx = bxLayer.pic[iy][ix];
            int by = byLayer.pic[iy][ix];
            int refIx = ix + bx, refIy = iy + by;
            if (refIx >= 0 && refIx < curMap.x && refIy >= 0 && refIy < curMap.y &&
                2 < (int)curMap.mapLayer.size()) {
                const auto &bldLayer = curMap.mapLayer[2];
                if (refIy < bldLayer.pic.size() && refIx < bldLayer.pic[refIy].size()) {
                    int tileId = bldLayer.pic[refIy][refIx] / 2;
                    m_lblRefBuildVal->setText(QString("(%1,%2) -> %3").arg(bx).arg(by).arg(tileId));
                    if (tileId >= 0 && tileId < m_tileCache.size() && !m_tileCache[tileId].isNull()) {
                        m_imgRefBuild->setPixmap(QPixmap::fromImage(m_tileCache[tileId]).scaled(
                            m_imgRefBuild->size(), Qt::KeepAspectRatio, Qt::SmoothTransformation));
                    } else {
                        m_imgRefBuild->clear();
                    }
                }
            }
        }
    }
}
