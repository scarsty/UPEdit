#include "warmapedit.h"
#include "grpdata.h"
#include "mapdata.h"
#include "fileio.h"
#include "iniconfig.h"
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QGroupBox>
#include <QPainter>
#include <QMouseEvent>
#include <QFileDialog>
#include <QMessageBox>
#include <QFile>
#include <QDataStream>

// ============ IsoMapEditor 基类 ============

IsoMapEditor::IsoMapEditor(QWidget *parent) : QWidget(parent)
{
    auto *mainLayout = new QHBoxLayout(this);

    // 左侧面板
    auto *leftPanel = new QVBoxLayout;
    m_layerCombo = new QComboBox;
    m_btnSelectTile = new QPushButton(tr("选贴图"));
    m_btnSave = new QPushButton(tr("保存"));

    leftPanel->addWidget(new QLabel(tr("操作层:")));
    leftPanel->addWidget(m_layerCombo);
    leftPanel->addWidget(m_btnSelectTile);
    leftPanel->addWidget(m_btnSave);
    leftPanel->addStretch();

    // 主地图区
    m_scroll = new QScrollArea;
    m_mapLabel = new QLabel;
    m_mapLabel->installEventFilter(this);
    m_scroll->setWidget(m_mapLabel);
    m_scroll->setWidgetResizable(false);

    mainLayout->addLayout(leftPanel);
    mainLayout->addWidget(m_scroll, 1);

    m_statusBar = new QStatusBar;
    // 添加到右侧底部需要修改布局
}

QPoint IsoMapEditor::isoToScreen(int ix, int iy) const
{
    int tw = tileW(), th = tileH();
    int sx = (ix - iy) * tw + m_renderCenterX;
    int sy = (ix + iy) * th + m_renderCenterY;
    return {sx, sy};
}

QPoint IsoMapEditor::screenToIso(int sx, int sy) const
{
    int tw = tileW(), th = tileH();
    double dx = sx - m_renderCenterX;
    double dy = sy - m_renderCenterY;
    double ix = (dx / tw + dy / th) / 2.0;
    double iy = (dy / th - dx / tw) / 2.0;
    return {(int)ix, (int)iy};
}

void IsoMapEditor::drawIsoTile(QPainter &p, int ix, int iy, const QImage &sprite, int xoff, int yoff)
{
    QPoint sp = isoToScreen(ix, iy);
    p.drawImage(sp.x() - xoff, sp.y() - yoff, sprite);
}

void IsoMapEditor::drawSelection(QPainter &p, int ix, int iy)
{
    QPoint sp = isoToScreen(ix, iy);
    int tw = tileW(), th = tileH();
    QPolygon diamond;
    diamond << QPoint(sp.x(), sp.y() - th)
            << QPoint(sp.x() + tw, sp.y())
            << QPoint(sp.x(), sp.y() + th)
            << QPoint(sp.x() - tw, sp.y());
    p.setPen(QPen(Qt::red, 2));
    p.drawPolygon(diamond);
}

bool IsoMapEditor::eventFilter(QObject *obj, QEvent *event)
{
    if (obj == m_mapLabel) {
        if (event->type() == QEvent::MouseButtonPress) {
            handleMousePress(static_cast<QMouseEvent*>(event));
            return true;
        }
        if (event->type() == QEvent::MouseMove) {
            handleMouseMove(static_cast<QMouseEvent*>(event));
            return true;
        }
        if (event->type() == QEvent::MouseButtonRelease) {
            handleMouseRelease(static_cast<QMouseEvent*>(event));
            return true;
        }
    }
    return QWidget::eventFilter(obj, event);
}

void IsoMapEditor::handleMousePress(QMouseEvent *event)
{
    QPoint iso = screenToIso(event->pos().x(), event->pos().y());
    m_selIsoX = iso.x();
    m_selIsoY = iso.y();
    onTileClicked(iso.x(), iso.y(), event->button());
}

void IsoMapEditor::handleMouseMove(QMouseEvent *event)
{
    QPoint iso = screenToIso(event->pos().x(), event->pos().y());
    if (m_statusBar)
        m_statusBar->showMessage(QString("(%1, %2)").arg(iso.x()).arg(iso.y()));
}

void IsoMapEditor::handleMouseRelease(QMouseEvent * /*event*/)
{
}

// ============ WarMapEdit ============

