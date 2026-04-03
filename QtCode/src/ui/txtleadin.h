#pragma once
#include <QWidget>
#include <QLineEdit>
#include <QTextEdit>
#include <QPushButton>

// Lua 脚本导入/执行器 (对应 Delphi TForm91 TxtLeadin)
class TxtLeadIn : public QWidget {
    Q_OBJECT
public:
    explicit TxtLeadIn(QWidget *parent = nullptr);

private slots:
    void onSelectFile();
    void onExecute();

private:
    void openScript(const QString &path);
    void registerLuaFunctions();

    QLineEdit *m_pathEdit;
    QTextEdit *m_logText;
};
