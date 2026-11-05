#include "waredit.h"
#include <QtEndian>
#include "fileio.h"
#include <QBuffer>
#include <QMouseEvent>
#include <QTemporaryFile>
#include "iniconfig.h"
#include "rfile.h"
#include "encoding.h"
#include "fileio.h"
#include "grpdata.h"
#include "mapdata.h"
#include "xlsxiowrapper.h"
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QSplitter>
#include <QFileDialog>
#include <QMessageBox>
#include <QPainter>
#include <QDataStream>
#include <QSettings>
#include <QInputDialog>
#include <QCloseEvent>

QByteArray WarEdit::stateBytes() const
{
    QByteArray bytes;
    QDataStream stream(&bytes, QIODevice::WriteOnly);
    stream << m_warFile.records.size();
    for (const auto &record : m_warFile.records) {
        stream << record.fields.size();
        for (const auto &field : record.fields) stream << field.values << field.rawBytes;
    }
    return bytes;
}

bool WarEdit::confirmDiscard()
{
    if ((!m_loaded && m_warFile.records.isEmpty()) || stateBytes() == m_savedState) return true;
    auto answer = QMessageBox::question(this, tr("未保存修改"), tr("保存战斗数据修改？"),
        QMessageBox::Save | QMessageBox::Discard | QMessageBox::Cancel, QMessageBox::Cancel);
    if (answer == QMessageBox::Cancel) return false;
    if (answer == QMessageBox::Save) { onSave(); return stateBytes() == m_savedState; }
    return true;
}

void WarEdit::closeEvent(QCloseEvent *event)
{
    if (confirmDiscard()) event->accept(); else event->ignore();
}

static QString warFieldDisplayName(const WTermini &wt, int flatIndex)
{
    QString name = wt.name;
    if (wt.datanum * wt.incnum > 1 && flatIndex > 0)
        name += QString::number(flatIndex);
    return name;
}

WarEdit::WarEdit(QWidget *parent) : QWidget(parent)
{
    auto *mainLayout = new QVBoxLayout(this);

    // 顶部工具栏
    auto *topBar = new QHBoxLayout;
    m_warCombo = new QComboBox;
    auto *btnLoad = new QPushButton(tr("读取"));
    auto *btnSave = new QPushButton(tr("保存"));
    auto *btnNew = new QPushButton(tr("新增"));
    auto *btnDel = new QPushButton(tr("删除"));
    auto *btnExport = new QPushButton(tr("导出Excel"));
    auto *btnImport = new QPushButton(tr("导入Excel"));

    topBar->addWidget(m_warCombo, 1);
    topBar->addWidget(btnLoad);
    topBar->addWidget(btnSave);
    topBar->addWidget(btnNew);
    topBar->addWidget(btnDel);
    topBar->addWidget(btnExport);
    topBar->addWidget(btnImport);
    mainLayout->addLayout(topBar);

    // 中间: 数据表 | 位置图
    auto *splitter = new QSplitter(Qt::Horizontal);
    m_table = new QTableWidget;
    m_table->setColumnCount(3);
    m_table->setHorizontalHeaderLabels({tr("字段"), tr("值"), tr("备注")});

    auto *rightPanel = new QWidget;
    auto *rightLayout = new QVBoxLayout(rightPanel);
    m_showMap = new QCheckBox(tr("显示地图"));
    m_showMap->setChecked(true);
    m_keepSelection = new QCheckBox(tr("移动后保留选择"));
    QTemporaryFile selectionSettings;
    QString selectionPath;
    if (prepareIniPath(IniConfig::instance().iniPath, selectionSettings, selectionPath)) {
        QSettings settings(selectionPath, QSettings::IniFormat);
        m_keepSelection->setChecked(settings.value("W_Modify/selectcontinue", 0).toInt() == 1);
    }
    connect(m_keepSelection, &QCheckBox::toggled, this, [this](bool keep) {
        if (!saveWarSelection(IniConfig::instance().iniPath, keep)) {
            QSignalBlocker blocker(m_keepSelection);
            m_keepSelection->setChecked(!keep);
            QMessageBox::warning(this, tr("战斗位置"), tr("选择模式保存失败，设置未修改"));
        }
    });
    m_scaleSpin = new QSpinBox; m_scaleSpin->setRange(1, 8); m_scaleSpin->setValue(1);
    m_posScroll = new QScrollArea;
    m_posImage = new QLabel;
    m_posImage->installEventFilter(this);
    m_posScroll->setWidget(m_posImage);

    auto *rTop = new QHBoxLayout;
    rTop->addWidget(m_showMap);
    rTop->addWidget(m_keepSelection);
    rTop->addWidget(new QLabel(tr("缩放:")));
    rTop->addWidget(m_scaleSpin);
    rTop->addStretch();
    rightLayout->addLayout(rTop);
    rightLayout->addWidget(m_posScroll, 1);

    splitter->addWidget(m_table);
    splitter->addWidget(rightPanel);
    splitter->setStretchFactor(0, 1);
    splitter->setStretchFactor(1, 1);
    mainLayout->addWidget(splitter, 1);

    m_statusBar = new QStatusBar;
    mainLayout->addWidget(m_statusBar);

    connect(m_warCombo, QOverload<int>::of(&QComboBox::currentIndexChanged), this, &WarEdit::onWarChanged);
    connect(btnLoad, &QPushButton::clicked, this, &WarEdit::onLoad);
    connect(btnSave, &QPushButton::clicked, this, &WarEdit::onSave);
    connect(btnNew, &QPushButton::clicked, this, &WarEdit::onNewWar);
    connect(btnDel, &QPushButton::clicked, this, &WarEdit::onDeleteWar);
    connect(btnExport, &QPushButton::clicked, this, &WarEdit::onExportExcel);
    connect(btnImport, &QPushButton::clicked, this, &WarEdit::onImportExcel);
    connect(m_showMap, &QCheckBox::toggled, this, &WarEdit::onDrawPosition);
    connect(m_scaleSpin, QOverload<int>::of(&QSpinBox::valueChanged), this, &WarEdit::onDrawPosition);
    connect(m_table, &QTableWidget::cellDoubleClicked, this, &WarEdit::onCellDoubleClicked);
    connect(m_table, &QTableWidget::itemChanged, this, &WarEdit::onTableItemChanged);

    // 自动加载战斗数据
    if (readWIni() && readW()) {
        readWarMapDef();
        readWarMapGrp();
        if (!m_warFile.records.isEmpty()) onWarChanged(0);
    }
}

