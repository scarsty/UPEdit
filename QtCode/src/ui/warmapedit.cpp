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
    // 从 INI 中读取战斗地图定义路径
    QString defIdxPath = cfg.gamePath + "/" + cfg.warMapIdxFile;
    QString defGrpPath = cfg.gamePath + "/" + cfg.warMapGrpFile;

    m_mapData = MapData::loadMap(defIdxPath, defGrpPath);

    m_mapCombo->blockSignals(true);
    m_mapCombo->clear();
    for (int i = 0; i < m_mapData.mapCount; ++i)
        m_mapCombo->addItem(QString::number(i));
    m_mapCombo->blockSignals(false);
}

void WarMapEdit::readWarMapGrp()
{
    IniConfig &cfg = IniConfig::instance();
    // 加载战斗地图贴图集
    m_grpPics = GrpData::loadGrpIdx(cfg.warMapTileIdxFile, cfg.warMapTileGrpFile);

    // 构建解码缓存
    m_tileCache.resize(m_grpPics.size());
    for (int i = 0; i < m_grpPics.size(); ++i) {
        const auto &pic = m_grpPics[i];
        if (pic.data.isEmpty() || pic.width <= 0 || pic.height <= 0) continue;
        m_tileCache[i] = QImage(pic.width, pic.height, QImage::Format_ARGB32);
        m_tileCache[i].fill(Qt::transparent);
        GrpData::decodeRLE8(pic.data, pic.width, pic.height, m_palette, m_tileCache[i]);
    }
}

void WarMapEdit::onLoadMap(int index)
{
    if (index < 0) return;
    // 首次加载
    if (m_mapData.mapCount == 0) {
        readWarMapDef();
        readWarMapGrp();
    }
    renderMap();
}

void WarMapEdit::renderMap()
{
    if (m_mapData.mapCount == 0) return;

    int mapW = m_mapData.xSize, mapH = m_mapData.ySize;
    int imgW = (mapW + mapH) * tileW() + tilePadding() * 2;
    int imgH = (mapW + mapH) * tileH() + tilePadding() * 2;

    m_mapImage = QImage(imgW, imgH, QImage::Format_ARGB32);
    m_mapImage.fill(QColor(0, 50, 0));
    QPainter p(&m_mapImage);

    int layer = m_layerCombo->currentIndex();
    int startLayer = (layer <= 0) ? 0 : layer - 1;
    int endLayer = (layer <= 0 || layer == 3) ? m_mapData.layerNum : layer;

    for (int ly = startLayer; ly < endLayer && ly < m_mapData.layers.size(); ++ly) {
        const auto &layerData = m_mapData.layers[ly];
        for (int iy = 0; iy < mapH; ++iy) {
            for (int ix = 0; ix < mapW; ++ix) {
                int tileId = layerData.tiles[iy * mapW + ix];
                if (tileId < 0 || tileId >= m_tileCache.size()) continue;
                const auto &tile = m_tileCache[tileId];
                if (tile.isNull()) continue;

                int xoff = (tileId < m_grpPics.size()) ? m_grpPics[tileId].xoff : 0;
                int yoff = (tileId < m_grpPics.size()) ? m_grpPics[tileId].yoff : 0;
                drawIsoTile(p, ix, iy, tile, xoff, yoff);
            }
        }
    }

    // 选中指示
    if (m_selIsoX >= 0 && m_selIsoY >= 0)
        drawSelection(p, m_selIsoX, m_selIsoY);

    m_mapLabel->setPixmap(QPixmap::fromImage(m_mapImage));
    m_mapLabel->resize(m_mapImage.size());
}

void WarMapEdit::onTileClicked(int ix, int iy, Qt::MouseButton btn)
{
    int layer = m_layerCombo->currentIndex();
    if (layer <= 0 || layer == 3) return; // 未选择或全部层：不编辑
    int ly = layer - 1;

    if (ly >= m_mapData.layers.size()) return;
    if (ix < 0 || ix >= m_mapData.xSize || iy < 0 || iy >= m_mapData.ySize) return;

    if (btn == Qt::LeftButton && m_selectedTileId >= 0) {
        m_mapData.layers[ly].tiles[iy * m_mapData.xSize + ix] = m_selectedTileId;
        renderMap();
    }
}

void WarMapEdit::onSaveMap()
{
    IniConfig &cfg = IniConfig::instance();
    MapData::saveMap(cfg.gamePath + "/" + cfg.warMapIdxFile,
                     cfg.gamePath + "/" + cfg.warMapGrpFile, m_mapData);
    QMessageBox::information(this, tr("保存"), tr("战场地图保存成功"));
}

void WarMapEdit::onNewMap()
{
    // 添加一个空地图
    m_mapData.mapCount++;
    m_mapCombo->addItem(QString::number(m_mapData.mapCount - 1));
}

void WarMapEdit::onDeleteMap()
{
    // 删除当前地图
    int idx = m_mapCombo->currentIndex();
    if (idx < 0) return;
    m_mapData.mapCount--;
    m_mapCombo->removeItem(idx);
}

void WarMapEdit::onExportImage()
{
    if (m_mapImage.isNull()) return;
    QString f = QFileDialog::getSaveFileName(this, tr("导出地图图片"), {}, "PNG (*.png);;BMP (*.bmp)");
    if (!f.isEmpty()) m_mapImage.save(f);
}
