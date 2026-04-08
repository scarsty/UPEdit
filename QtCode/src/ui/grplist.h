#pragma once
#include <QWidget>
#include <QImage>
#include <QScrollBar>
#include <QComboBox>
#include <QPushButton>
#include <QLabel>
#include <QMenu>
#include <QProgressBar>
#include "head.h"

// GRP 组贴图浏览器 (对应 Delphi TForm3)
class GrpList : public QWidget {
    Q_OBJECT
public:
    explicit GrpList(QWidget *parent = nullptr);

    void loadGrpFiles(const QString &idxPath, const QString &grpPath, const QString &colPath = {});

    const QVector<GrpPic> &grpPics() const { return m_grpPics; }
    const QVector<QRgb> &palette() const { return m_palette; }

signals:
    void editSprite(int index);

private slots:
    void onOpenIdx();
    void onOpenGrp();
    void onOpenCol();
    void onDisplay();
    void onSave();
    void onScroll(int value);
    void onContextMenu(const QPoint &pos);
    void onEditCurrent();
    void onDeleteCurrent();
    void onInsertBefore();
    void onExportAllPNG();
    void onReplacePNG();
    void onBatchOffset();
    void onPresetChanged(int index);
    void onSectionChanged(int index);
    void onBgColorPick();
    void onTextColorPick();

protected:
    void resizeEvent(QResizeEvent *e) override;
    void mousePressEvent(QMouseEvent *e) override;

private:
    void displayGrpList();
    void loadPalette(const QString &path);
    void updateSectionCombo();
    QImage decodeSprite(int index);

    QLineEdit *m_idxEdit, *m_grpEdit, *m_colEdit;
    QComboBox *m_presetCombo;
    QComboBox *m_sectionCombo;
    QLabel *m_imageLabel;
    QScrollBar *m_scrollBar;
    QProgressBar *m_progress;
    QMenu *m_contextMenu;
    QLabel *m_bgColorPanel;
    QLabel *m_textColorPanel;

    QVector<GrpPic> m_grpPics;
    QVector<QRgb> m_palette;     // 256色调色板
    int m_cols = 10;             // 每行列数
    int m_nowPic = -1;           // 当前选中
    int m_scrollOffset = 0;
    int m_beginPic = 0;          // 当前显示范围起始
    int m_endPic = -1;           // 当前显示范围结束 (-1 = 全部)
    QColor m_bgColor = Qt::white;
    QColor m_textColor = Qt::red;
};