WarMapEdit::WarMapEdit(QWidget *parent) : IsoMapEditor(parent)
{
    m_layerCombo->addItems({tr("未选择"), tr("地面"), tr("建筑"), tr("全部")});
    m_layerCombo->setCurrentIndex(3);  // 默认全部

    auto *leftLayout = static_cast<QVBoxLayout*>(layout()->itemAt(0)->layout());
    m_mapCombo = new QComboBox;
    auto *btnNew = new QPushButton(tr("新增"));
    auto *btnDel = new QPushButton(tr("删除"));
    auto *btnExport = new QPushButton(tr("导出图片"));
    auto *btnImportModule = new QPushButton(tr("导入模块"));
    auto *btnExportModule = new QPushButton(tr("导出模块"));

    leftLayout->insertWidget(0, new QLabel(tr("地图索引:")));
    leftLayout->insertWidget(1, m_mapCombo);
    leftLayout->insertWidget(4, btnNew);
    leftLayout->insertWidget(5, btnDel);
    leftLayout->insertWidget(6, btnExport);
    leftLayout->insertWidget(7, btnImportModule);
    leftLayout->insertWidget(8, btnExportModule);

    // 贴图预览 GroupBox
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
    addTileRow(tr("地面"), m_lblGroundVal, m_imgGround);
    addTileRow(tr("建筑"), m_lblBuildingVal, m_imgBuilding);
    tileGroup->setFixedWidth(200);
    leftLayout->addWidget(tileGroup);

    // 缩略图
    m_thumbLabel = new QLabel;
    m_thumbLabel->setFixedSize(256, 128);
    m_thumbLabel->setFrameStyle(QFrame::Panel | QFrame::Sunken);
    m_thumbLabel->setAlignment(Qt::AlignCenter);
    m_thumbLabel->setScaledContents(true);
    leftLayout->addWidget(new QLabel(tr("缩略图")));
    leftLayout->addWidget(m_thumbLabel);

    connect(m_mapCombo, QOverload<int>::of(&QComboBox::currentIndexChanged), this, &WarMapEdit::onLoadMap);
    connect(m_btnSave, &QPushButton::clicked, this, &WarMapEdit::onSaveMap);
    connect(btnNew, &QPushButton::clicked, this, &WarMapEdit::onNewMap);
    connect(btnDel, &QPushButton::clicked, this, &WarMapEdit::onDeleteMap);
    connect(btnExport, &QPushButton::clicked, this, &WarMapEdit::onExportImage);
    connect(btnImportModule, &QPushButton::clicked, this, &WarMapEdit::onImportModule);
    connect(btnExportModule, &QPushButton::clicked, this, &WarMapEdit::onExportModule);

    // 初始加载数据
    readWarMapDef();
    readWarMapGrp();
    if (m_mapData.num > 0) {
        m_mapCombo->setCurrentIndex(0);
        onLoadMap(0);
    }
}

void WarMapEdit::readWarMapDef()
{
    IniConfig &cfg = IniConfig::instance();
    QString defIdxPath = cfg.gamePath + "/" + cfg.warMapDefIdx;
    QString defGrpPath = cfg.gamePath + "/" + cfg.warMapDefGrp;

    QByteArray idxData = FileIO::readFileAll(defIdxPath);
    QByteArray grpData = FileIO::readFileAll(defGrpPath);
    if (idxData.isEmpty() || grpData.isEmpty()) return;

    // idx: cumulative END offsets, each 4 bytes
    int totalEntries = idxData.size() / 4;
    const uint32_t *offsets = reinterpret_cast<const uint32_t *>(idxData.constData());

    // Count non-zero offsets (Delphi: stop at first zero)
    int num = 0;
    for (int i = 0; i < totalEntries; ++i) {
        if (offsets[i] > 0) ++num;
        else break;
    }

    m_mapData.num = num;
    m_mapData.map.resize(num);

    // War maps: no header, hardcoded layerNum=2, x=64, y=64 (matching Delphi readwardef)
    const int layerNum = 2, mapW = 64, mapH = 64;
    for (int i = 0; i < num; ++i) {
        int startOff = (i == 0) ? 0 : static_cast<int>(offsets[i - 1]);
        MapIO::readSingleMap(grpData, startOff, m_mapData.map[i], layerNum, mapW, mapH);
    }

    m_mapCombo->blockSignals(true);
    m_mapCombo->clear();
    for (int i = 0; i < m_mapData.num; ++i)
        m_mapCombo->addItem(QString::number(i));
    m_mapCombo->blockSignals(false);
}