bool WarEdit::readWIni()
{
    IniConfig &cfg = IniConfig::instance();
    // Read W_Modify section from INI
    QTemporaryFile temporary;
    QString iniPath;
    if (!prepareIniPath(cfg.iniPath, temporary, iniPath)) return false;
    QSettings ini(iniPath, QSettings::IniFormat);
    ini.beginGroup("W_Modify");

    QVector<WTermini> definitions;
    int fieldCount = ini.value("typedataitem", 0).toInt();
    if (fieldCount <= 0 || fieldCount > 32767) return false;
    for (int i = 0; i < fieldCount; ++i) {
        QString val = ini.value(QString("data(%1)").arg(i)).toString();
        QStringList parts = val.split(' ', Qt::SkipEmptyParts);
        if (parts.size() < 7) return false;
        for (int part : {0, 1, 2, 3, 4, 5, 8, 9, 10}) {
            if (part >= parts.size()) continue;
            bool valid = false;
            int value = parts[part].toInt(&valid);
            if (!valid || value < -32768 || value > 32767) return false;
        }

        WTermini wt;
        wt.datanum = parts[0].toInt();
        wt.incnum = parts[1].toInt();
        wt.datalen = parts[2].toInt();
        wt.isstr = parts[3].toInt();
        wt.isname = parts[4].toInt();
        wt.quote = parts[5].toInt();
        wt.name = parts[6];
        if (parts.size() > 7) wt.note = parts[7];
        if (parts.size() > 8) wt.ismapnum = parts[8].toInt();
        if (parts.size() > 9) wt.labeltype = parts[9].toInt();
        if (parts.size() > 10) wt.labelnum = parts[10].toInt();
        definitions.append(wt);
    }

    ini.endGroup();
    WIni expanded;
    int mapField = -1;
    for (int field = 0; field < definitions.size(); ++field) {
        const auto &group = definitions[field];
        if (group.datanum < 0 || group.incnum < 0) return false;
        if (group.datanum == 0) continue;
        if (group.incnum == 0 || field + group.incnum > definitions.size()
            || qint64(expanded.wTerm.size()) + qint64(group.datanum) * group.incnum > 32767) return false;
        for (int repeat = 0; repeat < group.datanum; ++repeat) {
            for (int member = 0; member < group.incnum; ++member) {
                WTermini term = definitions[field + member];
                if (term.datalen <= 0 || (term.isstr != 0 && term.isstr != 1)
                    || (term.isstr == 0 && term.datalen != 1 && term.datalen != 2
                        && term.datalen != 4 && term.datalen != 8)) return false;
                term.datanum = term.incnum = 1;
                if (group.datanum > 1) term.name += QString::number(repeat);
                if (mapField < 0 && term.ismapnum == 1) mapField = expanded.wTerm.size();
                expanded.wTerm.append(term);
            }
        }
    }
    if (expanded.wTerm.isEmpty()) return false;
    m_wIni = expanded;
    m_wSelect.clear();
    m_mapFieldPos = mapField;
    return true;
}

bool WarEdit::readW()
{
    IniConfig &cfg = IniConfig::instance();
    QString warPath = cfg.gamePath + "/" + cfg.warData;

    QFile file(warPath);
    if (!file.open(QIODevice::ReadOnly)) return false;
    QByteArray data = file.readAll();

    // 计算记录大小
    qint64 recordSize = 0;
    for (const auto &wt : m_wIni.wTerm) {
        if (wt.datanum < 0 || wt.incnum < 0 || wt.datalen <= 0
            || (wt.isstr != 1 && wt.datalen != 1 && wt.datalen != 2 && wt.datalen != 4 && wt.datalen != 8)) return false;
        recordSize += qint64(wt.datanum) * wt.incnum * wt.datalen;
        if (recordSize > INT_MAX) return false;
    }
    if (file.error() != QFile::NoError || recordSize <= 0 || data.size() % recordSize != 0) return false;
    int recSize = int(recordSize);
    int warCount = data.size() / recSize;

    m_warFile.typeCount = warCount;
    m_warFile.records.resize(warCount);
    m_warFile.wType.dataNum = warCount;
    m_warFile.wType.mapPos = m_mapFieldPos;

    for (int w = 0; w < warCount; ++w) {
        auto &rec = m_warFile.records[w];
        rec.fields.resize(m_wIni.wTerm.size());
        int pos = w * recSize;

        for (int f = 0; f < m_wIni.wTerm.size(); ++f) {
            const auto &wt = m_wIni.wTerm[f];
            auto &field = rec.fields[f];
            int count = wt.datanum * wt.incnum;
            field.values.resize(count);

            if (wt.isstr == 1) {
                // 字符串字段: 按原始字节存储
                field.rawBytes.resize(count);
                for (int d = 0; d < count; ++d) {
                    int bytesToRead = qMin(wt.datalen, (int)(data.size() - pos));
                    if (bytesToRead > 0) {
                        field.rawBytes[d] = data.mid(pos, bytesToRead);
                        field.values[d] = 0;
                    }
                    pos += wt.datalen;
                }
            } else {
                for (int d = 0; d < count; ++d) {
                    int64_t val = 0;
                    for (int b = 0; b < wt.datalen && pos + b < data.size(); ++b)
                        val |= ((int64_t)(uint8_t)data[pos + b]) << (b * 8);
                    // 符号扩展 (Delphi 使用有符号整数)
                    if (wt.datalen == 1) val = (int8_t)(uint8_t)val;
                    else if (wt.datalen == 2) val = (int16_t)(uint16_t)val;
                    else if (wt.datalen == 4) val = (int32_t)(uint32_t)val;
                    field.values[d] = val;
                    pos += wt.datalen;
                }
            }
        }
    }

    rebuildWSelect();
    rebuildWarCombo();
    m_savedState = stateBytes();
    m_loaded = true;
    return true;
}

