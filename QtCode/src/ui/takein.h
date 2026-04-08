#pragma once
#include <QWidget>
#include <QLineEdit>
#include <QLabel>
#include <QCheckBox>
#include <QComboBox>
#include <QProgressBar>
#include "head.h"

// TAKEIN 图片导入到GRP (对应 Delphi TForm1)
class TakeIn : public QWidget {
    Q_OBJECT
public:
    explicit TakeIn(QWidget *parent = nullptr);

private slots:
    void onOpenImage();
    void onImportToGrp();
    void onSetTransColor();
    void onConfirmSize();

private:
    void displayImage();

    QLabel *m_imageLabel;
    QLineEdit *m_widthEdit, *m_heightEdit;
    QLineEdit *m_xoffEdit, *m_yoffEdit;
    QLineEdit *m_transColorEdit;
    QCheckBox *m_transCheck;
    QComboBox *m_grpCombo;
    QProgressBar *m_progress;

    QImage m_sourceImage;
    uint8_t m_palR[256]{}, m_palG[256]{}, m_palB[256]{};
    QRgb m_transColor = 0;
};
