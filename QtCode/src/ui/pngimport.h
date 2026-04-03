#pragma once
#include <QWidget>
#include <QLineEdit>
#include <QPushButton>
#include <QProgressBar>
#include <QLabel>
#include <QListWidget>
#include <QCheckBox>
#include <QDialog>
#include "head.h"

// PNG 批量导入 (对应 Delphi TForm94)
class PNGImport : public QWidget {
    Q_OBJECT
public:
    explicit PNGImport(QWidget *parent = nullptr);

private slots:
    void onOpenCol();
    void onOpenIdx();
    void onOpenGrp();
    void onAddFiles();
    void onModifyEntry();
    void onDeleteEntry();
    void onStartImport();

private:
    void loadPalette(const QString &path);
    void importPNG(int index);

    QLineEdit *m_colEdit, *m_idxEdit, *m_grpEdit;
    QListWidget *m_fileList;
    QProgressBar *m_progress;

    struct PNGEntry {
        QString fileName;
        int xOff = 0, yOff = 0;
        bool keepPNG = false;
        bool transparent = false;
        uint32_t transColor = 0;
    };
    QVector<PNGEntry> m_entries;
    QVector<QRgb> m_palette;
};

// PNG 导入偏移设置对话框 (对应 Delphi TForm95)
class PNGImportModify : public QDialog {
    Q_OBJECT
public:
    explicit PNGImportModify(const QImage &preview, QWidget *parent = nullptr);
    int xOffset() const;
    int yOffset() const;
    bool applyAll() const;
    bool keepPNG() const;
    bool useTransColor() const;
    QColor transColor() const;

private:
    void drawOffset();

    QLineEdit *m_xEdit, *m_yEdit;
    QLabel *m_previewLabel;
    QCheckBox *m_applyAllCheck, *m_keepPNGCheck, *m_transCheck;
    QPushButton *m_colorBtn;
    QImage m_preview;
    QColor m_transCol;
};

// PNG 批量导出 (对应 Delphi TForm88)
class PNGExport : public QDialog {
    Q_OBJECT
public:
    explicit PNGExport(QWidget *parent = nullptr);
    void startExport(const QVector<GrpPic> &pics, const QVector<QRgb> &palette);

private slots:
    void onSelectPath();
    void onStart();
    void onStop();

private:
    QLineEdit *m_pathEdit;
    QProgressBar *m_progress;
    QLabel *m_statusLabel;
    bool m_running = false;
    QVector<GrpPic> m_pics;
    QVector<QRgb> m_palette;
};
