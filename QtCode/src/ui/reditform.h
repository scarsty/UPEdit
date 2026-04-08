#pragma once

/*
 * R-数据详情编辑表单
 * 对应原 Delphi 版 Reditform.pas / TForm6
 * 显示单条记录的所有字段，可编辑
 */

#include <QWidget>
#include <QTableWidget>
#include <QVBoxLayout>
#include "head.h"
#include "rfile.h"

class REditForm : public QWidget {
    Q_OBJECT
public:
    explicit REditForm(QWidget *parent = nullptr);

    void setRFile(RFile *prf) { m_pRFile = prf; }
    void displayRecord(int typeIndex, int recordIndex);

private slots:
    void onCellChanged(int row, int column);

private:
    QTableWidget *m_table = nullptr;
    RFile *m_pRFile       = nullptr; // 指向 REditWidget::m_rFile
    int m_typeIndex   = -1;
    int m_recordIndex = -1;
    bool m_updating   = false;
};
