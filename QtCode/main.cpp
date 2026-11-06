#include <QApplication>
#include <QDir>
#include <QFileInfo>
#include <QTimer>
#include "mainwindow.h"
#include "iniconfig.h"
#include "tests/selftest.h"

int main(int argc, char *argv[])
{
    if (argc > 1 && QByteArray(argv[1]) == "--verify-resources")
        qputenv("QT_QPA_PLATFORM", "offscreen");
    QApplication app(argc, argv);
    app.setApplicationName("UPedit");
    app.setOrganizationName("Upwinded");
    app.setApplicationVersion("1.0.0");
    if (app.arguments().size() > 2 && app.arguments()[1] == "--self-test")
        return runSelfTests(app.arguments()[2]);
    if ((app.arguments().size() == 4 || (app.arguments().size() == 5 && app.arguments()[4] == "--data-only"))
        && app.arguments()[1] == "--verify-resources")
        return verifyResources(app.arguments()[2], app.arguments()[3]);
    QString argument = app.arguments().size() > 1 ? QFileInfo(app.arguments()[1]).absoluteFilePath() : QString();

    // 设置工作目录为可执行文件所在目录
    QDir::setCurrent(QApplication::applicationDirPath());

    // ── 确定 INI 路径 (参考 Delphi AppInitial) ──────────
    IniConfig &cfg = IniConfig::instance();
    QString startPath;
    QString iniFileName = cfg.iniFileName;

    QStringList args = app.arguments();
    if (args.size() > 1) {
        QString arg1 = argument;
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
    if (!argument.isEmpty() && !argument.endsWith(".ini", Qt::CaseInsensitive))
        QTimer::singleShot(0, &w, [&w, argument] { w.openAssociatedFile(argument); });

    return app.exec();
}
