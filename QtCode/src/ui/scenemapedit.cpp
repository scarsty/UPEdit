#include "scenemapedit.h"
#include "grpdata.h"
#include "mapdata.h"
#include "eventdata.h"
#include "iniconfig.h"
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QGroupBox>
#include <QFormLayout>
#include <QPainter>
#include <QFileDialog>
#include <QMessageBox>

SceneMapEdit::SceneMapEdit(QWidget *parent) : IsoMapEditor(parent)
{
    m_layerCombo->clear();
    m_layerCombo->addItems({tr("地面"), tr("建筑"), tr("空中"), tr("事件"), tr("海拔"), tr("全部")});

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
}

void SceneMapEdit::readSceneData(int sceneIndex)
{
    IniConfig &cfg = IniConfig::instance();
    m_currentScene = sceneIndex;

    // 加载场景地图
    QString mapPath = cfg.gamePath + "/" + cfg.sceneMapPath;
    m_mapData = MapData::loadMap(mapPath + ".idx", mapPath + ".grp");

    // 加载事件数据 (D-file format: 200 events per scene, 11 int16_t each)
    QString dPath = cfg.gamePath + "/" + cfg.dFilePath;
    QFile dFile(dPath);
    if (dFile.open(QIODevice::ReadOnly)) {
        QDataStream ds(&dFile);
        ds.setByteOrder(QDataStream::LittleEndian);

        int eventsPerScene = 200;
        int eventSize = 11 * 2; // 11 int16_t fields
        dFile.seek(sceneIndex * eventsPerScene * eventSize);

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

void SceneMapEdit::readSceneGrp()
{
    IniConfig &cfg = IniConfig::instance();
    m_grpPics = GrpData::loadGrpIdx(cfg.sceneTileIdxFile, cfg.sceneTileGrpFile);
    MapData::loadPalette(cfg.scenePalettePath, m_palette);

    m_tileCache.resize(m_grpPics.size());
    for (int i = 0; i < m_grpPics.size(); ++i) {
        const auto &pic = m_grpPics[i];
        if (pic.data.isEmpty() || pic.width <= 0 || pic.height <= 0) continue;
        m_tileCache[i] = QImage(pic.width, pic.height, QImage::Format_ARGB32);
        m_tileCache[i].fill(Qt::transparent);
        GrpData::decodeRLE8(pic.data, pic.width, pic.height, m_palette, m_tileCache[i]);
    }
}

void SceneMapEdit::onLoadScene(int index)
{
    if (index < 0) return;
    if (m_tileCache.isEmpty()) readSceneGrp();
    readSceneData(index);
    m_undoStack.clear();
    m_undoPos = -1;
    addUndoSave();
    renderMap();
}

void SceneMapEdit::renderMap()
{
    if (m_mapData.mapCount == 0) return;

    int mapW = m_mapData.xSize, mapH = m_mapData.ySize;
    int imgW = (mapW + mapH) * tileW() + tilePadding() * 2;
    int imgH = (mapW + mapH) * tileH() + tilePadding() * 2;

    m_mapImage = QImage(imgW, imgH, QImage::Format_ARGB32);
    m_mapImage.fill(QColor(0, 40, 0));
    QPainter p(&m_mapImage);

    int layer = m_layerCombo->currentIndex();

    // 渲染地图层 (0=地面, 1=建筑, 2=空中, 3=事件, 4=海拔, 5=全部)
    auto drawLayer = [&](int ly) {
        if (ly >= m_mapData.layers.size()) return;
        const auto &layerData = m_mapData.layers[ly];
        for (int iy = 0; iy < mapH; ++iy) {
            for (int ix = 0; ix < mapW; ++ix) {
                int tileId = layerData.tiles[iy * mapW + ix];
                if (tileId < 0 || tileId >= m_tileCache.size()) continue;
                if (m_tileCache[tileId].isNull()) continue;
                int xoff = (tileId < m_grpPics.size()) ? m_grpPics[tileId].xoff : 0;
                int yoff = (tileId < m_grpPics.size()) ? m_grpPics[tileId].yoff : 0;
                drawIsoTile(p, ix, iy, m_tileCache[tileId], xoff, yoff);
            }
        }
    };

    if (layer == 5 || layer == 0) drawLayer(0); // 地面
    if (layer == 5 || layer == 1) drawLayer(1); // 建筑
    if (layer == 5 || layer == 2) drawLayer(2); // 空中

    // 事件层: 绘制事件标记
    if (layer == 3 || layer == 5) {
        if (m_currentScene >= 0 && m_currentScene < m_sceneEvents.size()) {
            p.setPen(QPen(Qt::yellow, 1));
            for (const auto &evt : m_sceneEvents[m_currentScene]) {
                if (evt.index <= 0) continue;
                QPoint sp = isoToScreen(evt.x, evt.y);
                p.drawRect(sp.x() - 4, sp.y() - 4, 8, 8);
                p.drawText(sp.x() + 6, sp.y(), QString::number(evt.index));
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
        // 事件层 - 选择事件显示
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

    if (layer < 0 || layer >= m_mapData.layers.size()) return;
    if (ix < 0 || ix >= m_mapData.xSize || iy < 0 || iy >= m_mapData.ySize) return;

    addUndoSave();

    if (m_deleteMode->isChecked()) {
        m_mapData.layers[layer].tiles[iy * m_mapData.xSize + ix] = 0;
    } else if (m_selectedTileId >= 0 && btn == Qt::LeftButton) {
        m_mapData.layers[layer].tiles[iy * m_mapData.xSize + ix] = m_selectedTileId;
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
    QString mapPath = cfg.gamePath + "/" + cfg.sceneMapPath;
    MapData::saveMap(mapPath + ".idx", mapPath + ".grp", m_mapData);

    // 保存事件数据
    if (m_currentScene >= 0 && m_currentScene < m_sceneEvents.size()) {
        QString dPath = cfg.gamePath + "/" + cfg.dFilePath;
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
