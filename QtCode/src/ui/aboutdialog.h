#pragma once
#include <QDialog>
#include <QLabel>
#include <QVBoxLayout>

class AboutDialog : public QDialog {
    Q_OBJECT
public:
    explicit AboutDialog(QWidget *parent = nullptr)
        : QDialog(parent)
    {
        setWindowTitle(tr("关于 UPedit"));
        auto *layout = new QVBoxLayout(this);
        layout->addWidget(new QLabel(
            tr("<h2>UPedit (Qt版)</h2>"
               "<p>金庸群侠传编辑器</p>"
               "<p>原作者: Upwinded.L. ©2011</p>"
               "<p>Qt C++ 移植版</p>"), this));
        resize(350, 200);
    }
};
