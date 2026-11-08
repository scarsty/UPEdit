#include "scenemapedit.h"
#include "grpdata.h"
#include "mapdata.h"
#include "fileio.h"
#include "eventdata.h"
#include "iniconfig.h"
#include "encoding.h"
#include "rfile.h"
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QGroupBox>
#include <QFormLayout>
#include <QPainter>
#include <QMouseEvent>
#include <QFileDialog>
#include <QMessageBox>
#include <QDialogButtonBox>
#include <QDialog>
#include <QSet>
#include <QDataStream>
#include <QSaveFile>
#include <QtEndian>
#include <QCloseEvent>
#include <QSaveFile>
#include <cstring>
#include "imzdata.h"
#include <QBuffer>
#include <cmath>

int SceneMapEdit::backdropDepth(int x, int y, int width, int height)
{
    if (x < 0 || y < 0 || x >= width || y >= height) return -1;
    int diagonal = qMin(x, y);
    return diagonal * (width + height) + (y == diagonal ? x - diagonal : width - diagonal + y - diagonal - 1);
}

bool SceneMapEdit::backdropActive() const
{
    return m_backdropEnabled && m_backdropEnabled->isChecked() && !m_backdrop.isNull()
        && m_backdropSlot == m_currentSave && m_backdropScene == m_currentScene;
}

bool SceneMapEdit::confirmBackdropDiscard()
{
    return !m_backdropDirty || QMessageBox::question(this, tr("大图场景"),
        tr("大图或遮挡尚未保存，放弃这些修改？"), QMessageBox::Discard | QMessageBox::Cancel,
        QMessageBox::Cancel) == QMessageBox::Discard;
}

void SceneMapEdit::alignImportedBackdrop()
{
    if (m_mapData.map.isEmpty() || m_backdrop.isNull()) return;
    const auto &map = m_mapData.map[0];
    const QSize padded((map.x + map.y) * tileW() + 2 * tilePadding(),
        (map.x + map.y) * tileH() + 2 * tilePadding());
    const bool includesPadding = m_backdrop.size() == padded;
    const QSignalBlocker blockX(m_backdropX);
    const QSignalBlocker blockY(m_backdropY);
    m_backdropX->setValue(includesPadding ? 0 : tilePadding());
    m_backdropY->setValue(includesPadding ? 0 : tilePadding() - 2 * tileH());
}

void SceneMapEdit::setupBackdropTools(QVBoxLayout *layout)
{
    auto *group = new QGroupBox(tr("大图场景"));
    group->setObjectName("backdropSection");
    auto *form = new QFormLayout(group);
    auto *importImage = new QPushButton(tr("导入 WebP / PNG"));
    auto *loadProject = new QPushButton(tr("打开大图项目"));
    auto *saveProject = new QPushButton(tr("保存大图项目"));
    auto *undoMask = new QPushButton(tr("撤销遮挡"));
    auto *redoMask = new QPushButton(tr("重做遮挡"));
    undoMask->setObjectName("backdropUndo");
    redoMask->setObjectName("backdropRedo");
    form->addRow(importImage);
    form->addRow(loadProject, saveProject);
    form->addRow(undoMask, redoMask);
    connect(undoMask, &QPushButton::clicked, this, [this] {
        if (m_backdropHistoryPos <= 0) return;
        m_backdropDepth = m_backdropHistory[--m_backdropHistoryPos];
        m_backdropDirty = true;
        renderMap();
    });
    connect(redoMask, &QPushButton::clicked, this, [this] {
        if (m_backdropHistoryPos + 1 >= m_backdropHistory.size()) return;
        m_backdropDepth = m_backdropHistory[++m_backdropHistoryPos];
        m_backdropDirty = true;
        renderMap();
    });
    m_backdropEnabled = new QCheckBox(tr("启用大图"));
    m_backdropOverlay = new QCheckBox(tr("显示遮挡区域"));
    m_actorVisible = new QCheckBox(tr("显示预览人物"));
    form->addRow(m_backdropEnabled, m_backdropOverlay);
    form->addRow(m_actorVisible);
    m_backdropTool = new QComboBox;
    m_backdropTool->addItems({tr("原场景编辑"), tr("选择建筑落地点"), tr("涂绘遮挡"), tr("擦除遮挡"), tr("移动预览人物")});
    importImage->setToolTip(tr("使用不含动态人物、事件的干净场景图。仅支持不透明静态遮挡。"));
    m_backdropTool->setToolTip(tr("先选择建筑落地点，再涂绘建筑轮廓；右键可擦除遮挡。大图项目单独保存，不写入 S/D。"));
    form->addRow(tr("工具"), m_backdropTool);
    auto addNumber = [&](const QString &label, int minimum, int maximum, int initial) {
        auto *spin = new QSpinBox;
        spin->setRange(minimum, maximum);
        spin->setValue(initial);
        form->addRow(label, spin);
        return spin;
    };
    m_backdropX = new QSpinBox(group);
    m_backdropY = new QSpinBox(group);
    for (auto *offset : {m_backdropX, m_backdropY}) {
        offset->setRange(-32768, 32767);
        offset->hide();
    }
    m_backdropDepthInfo = new QLabel(tr("像素：—\n深度：—\n落点：—"));
    m_backdropDepthInfo->setWordWrap(false);
    m_backdropDepthInfo->setFixedHeight(m_backdropDepthInfo->fontMetrics().lineSpacing() * 3 + 6);
    m_backdropDepthInfo->setSizePolicy(QSizePolicy::Ignored, QSizePolicy::Fixed);
    m_backdropDepthInfo->setTextInteractionFlags(Qt::TextSelectableByMouse);
    form->addRow(tr("鼠标处遮挡值"), m_backdropDepthInfo);
    m_brushRadius = addNumber(tr("笔刷半径"), 1, 128, 12);
    m_anchorX = addNumber(tr("建筑落点 X"), 0, 63, 0);
    m_anchorY = addNumber(tr("建筑落点 Y"), 0, 63, 0);
    m_actorX = addNumber(tr("人物 X"), 0, 63, 0);
    m_actorY = addNumber(tr("人物 Y"), 0, 63, 0);
    layout->insertWidget(0, group);
    connect(importImage, &QPushButton::clicked, this, [this] {
        if (m_currentScene < 0) return;
        QString path = QFileDialog::getOpenFileName(this, tr("导入场景大图"), {}, "Images (*.webp *.png *.jpg *.jpeg)");
        if (path.isEmpty() || !confirmBackdropDiscard()) return;
        QByteArray bytes = FileIO::readFileAll(path);
        QImage image = ImzIO::decodeImage(bytes);
        if (image.isNull() || qint64(image.width()) * image.height() > 16000000) {
            QMessageBox::warning(this, tr("大图场景"), tr("图片无效或超过 1600 万像素。"));
            return;
        }
        m_backdrop = image;
        m_backdropDepth.fill(-1, image.width() * image.height());
        m_backdropHistory = {m_backdropDepth};
        m_backdropHistoryPos = 0;
        m_backdropSlot = m_currentSave;
        m_backdropScene = m_currentScene;
        alignImportedBackdrop();
        m_backdropDirty = true;
        m_backdropEnabled->setChecked(true);
        renderMap();
    });
    connect(saveProject, &QPushButton::clicked, this, [this] {
        if (!backdropActive()) return;
        QString path = QFileDialog::getSaveFileName(this, tr("保存大图项目"), {}, "Scene backdrop (*.sbg)");
        if (path.isEmpty()) return;
        if (!path.endsWith(".sbg", Qt::CaseInsensitive)) path += ".sbg";
        if (!saveBackdrop(path)) QMessageBox::warning(this, tr("大图场景"), tr("保存失败，原文件未替换。"));
    });
    connect(loadProject, &QPushButton::clicked, this, [this] {
        QString path = QFileDialog::getOpenFileName(this, tr("打开大图项目"), {}, "Scene backdrop (*.sbg)");
        if (path.isEmpty() || !confirmBackdropDiscard()) return;
        if (!loadBackdrop(path)) QMessageBox::warning(this, tr("大图场景"), tr("项目损坏或不属于当前存档槽、场景，保留原项目。"));
        renderMap();
    });
    for (auto *check : {m_backdropEnabled, m_backdropOverlay, m_actorVisible})
        connect(check, &QCheckBox::toggled, this, [this] { renderMap(); });
    connect(m_backdropTool, &QComboBox::currentIndexChanged, this, [this](int tool) {
        if (tool == 2 || tool == 3) m_backdropOverlay->setChecked(true);
        if (tool == 4) m_actorVisible->setChecked(true);
        renderMap();
    });
    connect(m_actorVisible, &QCheckBox::toggled, this, [this](bool visible) {
        if (!visible) return;
        if (m_hoverIsoX >= 0 && m_hoverIsoY >= 0) {
            m_actorX->setValue(m_hoverIsoX);
            m_actorY->setValue(m_hoverIsoY);
        }
        if (m_tileCache.size() <= 2501 || m_tileCache[2501].isNull())
            m_statusBar->showMessage(tr("场景贴图库缺少预览人物图片 2501"));
        renderMap();
    });
    for (auto *spin : {m_backdropX, m_backdropY, m_actorX, m_actorY})
        connect(spin, &QSpinBox::valueChanged, this, [this, spin] {
            if (!m_backdrop.isNull() && (spin == m_backdropX || spin == m_backdropY)) m_backdropDirty = true;
            renderMap();
        });
}