void WarEdit::onLoad()
{
    if (!confirmDiscard()) return;
    WIni previousSchema = m_wIni;
    QVector<WSelect> previousSelection = m_wSelect;
    int previousMap = m_mapFieldPos;
    bool previousAutoFriend = m_autoWarFriend;
    if (!readWIni() || !readW()) {
        m_wIni = previousSchema;
        m_wSelect = previousSelection;
        m_mapFieldPos = previousMap;
        m_autoWarFriend = previousAutoFriend;
        QMessageBox::warning(this, tr("读取"), tr("战斗数据读取失败，当前会话未改变。"));
        return;
    }
    readWarMapDef();
    readWarMapGrp();
    if (!m_warFile.records.isEmpty()) {
        m_warCombo->setCurrentIndex(0);
        onWarChanged(0);
    } else {
        m_currentWar = -1;
        m_table->setRowCount(0);
        drawWarPos();
    }
}

void WarEdit::displayW()
{
    if (m_currentWar < 0 || m_currentWar >= m_warFile.records.size()) return;
    const auto &rec = m_warFile.records[m_currentWar];
    m_updatingTable = true;
    m_table->blockSignals(true);

    int totalRows = 0;
    for (const auto &wt : m_wIni.wTerm) totalRows += wt.datanum * wt.incnum;
    m_table->setRowCount(totalRows);
    m_rowMap.clear();
    m_rowMap.resize(totalRows);

    int row = 0;
    for (int f = 0; f < m_wIni.wTerm.size() && f < rec.fields.size(); ++f) {
        const auto &wt = m_wIni.wTerm[f];
        const auto &field = rec.fields[f];
        for (int d = 0; d < field.values.size(); ++d) {
            m_rowMap[row] = { f, d };
            QString name = warFieldDisplayName(wt, d);
            m_table->setItem(row, 0, new QTableWidgetItem(name));

            if (wt.isstr == 1 && d < field.rawBytes.size()) {
                // 字符串字段: 解码显示
                QString str = Encoding::readOutStr(field.rawBytes[d].constData(), field.rawBytes[d].size());
                m_table->setItem(row, 1, new QTableWidgetItem(str));
            } else {
                m_table->setItem(row, 1, new QTableWidgetItem(QString::number(field.values[d])));
            }
            m_table->setItem(row, 2, new QTableWidgetItem(wt.note));
            m_table->item(row, 0)->setFlags(m_table->item(row, 0)->flags() & ~Qt::ItemIsEditable);
            m_table->item(row, 2)->setFlags(m_table->item(row, 2)->flags() & ~Qt::ItemIsEditable);
            row++;
        }
    }
    m_table->blockSignals(false);
    m_updatingTable = false;
}

void WarEdit::rebuildWSelect()
{
    m_wSelect.clear();
    QVector<int> labelCounts(8, 0);

    for (int f = 0; f < m_wIni.wTerm.size(); ++f) {
        const WTermini &wt = m_wIni.wTerm[f];
        int count = wt.datanum * wt.incnum;
        for (int d = 0; d < count; ++d) {
            WSelect sel;
            sel.pos1 = f;
            sel.pos2 = d;
            sel.pos3 = 0;
            sel.name = warFieldDisplayName(wt, d);
            sel.quote = wt.quote;
            sel.note = wt.note;
            sel.ismap = wt.ismapnum;
            sel.labeltype = wt.labeltype;
            sel.labelnum = wt.labelnum;
            if (sel.labelnum > 0) {
                if (labelCounts.size() <= sel.labelnum)
                    labelCounts.resize(sel.labelnum + 1);
                ++labelCounts[sel.labelnum];
                sel.labelcount = labelCounts[sel.labelnum];
            }
            m_wSelect.append(sel);
        }
    }
}

void WarEdit::rebuildWarCombo()
{
    m_warCombo->blockSignals(true);
    m_warCombo->clear();
    for (int i = 0; i < m_warFile.records.size(); ++i) {
        QString label = QString::number(i);
        for (int f = 0; f < m_wIni.wTerm.size() && f < m_warFile.records[i].fields.size(); ++f) {
            if (m_wIni.wTerm[f].isname != 1) continue;
            const auto &fld = m_warFile.records[i].fields[f];
            if (!fld.rawBytes.isEmpty()) {
                QString name = Encoding::readOutStr(fld.rawBytes[0].constData(), fld.rawBytes[0].size());
                if (!name.isEmpty())
                    label += " " + name;
            }
            break;
        }
        m_warCombo->addItem(label);
    }
    m_warCombo->blockSignals(false);
}

