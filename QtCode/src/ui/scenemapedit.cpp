#include "scenemapedit.h"
#include "grpdata.h"
#include "mapdata.h"
#include "fileio.h"
#include "eventdata.h"
#include "iniconfig.h"
#include "encoding.h"
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QGroupBox>
#include <QFormLayout>
#include <QPainter>
#include <QMouseEvent>
#include <QFileDialog>
#include <QMessageBox>

SceneMapEdit::SceneMapEdit(QWidget *parent) : IsoMapEditor(parent)
{
    m_layerCombo->clear();
    m_layerCombo->addItems({tr("地面"), tr("建筑"), tr("空中"), tr("事件"), tr("海拔"), tr("全部")});
    m_layerCombo->setCurrentIndex(5);  // 默认全部

    auto *leftLayout = static_cast<QVBoxLayout*>(layout()->itemAt(0)->layout());

    m_saveCombo = new QComboBox;
    m_sceneCombo = new QComboBox;
    m_deleteMode = new QCheckBox(tr("删除模式"));
    m_undoLimitSpin = new QSpinBox; m_undoLimitSpin->setRange(10, 100); m_undoLimitSpin->setValue(20);

    auto *btnNew = new QPushButton(tr("新增场景"));
    auto *btnDel = new QPushButton(tr("删除场景"));
    auto *btnImport = new QPushButton(tr("导入场景"));
    auto *btnExport = new QPushButton(tr("导出场景"));
    auto *btnExportImg = new QPushButton(tr("导出图片"));
    auto *btnUndo = new QPushButton(tr("撤销"));
    auto *btnRedo = new QPushButton(tr("重做"));

    leftLayout->insertWidget(0, new QLabel(tr("进度:")));
    leftLayout->insertWidget(1, m_saveCombo);
    leftLayout->insertWidget(2, new QLabel(tr("场景:")));
    leftLayout->insertWidget(3, m_sceneCombo);
    leftLayout->addWidget(m_deleteMode);
    leftLayout->addWidget(btnNew);
    leftLayout->addWidget(btnDel);
    leftLayout->addWidget(btnImport);
    leftLayout->addWidget(btnExport);
    leftLayout->addWidget(btnExportImg);
    leftLayout->addWidget(btnUndo);
    leftLayout->addWidget(btnRedo);
    leftLayout->addWidget(new QLabel(tr("撤销限制:")));
    leftLayout->addWidget(m_undoLimitSpin);

    // 事件编辑面板
    auto *evtGroup = new QGroupBox(tr("事件编辑"));
    auto *evtForm = new QFormLayout(evtGroup);
    m_evtCanWalk = new QLineEdit("0");
    m_evtIndex = new QLineEdit("0");
    m_evtEvent1 = new QLineEdit("-1");
    m_evtEvent2 = new QLineEdit("-1");
    m_evtEvent3 = new QLineEdit("-1");
    m_evtBeginPic = new QLineEdit("0");
    m_evtEndPic = new QLineEdit("0");
    m_evtAnim = new QLineEdit("0");
    m_evtX = new QLineEdit("0");
    m_evtY = new QLineEdit("0");
    evtForm->addRow(tr("可行走"), m_evtCanWalk);
    evtForm->addRow(tr("索引"), m_evtIndex);
    evtForm->addRow(tr("事件1"), m_evtEvent1);
    evtForm->addRow(tr("事件2"), m_evtEvent2);
    evtForm->addRow(tr("事件3"), m_evtEvent3);
    evtForm->addRow(tr("起贴图"), m_evtBeginPic);
    evtForm->addRow(tr("终贴图"), m_evtEndPic);
    evtForm->addRow(tr("动画帧"), m_evtAnim);
    evtForm->addRow(tr("X"), m_evtX);
    evtForm->addRow(tr("Y"), m_evtY);
    auto *btnEvtConfirm = new QPushButton(tr("确认事件"));
    evtForm->addRow(btnEvtConfirm);
    leftLayout->addWidget(evtGroup);

    // 贴图预览 GroupBox
    auto *tileGroup = new QGroupBox(tr("当前贴图"));
    auto *tileLay = new QVBoxLayout(tileGroup);
    auto addTileRow = [&](const QString &label, QLabel *&valLabel, QLabel *&imgLabel) {
        auto *h = new QHBoxLayout;
        auto *lbl = new QLabel(label);
        valLabel = new QLabel;
        h->addWidget(lbl);
        h->addWidget(valLabel);
        tileLay->addLayout(h);
        imgLabel = new QLabel;
        imgLabel->setFixedSize(85, 50);
        imgLabel->setFrameStyle(QFrame::Panel | QFrame::Sunken);
        imgLabel->setAlignment(Qt::AlignCenter);
        tileLay->addWidget(imgLabel);
    };
    addTileRow(tr("地面"), m_lblGroundVal, m_imgGround);
    addTileRow(tr("建筑"), m_lblBuildingVal, m_imgBuilding);
    addTileRow(tr("空中"), m_lblSkyVal, m_imgSky);
    addTileRow(tr("事件"), m_lblEventVal, m_imgEvent);
    tileGroup->setFixedWidth(200);
    leftLayout->addWidget(tileGroup);

    connect(m_saveCombo, QOverload<int>::of(&QComboBox::currentIndexChanged), this, &SceneMapEdit::onSaveSlotChanged);
    connect(m_sceneCombo, QOverload<int>::of(&QComboBox::currentIndexChanged), this, &SceneMapEdit::onLoadScene);
    connect(m_btnSave, &QPushButton::clicked, this, &SceneMapEdit::onSaveScene);
    connect(btnNew, &QPushButton::clicked, this, &SceneMapEdit::onNewScene);
    connect(btnDel, &QPushButton::clicked, this, &SceneMapEdit::onDeleteScene);
    connect(btnImport, &QPushButton::clicked, this, &SceneMapEdit::onImportScene);
    connect(btnExport, &QPushButton::clicked, this, &SceneMapEdit::onExportScene);
    connect(btnExportImg, &QPushButton::clicked, this, &SceneMapEdit::onExportImage);
    connect(btnUndo, &QPushButton::clicked, this, &SceneMapEdit::onUndo);
    connect(btnRedo, &QPushButton::clicked, this, &SceneMapEdit::onRedo);
    connect(btnEvtConfirm, &QPushButton::clicked, this, &SceneMapEdit::onEventConfirm);

    // 填充进度下拉框 (场景下拉框在选中进度后动态填充)
    IniConfig &cfg = IniConfig::instance();
    for (int i = 0; i < cfg.rFileNum && i < cfg.rFileNote.size(); ++i)
        m_saveCombo->addItem(Encoding::displayStr(cfg.rFileNote[i]));

    // 自动加载第一个存档
    if (m_saveCombo->count() > 0) {
        m_saveCombo->setCurrentIndex(0);
        onSaveSlotChanged(0);
    }
}

