#pragma once
#include <QDialog>
#include <QProgressBar>
#include <QLabel>

// 更新对话框 (对应 Delphi TForm87)
class UpdateDialog : public QDialog {
    Q_OBJECT
public:
    explicit UpdateDialog(QWidget *parent = nullptr);
    void checkForUpdate(const QString &url);

private slots:
    void onDownloadFinished();

private:
    QLabel *m_statusLabel;
    QProgressBar *m_progress;
};
