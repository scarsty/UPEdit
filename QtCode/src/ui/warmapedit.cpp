#include "warmapedit.h"
#include "grpdata.h"
#include "mapdata.h"
#include "iniconfig.h"
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QPainter>
#include <QMouseEvent>
#include <QFileDialog>
#include <QMessageBox>

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
    int sx = (ix - iy) * tw / 2 + tilePadding();
    int sy = (ix + iy) * th / 2 + tilePadding();
    return {sx, sy};
}

QPoint IsoMapEditor::screenToIso(int sx, int sy) const
{
    int tw = tileW(), th = tileH();
    sx -= tilePadding();
    sy -= tilePadding();
    double ix = (double)sx / tw + (double)sy / th;
    double iy = (double)sy / th - (double)sx / tw;
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

// ============ WarMapEdit ============

WarMapEdit::WarMapEdit(QWidget *parent) : IsoMapEditor(parent)
{
    m_layerCombo->addItems({tr("未选择"), tr("地面"), tr("建筑"), tr("全部")});

    auto *leftLayout = static_cast<QVBoxLayout*>(layout()->itemAt(0)->layout());
    m_mapCombo = new QComboBox;
    auto *btnNew = new QPushButton(tr("新增"));
    auto *btnDel = new QPushButton(tr("删除"));
    auto *btnExport = new QPushButton(tr("导出图片"));

    leftLayout->insertWidget(0, new QLabel(tr("地图索引:")));
    leftLayout->insertWidget(1, m_mapCombo);
    leftLayout->insertWidget(4, btnNew);
    leftLayout->insertWidget(5, btnDel);
    leftLayout->insertWidget(6, btnExport);

    connect(m_mapCombo, QOverload<int>::of(&QComboBox::currentIndexChanged), this, &WarMapEdit::onLoadMap);
    connect(m_btnSave, &QPushButton::clicked, this, &WarMapEdit::onSaveMap);
    connect(btnNew, &QPushButton::clicked, this, &WarMapEdit::onNewMap);
    connect(btnDel, &QPushButton::clicked, this, &WarMapEdit::onDeleteMap);
    connect(btnExport, &QPushButton::clicked, this, &WarMapEdit::onExportImage);
}

void WarMapEdit::readWarMapDef()
{
    IniConfig &cfg = IniConfig::instance();
    QString defIdxPath = cfg.gamePath + "/" + cfg.warMapIdx;
    QString defGrpPath = cfg.gamePath + "/" + cfg.warMapGrp;

    MapIO::readMap(defIdxPath, defGrpPath, m_mapData);

    m_mapCombo->blockSignals(true);
    m_mapCombo->clear();
    for (int i = 0; i < m_mapData.num; ++i)
        m_mapCombo->addItem(QString::number(i));
    m_mapCombo->blockSignals(false);
}

void WarMapEdit::readWarMapGrp()
{
    IniConfig &cfg = IniConfig::instance();
    GrpIO::readGrp(cfg.gamePath + "/" + cfg.warMapTileIdx,
                    cfg.gamePath + "/" + cfg.warMapTileGrp, m_grpPics);

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
    }
    m_currentMapIndex = index;
    renderMap();
}

void WarMapEdit::renderMap()
{
    if (m_currentMapIndex < 0 || m_currentMapIndex >= m_mapData.num) return;
    const Map &curMap = m_mapData.map[m_currentMapIndex];
    int mapW = curMap.x, mapH = curMap.y;

    int imgW = (mapW + mapH) * tileW() + tilePadding() * 2;
    int imgH = (mapW + mapH) * tileH() + tilePadding() * 2;

    m_mapImage = QImage(imgW, imgH, QImage::Format_ARGB32);
    m_mapImage.fill(QColor(0, 50, 0));
    QPainter p(&m_mapImage);

    int layer = m_layerCombo->currentIndex();
    int startLayer = (layer <= 0) ? 0 : layer - 1;
    int endLayer = (layer <= 0 || layer == 3) ? curMap.layerNum : layer;

    for (int ly = startLayer; ly < endLayer && ly < curMap.mapLayer.size(); ++ly) {
        const auto &layerData = curMap.mapLayer[ly];
        for (int iy = 0; iy < mapH; ++iy) {
            for (int ix = 0; ix < mapW; ++ix) {
                if (ix >= layerData.pic.size() || iy >= layerData.pic[ix].size()) continue;
                int tileId = layerData.pic[ix][iy];
                if (tileId < 0 || tileId >= m_tileCache.size()) continue;
                const auto &tile = m_tileCache[tileId];
                if (tile.isNull()) continue;
                int xoff = (tileId < m_grpPics.size()) ? m_grpPics[tileId].xoff : 0;
                int yoff = (tileId < m_grpPics.size()) ? m_grpPics[tileId].yoff : 0;
                drawIsoTile(p, ix, iy, tile, xoff, yoff);
            }
        }
    }

    if (m_selIsoX >= 0 && m_selIsoY >= 0)
        drawSelection(p, m_selIsoX, m_selIsoY);

    m_mapLabel->setPixmap(QPixmap::fromImage(m_mapImage));
    m_mapLabel->resize(m_mapImage.size());
}

void WarMapEdit::onTileClicked(int ix, int iy, Qt::MouseButton btn)
{
    int layer = m_layerCombo->currentIndex();
    if (layer <= 0 || layer == 3) return;
    int ly = layer - 1;
    if (m_currentMapIndex < 0 || m_currentMapIndex >= m_mapData.num) return;
    Map &curMap = m_mapData.map[m_currentMapIndex];
    if (ly >= curMap.mapLayer.size()) return;
    if (ix < 0 || ix >= curMap.x || iy < 0 || iy >= curMap.y) return;
    if (ix >= curMap.mapLayer[ly].pic.size()) return;

    if (btn == Qt::LeftButton && m_selectedTileId >= 0) {
        curMap.mapLayer[ly].pic[ix][iy] = m_selectedTileId;
        renderMap();
    }
}

void WarMapEdit::onSaveMap()
{
    IniConfig &cfg = IniConfig::instance();
    MapIO::saveMap(cfg.gamePath + "/" + cfg.warMapIdx,
                   cfg.gamePath + "/" + cfg.warMapGrp, m_mapData);
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
