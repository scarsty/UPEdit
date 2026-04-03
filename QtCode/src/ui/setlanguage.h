#pragma once
#include <QDialog>
#include <QRadioButton>
#include <QGroupBox>
#include <QLineEdit>

// 语言/编码设置对话框 (对应 Delphi TForm8)
class SetLanguage : public QDialog {
    Q_OBJECT
public:
    explicit SetLanguage(QWidget *parent = nullptr);

private slots:
    void onConfirm();

private:
    QRadioButton *m_dataGBK, *m_dataBIG5, *m_dataUTF16, *m_dataUTF8;
    QRadioButton *m_talkGBK, *m_talkBIG5, *m_talkUTF16, *m_talkUTF8;
    QRadioButton *m_invertYes, *m_invertNo;
    QRadioButton *m_updateCheck, *m_updateSilent, *m_updateNone;
    QLineEdit *m_tileScaleEdit;
};
