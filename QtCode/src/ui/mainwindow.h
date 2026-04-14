#pragma once

/*
 * 主窗口 (MDI 容器)
 * 对应原 Delphi 版 Main.pas / TUPeditMainForm
 */

#include <QMainWindow>
#include <QMdiArea>
#include <QMenu>
#include <QMenuBar>
#include <QStatusBar>
#include <QLabel>
#include <QSettings>

class REditWidget;
class GrpEdit;
class GrpList;
class PicEdit;
class WarEdit;
class WarMapEdit;
class SceneMapEdit;
class MainMapEdit;
class KDEFEdit;
class ImagezForm;
class PNGImport;
class PNGExport;
class CYHead;
class TxtLeadIn;
class ReplicatedList;

class MainWindow : public QMainWindow {
    Q_OBJECT

public:
    explicit MainWindow(QWidget *parent = nullptr);
    ~MainWindow();

    // 获取单例
    static MainWindow *instance();

    QMdiArea *mdiArea() const { return m_mdiArea; }

private slots:
    // 文件菜单
    void onSetPath();
    void onExit();

    // 编辑器菜单
    void onOpenREdit();
    void onOpenGrpEdit();
    void onOpenGrpList();
    void onOpenPicEdit();
    void onOpenWarEdit();
    void onOpenWarMapEdit();
    void onOpenSceneMapEdit();
    void onOpenMainMapEdit();
    void onOpenKDEFEdit();
    void onOpenImzEdit();
    void onOpenPNGExport();
    void onOpenPNGImport();
    void onOpenCYHead();
    void onOpenTxtLeadIn();
    void onOpenReplicatedList();

    // 帮助菜单
    void onAbout();

    // 设置
    void onSetLanguage();
    void onFileRelation();
    void updateWindowMenu();

private:
    void createMenus();
    void createStatusBar();
    void loadSettings();
    void initializeData();
    void loadGameData();

    QMdiArea *m_mdiArea = nullptr;

    // 子窗口指针 (惰性创建)
    REditWidget        *m_rEdit      = nullptr;
    GrpEdit            *m_grpEdit    = nullptr;
    GrpList            *m_grpList    = nullptr;
    PicEdit            *m_picEdit    = nullptr;
    WarEdit            *m_warEdit    = nullptr;
    WarMapEdit         *m_warMap     = nullptr;
    SceneMapEdit       *m_sceneMap   = nullptr;
    MainMapEdit        *m_mainMap    = nullptr;
    KDEFEdit           *m_kdefEdit   = nullptr;
    ImagezForm         *m_imagez     = nullptr;
    PNGImport          *m_pngImport  = nullptr;
    PNGExport          *m_pngExport  = nullptr;
    CYHead             *m_cyHead     = nullptr;
    TxtLeadIn          *m_txtLeadIn  = nullptr;
    ReplicatedList     *m_repList    = nullptr;

    QLabel *m_statusLabel = nullptr;
    QMenu *m_windowMenu = nullptr;

    static const QString TITLE;
    static const QString APP_NAME;
    static MainWindow *s_instance;
};
