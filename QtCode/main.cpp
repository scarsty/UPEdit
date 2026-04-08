#include <QApplication>
#include <QDir>
#include <QFileInfo>
#include "mainwindow.h"
#include "iniconfig.h"

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);
    app.setApplicationName("UPedit");
    app.setOrganizationName("Upwinded");
    app.setApplicationVersion("1.0.0");

    // 设置工作目录为可执行文件所在目录
    QDir::setCurrent(QApplication::applicationDirPath());

    // ── 确定 INI 路径 (参考 Delphi AppInitial) ──────────
    IniConfig &cfg = IniConfig::instance();
    QString startPath;
    QString iniFileName = cfg.iniFileName;

    QStringList args = app.arguments();
    if (args.size() > 1) {
        QString arg1 = args[1];
        if (arg1.endsWith(".ini", Qt::CaseInsensitive)) {
            QFileInfo fi(arg1);
            startPath   = fi.absolutePath() + "/";
            iniFileName = fi.fileName();
        }
    }
    if (startPath.isEmpty())
        startPath = QDir::currentPath() + "/";

    cfg.startPath   = startPath;
    cfg.iniFileName = iniFileName;
    QString iniPath = startPath + iniFileName;

    // 加载配置
    cfg.load(iniPath);

    // 创建主窗口
    MainWindow w;

    w.show();

    return app.exec();
}
