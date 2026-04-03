#pragma once

/*
 * R-数据编辑器 (核心编辑窗口)
 * 对应原 Delphi 版 Redit.pas / TForm5
 * 功能: 编辑人物、物品、场景等所有游戏 R 文件记录
 */

#include <QWidget>
#include <QComboBox>
#include <QListWidget>
#include <QPushButton>
#include <QLineEdit>
#include <QRadioButton>
#include <QStatusBar>
#include <QLabel>
#include <QSplitter>
#include "head.h"
#include "rfile.h"

class REditForm;

class REditWidget : public QWidget {
    Q_OBJECT
public:
    explicit REditWidget(QWidget *parent = nullptr);
    ~REditWidget();

private slots:
    void onTypeChanged(int index);
    void onRecordChanged(int index);
    void onFieldClicked(int row);
    void onFieldDoubleClicked(int row);
    void onSave();
    void onReload();
    void onNewRecord();
    void onDeleteRecord();
    void onCopyRecord();
    void onPasteRecord();
    void onBatchEdit();
    void onExportXlsx();
    void onImportXlsx();
    void onSearch();
    void onSearchRange();

private:
    void setupUI();
    void displayR();
    void arrange();
    void populateTypes();
    void populateRecords();
    void populateFields();

    QComboBox   *m_typeCombo    = nullptr; // 类型选择
    QComboBox   *m_recordCombo  = nullptr; // 记录选择 (按编号)
    QComboBox   *m_fieldCombo   = nullptr; // 字段选择 (批量操作用)
    QListWidget *m_recordList   = nullptr; // 记录列表 (带勾选)
    QPushButton *m_btnSave      = nullptr;
    QPushButton *m_btnReload    = nullptr;
    QPushButton *m_btnNew       = nullptr;
    QPushButton *m_btnDelete    = nullptr;
    QPushButton *m_btnCopy      = nullptr;
    QPushButton *m_btnPaste     = nullptr;
    QPushButton *m_btnSearch    = nullptr;
    QPushButton *m_btnExport    = nullptr;
    QPushButton *m_btnImport    = nullptr;
    QRadioButton *m_radioChecked = nullptr;
    QRadioButton *m_radioRange   = nullptr;
    QLineEdit   *m_editFrom     = nullptr;
    QLineEdit   *m_editTo       = nullptr;
    QLineEdit   *m_editValue    = nullptr;
    QComboBox   *m_opCombo      = nullptr; // 赋值/加/减/乘/除

    QSplitter   *m_splitter     = nullptr;

    // 右侧详情编辑区域
    REditForm   *m_editForm     = nullptr;

    QStatusBar  *m_statusBar    = nullptr;

    // 选择项列表
    QVector<Select> m_select;
    int m_currentType   = -1;
    int m_currentRecord = -1;
};
