#pragma once
#include <QWidget>
#include <QScrollBar>
#include <QComboBox>
#include <QPushButton>
#include <QLineEdit>
#include <QCheckBox>
#include <QLabel>
#include <QMenu>
#include <QTimer>
#include <QRadioButton>
#include "head.h"

// IMZ/PNG 容器编辑器 (对应 Delphi TImzForm)
class ImagezForm : public QWidget {
    Q_OBJECT
public:
    explicit ImagezForm(QWidget *parent = nullptr);
    void openImzFile(const QString &path);

private slots:
    void onRead();
    void onReadFolder();
    void onDisplay();
    void onSave();
    void onScroll(int value);
    void onAnimate();
    void onContextMenu(const QPoint &pos);
    void onEditSprite();
    void onCopySprite();
    void onPasteSprite();
    void onDeleteSprite();
    void onInsertSprite();
    void onExportAllPNG();
    void onSetFightFrames();
    void onPack();
    void onUnpack();

private:
    void readImzFromFile(const QString &path);
    void readImzFromFolder(const QString &dir);
    void drawImz();
    QImage drawImzPNG(int index);

    QLineEdit *m_fileEdit;
    QRadioButton *m_modeImz, *m_modePngFolder, *m_modePngZip;
    QCheckBox *m_animCheck;
    QLabel *m_imageLabel;
    QScrollBar *m_scrollBar;
    QTimer *m_animTimer;
    QMenu *m_contextMenu;

    Imz m_imz;
    int m_scrollOffset = 0;
    int m_cols = 10;
    int m_currentIndex = -1;
    int m_animFrame = 0;
    QString m_currentPath;
};