void WarMapEdit::readWarMapGrp()
{
    IniConfig &cfg = IniConfig::instance();
    GrpIO::readGrp(cfg.gamePath + "/" + cfg.warMapIdx,
                    cfg.gamePath + "/" + cfg.warMapGrp, m_grpPics);

    // 构建解码缓存
    uint8_t pr[256]={}, pg[256]={}, pb[256]={};
    if (!cfg.palette.isEmpty())
        MapIO::readPalette(cfg.gamePath + cfg.palette, pr, pg, pb);

    m_tileCache.resize(m_grpPics.size());
    for (int i = 0; i < m_grpPics.size(); ++i) {
        const auto &pic = m_grpPics[i];
        if (pic.data.isEmpty()) continue;
        if (GrpIO::isPNG(pic))
            m_tileCache[i] = GrpIO::decodePNG(pic);
        else
            m_tileCache[i] = GrpIO::decodeRLE(pic, pr, pg, pb);
    }
}

void WarMapEdit::onLoadMap(int index)
{
    if (index < 0) return;
    if (m_mapData.num == 0) {
        readWarMapDef();
        readWarMapGrp();
        if (index >= m_mapData.num) return;
    }
    if (m_tileCache.isEmpty())
        readWarMapGrp();
    m_currentMapIndex = index;
    renderMap();
}

void WarMapEdit::renderMap()
{
    if (m_currentMapIndex < 0 || m_currentMapIndex >= m_mapData.num) return;
    const Map &curMap = m_mapData.map[m_currentMapIndex];
    int mapW = curMap.x, mapH = curMap.y;
    int tw = tileW(), th = tileH(), pad = tilePadding();

    int imgW = (mapW + mapH) * tw + pad * 2;
    int imgH = (mapW + mapH) * th + pad * 2;

    // Delphi: pointx = width/2, pointy = height/2 - 31*18
    m_renderCenterX = imgW / 2;
    m_renderCenterY = imgH / 2 - 31 * tw;

    m_mapImage = QImage(imgW, imgH, QImage::Format_ARGB32);
    m_mapImage.fill(Qt::black);
    QPainter p(&m_mapImage);

    int layer = m_layerCombo->currentIndex();
    int startLayer = (layer <= 0 || layer == 3) ? 0 : layer - 1;
    int endLayer = (layer <= 0 || layer == 3) ? curMap.layerNum : layer;

    // 对角线遍历 (匹配 Delphi displaywareditmap)
    for (int i = 0; i < qMin(mapW, mapH); ++i) {
        // 行扫描: ix from i to mapW-1, iy = i
        for (int ix = i; ix < mapW; ++ix) {
            int iy = i;
            QPoint sp = isoToScreen(ix, iy);
            for (int ly = startLayer; ly < endLayer && ly < curMap.mapLayer.size(); ++ly) {
                const auto &layerData = curMap.mapLayer[ly];
                if (ix >= layerData.pic.size() || iy >= layerData.pic[ix].size()) continue;
                int tileId = layerData.pic[ix][iy] / 2;
                // 地面层(0): tileId>=0 均绘制; 其他层: tileId>0 才绘制
                if (ly == 0) {
                    if (tileId < 0 || tileId >= m_tileCache.size()) continue;
                } else {
                    if (tileId <= 0 || tileId >= m_tileCache.size()) continue;
                }
                const auto &tile = m_tileCache[tileId];
                if (tile.isNull()) continue;
                int xoff = (tileId < m_grpPics.size()) ? m_grpPics[tileId].xoff : 0;
                int yoff = (tileId < m_grpPics.size()) ? m_grpPics[tileId].yoff : 0;
                p.drawImage(sp.x() - xoff, sp.y() - yoff, tile);
            }
        }
        // 列扫描: ix = i, iy from i+1 to mapH-1
        for (int iy = i + 1; iy < mapH; ++iy) {
            int ix = i;
            QPoint sp = isoToScreen(ix, iy);
            for (int ly = startLayer; ly < endLayer && ly < curMap.mapLayer.size(); ++ly) {
                const auto &layerData = curMap.mapLayer[ly];
                if (ix >= layerData.pic.size() || iy >= layerData.pic[ix].size()) continue;
                int tileId = layerData.pic[ix][iy] / 2;
                if (ly == 0) {
                    if (tileId < 0 || tileId >= m_tileCache.size()) continue;
                } else {
                    if (tileId <= 0 || tileId >= m_tileCache.size()) continue;
                }
                const auto &tile = m_tileCache[tileId];
                if (tile.isNull()) continue;
                int xoff = (tileId < m_grpPics.size()) ? m_grpPics[tileId].xoff : 0;
                int yoff = (tileId < m_grpPics.size()) ? m_grpPics[tileId].yoff : 0;
                p.drawImage(sp.x() - xoff, sp.y() - yoff, tile);
            }
        }
    }

    if (m_selIsoX >= 0 && m_selIsoY >= 0)
        drawSelection(p, m_selIsoX, m_selIsoY);

    if (m_isSelecting && inCurrentMap(m_pressIsoX, m_pressIsoY) && inCurrentMap(m_hoverIsoX, m_hoverIsoY))
        drawSelectionArea(p, m_pressIsoX, m_pressIsoY, m_hoverIsoX, m_hoverIsoY);

    m_mapLabel->setPixmap(QPixmap::fromImage(m_mapImage));
    m_mapLabel->resize(m_mapImage.size());

    updateThumbnail();
}

