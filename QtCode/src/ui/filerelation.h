#pragma once
#include <QDialog>
#include <QCheckBox>
class QSettings;

// 文件关联设置对话框 (对应 Delphi TForm92)
class FileRelation : public QDialog {
    Q_OBJECT
    friend int runSelfTests(const QString &reportPath);
public:
    explicit FileRelation(QWidget *parent = nullptr);

private slots:
    void onConfirm();

private:
    static bool registerFileType(QSettings &classes, const QString &ext, const QString &desc, const QString &appPath);

    QCheckBox *m_grpCheck, *m_idxCheck, *m_picCheck;
    QCheckBox *m_bmpCheck, *m_pngCheck;
    QCheckBox *m_jpgCheck, *m_gifCheck, *m_imzCheck;
    QCheckBox *m_jpegCheck, *m_zipCheck;
};