void SceneMapEdit::onSaveSlotChanged(int index)
{
    if (index < 0) return;
    loadSceneGrpFile(index);
}

void SceneMapEdit::loadSceneGrpFile(int saveSlot)
{
    IniConfig &cfg = IniConfig::instance();
    if (saveSlot < 0 || saveSlot >= cfg.sGrp.size()) return;

    m_currentSave = saveSlot;
    QString path = cfg.gamePath + "/" + cfg.sGrp[saveSlot];
    QFile f(path);
    if (!f.open(QIODevice::ReadOnly)) {
        m_sceneRawData.clear();
        m_sceneCount = 0;
        m_sceneCombo->clear();
        return;
    }
    m_sceneRawData = f.readAll();

    // 每个场景: 64 * 64 * 6 层 * 2 字节 (无文件头, Delphi hardcoded)
    const int sceneStride = 64 * 64 * 6 * 2;
    m_sceneCount = m_sceneRawData.size() / sceneStride;

    m_sceneCombo->blockSignals(true);
    m_sceneCombo->clear();
    for (int i = 0; i < m_sceneCount; ++i)
        m_sceneCombo->addItem(QString::number(i));
    m_sceneCombo->blockSignals(false);

    if (m_sceneCount > 0) {
        m_sceneCombo->setCurrentIndex(0);
        onLoadScene(0);
    }
}