void WarEdit::onWarChanged(int index)
{
    m_selectedPerson = -1;
    m_currentWar = index;
    displayW();
    countWarPos();
    drawWarPos();
}

void WarEdit::countWarPos()
{
    m_warFriend.clear();
    m_warEnemy.clear();
    if (m_currentWar < 0 || m_currentWar >= m_warFile.records.size()) return;

    const auto &rec = m_warFile.records[m_currentWar];
    auto readSelValue = [&](const WSelect &sel) -> int {
        if (sel.pos1 < 0 || sel.pos1 >= rec.fields.size()) return -1;
        if (sel.pos2 < 0 || sel.pos2 >= rec.fields[sel.pos1].values.size()) return -1;
        return static_cast<int>(rec.fields[sel.pos1].values[sel.pos2]);
    };

    bool autoWarFriend = false;
    for (const auto &sel : m_wSelect) {
        if (sel.labelnum == 7 && readSelValue(sel) >= 0) {
            autoWarFriend = true;
            break;
        }
    }
    m_autoWarFriend = autoWarFriend;

    int friendLabel = autoWarFriend ? 7 : 5;
    int friendMax = 0;
    for (const auto &sel : m_wSelect) {
        if (sel.labelnum == friendLabel)
            friendMax = qMax(friendMax, static_cast<int>(sel.labelcount));
    }
    m_warFriend.resize(friendMax);
    for (auto &wp : m_warFriend) {
        wp.personNum = -1;
        wp.x = 0;
        wp.y = 0;
    }

    for (const auto &sel : m_wSelect) {
        if (sel.labelnum == friendLabel && sel.labelcount > 0 && sel.labelcount <= m_warFriend.size())
            m_warFriend[sel.labelcount - 1].personNum = readSelValue(sel);
    }
    for (const auto &sel : m_wSelect) {
        if (sel.labelnum == 1 && sel.labeltype == 1 && sel.labelcount > 0 && sel.labelcount <= m_warFriend.size())
            m_warFriend[sel.labelcount - 1].x = readSelValue(sel);
    }
    for (const auto &sel : m_wSelect) {
        if (sel.labelnum == 2 && sel.labeltype == 1 && sel.labelcount > 0 && sel.labelcount <= m_warFriend.size())
            m_warFriend[sel.labelcount - 1].y = readSelValue(sel);
    }

    int enemyMax = 0;
    for (const auto &sel : m_wSelect) {
        if (sel.labelnum == 6)
            enemyMax = qMax(enemyMax, static_cast<int>(sel.labelcount));
    }
    m_warEnemy.resize(enemyMax);
    for (auto &wp : m_warEnemy) {
        wp.personNum = -1;
        wp.x = 0;
        wp.y = 0;
    }

    for (const auto &sel : m_wSelect) {
        if (sel.labelnum == 6 && sel.labelcount > 0 && sel.labelcount <= m_warEnemy.size())
            m_warEnemy[sel.labelcount - 1].personNum = readSelValue(sel);
    }
    for (const auto &sel : m_wSelect) {
        if (sel.labelnum == 3 && sel.labeltype == 2 && sel.labelcount > 0 && sel.labelcount <= m_warEnemy.size())
            m_warEnemy[sel.labelcount - 1].x = readSelValue(sel);
    }
    for (const auto &sel : m_wSelect) {
        if (sel.labelnum == 4 && sel.labeltype == 2 && sel.labelcount > 0 && sel.labelcount <= m_warEnemy.size())
            m_warEnemy[sel.labelcount - 1].y = readSelValue(sel);
    }
}

int WarEdit::currentMapIndex() const
{
    if (m_currentWar < 0 || m_currentWar >= m_warFile.records.size()) return -1;
    if (m_mapFieldPos < 0 || m_mapFieldPos >= m_warFile.records[m_currentWar].fields.size()) return -1;
    const auto &field = m_warFile.records[m_currentWar].fields[m_mapFieldPos];
    if (field.values.isEmpty()) return -1;
    int mapIndex = static_cast<int>(field.values[0]);
    if (mapIndex < 0 || mapIndex >= m_warMapData.num) return -1;
    return mapIndex;
}

void WarEdit::readWarMapDef()
{
    IniConfig &cfg = IniConfig::instance();
    QByteArray idxData = FileIO::readFileAll(cfg.gamePath + "/" + cfg.warMapDefIdx);
    QByteArray grpData = FileIO::readFileAll(cfg.gamePath + "/" + cfg.warMapDefGrp);
    if (idxData.isEmpty() || idxData.size() % 4 != 0 || grpData.isEmpty()) return;
    MapStruct decoded;
    quint32 previous = 0;
    bool padding = false;
    for (int entry = 0; entry < idxData.size() / 4; ++entry) {
        quint32 end = qFromLittleEndian<quint32>(idxData.constData() + entry * 4);
        if (end == 0) { padding = true; continue; }
        if (padding || end > quint64(grpData.size()) || end < previous || end - previous != 16384) return;
        Map map;
        if (!MapIO::readSingleMap(grpData, int(previous), map, 2, 64, 64)) return;
        decoded.map.append(map);
        previous = end;
    }
    if (previous != quint64(grpData.size()) || decoded.map.isEmpty()) return;
    decoded.num = decoded.map.size();
    m_warMapData = decoded;
}

