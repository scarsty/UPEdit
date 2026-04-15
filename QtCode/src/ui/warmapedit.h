#pragma once
#include <QWidget>
#include <QImage>
#include <QComboBox>
#include <QScrollArea>
#include <QPushButton>
#include <QLabel>
#include <QStatusBar>
#include <QTimer>
#include "head.h"

// 等距地图编辑器基类
class IsoMapEditor : public QWidget {
    Q_OBJECT
public:
    explicit IsoMapEditor(QWidget *parent = nullptr);
    virtual ~IsoMapEditor() = default;

protected:
    // 等距坐标转换
    QPoint isoToScreen(int ix, int iy) const;
    QPoint screenToIso(int sx, int sy) const;
    int tileW() const { return 18 * m_tileScale; }
    int tileH() const { return  9 * m_tileScale; }
    int tilePadding() const { return 150 * m_tileScale; }

    void drawIsoTile(QPainter &p, int ix, int iy, const QImage &sprite, int xoff = 0, int yoff = 0);
    void drawSelection(QPainter &p, int ix, int iy);

    virtual void renderMap() = 0;
    virtual void onTileClicked(int ix, int iy, Qt::MouseButton btn) = 0;

    QScrollArea *m_scroll;
    QLabel *m_mapLabel;
    QComboBox *m_layerCombo;
    QPushButton *m_btnSelectTile;
    QPushButton *m_btnSave;
    QStatusBar *m_statusBar;

    MapStruct m_mapData;
    QVector<GrpPic> m_grpPics;
    QVector<QRgb> m_palette;
    QVector<QImage> m_tileCache;  // 解码后的精灵缓存

    int m_tileScale = 1;
    int m_currentLayer = 0;
    int m_selectedTileId = -1;
    int m_selIsoX = -1, m_selIsoY = -1;
    QImage m_mapImage;             // 渲染缓冲

    // 渲染坐标原点 (isoToScreen 使用)
    int m_renderCenterX = 0, m_renderCenterY = 0;

protected:
    bool eventFilter(QObject *obj, QEvent *event) override;
    virtual void handleMouseMove(QMouseEvent *event);
    virtual void handleMouseRelease(QMouseEvent *event);

private:
    void handleMousePress(QMouseEvent *event);
};

// 战斗地图编辑器 (对应 Delphi TForm11)
class WarMapEdit : public IsoMapEditor {
    Q_OBJECT
public:
    explicit WarMapEdit(QWidget *parent = nullptr);

private slots:
    void onLoadMap(int index);
    void onSaveMap();
    void onNewMap();
    void onDeleteMap();
    void onExportImage();
    void onImportModule();
    void onExportModule();

protected:
    void renderMap() override;
    void onTileClicked(int ix, int iy, Qt::MouseButton btn) override;
    void handleMouseMove(QMouseEvent *event) override;
    void handleMouseRelease(QMouseEvent *event) override;

private:
    void readWarMapDef();
    void readWarMapGrp();
    void updateTilePreview(int ix, int iy);
    void updateThumbnail();
    bool isLayerAll() const;
    int selectedLayerIndex() const;
    bool inCurrentMap(int ix, int iy) const;
    void copySelectionToClipboard(int sx, int sy, int ex, int ey);
    void pasteClipboardAt(int tx, int ty);
    bool loadModuleFile(const QString &filePath, Map &moduleMap);
    bool saveModuleFile(const QString &filePath, const Map &moduleMap);
    void drawSelectionArea(QPainter &p, int sx, int sy, int ex, int ey);

    QComboBox *m_mapCombo;
    int m_currentMapIndex = -1;

    // 贴图预览
    QLabel *m_imgGround = nullptr;
    QLabel *m_imgBuilding = nullptr;
    QLabel *m_lblGroundVal = nullptr;
    QLabel *m_lblBuildingVal = nullptr;

    // 缩略图
    QLabel *m_thumbLabel = nullptr;

    // Delphi 式编辑状态
    bool m_isSelecting = false;
    int m_pressIsoX = -1;
    int m_pressIsoY = -1;
    int m_hoverIsoX = -1;
    int m_hoverIsoY = -1;
    bool m_hasClipboard = false;
    Map m_clipboardMap;
};
