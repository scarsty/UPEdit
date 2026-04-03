#include "waredit.h"
#include "iniconfig.h"
#include "rfile.h"
#include "encoding.h"
#include "fileio.h"
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QSplitter>
#include <QFileDialog>
#include <QMessageBox>
#include <QPainter>
#include <QDataStream>

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
}

void WarEdit::readWIni()
{
    IniConfig &cfg = IniConfig::instance();
    // Read W_Modify section from INI
    QSettings ini(cfg.iniPath, QSettings::IniFormat);
    ini.setIniCodec("UTF-8");
    ini.beginGroup("W_Modify");

    m_wIni.wTerm.clear();
    m_wSelect.clear();

    int fieldCount = ini.value("typenum", 0).toInt();
    for (int i = 0; i < fieldCount; ++i) {
        QString val = ini.value(QString("data(%1)").arg(i)).toString();
        QStringList parts = val.split(' ', Qt::SkipEmptyParts);
        if (parts.size() < 7) continue;

        WTermini wt;
        wt.datanum = parts[0].toInt();
        wt.incnum = parts[1].toInt();
        wt.datalen = parts[2].toInt();
        wt.isStr = parts[3].toInt();
        wt.isMapNum = parts[4].toInt();
        wt.labelType = parts[5].toInt();
        wt.labelNum = parts[6].toInt();
        if (parts.size() > 7) wt.name = parts[7];
        if (parts.size() > 8) wt.note = parts[8];
        m_wIni.wTerm.append(wt);
    }

    ini.endGroup();
}

void WarEdit::readW()
{
    IniConfig &cfg = IniConfig::instance();
    QString warPath = cfg.gamePath + "/" + cfg.warFileName;

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

    for (int w = 0; w < warCount; ++w) {
        auto &rec = m_warFile.records[w];
        rec.fields.resize(m_wIni.wTerm.size());
        int pos = w * recSize;

        for (int f = 0; f < m_wIni.wTerm.size(); ++f) {
            const auto &wt = m_wIni.wTerm[f];
            auto &field = rec.fields[f];
            field.values.resize(wt.datanum * wt.incnum);

            for (int d = 0; d < wt.datanum * wt.incnum; ++d) {
                int64_t val = 0;
                for (int b = 0; b < wt.datalen && pos + b < data.size(); ++b)
                    val |= ((int64_t)(uint8_t)data[pos + b]) << (b * 8);
                field.values[d] = val;
                pos += wt.datalen;
            }
        }
    }

    // 填充战斗选择框
    m_warCombo->blockSignals(true);
    m_warCombo->clear();
    for (int i = 0; i < warCount; ++i)
        m_warCombo->addItem(QString::number(i));
    m_warCombo->blockSignals(false);
}

void WarEdit::onLoad()
{
    readWIni();
    readW();
    if (!m_warFile.records.isEmpty()) {
        m_warCombo->setCurrentIndex(0);
        onWarChanged(0);
    }
}

void WarEdit::displayW()
{
    if (m_currentWar < 0 || m_currentWar >= m_warFile.records.size()) return;
    const auto &rec = m_warFile.records[m_currentWar];

    int totalRows = 0;
    for (const auto &wt : m_wIni.wTerm) totalRows += wt.datanum * wt.incnum;
    m_table->setRowCount(totalRows);

    int row = 0;
    for (int f = 0; f < m_wIni.wTerm.size() && f < rec.fields.size(); ++f) {
        const auto &wt = m_wIni.wTerm[f];
        const auto &field = rec.fields[f];
        for (int d = 0; d < field.values.size(); ++d) {
            QString name = wt.name;
            if (wt.datanum > 1 || wt.incnum > 1)
                name += QString("[%1]").arg(d);
            m_table->setItem(row, 0, new QTableWidgetItem(name));
            m_table->setItem(row, 1, new QTableWidgetItem(QString::number(field.values[d])));
            m_table->setItem(row, 2, new QTableWidgetItem(wt.note));
            m_table->item(row, 0)->setFlags(m_table->item(row, 0)->flags() & ~Qt::ItemIsEditable);
            m_table->item(row, 2)->setFlags(m_table->item(row, 2)->flags() & ~Qt::ItemIsEditable);
            row++;
        }
    }
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
    for (int f = 0; f < m_wIni.wTerm.size() && f < rec.fields.size(); ++f) {
        const auto &wt = m_wIni.wTerm[f];
        if (wt.isMapNum > 0 && wt.labelType >= 0) {
            // 查找对应位置数据
            for (int d = 0; d < rec.fields[f].values.size(); ++d) {
                WarPos wp;
                wp.id = rec.fields[f].values[d];
                wp.x = 0; wp.y = 0; // 需要从labelType/labelNum引用查找
                if (wt.labelType == 0) m_warFriend.append(wp);
                else m_warEnemy.append(wp);
            }
        }
    }
}