void WarEdit::drawWarPos()
{
    if (m_warTileCache.isEmpty())
        readWarMapGrp();

    const int scale = m_scaleSpin->value();
    const int tileW = 18 * scale;
    const int tileH = 9 * scale;
    const int pad = 90 * scale;
    const int mapIndex = currentMapIndex();
    const bool canDrawMap = m_showMap->isChecked() && mapIndex >= 0 && mapIndex < m_warMapData.map.size();

    int imgW = 400;
    int imgH = 400;
    int centerX = imgW / 2;
    int centerY = imgH / 2;
    const Map *map = nullptr;

    if (canDrawMap) {
        map = &m_warMapData.map[mapIndex];
        imgW = (map->x + map->y) * tileW + pad * 2;
        imgH = (map->x + map->y) * tileH + pad * 2;
        centerX = imgW / 2;
        centerY = imgH / 2 - 31 * tileW;
    }

    QImage img(imgW, imgH, QImage::Format_ARGB32);
    img.fill(canDrawMap ? Qt::black : QColor(100, 150, 100));
    QPainter p(&img);

    auto isoToScreen = [&](int ix, int iy) -> QPoint {
        int sx = ix * tileW - iy * tileW + centerX;
        int sy = ix * tileH + iy * tileH + centerY;
        return {sx, sy};
    };

    if (canDrawMap && map) {
        for (int i = 0; i < qMin(map->x, map->y); ++i) {
            for (int ix = i; ix < map->x; ++ix) {
                int iy = i;
                QPoint sp = isoToScreen(ix, iy);
                for (int layer = 0; layer < map->layerNum && layer < map->mapLayer.size(); ++layer) {
                    const auto &layerData = map->mapLayer[layer];
                    if (ix >= layerData.pic.size() || iy >= layerData.pic[ix].size()) continue;
                    int tileId = layerData.pic[ix][iy] / 2;
                    if (layer == 0) {
                        if (tileId < 0 || tileId >= m_warTileCache.size()) continue;
                    } else {
                        if (tileId <= 0 || tileId >= m_warTileCache.size()) continue;
                    }
                    const QImage &tile = m_warTileCache[tileId];
                    if (tile.isNull()) continue;
                    int xoff = (tileId < m_warGrpPics.size()) ? m_warGrpPics[tileId].xoff : 0;
                    int yoff = (tileId < m_warGrpPics.size()) ? m_warGrpPics[tileId].yoff : 0;
                    p.drawImage(sp.x() - xoff, sp.y() - yoff, tile);
                }
            }
            for (int iy = i + 1; iy < map->y; ++iy) {
                int ix = i;
                QPoint sp = isoToScreen(ix, iy);
                for (int layer = 0; layer < map->layerNum && layer < map->mapLayer.size(); ++layer) {
                    const auto &layerData = map->mapLayer[layer];
                    if (ix >= layerData.pic.size() || iy >= layerData.pic[ix].size()) continue;
                    int tileId = layerData.pic[ix][iy] / 2;
                    if (layer == 0) {
                        if (tileId < 0 || tileId >= m_warTileCache.size()) continue;
                    } else {
                        if (tileId <= 0 || tileId >= m_warTileCache.size()) continue;
                    }
                    const QImage &tile = m_warTileCache[tileId];
                    if (tile.isNull()) continue;
                    int xoff = (tileId < m_warGrpPics.size()) ? m_warGrpPics[tileId].xoff : 0;
                    int yoff = (tileId < m_warGrpPics.size()) ? m_warGrpPics[tileId].yoff : 0;
                    p.drawImage(sp.x() - xoff, sp.y() - yoff, tile);
                }
            }
        }
    }

    p.setPen(QPen(Qt::red, 2));
    for (const auto &wp : m_warFriend) {
        if (m_autoWarFriend && wp.personNum < 0) continue;
        QPoint sp = isoToScreen(wp.x, wp.y);
        p.drawEllipse(sp, 8, 8);
        if (wp.personNum >= 0)
            p.drawText(QPoint(sp.x() - 4, sp.y() + 4), QString::number(wp.personNum));
    }

    p.setPen(QPen(Qt::blue, 2));
    for (const auto &wp : m_warEnemy) {
        if (wp.personNum < 0) continue;
        QPoint sp = isoToScreen(wp.x, wp.y);
        p.drawEllipse(sp, 8, 8);
        p.drawText(QPoint(sp.x() - 4, sp.y() + 4), QString::number(wp.personNum));
    }

    QPixmap pixmap = QPixmap::fromImage(img);
    const QSize maxPreviewSize(960, 720);
    if (pixmap.width() > maxPreviewSize.width() || pixmap.height() > maxPreviewSize.height()) {
        pixmap = pixmap.scaled(maxPreviewSize, Qt::KeepAspectRatio, Qt::SmoothTransformation);
    }

    m_posImage->setPixmap(pixmap);
    m_posImage->resize(pixmap.size());
    m_positionOrigin = QPointF(centerX, centerY);
    m_positionScale = double(pixmap.width()) / imgW;
}