void WarMapEdit::onTileClicked(int ix, int iy, Qt::MouseButton btn)
{
    if (m_currentMapIndex < 0 || m_currentMapIndex >= m_mapData.num) return;
    if (!inCurrentMap(ix, iy)) return;

    m_selIsoX = ix;
    m_selIsoY = iy;
    m_hoverIsoX = ix;
    m_hoverIsoY = iy;

    if (btn == Qt::LeftButton) {
        m_isSelecting = true;
        m_pressIsoX = ix;
        m_pressIsoY = iy;
        renderMap();
        return;
    }

    if (btn == Qt::RightButton) {
        int ly = selectedLayerIndex();
        Map &curMap = m_mapData.map[m_currentMapIndex];

        if (m_hasClipboard) {
            pasteClipboardAt(ix, iy);
            renderMap();
            return;
        }

        if (ly < 0 || ly >= curMap.mapLayer.size()) return;
        if (m_selectedTileId < 0) return;
        if (ix >= curMap.mapLayer[ly].pic.size() || iy >= curMap.mapLayer[ly].pic[ix].size()) return;

        curMap.mapLayer[ly].pic[ix][iy] = m_selectedTileId * 2;
        renderMap();
    }
}

void WarMapEdit::handleMouseMove(QMouseEvent *event)
{
    IsoMapEditor::handleMouseMove(event);
    QPoint iso = screenToIso(event->pos().x(), event->pos().y());
    m_hoverIsoX = iso.x();
    m_hoverIsoY = iso.y();
    updateTilePreview(iso.x(), iso.y());

    if (m_isSelecting)
        renderMap();
}

void WarMapEdit::handleMouseRelease(QMouseEvent *event)
{
    if (event->button() != Qt::LeftButton || !m_isSelecting) return;
    m_isSelecting = false;

    if (m_currentMapIndex < 0 || m_currentMapIndex >= m_mapData.num) return;
    QPoint iso = screenToIso(event->pos().x(), event->pos().y());
    m_hoverIsoX = iso.x();
    m_hoverIsoY = iso.y();

    if (!inCurrentMap(m_pressIsoX, m_pressIsoY)) {
        renderMap();
        return;
    }

    int ex = qBound(0, iso.x(), m_mapData.map[m_currentMapIndex].x - 1);
    int ey = qBound(0, iso.y(), m_mapData.map[m_currentMapIndex].y - 1);

    bool singleCell = (m_pressIsoX == ex && m_pressIsoY == ey);
    if (singleCell && !isLayerAll()) {
        int ly = selectedLayerIndex();
        const Map &curMap = m_mapData.map[m_currentMapIndex];
        if (ly >= 0 && ly < curMap.mapLayer.size()
            && ex < curMap.mapLayer[ly].pic.size()
            && ey < curMap.mapLayer[ly].pic[ex].size()) {
            m_selectedTileId = curMap.mapLayer[ly].pic[ex][ey] / 2;
            m_hasClipboard = false;
        }
    } else {
        copySelectionToClipboard(m_pressIsoX, m_pressIsoY, ex, ey);
        m_selectedTileId = -1;
    }

    renderMap();
}

