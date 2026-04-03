#pragma once
#include <QDialog>
#include <QCheckBox>

// 文件关联设置对话框 (对应 Delphi TForm92)
class FileRelation : public QDialog {
    Q_OBJECT
public:
    explicit FileRelation(QWidget *parent = nullptr);

private slots:
    void onConfirm();

private:
    void registerFileType(const QString &ext, const QString &desc, const QString &icon);

    QCheckBox *m_grpCheck, *m_idxCheck, *m_picCheck;
    QCheckBox *m_txtCheck, *m_bmpCheck, *m_pngCheck;
    QCheckBox *m_jpgCheck, *m_gifCheck, *m_imzCheck;
};