bool WarEdit::eventFilter(QObject *watched, QEvent *event)
{
    if (watched != m_posImage || event->type() != QEvent::MouseButtonPress)
        return QWidget::eventFilter(watched, event);
    auto *mouse = static_cast<QMouseEvent *>(event);
    if (mouse->button() != Qt::LeftButton || m_currentWar < 0 || m_currentWar >= m_warFile.records.size()) return false;
    QPointF point = (mouse->position() - m_posImage->contentsRect().topLeft()) / m_positionScale - m_positionOrigin;
    int scale = m_scaleSpin->value();
    int x = qRound((point.x() / (18 * scale) + point.y() / (9 * scale)) / 2);
    int y = qRound((-point.x() / (18 * scale) + point.y() / (9 * scale)) / 2);
    if (x < 0 || y < 0 || x >= 64 || y >= 64) return true;
    for (int faction : {1, 2}) {
        const auto &people = faction == 1 ? m_warFriend : m_warEnemy;
        for (int index = 0; index < people.size(); ++index) {
            const auto &person = people[index];
            if ((faction == 2 || m_autoWarFriend) && person.personNum < 0) continue;
            if (person.x == x && person.y == y) {
                m_selectedFaction = faction;
                m_selectedPerson = index;
                m_statusBar->showMessage(tr("已选择%1第%2人，点击空格移动").arg(faction == 1 ? tr("友军") : tr("敌军")).arg(index));
                return true;
            }
        }
    }
    if (m_selectedPerson < 0) return true;
    auto &record = m_warFile.records[m_currentWar];
    for (const auto &selection : m_wSelect) {
        if (selection.labeltype != m_selectedFaction || selection.labelcount != m_selectedPerson + 1) continue;
        int xLabel = m_selectedFaction == 1 ? 1 : 3, yLabel = xLabel + 1;
        if (selection.labelnum != xLabel && selection.labelnum != yLabel) continue;
        if (selection.pos1 < 0 || selection.pos1 >= record.fields.size()) continue;
        auto &values = record.fields[selection.pos1].values;
        if (selection.pos2 >= 0 && selection.pos2 < values.size()) values[selection.pos2] = selection.labelnum == xLabel ? x : y;
    }
    if (!m_keepSelection->isChecked()) {
        m_selectedPerson = -1;
        m_selectedFaction = 0;
    }
    displayW();
    countWarPos();
    drawWarPos();
    return true;
}

void WarEdit::readWarMapGrp()
{
    IniConfig &cfg = IniConfig::instance();
    GrpIO::readGrp(cfg.gamePath + "/" + cfg.warMapIdx,
                    cfg.gamePath + "/" + cfg.warMapGrp, m_warGrpPics);

    uint8_t pr[256] = {}, pg[256] = {}, pb[256] = {};
    if (!cfg.palette.isEmpty())
        MapIO::readPalette(cfg.gamePath + cfg.palette, pr, pg, pb);

    m_warTileCache.resize(m_warGrpPics.size());
    for (int i = 0; i < m_warGrpPics.size(); ++i) {
        const auto &pic = m_warGrpPics[i];
        if (pic.data.isEmpty()) continue;
        if (GrpIO::isPNG(pic))
            m_warTileCache[i] = GrpIO::decodePNG(pic);
        else
            m_warTileCache[i] = GrpIO::decodeRLE(pic, pr, pg, pb);
    }
}

void WarEdit::onSave()
{
    // 写入二进制文件
    IniConfig &cfg = IniConfig::instance();
    QString warPath = cfg.gamePath + "/" + cfg.warData;
    QByteArray bytes;
    QBuffer file(&bytes);
    if (!file.open(QIODevice::WriteOnly)) return;

    for (const auto &rec2 : m_warFile.records) {
        for (int f = 0; f < m_wIni.wTerm.size() && f < rec2.fields.size(); ++f) {
            const auto &wt = m_wIni.wTerm[f];
            if (wt.isstr == 1) {
                // 字符串字段: 写回原始字节
                for (int d = 0; d < rec2.fields[f].values.size(); ++d) {
                    QByteArray raw;
                    if (d < rec2.fields[f].rawBytes.size())
                        raw = rec2.fields[f].rawBytes[d];
                    raw.resize(wt.datalen);
                    file.write(raw.constData(), wt.datalen);
                }
            } else {
                for (int d = 0; d < rec2.fields[f].values.size(); ++d) {
                    int64_t val = rec2.fields[f].values[d];
                    for (int b = 0; b < wt.datalen; ++b)
                        file.putChar((val >> (b * 8)) & 0xFF);
                }
            }
        }
    }
    if (cfg.warData.isEmpty() || !FileIO::writeFileAll(warPath, bytes)) {
        QMessageBox::warning(this, tr("保存"), tr("保存失败")); return;
    }
    m_savedState = stateBytes();
    m_loaded = true;
    QMessageBox::information(this, tr("保存"), tr("保存成功"));
}

void WarEdit::onNewWar()
{
    WRecord rec;
    rec.fields.resize(m_wIni.wTerm.size());
    for (int f = 0; f < m_wIni.wTerm.size(); ++f) {
        int count = m_wIni.wTerm[f].datanum * m_wIni.wTerm[f].incnum;
        rec.fields[f].values.resize(count, 0);
        if (m_wIni.wTerm[f].isstr == 1)
            rec.fields[f].rawBytes.resize(count, QByteArray(m_wIni.wTerm[f].datalen, '\0'));
    }
    m_warFile.records.append(rec);
    m_warFile.typeCount = m_warFile.records.size();
    rebuildWarCombo();
    m_warCombo->setCurrentIndex(m_warFile.records.size() - 1);
}

