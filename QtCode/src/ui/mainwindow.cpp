#include "mainwindow.h"
#include "aboutdialog.h"
#include "redit.h"
#include "grpedit.h"
#include "grplist.h"
#include "picedit.h"
#include "waredit.h"
#include "warmapedit.h"
#include "scenemapedit.h"
#include "mainmapedit.h"
#include "kdefedit.h"
#include "imagezform.h"
#include "pngimport.h"
#include "cyhead.h"
#include "txtleadin.h"
#include "replicatedlist.h"
#include "setlanguage.h"
#include "filerelation.h"
#include "iniconfig.h"
#include "rfile.h"
#include "encoding.h"
#include "fileio.h"
#include "sqlite3wrapper.h"
#include "luawrapper.h"
#include "zipwrapper.h"
#include "xlsxiowrapper.h"

#include <QApplication>
#include <QMessageBox>
#include <QFileDialog>
#include <QMdiSubWindow>
#include <QCloseEvent>

const QString MainWindow::TITLE    = QStringLiteral("UPedit Formal Ver ");
const QString MainWindow::APP_NAME = QStringLiteral("UPedit Formal");
MainWindow *MainWindow::s_instance = nullptr;

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
{
    s_instance = this;

    m_mdiArea = new QMdiArea(this);
    m_mdiArea->setHorizontalScrollBarPolicy(Qt::ScrollBarAsNeeded);
    m_mdiArea->setVerticalScrollBarPolicy(Qt::ScrollBarAsNeeded);
    setCentralWidget(m_mdiArea);

    createMenus();
    createStatusBar();

    setWindowTitle(TITLE + FileIO::fileVersion(QApplication::applicationFilePath()));
    resize(1200, 800);

    // 加载配置
    loadSettings();
    initializeData();
    loadGameData();
}

MainWindow::~MainWindow()
{
    s_instance = nullptr;
}

MainWindow *MainWindow::instance()
{
    return s_instance;
}

void MainWindow::createMenus()
{
    // ── 文件菜单 ────────────────────────────────────────
    QMenu *fileMenu = menuBar()->addMenu(tr("文件(&F)"));
    fileMenu->addAction(tr("设置路径(&P)..."), this, &MainWindow::onSetPath);
    fileMenu->addSeparator();
    fileMenu->addAction(tr("退出(&X)"), this, &MainWindow::onExit, QKeySequence::Quit);

    // ── 编辑器菜单 ──────────────────────────────────────
    QMenu *editMenu = menuBar()->addMenu(tr("编辑器(&E)"));
    editMenu->addAction(tr("R-数据编辑(&R)"), this, &MainWindow::onOpenREdit);
    editMenu->addAction(tr("GRP-贴图编辑(&G)"), this, &MainWindow::onOpenGrpEdit);
    editMenu->addAction(tr("GRP-贴图列表(&L)"), this, &MainWindow::onOpenGrpList);
    editMenu->addAction(tr("单图编辑(&P)"), this, &MainWindow::onOpenPicEdit);
    editMenu->addSeparator();
    editMenu->addAction(tr("战斗数据编辑(&W)"), this, &MainWindow::onOpenWarEdit);
    editMenu->addAction(tr("战斗地图编辑"), this, &MainWindow::onOpenWarMapEdit);
    editMenu->addAction(tr("场景地图编辑(&S)"), this, &MainWindow::onOpenSceneMapEdit);
    editMenu->addAction(tr("主地图编辑(&M)"), this, &MainWindow::onOpenMainMapEdit);
    editMenu->addSeparator();
    editMenu->addAction(tr("KDEF-事件编辑(&K)"), this, &MainWindow::onOpenKDEFEdit);
    editMenu->addSeparator();
    editMenu->addAction(tr("IMZ-精灵编辑(&I)"), this, &MainWindow::onOpenImzEdit);
    editMenu->addAction(tr("PNG批量导出"), this, &MainWindow::onOpenPNGExport);
    editMenu->addAction(tr("PNG批量导入"), this, &MainWindow::onOpenPNGImport);
    editMenu->addAction(tr("苍炎头像(&C)"), this, &MainWindow::onOpenCYHead);
    editMenu->addSeparator();
    editMenu->addAction(tr("文本/Lua脚本(&T)"), this, &MainWindow::onOpenTxtLeadIn);
    editMenu->addAction(tr("关键值关联"), this, &MainWindow::onOpenReplicatedList);

    // ── 设置菜单 ────────────────────────────────────────
    QMenu *settingsMenu = menuBar()->addMenu(tr("设置(&S)"));
    settingsMenu->addAction(tr("语言/编码(&L)..."), this, &MainWindow::onSetLanguage);
    settingsMenu->addAction(tr("文件关联(&A)..."), this, &MainWindow::onFileRelation);

    // ── 窗口菜单 ────────────────────────────────────────
    QMenu *windowMenu = menuBar()->addMenu(tr("窗口(&W)"));
    windowMenu->addAction(tr("层叠"), m_mdiArea, &QMdiArea::cascadeSubWindows);
    windowMenu->addAction(tr("平铺"), m_mdiArea, &QMdiArea::tileSubWindows);

    // ── 帮助菜单 ────────────────────────────────────────
    QMenu *helpMenu = menuBar()->addMenu(tr("帮助(&H)"));
    helpMenu->addAction(tr("关于(&A)..."), this, &MainWindow::onAbout);
}

void MainWindow::createStatusBar()
{
    m_statusLabel = new QLabel(this);
    statusBar()->addWidget(m_statusLabel, 1);
}