void SceneMapEdit::readSceneData(int sceneIndex)
{
    m_currentScene = sceneIndex;

    // 从缓存的原始数据中提取指定场景 (64×64, 6 层, 无文件头)
    const int sceneStride = 64 * 64 * 6 * 2;
    int offset = sceneIndex * sceneStride;
    if (offset + sceneStride > m_sceneRawData.size()) return;

    m_mapData.num = 1;
    m_mapData.map.resize(1);
    MapIO::readSingleMap(m_sceneRawData, offset, m_mapData.map[0], 6, 64, 64);

    // 加载事件数据 (D-file, idx/grp 格式, 每场景 200 events × 11 int16)
    IniConfig &cfg = IniConfig::instance();
    if (m_currentSave < cfg.dIdx.size() && m_currentSave < cfg.dGrp.size()) {
        QByteArray idxData = FileIO::readFileAll(cfg.gamePath + "/" + cfg.dIdx[m_currentSave]);
        QByteArray grpData = FileIO::readFileAll(cfg.gamePath + "/" + cfg.dGrp[m_currentSave]);

        if (!idxData.isEmpty() && !grpData.isEmpty() && sceneIndex * 4 + 4 <= idxData.size()) {
            uint32_t dOff = *reinterpret_cast<const uint32_t*>(idxData.constData() + sceneIndex * 4);
            if (dOff < (uint32_t)grpData.size()) {
                QDataStream ds(grpData.mid(dOff));
                ds.setByteOrder(QDataStream::LittleEndian);

                int eventsPerScene = 200;
                QVector<SceneEventLocal> events(eventsPerScene);
                for (int i = 0; i < eventsPerScene; ++i) {
                    ds >> events[i].canWalk >> events[i].index
                       >> events[i].event1 >> events[i].event2 >> events[i].event3
                       >> events[i].beginPic >> events[i].endPic
                       >> events[i].animFrames
                       >> events[i].x >> events[i].y >> events[i].unused;
                }
                if (sceneIndex >= m_sceneEvents.size()) m_sceneEvents.resize(sceneIndex + 1);
                m_sceneEvents[sceneIndex] = events;
            }
        }
    }
}