void WarEdit::onDeleteWar()
{
    if (m_currentWar < 0 || m_currentWar >= m_warFile.records.size()) return;
    m_warFile.records.removeAt(m_currentWar);
    m_warFile.typeCount = m_warFile.records.size();
    rebuildWarCombo();
    if (!m_warFile.records.isEmpty())
        m_warCombo->setCurrentIndex(qMin(m_currentWar, m_warFile.records.size() - 1));
    else {
        m_currentWar = -1;
        m_table->setRowCount(0);
        drawWarPos();
    }
}

void WarEdit::onExportExcel()
{
    if (m_warFile.records.isEmpty()) return;

    QString filename = QFileDialog::getSaveFileName(this, tr("导出Excel"), {}, tr("Excel 文件 (*.xlsx)"));
    if (filename.isEmpty()) return;

    if (!exportExcel(filename)) {
        QMessageBox::warning(this, tr("导出失败"), tr("Excel 写入失败，目标文件未替换。"));
        return;
    }
    QMessageBox::information(this, tr("导出成功"), tr("战斗数据已导出为 Excel。"));
}

bool WarEdit::exportExcel(const QString &filename)
{
    if (!XlsxWriter::loadLibrary("xlsxwriter")) return false;
    QTemporaryFile temporary(QFileInfo(filename).absolutePath() + "/upedit-war-XXXXXX.xlsx");
    if (!temporary.open()) return false;
    QString temporaryPath = temporary.fileName();
    if (!temporary.remove()) return false;

    XlsxWriter writer;
    if (!writer.create(temporaryPath)) return false;
    writer.addWorksheet("Sheet1");

    int col = 0;
    for (const auto &wt : m_wIni.wTerm) {
        int count = wt.datanum * wt.incnum;
        for (int d = 0; d < count; ++d)
            writer.writeString(0, col++, warFieldDisplayName(wt, d));
    }

    for (int row = 0; row < m_warFile.records.size(); ++row) {
        col = 0;
        const auto &rec = m_warFile.records[row];
        for (int f = 0; f < m_wIni.wTerm.size() && f < rec.fields.size(); ++f) {
            const auto &wt = m_wIni.wTerm[f];
            const auto &field = rec.fields[f];
            int count = wt.datanum * wt.incnum;
            for (int d = 0; d < count; ++d) {
                if (wt.isstr == 1) {
                    QString value;
                    if (d < field.rawBytes.size())
                        value = Encoding::readOutStr(field.rawBytes[d].constData(), field.rawBytes[d].size());
                    writer.writeString(row + 1, col++, value);
                } else {
                    qint64 value = (d < field.values.size()) ? field.values[d] : 0;
                    if (value < -999999999999999LL || value > 999999999999999LL)
                        writer.writeString(row + 1, col++, QString::number(value));
                    else
                        writer.writeNumber(row + 1, col++, static_cast<double>(value));
                }
            }
        }
    }

    bool saved = writer.close();
    if (saved) saved = FileIO::writeFileAll(filename, FileIO::readFileAll(temporaryPath));
    QFile::remove(temporaryPath);
    return saved;
}

void WarEdit::onImportExcel()
{
    QString filename = QFileDialog::getOpenFileName(this, tr("导入Excel"), {}, tr("Excel 文件 (*.xlsx)"));
    if (filename.isEmpty()) return;

    if (!importExcel(filename)) {
        QMessageBox::warning(this, tr("导入失败"), tr("Excel 数据或字段范围无效，原数据未修改。"));
        return;
    }
    rebuildWarCombo();
    m_warCombo->setCurrentIndex(0);
    onWarChanged(0);
    QMessageBox::information(this, tr("导入成功"), tr("战斗数据已从 Excel 导入。"));
}

bool WarEdit::importExcel(const QString &filename)
{
    if (!XlsxReader::loadLibrary("libxlsxio_read") || m_wIni.wTerm.isEmpty()) return false;

    XlsxReader reader;
    if (!reader.open(filename)) return false;

    QVector<QStringList> rows = reader.readAll("Sheet1");
    if (rows.isEmpty())
        rows = reader.readAll();
    reader.close();

    if (rows.size() <= 1) return false;

    QVector<WRecord> records;
    for (int row = 1; row < rows.size(); ++row) {
        const QStringList &cells = rows[row];
        bool allEmpty = true;
        for (const QString &cell : cells) {
            if (!cell.trimmed().isEmpty()) {
                allEmpty = false;
                break;
            }
        }
        if (allEmpty) continue;

        WRecord rec;
        rec.fields.resize(m_wIni.wTerm.size());
        int col = 0;
        for (int f = 0; f < m_wIni.wTerm.size(); ++f) {
            const auto &wt = m_wIni.wTerm[f];
            if (wt.datanum < 0 || wt.incnum < 0 || wt.datalen <= 0) return false;
            int count = wt.datanum * wt.incnum;
            rec.fields[f].values.resize(count, 0);
            if (wt.isstr == 1)
                rec.fields[f].rawBytes.resize(count, QByteArray(wt.datalen, '\0'));

            for (int d = 0; d < count; ++d, ++col) {
                QString cell = (col < cells.size()) ? cells[col] : QString();
                if (wt.isstr == 1) {
                    Encoding::writeInStr(cell, rec.fields[f].rawBytes[d].data(), wt.datalen);
                } else {
                    bool ok = false;
                    qlonglong value = cell.isEmpty() ? 0 : cell.toLongLong(&ok);
                    if (!cell.isEmpty() && !ok) return false;
                    int bits = wt.datalen * 8;
                    if (bits != 8 && bits != 16 && bits != 32 && bits != 64) return false;
                    if (bits < 64 && (value < -(qint64(1) << (bits - 1)) || value > (qint64(1) << (bits - 1)) - 1)) return false;
                    rec.fields[f].values[d] = value;
                }
            }
        }
        records.append(rec);
    }

    if (records.isEmpty()) return false;

    m_warFile.records = records;
    m_warFile.typeCount = records.size();
    m_warFile.wType.dataNum = records.size();
    return true;
}