bool SceneMapEdit::saveBackdrop(const QString &path)
{
    if (!backdropActive()) return false;
    QByteArray imageBytes;
    QBuffer buffer(&imageBytes);
    if (!buffer.open(QIODevice::WriteOnly) || !m_backdrop.save(&buffer, "PNG")) return false;
    QByteArray raw;
    QDataStream depths(&raw, QIODevice::WriteOnly);
    depths.setByteOrder(QDataStream::LittleEndian);
    for (qint32 depth : m_backdropDepth) depths << depth;
    QSaveFile file(path);
    if (!file.open(QIODevice::WriteOnly)) return false;
    QDataStream stream(&file);
    stream.setVersion(QDataStream::Qt_6_0);
    stream.setByteOrder(QDataStream::LittleEndian);
    stream << quint32(0x31474253) << qint32(m_currentSave) << qint32(m_currentScene)
        << qint32(m_backdrop.width()) << qint32(m_backdrop.height())
        << qint32(m_backdropX->value()) << qint32(m_backdropY->value()) << imageBytes << raw;
    if (stream.status() != QDataStream::Ok || !file.commit()) return false;
    m_backdropDirty = false;
    return true;
}

bool SceneMapEdit::loadBackdrop(const QString &path)
{
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly) || file.size() > 256 * 1024 * 1024) return false;
    QDataStream stream(&file);
    stream.setVersion(QDataStream::Qt_6_0);
    stream.setByteOrder(QDataStream::LittleEndian);
    quint32 magic;
    qint32 slot, scene, width, height, offsetX, offsetY;
    stream >> magic >> slot >> scene >> width >> height >> offsetX >> offsetY;
    if (stream.status() != QDataStream::Ok || magic != 0x31474253 || slot != m_currentSave
        || scene != m_currentScene || scene < 0 || width <= 0 || height <= 0
        || qint64(width) * height > 16000000 || qAbs(qint64(offsetX)) > 32767 || qAbs(qint64(offsetY)) > 32767) return false;
    auto readBlock = [&]() {
        quint32 size = 0;
        stream >> size;
        if (stream.status() != QDataStream::Ok || size > quint64(file.bytesAvailable()) || size > 128 * 1024 * 1024) return QByteArray();
        return file.read(size);
    };
    QByteArray encoded = readBlock(), raw = readBlock();
    QImage image = ImzIO::decodeImage(encoded);
    if (stream.status() != QDataStream::Ok || !file.atEnd() || image.size() != QSize(width, height)
        || raw.size() != qint64(width) * height * 4) return false;
    QVector<qint32> candidate(width * height);
    QDataStream depths(raw);
    depths.setByteOrder(QDataStream::LittleEndian);
    for (auto &depth : candidate) {
        depths >> depth;
        if (depth < -1 || depth >= 8192) return false;
    }
    m_backdrop = image;
    m_backdropDepth = candidate;
    m_backdropHistory = {candidate};
    m_backdropHistoryPos = 0;
    m_backdropSlot = slot;
    m_backdropScene = scene;
    m_backdropX->setValue(offsetX);
    m_backdropY->setValue(offsetY);
    m_backdropEnabled->setChecked(true);
    m_backdropDirty = false;
    return true;
}

void SceneMapEdit::drawBackdropSprite(QPainter &painter, const QImage &sprite, QPoint position, int depth)
{
    QImage visible = sprite.convertToFormat(QImage::Format_ARGB32);
    for (int row = 0; row < visible.height(); ++row) {
        auto *pixels = reinterpret_cast<QRgb *>(visible.scanLine(row));
        int imageY = position.y() + row - m_backdropY->value();
        if (imageY < 0 || imageY >= m_backdrop.height()) continue;
        for (int column = 0; column < visible.width(); ++column) {
            int imageX = position.x() + column - m_backdropX->value();
            if (imageX >= 0 && imageX < m_backdrop.width()
                && m_backdropDepth[imageY * m_backdrop.width() + imageX] > depth) pixels[column] = 0;
        }
    }
    painter.drawImage(position, visible);
}

void SceneMapEdit::paintBackdrop(const QPoint &position, bool erase)
{
    QPoint center = position - QPoint(m_backdropX->value(), m_backdropY->value());
    int radius = m_brushRadius->value();
    const auto &map = m_mapData.map[0];
    int depth = erase ? -1 : backdropDepth(m_anchorX->value(), m_anchorY->value(), map.x, map.y);
    for (int row = qMax(0, center.y() - radius); row < qMin(m_backdrop.height(), center.y() + radius + 1); ++row)
        for (int column = qMax(0, center.x() - radius); column < qMin(m_backdrop.width(), center.x() + radius + 1); ++column)
            if ((column - center.x()) * (column - center.x()) + (row - center.y()) * (row - center.y()) <= radius * radius)
                m_backdropDepth[row * m_backdrop.width() + column] = depth;
    m_backdropDirty = true;
    renderMap();
}

QPoint SceneMapEdit::screenToIso(int sx, int sy) const
{
    const double horizontal = double(sx - m_renderCenterX) / tileW();
    const double vertical = double(sy - m_renderCenterY + tileH()) / tileH();
    return QPoint(int(std::floor((horizontal + vertical) / 2.0 + 0.5)),
        int(std::floor((vertical - horizontal) / 2.0 + 0.5)));
}

void SceneMapEdit::drawSelection(QPainter &painter, int ix, int iy)
{
    const QPoint center = isoToScreen(ix, iy) - QPoint(0, tileH());
    QPolygon outline;
    outline << center - QPoint(0, tileH()) << center + QPoint(tileW(), 0)
        << center + QPoint(0, tileH()) << center - QPoint(tileW(), 0);
    painter.setPen(QPen(Qt::red, 2));
    painter.setBrush(Qt::NoBrush);
    painter.drawPolygon(outline);
}

QPoint SceneMapEdit::eventClickTile(const QPoint &position) const
{
    const int layer = m_layerCombo->currentIndex();
    QPoint hit = screenToIso(position.x(), position.y());
    if (m_deleteMode->isChecked() || (layer != 3 && layer != 5)
        || (backdropActive() && m_backdropTool->currentIndex() != 0) || m_mapData.map.isEmpty()) return hit;
    const auto &map = m_mapData.map[0];
    int hitDepth = -1;
    for (int column = 0; column < map.x; ++column)
        for (int row = 0; row < map.y; ++row) {
            const int reference = eventIndexAt(column, row);
            const int depth = backdropDepth(column, row, map.x, map.y);
            if (reference >= 0 && eventLabelRect(column, row, reference).contains(position) && depth > hitDepth) {
                hit = QPoint(column, row);
                hitDepth = depth;
            }
        }
    return hit;
}

void SceneMapEdit::handleMousePress(QMouseEvent *event)
{
    if (!backdropActive() || m_backdropTool->currentIndex() == 0) {
        handleMouseMove(event);
        const QPoint tile = event->button() == Qt::LeftButton ? eventClickTile(event->pos())
            : screenToIso(event->pos().x(), event->pos().y());
        m_selIsoX = tile.x();
        m_selIsoY = tile.y();
        onTileClicked(tile.x(), tile.y(), event->button());
        return;
    }
    int tool = m_backdropTool->currentIndex();
    if (tool == 2 || tool == 3) {
        if (m_backdropHistory.isEmpty()) {
            m_backdropHistory = {m_backdropDepth};
            m_backdropHistoryPos = 0;
        }
        paintBackdrop(event->pos(), tool == 3 || event->button() == Qt::RightButton);
        return;
    }
    QPoint tile = screenToIso(event->pos().x(), event->pos().y());
    if (tile.x() < 0 || tile.y() < 0 || tile.x() >= 64 || tile.y() >= 64) return;
    if (tool == 1) { m_anchorX->setValue(tile.x()); m_anchorY->setValue(tile.y()); }
    else { m_actorX->setValue(tile.x()); m_actorY->setValue(tile.y()); m_actorVisible->setChecked(true); }
    renderMap();
}

