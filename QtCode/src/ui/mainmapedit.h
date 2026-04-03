#pragma once
#include "warmapedit.h"
#include <QScrollBar>

// 主地图编辑器 (对应 Delphi TForm13)
class MainMapEdit : public IsoMapEditor {
    Q_OBJECT
public:
    explicit MainMapEdit(QWidget *parent = nullptr);

private slots:
    void onSaveMap();
    void onExportImage();
    void onHScroll(int value);
    void onVScroll(int value);

protected:
    void renderMap() override;
    void onTileClicked(int ix, int iy, Qt::MouseButton btn) override;

private:
    void readMainMapFile();
    void readMainMapGrp();

    QScrollBar *m_hScroll, *m_vScroll;
    int m_viewX = 0, m_viewY = 0;
    int m_viewW = 30, m_viewH = 30;  // 可视区域大小 (格数)
};
