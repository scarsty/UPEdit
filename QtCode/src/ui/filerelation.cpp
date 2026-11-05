#include "filerelation.h"
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QPushButton>
#include <QLabel>
#include <QMessageBox>
#include <QApplication>
#include <QSettings>
#include <QDir>
#include <QRegularExpression>

#ifdef Q_OS_WIN
#include <QSettings>
#include <windows.h>
#include <shlobj.h>
#endif

FileRelation::FileRelation(QWidget *parent) : QDialog(parent)
{
    setWindowTitle(tr("文件关联设置"));
    auto *layout = new QVBoxLayout(this);

    layout->addWidget(new QLabel(tr("选择要关联到 UPEdit 的文件类型:")));

    m_grpCheck = new QCheckBox(tr("*.grp — GRP编辑器"));
    m_idxCheck = new QCheckBox(tr("*.idx — GRP编辑器"));
    m_picCheck = new QCheckBox(tr("*.pic — 图片编辑器"));
    m_bmpCheck = new QCheckBox(tr("*.bmp — GRP导入"));
    m_pngCheck = new QCheckBox(tr("*.png — GRP导入"));
    m_jpgCheck = new QCheckBox(tr("*.jpg — GRP导入"));
    m_gifCheck = new QCheckBox(tr("*.gif — GRP导入"));
    m_imzCheck = new QCheckBox(tr("*.imz — IMZ编辑器"));
    m_zipCheck = new QCheckBox(tr("*.zip - PNG压缩包编辑器"));
    m_jpegCheck = new QCheckBox(tr("*.jpeg - GRP导入"));

    layout->addWidget(m_grpCheck);
    layout->addWidget(m_idxCheck);
    layout->addWidget(m_picCheck);
    layout->addWidget(m_bmpCheck);
    layout->addWidget(m_pngCheck);
    layout->addWidget(m_jpgCheck);
    layout->addWidget(m_gifCheck);
    layout->addWidget(m_imzCheck);
    layout->addWidget(m_zipCheck);
    layout->addWidget(m_jpegCheck);

    auto *btnRow = new QHBoxLayout;
    auto *btnOK = new QPushButton(tr("确定"));
    auto *btnCancel = new QPushButton(tr("取消"));
    btnRow->addStretch();
    btnRow->addWidget(btnOK);
    btnRow->addWidget(btnCancel);
    layout->addLayout(btnRow);

    connect(btnOK, &QPushButton::clicked, this, &FileRelation::onConfirm);
    connect(btnCancel, &QPushButton::clicked, this, &QDialog::reject);
}

bool FileRelation::registerFileType(QSettings &classes, const QString &ext, const QString &desc, const QString &appPath)
{
    if (!QRegularExpression("^[a-z0-9]+$").match(ext).hasMatch()
        || appPath.isEmpty() || appPath.contains('"') || appPath.contains('\n') || appPath.contains('\r')) return false;
    QString progId = "UPEdit." + ext;

    classes.setValue(progId + "/Default", desc);
    classes.setValue(progId + "/DefaultIcon/Default", "\"" + appPath + "\",0");
    classes.setValue(progId + "/shell/open/command/Default",
                    "\"" + appPath + "\" \"%1\"");
    classes.sync();
    if (classes.status() != QSettings::NoError) return false;
    classes.setValue("." + ext + "/OpenWithProgids/" + progId, QString());
    classes.setValue("." + ext + "/Default", progId);
    classes.sync();
    return classes.status() == QSettings::NoError;
}

void FileRelation::onConfirm()
{
#ifdef Q_OS_WIN
    QSettings classes("HKEY_CURRENT_USER\\Software\\Classes", QSettings::NativeFormat);
    QString appPath = QDir::toNativeSeparators(QApplication::applicationFilePath());
    const QList<QPair<QCheckBox *, QString>> types = {
        {m_grpCheck, "grp"}, {m_idxCheck, "idx"}, {m_picCheck, "pic"}, {m_bmpCheck, "bmp"},
        {m_pngCheck, "png"}, {m_jpgCheck, "jpg"}, {m_jpegCheck, "jpeg"}, {m_gifCheck, "gif"},
        {m_imzCheck, "imz"}, {m_zipCheck, "zip"}};
    QStringList failed;
    for (const auto &type : types)
        if (type.first->isChecked() && !registerFileType(classes, type.second, "UPEdit " + type.second, appPath))
            failed.append("." + type.second);
    SHChangeNotify(SHCNE_ASSOCCHANGED, SHCNF_IDLIST, nullptr, nullptr);
    if (!failed.isEmpty()) {
        QMessageBox::warning(this, tr("文件关联"), tr("以下类型登记失败：%1").arg(failed.join(", ")));
        return;
    }
    QMessageBox::information(this, tr("完成"), tr("打开方式已登记。Windows 默认应用选择可能仍需在系统设置中确认。"));
    accept();
#else
    QMessageBox::warning(this, tr("文件关联"), tr("当前平台不支持此登记方式。"));
#endif
}