SceneMapEdit::SceneMapEdit(QWidget *parent) : IsoMapEditor(parent)
{
    m_mapLabel->setMouseTracking(true);
    m_layerCombo->clear();
    m_layerCombo->addItems({tr("地面"), tr("建筑"), tr("空中"), tr("事件"), tr("建筑海拔"), tr("全部"), tr("空中海拔")});
    m_layerCombo->setCurrentIndex(5);  // 默认全部
    connect(m_tileSourceCombo, QOverload<int>::of(&QComboBox::currentIndexChanged), this, [this] { readSceneGrp(); renderMap(); });

    auto *leftLayout = static_cast<QVBoxLayout*>(layout()->itemAt(0)->layout());
    setupBackdropTools(leftLayout);

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
    auto *btnImportModule = new QPushButton(tr("导入区域模块"));
    auto *btnExportModule = new QPushButton(tr("导出区域模块"));
    leftLayout->addWidget(btnImportModule);
    leftLayout->addWidget(btnExportModule);
    connect(btnImportModule, &QPushButton::clicked, this, &SceneMapEdit::onImportModule);
    connect(btnExportModule, &QPushButton::clicked, this, &SceneMapEdit::onExportModule);

    leftLayout->insertWidget(0, new QLabel(tr("进度:")));
    leftLayout->insertWidget(1, m_saveCombo);
    leftLayout->insertWidget(2, new QLabel(tr("场景:")));
    leftLayout->insertWidget(3, m_sceneCombo);
    leftLayout->addWidget(m_deleteMode);
    m_altitude = new QSpinBox;
    m_altitude->setRange(-32768, 32767);
    leftLayout->addWidget(new QLabel(tr("海拔值")));
    leftLayout->addWidget(m_altitude);
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
    m_evtBeginPic2 = new QLineEdit("0");
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
    evtForm->addRow(tr("起贴图2"), m_evtBeginPic2);
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

    auto *backdropGroup = findChild<QGroupBox *>("backdropSection");
    while (auto *item = leftLayout->takeAt(0)) {
        if (auto *widget = item->widget()) widget->hide();
        delete item;
    }
    int sectionIndex = 0;
    auto addSection = [this, leftLayout, &sectionIndex](const QString &title, QWidget *content, bool expanded) {
        return IsoMapEditor::addSection(leftLayout, "Scene" + QString::number(sectionIndex++), title, content, expanded);
    };
    auto *sceneContent = new QWidget;
    auto *sceneForm = new QFormLayout(sceneContent);
    sceneForm->addRow(tr("进度"), m_saveCombo);
    sceneForm->addRow(tr("场景"), m_sceneCombo);
    for (auto *button : {m_btnSave, btnNew, btnDel, btnImport, btnExport, btnExportImg}) {
        sceneForm->addRow(button);
        button->show();
    }
    m_saveCombo->show(); m_sceneCombo->show();
    addSection(tr("场景文件"), sceneContent, true);
    auto *editContent = new QWidget;
    auto *editForm = new QFormLayout(editContent);
    editForm->addRow(tr("操作层"), m_layerCombo);
    editForm->addRow(tr("贴图来源"), m_tileSourceCombo);
    editForm->addRow(m_btnSelectTile);
    editForm->addRow(m_deleteMode);
    editForm->addRow(tr("海拔值"), m_altitude);
    editForm->addRow(btnUndo, btnRedo);
    editForm->addRow(tr("撤销限制"), m_undoLimitSpin);
    const QList<QWidget *> editWidgets{m_layerCombo, m_tileSourceCombo, m_btnSelectTile,
        m_deleteMode, m_altitude, btnUndo, btnRedo, m_undoLimitSpin};
    for (auto *widget : editWidgets) widget->show();
    addSection(tr("地图编辑"), editContent, true);
    auto *moduleContent = new QWidget;
    auto *moduleLayout = new QVBoxLayout(moduleContent);
    moduleLayout->addWidget(btnImportModule);
    moduleLayout->addWidget(btnExportModule);
    btnImportModule->show(); btnExportModule->show();
    addSection(tr("区域模块"), moduleContent, true);
    backdropGroup->setTitle(QString());
    addSection(tr("大图与遮挡"), backdropGroup, false);
    evtGroup->setTitle(QString());
    m_eventSectionToggle = addSection(tr("事件编辑"), evtGroup, false);
    tileGroup->setTitle(QString());
    tileGroup->setMinimumWidth(0);
    tileGroup->setMaximumWidth(QWIDGETSIZE_MAX);
    addSection(tr("当前位置贴图"), tileGroup, true);
    leftLayout->addStretch();
    leftLayout->addWidget(m_statusBar);
    m_statusBar->show();

    auto *sidebar = new QWidget;
    auto *sidebarScroll = new QScrollArea;
    m_sidebarScroll = sidebarScroll;
    static_cast<QHBoxLayout *>(layout())->removeItem(leftLayout);
    sidebar->setLayout(leftLayout);
    sidebarScroll->setWidget(sidebar);
    sidebarScroll->setWidgetResizable(true);
    sidebarScroll->setMinimumWidth(300);
    sidebarScroll->setMaximumWidth(440);
    static_cast<QHBoxLayout *>(layout())->insertWidget(0, sidebarScroll);

    connect(m_saveCombo, QOverload<int>::of(&QComboBox::currentIndexChanged), this, &SceneMapEdit::onSaveSlotChanged);
    connect(m_sceneCombo, QOverload<int>::of(&QComboBox::currentIndexChanged), this, &SceneMapEdit::onLoadScene);
    connect(m_btnSave, &QPushButton::clicked, this, &SceneMapEdit::onSaveScene);
    connect(btnNew, &QPushButton::clicked, this, &SceneMapEdit::onNewScene);
    connect(btnDel, &QPushButton::clicked, this, &SceneMapEdit::onDeleteScene);
    connect(btnImport, &QPushButton::clicked, this, &SceneMapEdit::onImportScene);
    connect(btnExport, &QPushButton::clicked, this, &SceneMapEdit::onExportScene);
    connect(btnExportImg, &QPushButton::clicked, this, &SceneMapEdit::onExportImage);
    btnUndo->setShortcut(QKeySequence("Ctrl+Z"));
    btnRedo->setShortcut(QKeySequence("Ctrl+Shift+Z"));
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

    if (m_sessionLoaded) {
        syncCurrentScene();
        m_sessions[m_currentSave] = {m_sceneRawData, m_dFile, m_currentScene};
    }
    m_currentSave = saveSlot;
    m_currentScene = -1;
    m_mapData = {};
    m_undoStack.clear();
    m_undoPos = -1;
    m_selectedEventIndex = -1;
    m_mapLabel->clear();
    m_sessionLoaded = true;
    int restoredScene = 0;
    if (m_sessions.contains(saveSlot)) {
        const auto &session = m_sessions[saveSlot];
        m_sceneRawData = session.maps;
        m_dFile = session.events;
        restoredScene = session.scene;
    } else {
    m_invalidSaveSlots.insert(saveSlot);
    QString path = cfg.gamePath + "/" + cfg.sGrp[saveSlot];
    QFile f(path);
    if (!f.open(QIODevice::ReadOnly)) {
        m_sceneRawData.clear();
        m_sceneCount = 0;
        m_sceneCombo->clear();
        m_dFile = {};
        return;
    }
    m_sceneRawData = f.readAll();

    m_dFile.mapNum = 0;
    m_dFile.mapEvent.clear();
    m_invalidSaveSlots.insert(saveSlot);
    if (saveSlot < cfg.dIdx.size() && saveSlot < cfg.dGrp.size()) {
        if (EventIO::readEvents(cfg.gamePath + "/" + cfg.dIdx[saveSlot],
                            cfg.gamePath + "/" + cfg.dGrp[saveSlot], m_dFile)
            && m_sceneRawData.size() % 49152 == 0
            && m_dFile.mapEvent.size() == m_sceneRawData.size() / 49152)
            m_invalidSaveSlots.remove(saveSlot);
    }
    }
    if (!m_savedSessions.contains(saveSlot)) m_savedSessions[saveSlot] = {m_sceneRawData, m_dFile, 0};

    // 每个场景: 64 * 64 * 6 层 * 2 字节 (无文件头, Delphi hardcoded)
    const int sceneStride = 64 * 64 * 6 * 2;
    m_sceneCount = m_sceneRawData.size() / sceneStride;
    int previousCount = m_dFile.mapEvent.size();
    m_dFile.mapEvent.resize(m_sceneCount);
    m_dFile.mapNum = m_sceneCount;
    for (int scene = previousCount; scene < m_sceneCount; ++scene)
        for (auto &event : m_dFile.mapEvent[scene].sceneEvent)
            event.num = event.event1 = event.event2 = event.event3 = -1;
    if (!m_sessions.contains(saveSlot)) m_savedSessions[saveSlot] = {m_sceneRawData, m_dFile, 0};

    m_sceneCombo->blockSignals(true);
    m_sceneCombo->clear();
    const RFile &rFile = cfg.rGlobals.rFile;
    const RType *sceneType = (rFile.rType.size() > 3) ? &rFile.rType[3] : nullptr;
    for (int i = 0; i < m_sceneCount; ++i) {
        QString label = QString::number(i);
        if (sceneType && i < sceneType->rData.size() && sceneType->namePos >= 0
            && sceneType->namePos < sceneType->rData[i].rDataLine.size()) {
            const RDataLine &line = sceneType->rData[i].rDataLine[sceneType->namePos];
            if (!line.rArray.isEmpty() && !line.rArray[0].dataArray.isEmpty()) {
                QString name = Encoding::displayStr(RFileIO::readRDataStr(line.rArray[0].dataArray[0]));
                if (!name.isEmpty())
                    label += name;
            }
        }
        m_sceneCombo->addItem(label);
    }
    m_sceneCombo->blockSignals(false);

    if (m_sceneCount > 0) {
        restoredScene = qBound(0, restoredScene, m_sceneCount - 1);
        m_sceneCombo->setCurrentIndex(restoredScene);
        if (m_currentScene != restoredScene) onLoadScene(restoredScene);
    }
}

void SceneMapEdit::readSceneData(int sceneIndex)
{
    m_currentScene = sceneIndex;
    m_selectedEventIndex = -1;
    m_selectedEventX = -1;
    m_selectedEventY = -1;
    m_hoverIsoX = -1;
    m_hoverIsoY = -1;
    m_selectedRegion = QRect();
    m_selectionStart = QPoint(-1, -1);

    // 从缓存的原始数据中提取指定场景 (64×64, 6 层, 无文件头)
    const int sceneStride = 64 * 64 * 6 * 2;
    int offset = sceneIndex * sceneStride;
    if (offset + sceneStride > m_sceneRawData.size()) return;

    m_mapData.num = 1;
    m_mapData.map.resize(1);
    MapIO::readSingleMap(m_sceneRawData, offset, m_mapData.map[0], 6, 64, 64);

}