void WarEdit::drawWarPos()
{
    int mapW = 400, mapH = 400;
    QImage img(mapW, mapH, QImage::Format_ARGB32);
    img.fill(QColor(100, 150, 100));
    QPainter p(&img);

    int scale = m_scaleSpin->value();
    int tileW = 18 * scale, tileH = 9 * scale;

    auto isoToScreen = [&](int ix, int iy) -> QPoint {
        int sx = (ix - iy) * tileW / 2 + mapW / 2;
        int sy = (ix + iy) * tileH / 2 + 20;
        return {sx, sy};
    };

    // Draw friend positions (blue)
    p.setPen(QPen(Qt::blue, 2));
    for (const auto &wp : m_warFriend) {
        QPoint sp = isoToScreen(wp.x, wp.y);
        p.drawEllipse(sp, 8, 8);
        p.drawText(sp.x() - 4, sp.y() + 4, QString::number(wp.id));
    }

    // Draw enemy positions (red)
    p.setPen(QPen(Qt::red, 2));
    for (const auto &wp : m_warEnemy) {
        QPoint sp = isoToScreen(wp.x, wp.y);
        p.drawEllipse(sp, 8, 8);
        p.drawText(sp.x() - 4, sp.y() + 4, QString::number(wp.id));
    }

    m_posImage->setPixmap(QPixmap::fromImage(img));
    m_posImage->resize(img.size());
}

void WarEdit::onSave()
{
    // 从表格回写到m_warFile
    if (m_currentWar < 0) return;
    auto &rec = m_warFile.records[m_currentWar];
    int row = 0;
    for (int f = 0; f < m_wIni.wTerm.size() && f < rec.fields.size(); ++f) {
        for (int d = 0; d < rec.fields[f].values.size(); ++d) {
            auto *item = m_table->item(row, 1);
            if (item) rec.fields[f].values[d] = item->text().toLongLong();
            row++;
        }
    }

    // 写入二进制文件
    IniConfig &cfg = IniConfig::instance();
    QString warPath = cfg.gamePath + "/" + cfg.warFileName;
    QFile file(warPath);
    if (!file.open(QIODevice::WriteOnly)) return;

    for (const auto &rec2 : m_warFile.records) {
        for (int f = 0; f < m_wIni.wTerm.size() && f < rec2.fields.size(); ++f) {
            const auto &wt = m_wIni.wTerm[f];
            for (int d = 0; d < rec2.fields[f].values.size(); ++d) {
                int64_t val = rec2.fields[f].values[d];
                for (int b = 0; b < wt.datalen; ++b)
                    file.putChar((val >> (b * 8)) & 0xFF);
            }
        }
    }
    QMessageBox::information(this, tr("保存"), tr("保存成功"));
}

void WarEdit::onNewWar()
{
    WRecord rec;
    rec.fields.resize(m_wIni.wTerm.size());
    for (int f = 0; f < m_wIni.wTerm.size(); ++f)
        rec.fields[f].values.resize(m_wIni.wTerm[f].datanum * m_wIni.wTerm[f].incnum, 0);
    m_warFile.records.append(rec);
    m_warFile.typeCount = m_warFile.records.size();
    m_warCombo->addItem(QString::number(m_warFile.records.size() - 1));
    m_warCombo->setCurrentIndex(m_warFile.records.size() - 1);
}

void WarEdit::onDeleteWar()
{
    if (m_currentWar < 0 || m_currentWar >= m_warFile.records.size()) return;
    m_warFile.records.removeAt(m_currentWar);
    m_warFile.typeCount = m_warFile.records.size();
    m_warCombo->removeItem(m_currentWar);
}

void WarEdit::onExportExcel() { /* TODO: xlsxwriter export */ }
void WarEdit::onImportExcel() { /* TODO: xlsxio import */ }
void WarEdit::onDrawPosition() { drawWarPos(); }