void WarMapEdit::onSaveMap()
{
    IniConfig &cfg = IniConfig::instance();
    QString defIdxPath = cfg.gamePath + "/" + cfg.warMapDefIdx;
    QString defGrpPath = cfg.gamePath + "/" + cfg.warMapDefGrp;

    QByteArray grpData;
    QByteArray idxData(m_mapData.num * 4, '\0');
    uint32_t *offsets = reinterpret_cast<uint32_t *>(idxData.data());

    for (int i = 0; i < m_mapData.num; ++i) {
        const Map &m = m_mapData.map[i];
        // War maps: no header, write tile data directly
        for (int l = 0; l < m.layerNum && l < m.mapLayer.size(); ++l) {
            const MapLayer &layer = m.mapLayer[l];
            for (int y = 0; y < m.y; ++y) {
                for (int x = 0; x < m.x; ++x) {
                    int16_t v = (x < layer.pic.size() && y < layer.pic[x].size())
                                ? layer.pic[x][y] : 0;
                    grpData.append(reinterpret_cast<const char *>(&v), 2);
                }
            }
        }
        // Cumulative END offset
        offsets[i] = static_cast<uint32_t>(grpData.size());
    }

    FileIO::writeFileAll(defGrpPath, grpData);
    FileIO::writeFileAll(defIdxPath, idxData);
    QMessageBox::information(this, tr("保存"), tr("战场地图保存成功"));
}

void WarMapEdit::onNewMap()
{
    Map newMap;
    newMap.x = 64; newMap.y = 64; newMap.layerNum = 2;
    newMap.mapLayer.resize(2);
    for (auto &ml : newMap.mapLayer) {
        ml.pic.resize(newMap.x);
        for (auto &col : ml.pic) col.resize(newMap.y, 0);
    }
    m_mapData.map.append(newMap);
    m_mapData.num = m_mapData.map.size();
    m_mapCombo->addItem(QString::number(m_mapData.num - 1));
}

void WarMapEdit::onDeleteMap()
{
    int idx = m_mapCombo->currentIndex();
    if (idx < 0 || idx >= m_mapData.num) return;
    m_mapData.map.removeAt(idx);
    m_mapData.num = m_mapData.map.size();
    m_mapCombo->removeItem(idx);
}

void WarMapEdit::onExportImage()
{
    if (m_mapImage.isNull()) return;
    QString f = QFileDialog::getSaveFileName(this, tr("导出地图图片"), {}, "PNG (*.png);;BMP (*.bmp)");
    if (!f.isEmpty()) m_mapImage.save(f);
}

void WarMapEdit::updateTilePreview(int ix, int iy)
{
    if (m_currentMapIndex < 0 || m_currentMapIndex >= m_mapData.num) return;
    const Map &curMap = m_mapData.map[m_currentMapIndex];
    if (ix < 0 || iy < 0 || ix >= curMap.x || iy >= curMap.y) return;

    auto showTile = [&](int layerIdx, QLabel *valLbl, QLabel *imgLbl) {
        if (layerIdx >= (int)curMap.mapLayer.size()) return;
        const auto &layer = curMap.mapLayer[layerIdx];
        if (ix >= layer.pic.size() || iy >= layer.pic[ix].size()) return;
        int tileId = layer.pic[ix][iy] / 2;
        valLbl->setText(QString::number(tileId));
        if (tileId >= 0 && tileId < m_tileCache.size() && !m_tileCache[tileId].isNull()) {
            imgLbl->setPixmap(QPixmap::fromImage(m_tileCache[tileId]).scaled(
                imgLbl->size(), Qt::KeepAspectRatio, Qt::SmoothTransformation));
        } else {
            imgLbl->clear();
        }
    };

    showTile(0, m_lblGroundVal, m_imgGround);
    showTile(1, m_lblBuildingVal, m_imgBuilding);
}

void WarMapEdit::updateThumbnail()
{
    if (m_mapImage.isNull() || !m_thumbLabel) return;
    m_thumbLabel->setPixmap(QPixmap::fromImage(m_mapImage).scaled(
        m_thumbLabel->size(), Qt::KeepAspectRatio, Qt::SmoothTransformation));
}