void SceneMapEdit::readSceneGrp()
{
    IniConfig &cfg = IniConfig::instance();
    GrpIO::readGrp(cfg.gamePath + "/" + cfg.smapIdx,
                    cfg.gamePath + "/" + cfg.smapGrp, m_grpPics);

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

void SceneMapEdit::onLoadScene(int index)
{
    if (index < 0 || index >= m_sceneCount) return;
    if (m_tileCache.isEmpty()) readSceneGrp();
    if (m_sceneRawData.isEmpty()) return;
    readSceneData(index);
    m_undoStack.clear();
    m_undoPos = -1;
    addUndoSave();
    renderMap();
}

void SceneMapEdit::renderMap()
{
    if (m_mapData.num == 0 || m_mapData.map.isEmpty()) return;
    const Map &curMap = m_mapData.map[0]; // 场景只有一张地图
    int mapW = curMap.x, mapH = curMap.y;
    int tw = tileW(), th = tileH(), pad = tilePadding();

    int imgW = (mapW + mapH) * tw + pad * 2;
    int imgH = (mapW + mapH) * th + pad * 2;

    // Delphi: pointx = width/2, pointy = height/2 - 31*TileW
    m_renderCenterX = imgW / 2;
    m_renderCenterY = imgH / 2 - 31 * tw;

    m_mapImage = QImage(imgW, imgH, QImage::Format_ARGB32);
    m_mapImage.fill(Qt::black);
    QPainter p(&m_mapImage);

    int layer = m_layerCombo->currentIndex();
    // 层: 0=地面, 1=建筑, 2=空中, 3=事件, 4=海拔, 5=全部
    bool showGround   = (layer == 5 || layer == 0);
    bool showBuilding = (layer == 5 || layer == 1);
    bool showSky      = (layer == 5 || layer == 2);
    bool showEvent    = (layer == 5 || layer == 3);

    // 获取事件数据
    const QVector<SceneEventLocal> *evts = nullptr;
    if (m_currentScene >= 0 && m_currentScene < m_sceneEvents.size())
        evts = &m_sceneEvents[m_currentScene];

    // 辅助: 绘制单个贴图
    auto drawOneTile = [&](int ly, int ix, int iy, const QPoint &sp, int elevLayer) {
        if (ly >= curMap.mapLayer.size()) return;
        const auto &layerData = curMap.mapLayer[ly];
        if (ix >= layerData.pic.size() || iy >= layerData.pic[ix].size()) return;
        int tileId = layerData.pic[ix][iy] / 2;
        if (ly == 0) {
            if (tileId < 0 || tileId >= m_tileCache.size()) return;
        } else {
            if (tileId <= 0 || tileId >= m_tileCache.size()) return;
        }
        const auto &tile = m_tileCache[tileId];
        if (tile.isNull()) return;
        int xoff = (tileId < m_grpPics.size()) ? m_grpPics[tileId].xoff : 0;
        int yoff = (tileId < m_grpPics.size()) ? m_grpPics[tileId].yoff : 0;
        int elev = 0;
        if (elevLayer >= 0 && elevLayer < curMap.mapLayer.size()) {
            const auto &eLayer = curMap.mapLayer[elevLayer];
            if (ix < eLayer.pic.size() && iy < eLayer.pic[ix].size())
                elev = eLayer.pic[ix][iy];
        }
        p.drawImage(sp.x() - xoff, sp.y() - yoff - elev, tile);
    };

    // 辅助: 绘制事件贴图
    auto drawEventTile = [&](int ix, int iy, const QPoint &sp) {
        if (3 >= curMap.mapLayer.size()) return;
        const auto &layerData = curMap.mapLayer[3];
        if (ix >= layerData.pic.size() || iy >= layerData.pic[ix].size()) return;
        int evtIdx = layerData.pic[ix][iy];
        if (evtIdx < 0 || !evts || evtIdx >= evts->size()) return;
        int beginPic = (*evts)[evtIdx].beginPic;
        int tileId = beginPic / 2;
        if (tileId <= 0 || tileId >= m_tileCache.size()) return;
        const auto &tile = m_tileCache[tileId];
        if (tile.isNull()) return;
        int xoff = (tileId < m_grpPics.size()) ? m_grpPics[tileId].xoff : 0;
        int yoff = (tileId < m_grpPics.size()) ? m_grpPics[tileId].yoff : 0;
        // 事件使用建筑高度层 (layer 4)
        int elev = 0;
        if (4 < curMap.mapLayer.size()) {
            const auto &eLayer = curMap.mapLayer[4];
            if (ix < eLayer.pic.size() && iy < eLayer.pic[ix].size())
                elev = eLayer.pic[ix][iy];
        }
        p.drawImage(sp.x() - xoff, sp.y() - yoff - elev, tile);
    };

    // 对角线遍历 (匹配 Delphi displayscenemap 绘制顺序, 所有层一起绘制)
    for (int i = 0; i < qMin(mapW, mapH); ++i) {
        // 行扫描: ix from i to mapW-1, iy = i
        for (int ix = i; ix < mapW; ++ix) {
            int iy = i;
            QPoint sp = isoToScreen(ix, iy);
            if (showGround)   drawOneTile(0, ix, iy, sp, -1);
            if (showBuilding) drawOneTile(1, ix, iy, sp, 4);
            if (showSky)      drawOneTile(2, ix, iy, sp, 5);
            if (showEvent)    drawEventTile(ix, iy, sp);
        }
        // 列扫描: ix = i, iy from i+1 to mapH-1
        for (int iy = i + 1; iy < mapH; ++iy) {
            int ix = i;
            QPoint sp = isoToScreen(ix, iy);
            if (showGround)   drawOneTile(0, ix, iy, sp, -1);
            if (showBuilding) drawOneTile(1, ix, iy, sp, 4);
            if (showSky)      drawOneTile(2, ix, iy, sp, 5);
            if (showEvent)    drawEventTile(ix, iy, sp);
        }
    }

    // 事件标签 (所有图层绘制完后单独遍历, 匹配 Delphi TextOut)
    if (showEvent && 3 < curMap.mapLayer.size()) {
        p.setPen(Qt::yellow);
        p.setFont(QFont("Arial", 8));
        const auto &evtLayer = curMap.mapLayer[3];
        for (int ix = 0; ix < mapW; ++ix) {
            for (int iy = 0; iy < mapH; ++iy) {
                if (ix >= evtLayer.pic.size() || iy >= evtLayer.pic[ix].size()) continue;
                int evtIdx = evtLayer.pic[ix][iy];
                if (evtIdx < 0) continue;
                QPoint sp = isoToScreen(ix, iy);
                // Delphi: TextOut(posx - 5, posy - TileW, '['+inttostr(evtIdx)+']')
                p.drawText(sp.x() - 5, sp.y() - tw, QString("[%1]").arg(evtIdx));
            }
        }
    }

    if (m_selIsoX >= 0 && m_selIsoY >= 0)
        drawSelection(p, m_selIsoX, m_selIsoY);

    m_mapLabel->setPixmap(QPixmap::fromImage(m_mapImage));
    m_mapLabel->resize(m_mapImage.size());
}

void SceneMapEdit::onTileClicked(int ix, int iy, Qt::MouseButton btn)
{
    int layer = m_layerCombo->currentIndex();
    if (layer >= 3) {
        // 事件层
        if (m_currentScene >= 0 && m_currentScene < m_sceneEvents.size()) {
            for (auto &evt : m_sceneEvents[m_currentScene]) {
                if (evt.x == ix && evt.y == iy) {
                    m_evtCanWalk->setText(QString::number(evt.canWalk));
                    m_evtIndex->setText(QString::number(evt.index));
                    m_evtEvent1->setText(QString::number(evt.event1));
                    m_evtEvent2->setText(QString::number(evt.event2));
                    m_evtEvent3->setText(QString::number(evt.event3));
                    m_evtBeginPic->setText(QString::number(evt.beginPic));
                    m_evtEndPic->setText(QString::number(evt.endPic));
                    m_evtAnim->setText(QString::number(evt.animFrames));
                    m_evtX->setText(QString::number(evt.x));
                    m_evtY->setText(QString::number(evt.y));
                    return;
                }
            }
        }
        return;
    }

    if (m_mapData.map.isEmpty()) return;
    Map &curMap = m_mapData.map[0];
    if (layer < 0 || layer >= curMap.mapLayer.size()) return;
    if (ix < 0 || ix >= curMap.x || iy < 0 || iy >= curMap.y) return;

    addUndoSave();

    if (m_deleteMode->isChecked()) {
        curMap.mapLayer[layer].pic[ix][iy] = 0;
    } else if (m_selectedTileId >= 0 && btn == Qt::LeftButton) {
        curMap.mapLayer[layer].pic[ix][iy] = m_selectedTileId * 2;
    }
    renderMap();
}

void SceneMapEdit::onEventConfirm()
{
    if (m_currentScene < 0 || m_currentScene >= m_sceneEvents.size()) return;
    int x = m_evtX->text().toInt(), y = m_evtY->text().toInt();
    for (auto &evt : m_sceneEvents[m_currentScene]) {
        if (evt.x == x && evt.y == y) {
            evt.canWalk = m_evtCanWalk->text().toShort();
            evt.index = m_evtIndex->text().toShort();
            evt.event1 = m_evtEvent1->text().toShort();
            evt.event2 = m_evtEvent2->text().toShort();
            evt.event3 = m_evtEvent3->text().toShort();
            evt.beginPic = m_evtBeginPic->text().toShort();
            evt.endPic = m_evtEndPic->text().toShort();
            evt.animFrames = m_evtAnim->text().toShort();
            renderMap();
            return;
        }
    }
}

void SceneMapEdit::addUndoSave()
{
    if (m_undoPos < (int)m_undoStack.size() - 1)
        m_undoStack.resize(m_undoPos + 1);

    UndoState state;
    state.mapData = m_mapData;
    if (m_currentScene >= 0 && m_currentScene < m_sceneEvents.size())
        state.events = m_sceneEvents[m_currentScene];
    m_undoStack.append(state);
    m_undoPos = m_undoStack.size() - 1;

    int limit = m_undoLimitSpin->value();
    while (m_undoStack.size() > limit) {
        m_undoStack.removeFirst();
        m_undoPos--;
    }
}

void SceneMapEdit::onUndo()
{
    if (m_undoPos <= 0) return;
    m_undoPos--;
    m_mapData = m_undoStack[m_undoPos].mapData;
    if (m_currentScene >= 0 && m_currentScene < m_sceneEvents.size())
        m_sceneEvents[m_currentScene] = m_undoStack[m_undoPos].events;
    renderMap();
}

void SceneMapEdit::onRedo()
{
    if (m_undoPos >= m_undoStack.size() - 1) return;
    m_undoPos++;
    m_mapData = m_undoStack[m_undoPos].mapData;
    if (m_currentScene >= 0 && m_currentScene < m_sceneEvents.size())
        m_sceneEvents[m_currentScene] = m_undoStack[m_undoPos].events;
    renderMap();
}

void SceneMapEdit::onSaveScene()
{
    IniConfig &cfg = IniConfig::instance();
    if (m_currentScene < 0) return;

    // 保存地图
    QString idxPath = cfg.gamePath + "/" + cfg.sIdx[m_currentScene];
    QString grpPath = cfg.gamePath + "/" + cfg.sGrp[m_currentScene];
    MapIO::saveMap(idxPath, grpPath, m_mapData);

    // 保存事件数据
    if (m_currentScene < m_sceneEvents.size() && m_currentScene < cfg.dIdx.size()) {
        QString dPath = cfg.gamePath + "/" + cfg.dIdx[m_currentScene];
        QFile dFile(dPath);
        if (dFile.open(QIODevice::ReadWrite)) {
            int eventsPerScene = 200, eventSize = 11 * 2;
            dFile.seek(m_currentScene * eventsPerScene * eventSize);
            QDataStream ds(&dFile);
            ds.setByteOrder(QDataStream::LittleEndian);
            for (const auto &evt : m_sceneEvents[m_currentScene]) {
                ds << evt.canWalk << evt.index
                   << evt.event1 << evt.event2 << evt.event3
                   << evt.beginPic << evt.endPic
                   << evt.animFrames << evt.x << evt.y << evt.unused;
            }
        }
    }
    QMessageBox::information(this, tr("保存"), tr("场景保存成功"));
}

void SceneMapEdit::onNewScene() { QMessageBox::information(this, tr("提示"), tr("TODO: 新增场景")); }
void SceneMapEdit::onDeleteScene() { QMessageBox::information(this, tr("提示"), tr("TODO: 删除场景")); }

void SceneMapEdit::onImportScene()
{
    QString f = QFileDialog::getOpenFileName(this, tr("导入场景"), {}, "Scene (*.*)");
    if (f.isEmpty()) return;
    // TODO: 读取场景二进制数据替换当前
}

void SceneMapEdit::onExportScene()
{
    QString f = QFileDialog::getSaveFileName(this, tr("导出场景"), {}, "Scene (*.*)");
    if (f.isEmpty()) return;
    // TODO: 写出当前场景数据
}

void SceneMapEdit::onExportImage()
{
    if (m_mapImage.isNull()) return;
    QString f = QFileDialog::getSaveFileName(this, tr("导出图片"), {}, "PNG (*.png);;BMP (*.bmp)");
    if (!f.isEmpty()) m_mapImage.save(f);
}

void SceneMapEdit::handleMouseMove(QMouseEvent *event)
{
    IsoMapEditor::handleMouseMove(event);
    QPoint iso = screenToIso(event->pos().x(), event->pos().y());
    updateTilePreview(iso.x(), iso.y());
}

void SceneMapEdit::updateTilePreview(int ix, int iy)
{
    if (m_mapData.map.isEmpty()) return;
    const Map &curMap = m_mapData.map[0];
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
    showTile(2, m_lblSkyVal, m_imgSky);

    // 事件层: layer 3 存事件索引, 用 beginPic 查找贴图
    if (3 < (int)curMap.mapLayer.size()) {
        const auto &layer = curMap.mapLayer[3];
        if (ix < layer.pic.size() && iy < layer.pic[ix].size()) {
            int evtIdx = layer.pic[ix][iy];
            if (evtIdx >= 0 && m_currentScene >= 0 && m_currentScene < m_sceneEvents.size()
                && evtIdx < m_sceneEvents[m_currentScene].size()) {
                int tileId = m_sceneEvents[m_currentScene][evtIdx].beginPic / 2;
                m_lblEventVal->setText(QString("%1 (pic:%2)").arg(evtIdx).arg(tileId));
                if (tileId > 0 && tileId < m_tileCache.size() && !m_tileCache[tileId].isNull()) {
                    m_imgEvent->setPixmap(QPixmap::fromImage(m_tileCache[tileId]).scaled(
                        m_imgEvent->size(), Qt::KeepAspectRatio, Qt::SmoothTransformation));
                } else {
                    m_imgEvent->clear();
                }
            } else {
                m_lblEventVal->clear();
                m_imgEvent->clear();
            }
        }
    }
}
