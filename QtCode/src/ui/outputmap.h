#pragma once
#include <QDialog>
#include <QTextEdit>
#include <QGroupBox>
#include <QCheckBox>
#include <QLineEdit>

// 地图导出对话框 (对应 Delphi TForm93)
class OutputMap : public QDialog {
    Q_OBJECT
public:
    explicit OutputMap(QWidget *parent = nullptr);

private slots:
    void onExport();
    void onSelectFont();

private:
    QCheckBox *m_drawNamesCheck;
    QCheckBox *m_groundCheck, *m_surfaceCheck, *m_buildingCheck;
    QLineEdit *m_fileEdit, *m_zoomEdit;
    QTextEdit *m_logText;
    QPushButton *m_fontBtn, *m_colorBtn;
    QFont m_mapFont;
    QColor m_mapColor;
};
