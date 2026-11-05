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
    friend int runSelfTests(const QString &reportPath);
    void drawPNG();
    QImage imageFor(const GrpPic &picture) const;
    uint8_t m_red[256]{}, m_green[256]{}, m_blue[256]{};
    bool m_paletteReady = false;

    QLineEdit *m_idxEdit, *m_grpEdit;
    QLabel *m_imageLabel;
    QLabel *m_indexLabel;

    QVector<GrpPic> m_heads;
    int m_currentIndex = 0;
};
