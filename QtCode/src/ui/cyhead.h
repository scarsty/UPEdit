#pragma once
#include <QWidget>
#include <QLineEdit>
#include <QPushButton>
#include <QLabel>
#include "head.h"

// CY 头像编辑器 (对应 Delphi TForm89)
class CYHead : public QWidget {
    Q_OBJECT
public:
    explicit CYHead(QWidget *parent = nullptr);

private slots:
    void onOpenIdx();
    void onOpenGrp();
    void onLoad();
    void onSave();
    void onPrev();
    void onNext();
    void onPrev10();
    void onNext10();
    void onReplacePNG();
    void onExportAll();

private:
    void drawPNG();

    QLineEdit *m_idxEdit, *m_grpEdit;
    QLabel *m_imageLabel;
    QLabel *m_indexLabel;

    QVector<GrpPic> m_heads;
    int m_currentIndex = 0;
};
