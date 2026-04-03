#include <QApplication>
#include <QDir>
#include <QSplashScreen>
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

    // 启动画面
    QPixmap splashPix("splash.png");
    QSplashScreen splash(splashPix.isNull() ? QPixmap(400, 200) : splashPix);
    splash.show();
    splash.showMessage(QObject::tr("正在加载..."), Qt::AlignBottom | Qt::AlignCenter, Qt::white);
    app.processEvents();

    // 创建主窗口
    MainWindow w;

    // 命令行参数处理 (文件关联双击打开)
    QStringList args = app.arguments();
    if (args.size() > 1) {
        // TODO: 根据文件扩展名打开对应编辑器
        // 例如 .grp → GrpList, .imz → ImagezForm
    }

    splash.finish(&w);
    w.show();

    return app.exec();
}