int SceneMapEdit::eventIndexAt(int ix, int iy) const
{
    if (m_mapData.map.isEmpty()) return -1;
    const Map &curMap = m_mapData.map[0];
    if (3 >= curMap.mapLayer.size()) return -1;
    if (ix < 0 || iy < 0 || ix >= curMap.x || iy >= curMap.y) return -1;
    const auto &evtLayer = curMap.mapLayer[3];
    if (ix >= evtLayer.pic.size() || iy >= evtLayer.pic[ix].size()) return -1;
    int eventIndex = evtLayer.pic[ix][iy];
    if (eventIndex < 0 || eventIndex >= 200) return -1;
    if (m_currentScene < 0 || m_currentScene >= m_dFile.mapEvent.size()) return -1;
    return eventIndex;
}

QRect SceneMapEdit::eventLabelRect(int ix, int iy, int eventIndex) const
{
    QPoint baseline = isoToScreen(ix, iy) - QPoint(5, tileW());
    return QFontMetrics(QFont("Arial", 8)).boundingRect(QString("[%1]").arg(eventIndex))
        .translated(baseline).adjusted(-3, -3, 3, 3);
}

void SceneMapEdit::loadEventToEditor(int eventIndex, int ix, int iy)
{
    if (m_currentScene < 0 || m_currentScene >= m_dFile.mapEvent.size()) return;
    if (eventIndex < 0 || eventIndex >= 200) return;

    const SceneEvent &evt = m_dFile.mapEvent[m_currentScene].sceneEvent[eventIndex];
    m_selectedEventIndex = eventIndex;
    m_selectedEventX = ix;
    m_selectedEventY = iy;
    m_evtCanWalk->setText(QString::number(evt.canWalk));
    m_evtIndex->setText(QString::number(evt.num));
    m_evtEvent1->setText(QString::number(evt.event1));
    m_evtEvent2->setText(QString::number(evt.event2));
    m_evtEvent3->setText(QString::number(evt.event3));
    m_evtBeginPic->setText(QString::number(evt.beginPic1));
    m_evtBeginPic2->setText(QString::number(evt.beginPic2));
    m_evtEndPic->setText(QString::number(evt.endPic));
    m_evtAnim->setText(QString::number(evt.picDelay));
    m_evtX->setText(QString::number(evt.xPos));
    m_evtY->setText(QString::number(evt.yPos));
    if (m_eventSectionToggle) m_eventSectionToggle->setChecked(true);
    if (m_sidebarScroll) m_sidebarScroll->ensureWidgetVisible(m_evtEvent1);
}

int SceneMapEdit::displayedEventPic(const SceneEvent &evt) const
{
    return evt.beginPic1;
}

void SceneMapEdit::readSceneGrp()
{
    IniConfig &cfg = IniConfig::instance();
    int source = m_tileSourceCombo->currentIndex();
    if ((source == 0 || source == 2) && !cfg.smapImz.isEmpty()
        && MapIO::loadPngTiles(cfg.gamePath + cfg.smapImz, m_grpPics, m_tileCache)) return;
    if ((source == 0 || source == 3) && !cfg.smapPNGPath.isEmpty()
        && MapIO::loadPngTiles(cfg.gamePath + cfg.smapPNGPath, m_grpPics, m_tileCache)) return;
    if (source == 2 || source == 3) { QMessageBox::warning(this, tr("贴图"), tr("PNG贴图读取失败")); return; }
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
    syncCurrentScene();
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
    m_renderCenterY = pad;
    if (backdropActive()) {
        imgW = qMax(imgW, m_backdropX->value() + m_backdrop.width());
        imgH = qMax(imgH, m_backdropY->value() + m_backdrop.height());
        if (qint64(imgW) * imgH > 32000000) return;
    }

    m_mapImage = QImage(imgW, imgH, QImage::Format_ARGB32);
    m_mapImage.fill(m_exporting ? Qt::transparent : Qt::black);
    QPainter p(&m_mapImage);
    const bool backdrop = backdropActive();
    if (backdrop) p.drawImage(m_backdropX->value(), m_backdropY->value(), m_backdrop);

    int layer = m_layerCombo->currentIndex();
    // 层: 0=地面, 1=建筑, 2=空中, 3=事件, 4=海拔, 5=全部
    bool showGround   = (layer == 5 || layer == 0);
    bool showBuilding = (layer == 5 || layer == 1);
    bool showSky      = (layer == 5 || layer == 2);
    bool showEvent    = (layer == 5 || layer == 3);
    if (m_exporting) {
        showGround = (m_exportLayers & 1) != 0;
        showBuilding = (m_exportLayers & 2) != 0;
        showSky = (m_exportLayers & 4) != 0;
        showEvent = (m_exportLayers & 8) != 0;
    }
    if (backdrop) showGround = showBuilding = showSky = false;

    // 获取事件数据
    const MapEvent *evts = nullptr;
    if (m_currentScene >= 0 && m_currentScene < m_dFile.mapEvent.size())
        evts = &m_dFile.mapEvent[m_currentScene];

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
        if (evtIdx < 0 || !evts || evtIdx >= 200) return;
        int tileId = displayedEventPic(evts->sceneEvent[evtIdx]) / 2;
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
        if (backdrop) drawBackdropSprite(p, tile, QPoint(sp.x() - xoff, sp.y() - yoff - elev),
            backdropDepth(ix, iy, mapW, mapH));
        else p.drawImage(sp.x() - xoff, sp.y() - yoff - elev, tile);
    };

    auto drawActor = [&](int actorX, int actorY) {
        if (!backdrop || m_exporting || !m_actorVisible->isChecked()
            || actorX != m_actorX->value() || actorY != m_actorY->value()) return;
        const int tile = 2501;
        if (tile >= m_tileCache.size()) return;
        QPoint position = isoToScreen(actorX, actorY);
        if (curMap.mapLayer.size() > 4) position.ry() -= curMap.mapLayer[4].pic[actorX][actorY];
        if (tile < m_grpPics.size()) position -= QPoint(m_grpPics[tile].xoff, m_grpPics[tile].yoff);
        drawBackdropSprite(p, m_tileCache[tile], position, backdropDepth(actorX, actorY, mapW, mapH));
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
            drawActor(ix, iy);
        }
        // 列扫描: ix = i, iy from i+1 to mapH-1
        for (int iy = i + 1; iy < mapH; ++iy) {
            int ix = i;
            QPoint sp = isoToScreen(ix, iy);
            if (showGround)   drawOneTile(0, ix, iy, sp, -1);
            if (showBuilding) drawOneTile(1, ix, iy, sp, 4);
            if (showSky)      drawOneTile(2, ix, iy, sp, 5);
            if (showEvent)    drawEventTile(ix, iy, sp);
            drawActor(ix, iy);
        }
    }

    if (backdrop && !m_exporting && m_backdropOverlay->isChecked()) {
        QImage overlay(m_backdrop.size(), QImage::Format_ARGB32);
        overlay.fill(Qt::transparent);
        for (int row = 0; row < overlay.height(); ++row) {
            auto *pixels = reinterpret_cast<QRgb *>(overlay.scanLine(row));
            for (int column = 0; column < overlay.width(); ++column)
                if (m_backdropDepth[row * overlay.width() + column] >= 0) pixels[column] = qRgba(230, 40, 80, 100);
        }
        p.drawImage(m_backdropX->value(), m_backdropY->value(), overlay);
    }

    // 事件标签 (所有图层绘制完后单独遍历, 匹配 Delphi TextOut)
    if (!m_exporting && showEvent && 3 < curMap.mapLayer.size()) {
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

    if (!m_exporting) {
        drawRegionOutline(p, m_selectedRegion, Qt::yellow);
        if (m_selectionStart.x() >= 0 && m_hoverIsoX >= 0)
            drawRegionOutline(p, QRect(m_selectionStart, QPoint(m_hoverIsoX, m_hoverIsoY)).normalized()
                .intersected(QRect(0, 0, mapW, mapH)), Qt::yellow);
    }
    if (!m_exporting && m_hoverIsoX >= 0 && m_hoverIsoY >= 0)
        drawSelection(p, m_hoverIsoX, m_hoverIsoY);
    if (!m_exporting && !pastePreviewBounds().isEmpty()) {
        const QPoint origin(m_hoverIsoX - m_moduleMap.x + 1, m_hoverIsoY - m_moduleMap.y + 1);
        const int selectedLayer = m_layerCombo->currentIndex();
        p.setOpacity(0.65);
        for (int column = 0; column < m_moduleMap.x; ++column)
            for (int row = 0; row < m_moduleMap.y; ++row) {
                const QPoint target = origin + QPoint(column, row);
                if (target.x() < 0 || target.y() < 0 || target.x() >= mapW || target.y() >= mapH) continue;
                for (int ly = 0; ly < 4; ++ly) {
                    if (selectedLayer != 5 && ly != selectedLayer) continue;
                    int tile = m_moduleMap.mapLayer[ly].pic[column][row] / 2;
                    if (ly == 3) {
                        const int reference = m_moduleMap.mapLayer[3].pic[column][row];
                        if (!m_moduleEvents.contains(reference)) continue;
                        tile = displayedEventPic(m_moduleEvents[reference]) / 2;
                    }
                    if (tile < 0 || (ly > 0 && tile == 0) || tile >= m_tileCache.size()) continue;
                    QPoint position = isoToScreen(target.x(), target.y());
                    if (tile < m_grpPics.size()) position -= QPoint(m_grpPics[tile].xoff, m_grpPics[tile].yoff);
                    if (ly > 0) position.ry() -= m_moduleMap.mapLayer[ly == 2 ? 5 : 4].pic[column][row];
                    p.drawImage(position, m_tileCache[tile]);
                }
            }
        p.setOpacity(1);
        drawRegionOutline(p, pastePreviewBounds(), Qt::green);
    }

    m_backdropDepthInfo->setText(tr("像素：—\n深度：—\n落点：—"));
    if (backdrop) {
        const QPoint pixel = m_backdropCursor - QPoint(m_backdropX->value(), m_backdropY->value());
        if (m_backdrop.rect().contains(pixel)) {
            const int depth = m_backdropDepth[pixel.y() * m_backdrop.width() + pixel.x()];
            QString value = tr("像素 (%1, %2)\n深度 %3").arg(pixel.x()).arg(pixel.y()).arg(depth);
            if (depth < 0) value += tr("（无遮挡）\n落点：—");
            else {
                QString anchor = tr("—");
                for (int column = 0; column < mapW; ++column)
                    for (int row = 0; row < mapH; ++row)
                        if (backdropDepth(column, row, mapW, mapH) == depth)
                            anchor = QString("(%1, %2)").arg(column).arg(row);
                value += tr("\n落点 %1").arg(anchor);
            }
            m_backdropDepthInfo->setText(value);
            m_backdropDepthInfo->setToolTip(value);
        }
    }

    m_mapLabel->setPixmap(QPixmap::fromImage(m_mapImage));
    m_mapLabel->resize(m_mapImage.size());
}

