#pragma once
#include <QWidget>
#include <QImage>
#include <QScrollArea>
#include <QSpinBox>
#include <QPushButton>
#include <QLabel>
#include <QProgressBar>
#include <QCheckBox>
#include "head.h"

// PIC 图片编辑器 (对应 Delphi TForm4)
class PicEdit : public QWidget {
    Q_OBJECT
public:
    explicit PicEdit(QWidget *parent = nullptr);
    void openFile(const QString &path);
    struct PicData {
        qint32 xoff = 0, yoff = 0, background = 0;
        QByteArray data;
    };
    static bool decodeFile(const QByteArray &bytes, QVector<PicData> &pictures);
    static QByteArray encodeFile(const QVector<PicData> &pictures);

protected:
    bool eventFilter(QObject *watched, QEvent *event) override;

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
    void displayCurrent();
    void drawThumbnails();
    void insertImage(bool append);
    void updateMetadata();

    QSpinBox *m_indexSpin;
    QScrollArea *m_scroll;
    QLabel *m_imageLabel;
    QLabel *m_thumbLabel;
    QSpinBox *m_xoffSpin, *m_yoffSpin;
    QCheckBox *m_backgroundCheck;
    QProgressBar *m_progress;

    QVector<PicData> m_pics;
    int m_currentIndex = 0;
    QString m_filePath;
};
