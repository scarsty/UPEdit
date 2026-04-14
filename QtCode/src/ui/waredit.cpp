#include "waredit.h"
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
    m_scaleSpin = new QSpinBox; m_scaleSpin->setRange(1, 8); m_scaleSpin->setValue(1);
    m_posScroll = new QScrollArea;
    m_posImage = new QLabel;
    m_posScroll->setWidget(m_posImage);

    auto *rTop = new QHBoxLayout;
    rTop->addWidget(m_showMap);
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
    onLoad();
}

void WarEdit::readWIni()
{
    IniConfig &cfg = IniConfig::instance();
    // Read W_Modify section from INI
    QSettings ini(cfg.iniPath, QSettings::IniFormat);
    ini.beginGroup("W_Modify");

    m_wIni.wTerm.clear();
    m_wSelect.clear();
    m_mapFieldPos = -1;

    int fieldCount = ini.value("typedataitem", 0).toInt();
    for (int i = 0; i < fieldCount; ++i) {
        QString val = ini.value(QString("data(%1)").arg(i)).toString();
        QStringList parts = val.split(' ', Qt::SkipEmptyParts);
        if (parts.size() < 7) continue;

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
        m_wIni.wTerm.append(wt);
        if (m_mapFieldPos < 0 && wt.ismapnum == 1)
            m_mapFieldPos = m_wIni.wTerm.size() - 1;
    }

    ini.endGroup();
}

void WarEdit::readW()
{
    IniConfig &cfg = IniConfig::instance();
    QString warPath = cfg.gamePath + "/" + cfg.warData;

    QFile file(warPath);
    if (!file.open(QIODevice::ReadOnly)) return;
    QByteArray data = file.readAll();

    // 计算记录大小
    int recSize = 0;
    for (const auto &wt : m_wIni.wTerm)
        recSize += wt.datanum * wt.incnum * wt.datalen;

    if (recSize <= 0) return;
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
}

void WarEdit::onLoad()
{
    readWIni();
    readW();
    readWarMapDef();
    readWarMapGrp();
    if (!m_warFile.records.isEmpty()) {
        m_warCombo->setCurrentIndex(0);
        onWarChanged(0);
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
    if (idxData.isEmpty() || grpData.isEmpty()) return;

    const uint32_t *offsets = reinterpret_cast<const uint32_t *>(idxData.constData());
    int totalEntries = idxData.size() / 4;
    int mapCount = 0;
    for (int i = 0; i < totalEntries; ++i) {
        if (offsets[i] > 0) ++mapCount;
        else break;
    }

    m_warMapData.num = mapCount;
    m_warMapData.map.resize(mapCount);
    for (int i = 0; i < mapCount; ++i) {
        int startOff = (i == 0) ? 0 : static_cast<int>(offsets[i - 1]);
        MapIO::readSingleMap(grpData, startOff, m_warMapData.map[i], 2, 64, 64);
    }
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
    // 从表格回写到m_warFile
    if (m_currentWar < 0) return;
    auto &rec = m_warFile.records[m_currentWar];
    int row = 0;
    for (int f = 0; f < m_wIni.wTerm.size() && f < rec.fields.size(); ++f) {
        const auto &wt = m_wIni.wTerm[f];
        for (int d = 0; d < rec.fields[f].values.size(); ++d) {
            auto *item = m_table->item(row, 1);
            if (item) {
                if (wt.isstr == 1) {
                    // 字符串字段: 编码回写到 rawBytes
                    if (d < rec.fields[f].rawBytes.size()) {
                        rec.fields[f].rawBytes[d].fill(0, wt.datalen);
                        Encoding::writeInStr(item->text(),
                            rec.fields[f].rawBytes[d].data(), wt.datalen);
                    }
                } else {
                    rec.fields[f].values[d] = item->text().toLongLong();
                }
            }
            row++;
        }
    }
    rebuildWarCombo();

    // 写入二进制文件
    IniConfig &cfg = IniConfig::instance();
    QString warPath = cfg.gamePath + "/" + cfg.warData;
    QFile file(warPath);
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

    XlsxWriter writer;
    if (!writer.create(filename) || !writer.addWorksheet("Sheet1")) {
        QMessageBox::warning(this, tr("导出失败"), tr("无法创建 Excel 文件。"));
        return;
    }

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
                    double value = (d < field.values.size()) ? static_cast<double>(field.values[d]) : 0.0;
                    writer.writeNumber(row + 1, col++, value);
                }
            }
        }
    }

    writer.close();
    QMessageBox::information(this, tr("导出成功"), tr("战斗数据已导出为 Excel。"));
}

void WarEdit::onImportExcel()
{
    QString filename = QFileDialog::getOpenFileName(this, tr("导入Excel"), {}, tr("Excel 文件 (*.xlsx)"));
    if (filename.isEmpty()) return;

    XlsxReader reader;
    if (!reader.open(filename)) {
        QMessageBox::warning(this, tr("导入失败"), tr("无法打开 Excel 文件。"));
        return;
    }

    QVector<QStringList> rows = reader.readAll("Sheet1");
    if (rows.isEmpty())
        rows = reader.readAll();
    reader.close();

    if (rows.size() <= 1) {
        QMessageBox::warning(this, tr("导入失败"), tr("Excel 中没有可导入的数据行。"));
        return;
    }

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
                    qlonglong value = cell.toLongLong(&ok);
                    rec.fields[f].values[d] = ok ? value : 0;
                }
            }
        }
        records.append(rec);
    }

    if (records.isEmpty()) {
        QMessageBox::warning(this, tr("导入失败"), tr("Excel 中没有有效记录。"));
        return;
    }

    m_warFile.records = records;
    m_warFile.typeCount = records.size();
    m_warFile.wType.dataNum = records.size();
    rebuildWarCombo();
    m_warCombo->setCurrentIndex(0);
    onWarChanged(0);
    QMessageBox::information(this, tr("导入成功"), tr("战斗数据已从 Excel 导入。"));
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
        if (ok)
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
            rec.fields[f].values[d] = idx - 1;
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
            if (ok)
                rec.fields[f].values[d] = newVal.toLongLong();
        }
    }
    if (wt.isname == 1)
        rebuildWarCombo();
    displayW();
    countWarPos();
    drawWarPos();
}