void SceneMapEdit::onTileClicked(int ix, int iy, Qt::MouseButton btn)
{
    const int selectedLayer = m_layerCombo->currentIndex();
    if (btn == Qt::LeftButton && !m_deleteMode->isChecked()
        && (selectedLayer == 3 || selectedLayer == 5)) {
        int eventIndex = eventIndexAt(ix, iy);
        if (eventIndex >= 0) {
            m_selectionStart = QPoint(-1, -1);
            loadEventToEditor(eventIndex, ix, iy);
            renderMap();
            return;
        }
    }
    int layer = m_layerCombo->currentIndex();
    if (layer >= 0 && layer <= 2 && !m_mapData.map.isEmpty()) {
        if (btn == Qt::LeftButton) m_selectionStart = QPoint(ix, iy);
        if (btn == Qt::RightButton && m_moduleMap.layerNum == 6) {
            if (pasteModule(QPoint(ix, iy))) { addUndoSave(); renderMap(); }
            return;
        }
    }
    if (layer == 4 || layer == 6) {
        if (btn == Qt::LeftButton || btn == Qt::RightButton) m_selectionStart = QPoint(ix, iy);
        return;
    }
    if (layer == 5 && !m_mapData.map.isEmpty()) {
        if (btn == Qt::LeftButton) m_selectionStart = QPoint(ix, iy);
        if (btn == Qt::RightButton && m_moduleMap.layerNum > 0) {
            if (pasteModule(QPoint(ix, iy))) { addUndoSave(); renderMap(); }
        }
        return;
    }
    if (layer == 3) {
        if (m_mapData.map.isEmpty() || ix < 0 || iy < 0 || ix >= m_mapData.map[0].x || iy >= m_mapData.map[0].y
            || m_currentScene < 0 || m_currentScene >= m_dFile.mapEvent.size()) return;
        int eventIndex = eventIndexAt(ix, iy);
        auto &events = m_dFile.mapEvent[m_currentScene].sceneEvent;
        auto &eventLayer = m_mapData.map[0].mapLayer[3];
        if (m_deleteMode->isChecked()) {
            eventLayer.pic[ix][iy] = -1;
            m_selectedEventIndex = -1;
            addUndoSave();
            renderMap();
            return;
        }
        if (eventIndex < 0) {
            if (btn != Qt::RightButton) return;
            QSet<int> used;
            for (const auto &column : eventLayer.pic) for (int reference : column) if (reference >= 0) used.insert(reference);
            for (int candidate = 0; candidate < 200; ++candidate)
                if (!used.contains(candidate) && events[candidate].num < 0
                    && events[candidate].event1 < 0 && events[candidate].event2 < 0 && events[candidate].event3 < 0) {
                    eventIndex = candidate;
                    break;
                }
            if (eventIndex < 0) { QMessageBox::warning(this, tr("事件"), tr("没有可用事件编号")); return; }
            events[eventIndex] = {};
            events[eventIndex].num = eventIndex;
            events[eventIndex].event1 = events[eventIndex].event2 = events[eventIndex].event3 = -1;
            events[eventIndex].xPos = ix;
            events[eventIndex].yPos = iy;
            eventLayer.pic[ix][iy] = eventIndex;
            addUndoSave();
            renderMap();
        }
        loadEventToEditor(eventIndex, ix, iy);
        return;
    }

    if (m_mapData.map.isEmpty()) return;
    Map &curMap = m_mapData.map[0];
    if (layer == 6) layer = 5;
    if (layer < 0 || layer >= curMap.mapLayer.size()) return;
    if (ix < 0 || ix >= curMap.x || iy < 0 || iy >= curMap.y) return;

    if (m_deleteMode->isChecked()) {
        curMap.mapLayer[layer].pic[ix][iy] = 0;
    } else if (layer == 4 || layer == 5) {
        curMap.mapLayer[layer].pic[ix][iy] = m_altitude->value();
    } else if (m_selectedTileId >= 0 && btn == Qt::LeftButton) {
        curMap.mapLayer[layer].pic[ix][iy] = m_selectedTileId * 2;
    }
    addUndoSave();
    renderMap();
}

void SceneMapEdit::onEventConfirm()
{
    if (m_currentScene < 0 || m_currentScene >= m_dFile.mapEvent.size()) return;
    if (m_mapData.map.isEmpty()) return;

    Map &curMap = m_mapData.map[0];
    if (3 >= curMap.mapLayer.size()) return;

    int eventIndex = m_selectedEventIndex;
    if (eventIndex < 0 && m_selectedEventX >= 0 && m_selectedEventY >= 0)
        eventIndex = eventIndexAt(m_selectedEventX, m_selectedEventY);
    if (eventIndex < 0 || eventIndex >= 200) return;

    QVector<int> values;
    for (auto *input : {m_evtCanWalk, m_evtIndex, m_evtEvent1, m_evtEvent2, m_evtEvent3,
                       m_evtBeginPic, m_evtBeginPic2, m_evtEndPic, m_evtAnim, m_evtX, m_evtY}) {
        bool valid = false;
        int value = input->text().toInt(&valid);
        if (!valid || value < -32768 || value > 32767) {
            QMessageBox::warning(this, tr("事件"), tr("事件字段必须是 -32768 到 32767 的整数"));
            input->setFocus();
            return;
        }
        values.append(value);
    }
    int newX = values[9];
    int newY = values[10];
    if (newX < 0 || newY < 0 || newX >= curMap.x || newY >= curMap.y) {
        QMessageBox::warning(this, tr("事件"), tr("事件坐标超出地图范围")); return;
    }
    int occupied = eventIndexAt(newX, newY);
    if (occupied >= 0 && occupied != eventIndex) {
        QMessageBox::warning(this, tr("事件"), tr("目标位置已有其他事件")); return;
    }
    bool oldValid = m_selectedEventX >= 0 && m_selectedEventY >= 0
        && m_selectedEventX < curMap.x && m_selectedEventY < curMap.y;
    bool newValid = newX >= 0 && newY >= 0 && newX < curMap.x && newY < curMap.y;
    if (!oldValid && !newValid) return;

    auto &evtLayer = curMap.mapLayer[3];
    if (oldValid && m_selectedEventX < evtLayer.pic.size() && m_selectedEventY < evtLayer.pic[m_selectedEventX].size()
        && evtLayer.pic[m_selectedEventX][m_selectedEventY] == eventIndex) {
        evtLayer.pic[m_selectedEventX][m_selectedEventY] = -1;
    }

    if (newValid) {
        if (newX < evtLayer.pic.size() && newY < evtLayer.pic[newX].size())
            evtLayer.pic[newX][newY] = eventIndex;

        SceneEvent &evt = m_dFile.mapEvent[m_currentScene].sceneEvent[eventIndex];
        evt.canWalk = m_evtCanWalk->text().toShort();
        evt.num = m_evtIndex->text().toShort();
        evt.event1 = m_evtEvent1->text().toShort();
        evt.event2 = m_evtEvent2->text().toShort();
        evt.event3 = m_evtEvent3->text().toShort();
        evt.beginPic1 = m_evtBeginPic->text().toShort();
        evt.beginPic2 = m_evtBeginPic2->text().toShort();
        evt.endPic = m_evtEndPic->text().toShort();
        evt.picDelay = m_evtAnim->text().toShort();
        evt.xPos = newX;
        evt.yPos = newY;
        loadEventToEditor(eventIndex, newX, newY);
        addUndoSave();
        renderMap();
        updateTilePreview(m_hoverIsoX, m_hoverIsoY);
    }
}

