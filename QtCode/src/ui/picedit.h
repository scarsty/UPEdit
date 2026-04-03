#pragma once
#include <QWidget>
#include <QImage>
#include <QScrollArea>
#include <QSpinBox>
#include <QPushButton>
#include <QLabel>
#include <QProgressBar>
#include "head.h"

// PIC 图片编辑器 (对应 Delphi TForm4)
class PicEdit : public QWidget {
    Q_OBJECT
public:
    explicit PicEdit(QWidget *parent = nullptr);
    void openFile(const QString &path);

private slots:
    void onOpen();
    void onSave();
    void onPrev();
    void onNext();
    void onCopy();
    void onPaste();
    void onInsert();
    void onDelete();
    void onExportAll();
    void onIndexChanged(int val);

private:
    void readPicFile(const QString &path);
    void displayCurrent();
    void drawThumbnails();

    QSpinBox *m_indexSpin;
    QScrollArea *m_scroll;
    QLabel *m_imageLabel;
    QLabel *m_thumbLabel;
    QSpinBox *m_xoffSpin, *m_yoffSpin;
    QProgressBar *m_progress;

    struct PicData {
        int width = 0, height = 0;
        int background = 0;
        QByteArray data;
        int picType = 0; // 0=raw, 1=PNG, 2=JPG
    };
    QVector<PicData> m_pics;
    int m_currentIndex = 0;
    QString m_filePath;
};
