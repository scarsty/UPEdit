#include "filerelation.h"
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QPushButton>
#include <QLabel>
#include <QMessageBox>
#include <QApplication>

#ifdef Q_OS_WIN
#include <QSettings>
#include <windows.h>
#endif

FileRelation::FileRelation(QWidget *parent) : QDialog(parent)
{
    setWindowTitle(tr("文件关联设置"));
    auto *layout = new QVBoxLayout(this);

    layout->addWidget(new QLabel(tr("选择要关联到 UPEdit 的文件类型:")));

    m_grpCheck = new QCheckBox(tr("*.grp — GRP编辑器"));
    m_idxCheck = new QCheckBox(tr("*.idx — GRP编辑器"));
    m_picCheck = new QCheckBox(tr("*.pic — 图片编辑器"));
    m_txtCheck = new QCheckBox(tr("*.txt — 脚本导入"));
    m_bmpCheck = new QCheckBox(tr("*.bmp — GRP导入"));
    m_pngCheck = new QCheckBox(tr("*.png — GRP导入"));
    m_jpgCheck = new QCheckBox(tr("*.jpg — GRP导入"));
    m_gifCheck = new QCheckBox(tr("*.gif — GRP导入"));
    m_imzCheck = new QCheckBox(tr("*.imz — IMZ编辑器"));

    layout->addWidget(m_grpCheck);
    layout->addWidget(m_idxCheck);
    layout->addWidget(m_picCheck);
    layout->addWidget(m_txtCheck);
    layout->addWidget(m_bmpCheck);
    layout->addWidget(m_pngCheck);
    layout->addWidget(m_jpgCheck);
    layout->addWidget(m_gifCheck);
    layout->addWidget(m_imzCheck);

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

void FileRelation::registerFileType(const QString &ext, const QString &desc, const QString &icon)
{
#ifdef Q_OS_WIN
    QString appPath = QApplication::applicationFilePath().replace('/', '\\');
    QString progId = "UPEdit." + ext;

    QSettings classes("HKEY_CURRENT_USER\\Software\\Classes", QSettings::NativeFormat);
    classes.setValue("." + ext + "/Default", progId);
    classes.setValue(progId + "/Default", desc);
    classes.setValue(progId + "/DefaultIcon/Default", appPath + ",0");
    classes.setValue(progId + "/shell/open/command/Default",
                    "\"" + appPath + "\" \"%1\"");

    // Notify shell
    SHChangeNotify(SHCNE_ASSOCCHANGED, SHCNF_IDLIST, nullptr, nullptr);
#else
    Q_UNUSED(ext); Q_UNUSED(desc); Q_UNUSED(icon);
#endif
}

void FileRelation::onConfirm()
{
    if (m_grpCheck->isChecked()) registerFileType("grp", "GRP Sprite File", "");
    if (m_idxCheck->isChecked()) registerFileType("idx", "IDX Index File", "");
    if (m_picCheck->isChecked()) registerFileType("pic", "PIC Image File", "");
    if (m_txtCheck->isChecked()) registerFileType("txt", "Lua Script File", "");
    if (m_bmpCheck->isChecked()) registerFileType("bmp", "BMP Image File", "");
    if (m_pngCheck->isChecked()) registerFileType("png", "PNG Image File", "");
    if (m_jpgCheck->isChecked()) registerFileType("jpg", "JPEG Image File", "");
    if (m_gifCheck->isChecked()) registerFileType("gif", "GIF Image File", "");
    if (m_imzCheck->isChecked()) registerFileType("imz", "IMZ Sprite Container", "");

    QMessageBox::information(this, tr("完成"), tr("文件关联设置完成"));
    accept();
}