void SceneMapEdit::addUndoSave()
{
    if (m_undoPos < (int)m_undoStack.size() - 1)
        m_undoStack.resize(m_undoPos + 1);

    UndoState state;
    state.mapData = m_mapData;
    if (m_currentScene >= 0 && m_currentScene < m_dFile.mapEvent.size()) {
        state.events.resize(200);
        for (int i = 0; i < 200; ++i)
            state.events[i] = m_dFile.mapEvent[m_currentScene].sceneEvent[i];
    }
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
    if (m_currentScene >= 0 && m_currentScene < m_dFile.mapEvent.size()) {
        for (int i = 0; i < m_undoStack[m_undoPos].events.size() && i < 200; ++i)
            m_dFile.mapEvent[m_currentScene].sceneEvent[i] = m_undoStack[m_undoPos].events[i];
    }
    renderMap();
}

void SceneMapEdit::onRedo()
{
    if (m_undoPos >= m_undoStack.size() - 1) return;
    m_undoPos++;
    m_mapData = m_undoStack[m_undoPos].mapData;
    if (m_currentScene >= 0 && m_currentScene < m_dFile.mapEvent.size()) {
        for (int i = 0; i < m_undoStack[m_undoPos].events.size() && i < 200; ++i)
            m_dFile.mapEvent[m_currentScene].sceneEvent[i] = m_undoStack[m_undoPos].events[i];
    }
    renderMap();
}

void SceneMapEdit::onSaveScene()
{
    IniConfig &cfg = IniConfig::instance();
    if (m_invalidSaveSlots.contains(m_currentSave)) {
        QMessageBox::warning(this, tr("保存"), tr("场景或事件文件读取不完整，禁止保存以保护原数据"));
        return;
    }
    if (m_currentScene < 0 && m_sceneCount > 0) return;

    const int stride = 64 * 64 * 6 * 2;
    if (m_sceneCount > 0 && (m_currentScene >= m_sceneCount || m_mapData.map.isEmpty()
        || m_sceneRawData.size() < m_sceneCount * stride)
        ) return;

    // Update only the selected scene in the raw fixed-size scene stream.
    syncCurrentScene();

    if (m_currentSave >= cfg.sIdx.size() || m_currentSave >= cfg.sGrp.size()) return;
    QString idxPath = cfg.gamePath + "/" + cfg.sIdx[m_currentSave];
    QString grpPath = cfg.gamePath + "/" + cfg.sGrp[m_currentSave];
    QByteArray idxData(m_sceneCount * 4, '\0');
    uint32_t *offsets = reinterpret_cast<uint32_t *>(idxData.data());
    for (int i = 0; i < m_sceneCount; ++i)
        offsets[i] = static_cast<uint32_t>((i + 1) * stride);
    if (m_currentSave >= cfg.dIdx.size() || m_currentSave >= cfg.dGrp.size()
        || m_dFile.mapEvent.size() < m_sceneCount) {
        QMessageBox::warning(this, tr("保存"), tr("事件数据或保存路径不完整，未写入任何文件")); return;
    }
    QByteArray eventData, eventIndex(m_sceneCount * 4, '\0');
    for (int scene = 0; scene < m_sceneCount; ++scene) {
        eventData.append(reinterpret_cast<const char *>(m_dFile.mapEvent[scene].sceneEvent), 200 * sizeof(SceneEvent));
        qToLittleEndian<quint32>(eventData.size(), eventIndex.data() + scene * 4);
    }
    QMap<QString, QByteArray> writes = {{grpPath, m_sceneRawData},
        {cfg.gamePath + "/" + cfg.dGrp[m_currentSave], eventData}};
    if (cfg.sIdx.count(cfg.sIdx[m_currentSave]) == 1) writes.insert(idxPath, idxData);
    if (cfg.dIdx.count(cfg.dIdx[m_currentSave]) == 1)
        writes.insert(cfg.gamePath + "/" + cfg.dIdx[m_currentSave], eventIndex);
    if (!FileIO::writeFiles(writes)) {
        QMessageBox::warning(this, tr("保存"), tr("场景保存失败；请保留目录内 .upedit-old-* 备份")); return;
    }
    QMessageBox::information(this, tr("保存"), tr("场景保存成功"));
    m_savedSessions[m_currentSave] = {m_sceneRawData, m_dFile, m_currentScene};
}

bool SceneMapEdit::hasUnsavedChanges()
{
    if (m_sessionLoaded) {
        syncCurrentScene();
        m_sessions[m_currentSave] = {m_sceneRawData, m_dFile, m_currentScene};
    }
    for (auto entry = m_sessions.constBegin(); entry != m_sessions.constEnd(); ++entry) {
        if (!m_savedSessions.contains(entry.key())) return true;
        const auto &saved = m_savedSessions[entry.key()];
        const auto &current = entry.value();
        if (saved.maps != current.maps || saved.events.mapEvent.size() != current.events.mapEvent.size()) return true;
        for (int scene = 0; scene < saved.events.mapEvent.size(); ++scene)
            if (std::memcmp(saved.events.mapEvent[scene].sceneEvent, current.events.mapEvent[scene].sceneEvent,
                            sizeof(MapEvent)) != 0) return true;
    }
    return false;
}

void SceneMapEdit::closeEvent(QCloseEvent *event)
{
    if (!confirmBackdropDiscard()) { event->ignore(); return; }
    if (hasUnsavedChanges() && QMessageBox::warning(this, tr("未保存的场景"), tr("存在未保存的进度，确定放弃修改并关闭？"),
        QMessageBox::Discard | QMessageBox::Cancel, QMessageBox::Cancel) != QMessageBox::Discard) {
        event->ignore(); return;
    }
    event->accept();
}

void SceneMapEdit::onNewScene()
{
    if (m_sceneCount <= 0 || m_sceneRawData.size() < 64 * 64 * 6 * 2) return;
    const int stride = 64 * 64 * 6 * 2;
    int source = m_currentScene >= 0 ? m_currentScene : 0;
    syncCurrentScene();
    m_sceneRawData.append(m_sceneRawData.mid(source * stride, stride));
    if (source < m_dFile.mapEvent.size()) {
        MapEvent copied = m_dFile.mapEvent[source];
        m_dFile.mapEvent.resize(m_sceneCount + 1);
        m_dFile.mapEvent[m_sceneCount] = copied;
    } else {
        m_dFile.mapEvent.resize(m_sceneCount + 1);
        for (auto &event : m_dFile.mapEvent[m_sceneCount].sceneEvent) {
            event.num = -1;
            event.event1 = event.event2 = event.event3 = -1;
        }
    }
    m_dFile.mapNum = m_dFile.mapEvent.size();
    ++m_sceneCount;
    m_sceneCombo->addItem(QString::number(m_sceneCount - 1));
    m_sceneCombo->setCurrentIndex(m_sceneCount - 1);
    onLoadScene(m_sceneCount - 1);
}

void SceneMapEdit::onDeleteScene()
{
    if (m_currentScene < 0 || m_currentScene >= m_sceneCount) return;
    if (QMessageBox::question(this, tr("删除场景"), tr("删除最后一个场景？")) != QMessageBox::Yes) return;
    syncCurrentScene();
    const int stride = 64 * 64 * 6 * 2;
    int removed = m_sceneCount - 1;
    m_sceneRawData.remove(removed * stride, stride);
    if (removed < m_dFile.mapEvent.size())
        m_dFile.mapEvent.remove(removed);
    m_dFile.mapNum = m_dFile.mapEvent.size();
    --m_sceneCount;
    m_currentScene = -1;
    m_sceneCombo->blockSignals(true);
    m_sceneCombo->removeItem(removed);
    m_sceneCombo->blockSignals(false);
    if (m_sceneCount > 0) {
        int next = m_sceneCount - 1;
        m_sceneCombo->setCurrentIndex(next);
        onLoadScene(next);
    } else {
        m_currentScene = -1;
        m_mapData = {};
    }
}

void SceneMapEdit::onImportScene()
{
    QString f = QFileDialog::getOpenFileName(this, tr("导入场景"), {}, "Map files (*.map);;All Files (*)");
    if (f.isEmpty()) return;
    QByteArray data = FileIO::readFileAll(f);
    const int stride = 64 * 64 * 6 * 2;
    if (data.size() != stride) {
        QMessageBox::warning(this, tr("导入"), tr("场景文件大小不正确"));
        return;
    }
    if (m_currentScene < 0) return;
    m_sceneRawData.replace(m_currentScene * stride, stride, data);
    if (m_currentScene < m_dFile.mapEvent.size()) {
        MapEvent emptyEvent{};
        for (auto &event : emptyEvent.sceneEvent) {
            event.num = -1;
            event.event1 = event.event2 = event.event3 = -1;
        }
        m_dFile.mapEvent[m_currentScene] = emptyEvent;
    }
    readSceneData(m_currentScene);
    if (!m_mapData.map.isEmpty()) {
        for (auto &column : m_mapData.map[0].mapLayer[3].pic) column.fill(-1);
        syncCurrentScene();
    }
    addUndoSave();
    renderMap();
}

void SceneMapEdit::onExportScene()
{
    syncCurrentScene();
    QString f = QFileDialog::getSaveFileName(this, tr("导出场景"), {}, "Map files (*.map);;All Files (*)");
    if (f.isEmpty()) return;
    if (!f.endsWith(".map", Qt::CaseInsensitive)) f += ".map";
    const int stride = 64 * 64 * 6 * 2;
    if (m_currentScene < 0 || (m_currentScene + 1) * stride > m_sceneRawData.size()) return;
    if (!FileIO::writeFileAll(f, m_sceneRawData.mid(m_currentScene * stride, stride)))
        QMessageBox::warning(this, tr("导出"), tr("无法写入场景文件"));
}

