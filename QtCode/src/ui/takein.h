#pragma once
#include <QDialog>
#include <QLineEdit>

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
    QByteArray picToRLE8(const QImage &img, const QRect &region, bool useTrans, QRgb transColor);

    QLabel *m_imageLabel;
    QLineEdit *m_widthEdit, *m_heightEdit;
    QLineEdit *m_xoffEdit, *m_yoffEdit;
    QLineEdit *m_transColorEdit;
    QCheckBox *m_transCheck;
    QComboBox *m_grpCombo;
    QProgressBar *m_progress;

    QImage m_sourceImage;
    QVector<QRgb> m_palette;
    QRgb m_transColor = 0;
};
