#pragma once
#include "warmapedit.h"
#include <QScrollBar>
#include <QGroupBox>
#include <QCheckBox>
#include <QTimer>

// 主地图编辑器 (对应 Delphi TForm13)
class MainMapEdit : public IsoMapEditor {
    Q_OBJECT
public:
    explicit MainMapEdit(QWidget *parent = nullptr);

private slots:
    void onSaveMap();
    void onExportImage();
    void onImportBlock();
    void onExportBlock();
    void onHScroll(int value);
    void onVScroll(int value);
    void onTimerTick();
    void onMoreSettings(bool checked);

protected:
    void renderMap() override;
    void onTileClicked(int ix, int iy, Qt::MouseButton btn) override;
    void resizeEvent(QResizeEvent *e) override;

private:
    void readMainMapFile();
    void readMainMapGrp();
    void updateTilePreview();

    QPoint mapToScreen(int ix, int iy) const;
    QPoint screenToMapRel(int sx, int sy) const;

    QScrollBar *m_hScroll = nullptr, *m_vScroll = nullptr;
    QTimer *m_timer = nullptr;

    // 当前悬停地图坐标
    int m_hoverIX = -1, m_hoverIY = -1;

    bool m_needUpdate = true;

    // 当前操作层 (-1=未选, 0=地面, 1=表面, 2=建筑, 3=引用建筑, 4=全部)
    int m_layer = -1;

    // 引用建筑点击记录
    int m_qbuildx = -1, m_qbuildy = -1;

    // 框选相关
    int m_stillMode = 0;
    int m_stillX = -1, m_stillY = -1;
    int m_copyMapMode = 0;

    // 左侧面板元素
    QLabel *m_lblEarthVal = nullptr, *m_lblSurfVal = nullptr;
    QLabel *m_lblBuildVal = nullptr, *m_lblRefBuildVal = nullptr;
    QLabel *m_imgEarth = nullptr, *m_imgSurf = nullptr;
    QLabel *m_imgBuild = nullptr, *m_imgRefBuild = nullptr;
    QCheckBox *m_chkMore = nullptr;
    QWidget *m_morePanel = nullptr;
};