void SceneMapEdit::onExportImage()
{
    if (m_mapData.map.isEmpty()) return;
    QDialog dialog(this);
    dialog.setWindowTitle(tr("导出图层"));
    QVBoxLayout layout(&dialog);
    QCheckBox ground(tr("地面")), building(tr("建筑")), sky(tr("空中")), events(tr("事件"));
    for (QCheckBox *check : {&ground, &building, &sky, &events}) { check->setChecked(true); layout.addWidget(check); }
    QDialogButtonBox buttons(QDialogButtonBox::Ok | QDialogButtonBox::Cancel);
    layout.addWidget(&buttons);
    connect(&buttons, &QDialogButtonBox::accepted, &dialog, &QDialog::accept);
    connect(&buttons, &QDialogButtonBox::rejected, &dialog, &QDialog::reject);
    if (dialog.exec() != QDialog::Accepted) return;
    QString f = QFileDialog::getSaveFileName(this, tr("导出图片"), {}, "PNG (*.png);;BMP (*.bmp)");
    if (f.isEmpty()) return;
    m_exportLayers = (ground.isChecked() ? 1 : 0) | (building.isChecked() ? 2 : 0)
        | (sky.isChecked() ? 4 : 0) | (events.isChecked() ? 8 : 0);
    m_exporting = true;
    renderMap();
    QImage image = m_mapImage;
    m_exporting = false;
    renderMap();
    if (f.endsWith(".bmp", Qt::CaseInsensitive)) {
        QImage opaque(image.size(), QImage::Format_RGB32);
        opaque.fill(Qt::black);
        QPainter painter(&opaque);
        painter.drawImage(0, 0, image);
        painter.end();
        image = opaque;
    }
    QSaveFile output(f);
    QByteArray format = QFileInfo(f).suffix().toLatin1();
    if (!output.open(QIODevice::WriteOnly) || !image.save(&output, format.constData()) || !output.commit())
        QMessageBox::warning(this, tr("导出"), tr("图片写入失败"));
}

void SceneMapEdit::handleMouseMove(QMouseEvent *event)
{
    m_backdropCursor = event->pos();
    QPoint iso = screenToIso(event->pos().x(), event->pos().y());
    m_statusBar->showMessage(QString("(%1, %2)").arg(iso.x()).arg(iso.y()));
    if (!m_mapData.map.isEmpty() && iso.x() >= 0 && iso.y() >= 0
        && iso.x() < m_mapData.map[0].x && iso.y() < m_mapData.map[0].y) {
        m_hoverIsoX = iso.x();
        m_hoverIsoY = iso.y();
    } else {
        m_hoverIsoX = -1;
        m_hoverIsoY = -1;
    }
    updateTilePreview(iso.x(), iso.y());
    if (backdropActive() && m_actorVisible->isChecked() && m_hoverIsoX >= 0 && m_hoverIsoY >= 0) {
        const QSignalBlocker blockX(m_actorX);
        const QSignalBlocker blockY(m_actorY);
        m_actorX->setValue(m_hoverIsoX);
        m_actorY->setValue(m_hoverIsoY);
    }
    if (backdropActive() && m_backdropTool->currentIndex() != 0) {
        int tool = m_backdropTool->currentIndex();
        if ((tool == 2 || tool == 3) && (event->buttons() & (Qt::LeftButton | Qt::RightButton)))
            paintBackdrop(event->pos(), tool == 3 || event->buttons().testFlag(Qt::RightButton));
        else
            renderMap();
        return;
    }
    renderMap();
}

void SceneMapEdit::syncCurrentScene()
{
    const int stride = 64 * 64 * 6 * 2;
    if (m_currentScene < 0 || m_mapData.map.isEmpty()
        || (m_currentScene + 1) * stride > m_sceneRawData.size()) return;
    m_sceneRawData.replace(m_currentScene * stride, stride, MapIO::encodeMap(m_mapData.map[0]));
}

void SceneMapEdit::handleMouseRelease(QMouseEvent *event)
{
    if (backdropActive() && m_backdropTool->currentIndex() != 0) {
        if (m_backdropTool->currentIndex() == 2 || m_backdropTool->currentIndex() == 3) {
            m_backdropHistory.resize(m_backdropHistoryPos + 1);
            m_backdropHistory.append(m_backdropDepth);
            const int historyLimit = qMax(2, qMin(8, int(128 * 1024 * 1024 / qMax(qint64(1), qint64(m_backdropDepth.size()) * 4))));
            while (m_backdropHistory.size() > historyLimit) m_backdropHistory.removeFirst();
            m_backdropHistoryPos = m_backdropHistory.size() - 1;
        }
        return;
    }
    if (m_selectionStart.x() < 0 || m_mapData.map.isEmpty()) return;
    int layer = m_layerCombo->currentIndex();
    if (event->button() != Qt::LeftButton && !(event->button() == Qt::RightButton && (layer == 4 || layer == 6))) return;
    QPoint end = screenToIso(event->pos().x(), event->pos().y());
    QPoint first(qMin(m_selectionStart.x(), end.x()), qMin(m_selectionStart.y(), end.y()));
    QPoint last(qMax(m_selectionStart.x(), end.x()), qMax(m_selectionStart.y(), end.y()));
    QRect bounds = QRect(first, last).intersected(QRect(0, 0, 64, 64));
    if (bounds.isEmpty()) { m_selectionStart = QPoint(-1, -1); return; }
    m_selectedRegion = bounds;
    if (layer <= 2 && bounds.size() == QSize(1, 1)) {
        m_selectionStart = QPoint(-1, -1);
        renderMap();
        return;
    }
    if (layer == 4 || layer == 6) {
        if (end == m_selectionStart) {
            auto &height = m_mapData.map[0].mapLayer[layer == 4 ? 4 : 5].pic[first.x()][first.y()];
            int value = int(height) + (event->button() == Qt::LeftButton ? 1 : -1);
            if (value >= -32768 && value <= 32767) {
                height = value;
                m_altitude->setValue(value);
                addUndoSave();
            }
            m_selectionStart = QPoint(-1, -1);
            renderMap();
            return;
        }
        for (int column = bounds.left(); column <= bounds.right(); ++column)
            for (int row = bounds.top(); row <= bounds.bottom(); ++row)
                m_mapData.map[0].mapLayer[layer == 4 ? 4 : 5].pic[column][row] = m_altitude->value();
        addUndoSave();
        m_selectionStart = QPoint(-1, -1);
        renderMap();
        return;
    }
    m_moduleMap = MapIO::extractRegion(m_mapData.map[0], bounds);
    if (layer <= 2) m_selectedTileId = -1;
    m_moduleEvents.clear();
    if (m_currentScene >= 0 && m_currentScene < m_dFile.mapEvent.size())
        for (const auto &column : m_moduleMap.mapLayer[3].pic)
            for (int reference : column)
                if (reference >= 0 && reference < 200 && !m_moduleEvents.contains(reference)) {
                    SceneEvent event = m_dFile.mapEvent[m_currentScene].sceneEvent[reference];
                    event.xPos -= bounds.left();
                    event.yPos -= bounds.top();
                    m_moduleEvents.insert(reference, event);
                }
    m_selectionStart = QPoint(-1, -1);
    renderMap();
    m_statusBar->showMessage(tr("已复制模块 %1 x %2，右键粘贴").arg(m_moduleMap.x).arg(m_moduleMap.y));
}

QRect SceneMapEdit::pastePreviewBounds() const
{
    const int layer = m_layerCombo->currentIndex();
    if (m_mapData.map.isEmpty() || m_moduleMap.layerNum != 6 || m_moduleMap.x <= 0 || m_moduleMap.y <= 0
        || m_hoverIsoX < 0 || m_hoverIsoY < 0 || m_selectionStart.x() >= 0
        || (layer != 5 && (layer < 0 || layer > 2))
        || (backdropActive() && m_backdropTool->currentIndex() != 0)) return QRect();
    return QRect(QPoint(m_hoverIsoX - m_moduleMap.x + 1, m_hoverIsoY - m_moduleMap.y + 1),
        QSize(m_moduleMap.x, m_moduleMap.y)).intersected(QRect(0, 0, m_mapData.map[0].x, m_mapData.map[0].y));
}

void SceneMapEdit::drawRegionOutline(QPainter &painter, const QRect &bounds, const QColor &color)
{
    if (bounds.isEmpty()) return;
    QPolygon outline;
    outline << isoToScreen(bounds.left(), bounds.top()) - QPoint(0, 2 * tileH())
        << isoToScreen(bounds.right(), bounds.top()) + QPoint(tileW(), -tileH())
        << isoToScreen(bounds.right(), bounds.bottom())
        << isoToScreen(bounds.left(), bounds.bottom()) - QPoint(tileW(), tileH());
    painter.setPen(QPen(color, 2));
    painter.setBrush(Qt::NoBrush);
    painter.drawPolygon(outline);
}

