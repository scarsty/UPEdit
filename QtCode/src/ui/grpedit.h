#pragma once
#include <QWidget>
#include <QImage>
#include <QComboBox>
#include <QScrollArea>
#include <QLabel>
#include <QPushButton>
#include <QSpinBox>
#include <QCheckBox>
#include "head.h"

// GRP 单贴图编辑器 (对应 Delphi TForm2)
class GrpEdit : public QWidget {
    Q_OBJECT
public:
    enum EditMode { PicMode, GrpMode };
    explicit GrpEdit(QWidget *parent = nullptr);

    void setSprite(const GrpPic &pic, const QVector<QRgb> &palette);
    void setSpriteData(QByteArray data, int w, int h, int xoff, int yoff);
    GrpPic resultSprite() const;

    void setPalette(const QVector<QRgb> &pal);

protected:
    bool eventFilter(QObject *watched, QEvent *event) override;

signals:
    void spriteModified(const GrpPic &pic);

private slots:
    void onZoomChanged(int index);
    void onCopy();
    void onPaste();
    void onSave();
    void onFlipH();
    void onFlipV();
    void onRotate90();
    void onRotate270();
    void onPaletteClicked(const QPoint &pos);
    void onImageClicked(const QPoint &pos);

private:
    void display();
    void drawPalette();
    void decodeRLE8(const GrpPic &pic);
    QByteArray encodeRLE8();

    QScrollArea *m_scroll;
    QLabel *m_imageLabel;
    QLabel *m_paletteLabel;
    QComboBox *m_zoomCombo;
    QComboBox *m_toolCombo;
    QSpinBox *m_xoffSpin, *m_yoffSpin;
    QSpinBox *m_widthSpin, *m_heightSpin;
    QCheckBox *m_showOffset;
    QRgb m_customColor = qRgb(0, 0, 0);
    bool m_useCustomColor = false;

    QImage m_bitmap;       // 工作位图(ARGB32)
    QVector<QRgb> m_pal;   // 256色调色板
    int m_zoom = 1;
    int m_xmove = 0, m_ymove = 0;
    int m_curColor = 0;    // 当前选中调色板颜色
    EditMode m_editMode = GrpMode;
    bool m_keepPNG = false;
};