void WarEdit::onTableItemChanged(QTableWidgetItem *item)
{
    if (m_updatingTable || !item || item->column() != 1) return;
    if (m_currentWar < 0 || m_currentWar >= m_warFile.records.size()) return;
    int row = item->row();
    if (row < 0 || row >= m_rowMap.size()) return;

    auto &rec = m_warFile.records[m_currentWar];
    int f = m_rowMap[row].fieldIdx;
    int d = m_rowMap[row].valueIdx;
    if (f < 0 || f >= m_wIni.wTerm.size() || f >= rec.fields.size()) return;
    if (d < 0 || d >= rec.fields[f].values.size()) return;

    const auto &wt = m_wIni.wTerm[f];
    if (wt.isstr == 1) {
        if (d < rec.fields[f].rawBytes.size()) {
            rec.fields[f].rawBytes[d].fill(0, wt.datalen);
            Encoding::writeInStr(item->text(), rec.fields[f].rawBytes[d].data(), wt.datalen);
        }
    } else {
        bool ok = false;
        qlonglong value = item->text().toLongLong(&ok);
        if (wt.datalen == 1) ok = ok && value >= -128 && value <= 127;
        else if (wt.datalen == 2) ok = ok && value >= -32768 && value <= 32767;
        else if (wt.datalen == 4) ok = ok && value >= INT_MIN && value <= INT_MAX;
        else if (wt.datalen != 8) ok = false;
        if (!ok) {
            QSignalBlocker blocker(m_table);
            item->setText(QString::number(rec.fields[f].values[d]));
            return;
        }
        rec.fields[f].values[d] = value;
    }

    if (wt.isname == 1)
        rebuildWarCombo();
    countWarPos();
    drawWarPos();
}

void WarEdit::onDrawPosition() { drawWarPos(); }

void WarEdit::onCellDoubleClicked(int row, int /*column*/)
{
    if (m_currentWar < 0 || m_currentWar >= m_warFile.records.size()) return;
    if (row < 0 || row >= m_rowMap.size()) return;

    auto &rec = m_warFile.records[m_currentWar];
    int f = m_rowMap[row].fieldIdx;
    int d = m_rowMap[row].valueIdx;
    if (f < 0 || f >= m_wIni.wTerm.size() || f >= rec.fields.size()) return;
    if (d < 0 || d >= rec.fields[f].values.size()) return;

    const auto &wt = m_wIni.wTerm[f];

    if (wt.quote > 0) {
        // 引用字段: 弹出选择对话框 (匹配 Delphi Form6)
        IniConfig &cfg = IniConfig::instance();
        const auto &rFile = cfg.rGlobals.rFile;
        if (wt.quote >= rFile.rType.size()) return;
        const RType &refType = rFile.rType[wt.quote];

        QStringList items;
        items << "-1";
        for (int i = 0; i < refType.rData.size(); ++i) {
            QString name;
            if (refType.namePos >= 0 && refType.namePos < refType.rData[i].rDataLine.size()) {
                const auto &nl = refType.rData[i].rDataLine[refType.namePos];
                if (!nl.rArray.isEmpty() && !nl.rArray[0].dataArray.isEmpty())
                    name = Encoding::displayStr(RFileIO::readRDataStr(nl.rArray[0].dataArray[0]));
            }
            items << QString("%1 %2").arg(i).arg(name);
        }

        int curVal = static_cast<int>(rec.fields[f].values[d]);
        int curIdx = curVal + 1;
        if (curIdx < 0 || curIdx >= items.size()) curIdx = 0;

        QString typeName = (wt.quote < cfg.rGlobals.typeName.size())
                           ? cfg.rGlobals.typeName[wt.quote] : QString::number(wt.quote);
        bool ok;
        QString selected = QInputDialog::getItem(this, tr("选择引用"), typeName, items, curIdx, false, &ok);
        if (ok) {
            int idx = items.indexOf(selected);
            if (idx >= 0 && m_table->item(row, 1))
                m_table->item(row, 1)->setText(QString::number(idx - 1));
        }
    } else {
        // 非引用字段: 弹出编辑对话框 (匹配 Delphi InputBox)
        bool ok;
        if (wt.isstr == 1 && d < rec.fields[f].rawBytes.size()) {
            QString curVal = Encoding::readOutStr(rec.fields[f].rawBytes[d].constData(), rec.fields[f].rawBytes[d].size());
            QString newVal = QInputDialog::getText(this, tr("修改字符串"), tr("修改此项:"), QLineEdit::Normal, curVal, &ok);
            if (ok) {
                rec.fields[f].rawBytes[d].fill(0, wt.datalen);
                Encoding::writeInStr(newVal, rec.fields[f].rawBytes[d].data(), wt.datalen);
            }
        } else {
            QString curVal = QString::number(rec.fields[f].values[d]);
            QString newVal = QInputDialog::getText(this, tr("修改数值"), tr("修改此项:"), QLineEdit::Normal, curVal, &ok);
            if (ok && m_table->item(row, 1))
                m_table->item(row, 1)->setText(newVal);
        }
    }
    if (wt.isname == 1)
        rebuildWarCombo();
    displayW();
    countWarPos();
    drawWarPos();
}