void SceneMapEdit::onImportModule()
{
    QString path = QFileDialog::getOpenFileName(this, tr("导入场景模块"), {}, "Scene Module (*.smd)");
    if (path.isEmpty()) return;
    Map module;
    if (!MapIO::decodeModule(FileIO::readFileAll(path), 6, module, 64)) {
        QMessageBox::warning(this, tr("导入"), tr("场景模块格式不正确"));
        return;
    }
    QMap<int, SceneEvent> moduleEvents;
    QFile eventFile(path + ".events");
    if (eventFile.exists()) {
        if (!eventFile.open(QIODevice::ReadOnly)) { QMessageBox::warning(this, tr("导入"), tr("事件文件无法读取")); return; }
        if (eventFile.size() > 64 * 64 * 6 * 2 + 6000) { QMessageBox::warning(this, tr("导入"), tr("事件文件过大")); return; }
        QDataStream stream(&eventFile);
        stream.setByteOrder(QDataStream::LittleEndian);
        QByteArray mapBytes;
        quint32 count = 0;
        stream >> mapBytes >> count;
        if (mapBytes != MapIO::encodeMap(module, true) || count > 200) {
            QMessageBox::warning(this, tr("导入"), tr("事件文件与模块不匹配")); return;
        }
        for (quint32 index = 0; index < count; ++index) {
            qint16 reference;
            SceneEvent event;
            stream >> reference >> event.canWalk >> event.num >> event.event1 >> event.event2 >> event.event3
                >> event.beginPic1 >> event.endPic >> event.beginPic2 >> event.picDelay >> event.xPos >> event.yPos;
            if (stream.status() != QDataStream::Ok || reference < 0 || reference >= 200 || moduleEvents.contains(reference)) {
                QMessageBox::warning(this, tr("导入"), tr("事件文件损坏")); return;
            }
            moduleEvents.insert(reference, event);
        }
        if (stream.status() != QDataStream::Ok || !stream.atEnd()) {
            QMessageBox::warning(this, tr("导入"), tr("事件文件损坏")); return;
        }
        for (const auto &column : module.mapLayer[3].pic)
            for (int reference : column)
                if (reference < -1 || reference >= 200 || (reference >= 0 && !moduleEvents.contains(reference))) {
                    QMessageBox::warning(this, tr("导入"), tr("模块包含未定义的事件引用")); return;
                }
    } else {
        for (auto &column : module.mapLayer[3].pic) column.fill(-1);
        QMessageBox::information(this, tr("导入"), tr("旧版模块不含事件定义，已跳过事件层"));
    }
    m_moduleMap = module;
    m_moduleEvents = moduleEvents;
    m_layerCombo->setCurrentIndex(5);
    m_statusBar->showMessage(tr("模块已载入，右键粘贴"));
}

void SceneMapEdit::onExportModule()
{
    if (m_moduleMap.layerNum == 0) {
        QMessageBox::information(this, tr("导出"), tr("请在全部图层下先框选区域"));
        return;
    }
    QString path = QFileDialog::getSaveFileName(this, tr("导出场景模块"), {}, "Scene Module (*.smd)");
    if (path.isEmpty()) return;
    if (!path.endsWith(".smd", Qt::CaseInsensitive)) path += ".smd";
    {
        QByteArray eventBytes;
        QDataStream stream(&eventBytes, QIODevice::WriteOnly);
        stream.setByteOrder(QDataStream::LittleEndian);
        stream << MapIO::encodeMap(m_moduleMap, true) << quint32(m_moduleEvents.size());
        for (auto entry = m_moduleEvents.constBegin(); entry != m_moduleEvents.constEnd(); ++entry) {
            const auto &event = entry.value();
            stream << qint16(entry.key()) << event.canWalk << event.num << event.event1 << event.event2 << event.event3
                << event.beginPic1 << event.endPic << event.beginPic2 << event.picDelay << event.xPos << event.yPos;
        }
        if (stream.status() != QDataStream::Ok || !FileIO::writeFiles({{path, MapIO::encodeMap(m_moduleMap, true)},
                {path + ".events", eventBytes}})) {
            QMessageBox::warning(this, tr("导出"), tr("模块或事件文件写入失败")); return;
        }
        MapStruct previous = m_mapData;
        DFile previousEvents = m_dFile;
        int previousScene = m_currentScene;
        int previousLayers = m_exportLayers;
        bool previousExporting = m_exporting;
        m_dFile.mapEvent.resize(1);
        for (auto entry = m_moduleEvents.constBegin(); entry != m_moduleEvents.constEnd(); ++entry)
            m_dFile.mapEvent[0].sceneEvent[entry.key()] = entry.value();
        m_currentScene = 0;
        m_mapData.map = {m_moduleMap};
        m_mapData.num = 1;
        m_exporting = true;
        m_exportLayers = 15;
        renderMap();
        QImage preview = m_mapImage;
        m_mapData = previous;
        m_dFile = previousEvents;
        m_currentScene = previousScene;
        m_exporting = previousExporting;
        m_exportLayers = previousLayers;
        renderMap();
        QSaveFile output(path + ".png");
        if (!output.open(QIODevice::WriteOnly) || !preview.save(&output, "PNG") || !output.commit())
            QMessageBox::warning(this, tr("导出"), tr("模块已保存，但预览图写入失败"));
    }
}

bool SceneMapEdit::pasteModule(const QPoint &anchor)
{
    if (m_mapData.map.isEmpty() || m_moduleMap.mapLayer.size() != 6
        || m_currentScene < 0 || m_currentScene >= m_dFile.mapEvent.size()) return false;
    Map destination = m_mapData.map[0];
    Map adjusted = m_moduleMap;
    int selectedLayer = m_layerCombo->currentIndex();
    if (selectedLayer >= 0 && selectedLayer <= 2) {
        for (int column = 0; column < adjusted.x; ++column)
            for (int row = 0; row < adjusted.y; ++row) {
                int targetX = anchor.x() - adjusted.x + 1 + column;
                int targetY = anchor.y() - adjusted.y + 1 + row;
                if (targetX < 0 || targetY < 0 || targetX >= destination.x || targetY >= destination.y) continue;
                destination.mapLayer[selectedLayer].pic[targetX][targetY] = adjusted.mapLayer[selectedLayer].pic[column][row];
                if (selectedLayer > 0)
                    destination.mapLayer[selectedLayer + 3].pic[targetX][targetY] = adjusted.mapLayer[selectedLayer + 3].pic[column][row];
            }
        m_mapData.map[0] = destination;
        return true;
    }
    MapEvent events = m_dFile.mapEvent[m_currentScene];
    QPoint origin = anchor - QPoint(adjusted.x - 1, adjusted.y - 1);
    QSet<int> used;
    for (const auto &column : destination.mapLayer[3].pic)
        for (int reference : column) if (reference >= 0) used.insert(reference);
    QMap<int, int> remapped;
    for (int column = 0; column < adjusted.x; ++column) {
        for (int row = 0; row < adjusted.y; ++row) {
            QPoint target = origin + QPoint(column, row);
            auto &reference = adjusted.mapLayer[3].pic[column][row];
            if (target.x() < 0 || target.y() < 0 || target.x() >= destination.x || target.y() >= destination.y) continue;
            if (reference < 0 || !m_moduleEvents.contains(reference)) {
                reference = destination.mapLayer[3].pic[target.x()][target.y()];
                continue;
            }
            if (destination.mapLayer[3].pic[target.x()][target.y()] >= 0) {
                QMessageBox::warning(this, tr("粘贴"), tr("目标区域已有事件，请先移除或选择空白区域")); return false;
            }
            if (!remapped.contains(reference)) {
                int available = -1;
                for (int candidate = 0; candidate < 200; ++candidate)
                    if (!used.contains(candidate) && events.sceneEvent[candidate].num < 0
                        && events.sceneEvent[candidate].event1 < 0 && events.sceneEvent[candidate].event2 < 0
                        && events.sceneEvent[candidate].event3 < 0) { available = candidate; break; }
                if (available < 0) { QMessageBox::warning(this, tr("粘贴"), tr("空闲事件编号不足，未粘贴任何内容")); return false; }
                used.insert(available);
                remapped.insert(reference, available);
                SceneEvent event = m_moduleEvents[reference];
                event.num = available;
                event.xPos = target.x();
                event.yPos = target.y();
                events.sceneEvent[available] = event;
            }
            reference = remapped[reference];
        }
    }
    MapIO::pasteRegion(destination, adjusted, anchor);
    m_mapData.map[0] = destination;
    m_dFile.mapEvent[m_currentScene] = events;
    return true;
}

void SceneMapEdit::updateTilePreview(int ix, int iy)
{
    for (auto *label : {m_lblGroundVal, m_lblBuildingVal, m_lblSkyVal, m_lblEventVal}) label->clear();
    for (auto *image : {m_imgGround, m_imgBuilding, m_imgSky, m_imgEvent}) image->clear();
    if (m_mapData.map.isEmpty()) return;
    const Map &curMap = m_mapData.map[0];
    if (ix < 0 || iy < 0 || ix >= curMap.x || iy >= curMap.y) return;

    auto showTile = [&](int layerIdx, QLabel *valLbl, QLabel *imgLbl) {
        if (layerIdx >= (int)curMap.mapLayer.size()) return;
        const auto &layer = curMap.mapLayer[layerIdx];
        if (ix >= layer.pic.size() || iy >= layer.pic[ix].size()) return;
        int tileId = layer.pic[ix][iy] / 2;
        valLbl->setText(QString::number(tileId));
        if ((layerIdx == 0 ? layer.pic[ix][iy] >= 0 : layer.pic[ix][iy] > 0)
            && tileId >= 0 && (layerIdx == 0 || tileId > 0)
            && tileId < m_tileCache.size() && !m_tileCache[tileId].isNull()) {
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
            if (evtIdx >= 0 && m_currentScene >= 0 && m_currentScene < m_dFile.mapEvent.size()
                && evtIdx < 200) {
                int displayPic = displayedEventPic(m_dFile.mapEvent[m_currentScene].sceneEvent[evtIdx]);
                int tileId = displayPic / 2;
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
