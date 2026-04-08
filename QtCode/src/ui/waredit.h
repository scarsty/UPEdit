#pragma once
#include <QWidget>
#include <QComboBox>
#include <QTableWidget>
#include <QPushButton>
#include <QCheckBox>
#include <QSpinBox>
#include <QLabel>
#include <QImage>
#include <QScrollArea>
#include <QStatusBar>
#include "head.h"

// 战斗数据编辑器 (对应 Delphi TForm10)
class WarEdit : public QWidget {
    Q_OBJECT
public:
    explicit WarEdit(QWidget *parent = nullptr);

private slots:
    void onLoad();
    void onSave();
    void onNewWar();
    void onDeleteWar();
    void onExportExcel();
    void onImportExcel();
    void onWarChanged(int index);
    void onDrawPosition();
    void onCellDoubleClicked(int row, int column);

private:
    struct WarRowInfo { int fieldIdx = -1; int valueIdx = -1; };
    QVector<WarRowInfo> m_rowMap;
    void readWIni();
    void readW();
    void displayW();
    void drawWarPos();
    void countWarPos();

    QComboBox *m_warCombo;
    QTableWidget *m_table;
    QLabel *m_posImage;
    QScrollArea *m_posScroll;
    QCheckBox *m_showMap;
    QSpinBox *m_scaleSpin;
    QStatusBar *m_statusBar;

    WFile m_warFile;
    QVector<WSelect> m_wSelect;
    WIni m_wIni;
    QVector<WarPos> m_warFriend, m_warEnemy;
    int m_currentWar = -1;
};