bool WarMapEdit::isLayerAll() const
{
    return m_layerCombo->currentIndex() == 3;
}

int WarMapEdit::selectedLayerIndex() const
{
    int layer = m_layerCombo->currentIndex();
    if (layer <= 0 || layer == 3) return -1;
    return layer - 1;
}

bool WarMapEdit::inCurrentMap(int ix, int iy) const
{
    if (m_currentMapIndex < 0 || m_currentMapIndex >= m_mapData.num) return false;
    const Map &curMap = m_mapData.map[m_currentMapIndex];
    return ix >= 0 && iy >= 0 && ix < curMap.x && iy < curMap.y;
}

void WarMapEdit::copySelectionToClipboard(int sx, int sy, int ex, int ey)
{
    if (m_currentMapIndex < 0 || m_currentMapIndex >= m_mapData.num) return;
    const Map &src = m_mapData.map[m_currentMapIndex];

    int minX = qMin(sx, ex), maxX = qMax(sx, ex);
    int minY = qMin(sy, ey), maxY = qMax(sy, ey);
    minX = qBound(0, minX, src.x - 1);
    maxX = qBound(0, maxX, src.x - 1);
    minY = qBound(0, minY, src.y - 1);
    maxY = qBound(0, maxY, src.y - 1);

    m_clipboardMap.layerNum = src.layerNum;
    m_clipboardMap.x = maxX - minX + 1;
    m_clipboardMap.y = maxY - minY + 1;
    m_clipboardMap.mapLayer.resize(src.layerNum);

    for (int l = 0; l < src.layerNum; ++l) {
        m_clipboardMap.mapLayer[l].pic.resize(m_clipboardMap.x);
        for (int x = 0; x < m_clipboardMap.x; ++x) {
            m_clipboardMap.mapLayer[l].pic[x].resize(m_clipboardMap.y, 0);
            for (int y = 0; y < m_clipboardMap.y; ++y) {
                int srcX = minX + x;
                int srcY = minY + y;
                if (srcX < src.mapLayer[l].pic.size() && srcY < src.mapLayer[l].pic[srcX].size())
                    m_clipboardMap.mapLayer[l].pic[x][y] = src.mapLayer[l].pic[srcX][srcY];
            }
        }
    }
    m_hasClipboard = true;
}

void WarMapEdit::pasteClipboardAt(int tx, int ty)
{
    if (!m_hasClipboard) return;
    if (m_currentMapIndex < 0 || m_currentMapIndex >= m_mapData.num) return;

    Map &dst = m_mapData.map[m_currentMapIndex];
    int ly = selectedLayerIndex();

    auto pasteLayer = [&](int layerIdx) {
        if (layerIdx < 0 || layerIdx >= dst.layerNum || layerIdx >= m_clipboardMap.layerNum) return;
        for (int dx = 0; dx < m_clipboardMap.x; ++dx) {
            for (int dy = 0; dy < m_clipboardMap.y; ++dy) {
                int dstX = tx - dx;
                int dstY = ty - dy;
                if (dstX < 0 || dstY < 0 || dstX >= dst.x || dstY >= dst.y) continue;

                int srcX = m_clipboardMap.x - dx - 1;
                int srcY = m_clipboardMap.y - dy - 1;
                if (srcX < 0 || srcY < 0) continue;
                if (srcX >= m_clipboardMap.mapLayer[layerIdx].pic.size()) continue;
                if (srcY >= m_clipboardMap.mapLayer[layerIdx].pic[srcX].size()) continue;
                if (dstX >= dst.mapLayer[layerIdx].pic.size()) continue;
                if (dstY >= dst.mapLayer[layerIdx].pic[dstX].size()) continue;

                dst.mapLayer[layerIdx].pic[dstX][dstY] = m_clipboardMap.mapLayer[layerIdx].pic[srcX][srcY];
            }
        }
    };

    if (isLayerAll()) {
        for (int l = 0; l < qMin(dst.layerNum, m_clipboardMap.layerNum); ++l)
            pasteLayer(l);
    } else {
        pasteLayer(ly);
    }
}

