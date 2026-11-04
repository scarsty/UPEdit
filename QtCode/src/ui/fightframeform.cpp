#include "fightframeform.h"
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QLabel>
#include <QDialogButtonBox>
#include <QMessageBox>

FightFrameForm::FightFrameForm(QWidget *parent) : QDialog(parent)
{
    setWindowTitle(tr("战斗帧数设置"));
    auto *layout = new QVBoxLayout(this);

    QStringList labels = {tr("匕"), tr("拿"), tr("刺"), tr("劈"), tr("特")};
    for (int i = 0; i < 5; ++i) {
        auto *row = new QHBoxLayout;
        row->addWidget(new QLabel(labels[i]));
        m_edit[i] = new QLineEdit("0");
        row->addWidget(m_edit[i]);
        layout->addLayout(row);
    }

    auto *buttons = new QDialogButtonBox(QDialogButtonBox::Ok | QDialogButtonBox::Cancel);
    layout->addWidget(buttons);

    connect(buttons, &QDialogButtonBox::accepted, this, &FightFrameForm::onConfirm);
    connect(buttons, &QDialogButtonBox::rejected, this, &QDialog::reject);
}

void FightFrameForm::setContent(const QString &content)
{
    m_content = content;
    // 解析 "index, value\n" 格式
    QStringList lines = content.split('\n', Qt::SkipEmptyParts);
    for (const auto &line : lines) {
        QStringList parts = line.split(',', Qt::SkipEmptyParts);
        if (parts.size() >= 2) {
            int idx = parts[0].trimmed().toInt();
            if (idx >= 0 && idx < 5)
                m_edit[idx]->setText(parts[1].trimmed());
        }
    }
}

QString FightFrameForm::content() const { return m_content; }

void FightFrameForm::onConfirm()
{
    QString content;
    for (int i = 0; i < 5; ++i) {
        bool valid = false;
        int val = m_edit[i]->text().toInt(&valid);
        if (!valid) {
            QMessageBox::warning(this, tr("战斗帧"), tr("请输入有效整数"));
            m_edit[i]->setFocus();
            return;
        }
        if (val != 0)
            content += QString("%1, %2\n").arg(i).arg(val);
    }
    m_content = content;
    accept();
}
