#pragma once
#include <QDialog>
#include <QLineEdit>
#include <QPushButton>

// 战斗帧数设置对话框 (对应 Delphi TFightFrameForm)
class FightFrameForm : public QDialog {
    Q_OBJECT
public:
    explicit FightFrameForm(QWidget *parent = nullptr);

    void setContent(const QString &content);
    QString content() const;

private slots:
    void onConfirm();

private:
    // 5种攻击方式: 匕/拿/刺/劈/特
    QLineEdit *m_edit[5];
    QString m_content;
};