void MainWindow::loadSettings()
{
    IniConfig &cfg = IniConfig::instance();
    QString iniPath = QApplication::applicationDirPath() + "/" + cfg.iniFileName;
    cfg.load(iniPath);

    setWindowTitle(TITLE + FileIO::fileVersion(QApplication::applicationFilePath())
                   + " - " + cfg.gamePath);
}

void MainWindow::initializeData()
{
    // 加载外部库
    SQLite3Database::loadLibrary("sqlite3");
    ZipWrapper::loadLibrary("zip");
    XlsxReader::loadLibrary("libxlsxio_read");
    XlsxWriter::loadLibrary("xlsxwriter");
}

void MainWindow::loadGameData()
{
    IniConfig &cfg = IniConfig::instance();

    // 加载 R 文件
    if (cfg.rGlobals.typeNumber > 0 && !cfg.rFileName.isEmpty()) {
        QString grpFile = cfg.gamePath + cfg.rFileName[0];
        QString idxFile = cfg.gamePath + cfg.rIdxFileName[0];

        if (grpFile.endsWith(".db", Qt::CaseInsensitive)) {
            RFileIO::readDB(grpFile, &cfg.rGlobals.rFile, cfg.rGlobals);
        } else {
            RFileIO::readR(idxFile, grpFile, &cfg.rGlobals.rFile, cfg.rGlobals);
        }
        RFileIO::calcNamePos(&cfg.rGlobals.rFile, cfg.rGlobals);
    }

    // 读取调色板
    if (!cfg.palette.isEmpty()) {
        uint8_t r[256], g[256], b[256];
        MapIO::readPalette(cfg.gamePath + cfg.palette, r, g, b);
    }

    m_statusLabel->setText(tr("已加载: %1").arg(cfg.gamePath));
}

// ── 菜单动作 ────────────────────────────────────────────

template<typename WidgetType>
static WidgetType *showOrCreateMdi(WidgetType *&ptr, QMdiArea *mdi, const QString &title)
{
    if (ptr) {
        // 已存在，激活
        for (auto *sub : mdi->subWindowList()) {
            if (sub->widget() == ptr) {
                sub->showNormal();
                mdi->setActiveSubWindow(sub);
                return ptr;
            }
        }
    }
    ptr = new WidgetType();
    QMdiSubWindow *sub = mdi->addSubWindow(ptr);
    sub->setWindowTitle(title);
    sub->resize(800, 600);
    ptr->show();
    return ptr;
}

void MainWindow::onSetPath()
{
    QString dir = QFileDialog::getExistingDirectory(this, tr("选择游戏路径"),
                                                    IniConfig::instance().gamePath);
    if (dir.isEmpty()) return;
    if (!dir.endsWith('/') && !dir.endsWith('\\'))
        dir += '/';
    IniConfig::instance().gamePath = dir;
    loadGameData();
}

void MainWindow::onExit()     { close(); }

void MainWindow::onOpenREdit()      { showOrCreateMdi(m_rEdit, m_mdiArea, tr("R-数据编辑")); }
void MainWindow::onOpenGrpEdit()    { showOrCreateMdi(m_grpEdit, m_mdiArea, tr("GRP-贴图编辑")); }
void MainWindow::onOpenGrpList()    { showOrCreateMdi(m_grpList, m_mdiArea, tr("GRP-贴图列表")); }
void MainWindow::onOpenPicEdit()    { showOrCreateMdi(m_picEdit, m_mdiArea, tr("单图编辑")); }
void MainWindow::onOpenWarEdit()    { showOrCreateMdi(m_warEdit, m_mdiArea, tr("战斗数据编辑")); }
void MainWindow::onOpenWarMapEdit() { showOrCreateMdi(m_warMap, m_mdiArea, tr("战斗地图编辑")); }
void MainWindow::onOpenSceneMapEdit() { showOrCreateMdi(m_sceneMap, m_mdiArea, tr("场景地图编辑")); }
void MainWindow::onOpenMainMapEdit()  { showOrCreateMdi(m_mainMap, m_mdiArea, tr("主地图编辑")); }
void MainWindow::onOpenKDEFEdit()   { showOrCreateMdi(m_kdefEdit, m_mdiArea, tr("KDEF-事件编辑")); }
void MainWindow::onOpenImzEdit()    { showOrCreateMdi(m_imagez, m_mdiArea, tr("IMZ-精灵编辑")); }
void MainWindow::onOpenPNGExport()  { showOrCreateMdi(m_pngExport, m_mdiArea, tr("PNG批量导出")); }
void MainWindow::onOpenPNGImport()  { showOrCreateMdi(m_pngImport, m_mdiArea, tr("PNG批量导入")); }
void MainWindow::onOpenCYHead()     { showOrCreateMdi(m_cyHead, m_mdiArea, tr("苍炎头像")); }
void MainWindow::onOpenTxtLeadIn()  { showOrCreateMdi(m_txtLeadIn, m_mdiArea, tr("文本/Lua脚本")); }
void MainWindow::onOpenReplicatedList() { showOrCreateMdi(m_repList, m_mdiArea, tr("关键值关联")); }

void MainWindow::onAbout()
{
    AboutDialog dlg(this);
    dlg.exec();
}

void MainWindow::onSetLanguage()
{
    SetLanguage dlg(this);
    dlg.exec();
}

void MainWindow::onFileRelation()
{
    FileRelation dlg(this);
    dlg.exec();
}