bool WarMapEdit::loadModuleFile(const QString &filePath, Map &moduleMap)
{
    QFile f(filePath);
    if (!f.open(QIODevice::ReadOnly)) return false;

    QDataStream ds(&f);
    ds.setByteOrder(QDataStream::LittleEndian);

    qint32 mapX = 0, mapY = 0;
    ds >> mapX >> mapY;
    if (mapX <= 0 || mapY <= 0) return false;

    moduleMap.layerNum = 2;
    moduleMap.x = mapX;
    moduleMap.y = mapY;
    moduleMap.mapLayer.resize(moduleMap.layerNum);

    for (int l = 0; l < moduleMap.layerNum; ++l) {
        moduleMap.mapLayer[l].pic.resize(moduleMap.x);
        for (int x = 0; x < moduleMap.x; ++x)
            moduleMap.mapLayer[l].pic[x].resize(moduleMap.y, 0);

        for (int y = 0; y < moduleMap.y; ++y) {
            for (int x = 0; x < moduleMap.x; ++x) {
                qint16 v = 0;
                ds >> v;
                moduleMap.mapLayer[l].pic[x][y] = v;
            }
        }
    }
    return ds.status() == QDataStream::Ok;
}

bool WarMapEdit::saveModuleFile(const QString &filePath, const Map &moduleMap)
{
    QFile f(filePath);
    if (!f.open(QIODevice::WriteOnly)) return false;

    QDataStream ds(&f);
    ds.setByteOrder(QDataStream::LittleEndian);
    ds << static_cast<qint32>(moduleMap.x) << static_cast<qint32>(moduleMap.y);

    int layers = qMin(2, moduleMap.layerNum);
    for (int l = 0; l < layers; ++l) {
        for (int y = 0; y < moduleMap.y; ++y) {
            for (int x = 0; x < moduleMap.x; ++x) {
                qint16 v = 0;
                if (x < moduleMap.mapLayer[l].pic.size() && y < moduleMap.mapLayer[l].pic[x].size())
                    v = static_cast<qint16>(moduleMap.mapLayer[l].pic[x][y]);
                ds << v;
            }
        }
    }
    return ds.status() == QDataStream::Ok;
}

void WarMapEdit::onImportModule()
{
    QString filePath = QFileDialog::getOpenFileName(this, tr("导入模块"), {}, tr("War Module (*.wmd);;All Files (*.*)"));
    if (filePath.isEmpty()) return;

    Map moduleMap;
    if (!loadModuleFile(filePath, moduleMap)) {
        QMessageBox::warning(this, tr("导入失败"), tr("无法读取模块文件。"));
        return;
    }

    m_clipboardMap = moduleMap;
    m_hasClipboard = true;
    m_selectedTileId = -1;
    m_layerCombo->setCurrentIndex(3); // 全部层
    renderMap();
    QMessageBox::information(this, tr("导入成功"), tr("模块已载入，右键可粘贴。"));
}

void WarMapEdit::onExportModule()
{
    if (!m_hasClipboard) {
        QMessageBox::information(this, tr("提示"), tr("请先左键框选区域以复制模块。"));
        return;
    }

    QString filePath = QFileDialog::getSaveFileName(this, tr("导出模块"), {}, tr("War Module (*.wmd)"));
    if (filePath.isEmpty()) return;
    if (!filePath.endsWith(".wmd", Qt::CaseInsensitive))
        filePath += ".wmd";

    if (!saveModuleFile(filePath, m_clipboardMap)) {
        QMessageBox::warning(this, tr("导出失败"), tr("无法写入模块文件。"));
        return;
    }
    QMessageBox::information(this, tr("导出成功"), tr("模块导出成功。"));
}

void WarMapEdit::drawSelectionArea(QPainter &p, int sx, int sy, int ex, int ey)
{
    int minX = qMin(sx, ex), maxX = qMax(sx, ex);
    int minY = qMin(sy, ey), maxY = qMax(sy, ey);
    p.setPen(QPen(Qt::red, 2));
    for (int x = minX; x <= maxX; ++x) {
        for (int y = minY; y <= maxY; ++y) {
            if (!inCurrentMap(x, y)) continue;
            QPoint sp = isoToScreen(x, y);
            int tw = tileW(), th = tileH();
            QPolygon diamond;
            diamond << QPoint(sp.x(), sp.y() - th)
                    << QPoint(sp.x() + tw, sp.y())
                    << QPoint(sp.x(), sp.y() + th)
                    << QPoint(sp.x() - tw, sp.y());
            p.drawPolygon(diamond);
        }
    }
}
