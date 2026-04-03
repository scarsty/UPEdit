#include "updatedialog.h"
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QPushButton>
#include <QNetworkAccessManager>
#include <QNetworkReply>

UpdateDialog::UpdateDialog(QWidget *parent) : QDialog(parent)
{
    setWindowTitle(tr("检查更新"));
    auto *layout = new QVBoxLayout(this);

    m_statusLabel = new QLabel(tr("正在检查更新..."));
    m_progress = new QProgressBar;
    m_progress->setRange(0, 0); // Indeterminate

    layout->addWidget(m_statusLabel);
    layout->addWidget(m_progress);

    auto *btnRow = new QHBoxLayout;
    auto *btnClose = new QPushButton(tr("关闭"));
    btnRow->addStretch();
    btnRow->addWidget(btnClose);
    layout->addLayout(btnRow);

    connect(btnClose, &QPushButton::clicked, this, &QDialog::close);
}

void UpdateDialog::checkForUpdate(const QString &url)
{
    auto *mgr = new QNetworkAccessManager(this);
    auto *reply = mgr->get(QNetworkRequest(QUrl(url)));
    connect(reply, &QNetworkReply::finished, this, &UpdateDialog::onDownloadFinished);
}

void UpdateDialog::onDownloadFinished()
{
    auto *reply = qobject_cast<QNetworkReply*>(sender());
    if (!reply) return;

    if (reply->error() != QNetworkReply::NoError) {
        m_statusLabel->setText(tr("检查更新失败: %1").arg(reply->errorString()));
        m_progress->setRange(0, 1);
        m_progress->setValue(1);
        reply->deleteLater();
        return;
    }

    QByteArray data = reply->readAll();
    QString version = QString::fromUtf8(data).trimmed();

    // 简单版本比较
    m_statusLabel->setText(tr("最新版本: %1").arg(version));
    m_progress->setRange(0, 1);
    m_progress->setValue(1);
    reply->deleteLater();
}
