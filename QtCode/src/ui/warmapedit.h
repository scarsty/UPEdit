#pragma once
#include <QWidget>
#include <QImage>
#include <QComboBox>
#include <QScrollArea>
#include <QPushButton>
#include <QLabel>
#include <QStatusBar>
#include <QTimer>
#include <QVBoxLayout>
#include <QCheckBox>
#include <QSpinBox>
#include <QToolButton>
#include <QTimer>
#include "head.h"
#include "occlusioneditor.h"

// 等距地图编辑器基类
class IsoMapEditor : public QWidget {
    Q_OBJECT
    friend int verifyResources(const QString &iniPath, const QString &reportPath);
public:
    explicit IsoMapEditor(QWidget *parent = nullptr);
    virtual ~IsoMapEditor() = default;

protected:
    // 等距坐标转换
    QPoint isoToScreen(int ix, int iy) const;
    virtual QPoint screenToIso(int sx, int sy) const;
    int tileW() const { return 18 * m_tileScale; }
    int tileH() const { return  9 * m_tileScale; }
    int tilePadding() const { return 150 * m_tileScale; }

    void drawIsoTile(QPainter &p, int ix, int iy, const QImage &sprite, int xoff = 0, int yoff = 0);
    void drawSelection(QPainter &p, int ix, int iy);
    void drawRegion(QPainter &p, const QRect &bounds, const QColor &color);
    QToolButton *addSection(QVBoxLayout *layout, const QString &key, const QString &title, QWidget *content, bool expanded);
    void setupSections(QVBoxLayout *layout, const QString &prefix, const QList<QPair<QString, QList<QWidget *>>> &sections,
        const QStringList &keys = {});

    virtual void renderMap() = 0;
    virtual void onTileClicked(int ix, int iy, Qt::MouseButton btn) = 0;

    QScrollArea *m_scroll;
    QLabel *m_mapLabel;
    QComboBox *m_layerCombo;
    QComboBox *m_tileSourceCombo;
    QPushButton *m_btnSelectTile;
    QPushButton *m_btnSave;
    QStatusBar *m_statusBar;

    MapStruct m_mapData;
    QVector<GrpPic> m_grpPics;
    QVector<QRgb> m_palette;
    QVector<QImage> m_tileCache;  // 解码后的精灵缓存

    int m_tileScale = 1;
    double m_canvasZoom = 1.0;
    double m_displayZoom = 1.0;
    QTimer *m_canvasZoomTimer = nullptr;
    bool m_canvasZoomPending = false;
    QPoint m_canvasZoomAnchor;
    int m_currentLayer = 0;
    int m_selectedTileId = -1;
    int m_selIsoX = -1, m_selIsoY = -1;
    QImage m_mapImage;             // 渲染缓冲

    // 渲染坐标原点 (isoToScreen 使用)
    int m_renderCenterX = 0, m_renderCenterY = 0;
    QPoint canvasPoint(const QPoint &viewPoint) const;
    void updateCanvasDisplay();
    void setCanvasZoom(double zoom, const QPoint &anchor);
    void applyCanvasZoom();

protected:
    bool eventFilter(QObject *obj, QEvent *event) override;
    virtual void handleMouseMove(QMouseEvent *event);
    virtual void handleMouseRelease(QMouseEvent *event);
    virtual void handleMousePress(QMouseEvent *event);
    virtual void selectTile(int tileId) { m_selectedTileId = tileId; }
};

// 战斗地图编辑器 (对应 Delphi TForm11)
class WarMapEdit : public IsoMapEditor {
    Q_OBJECT
    friend int runSelfTests(const QString &reportPath);
    friend int verifyResources(const QString &iniPath, const QString &reportPath);
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
    void handleMousePress(QMouseEvent *event) override;
    void closeEvent(QCloseEvent *event) override;
    void selectTile(int tileId) override { m_selectedTileId = tileId; m_hasClipboard = false; }

private:
    bool backdropActive() const;
    QPoint backdropOffset() const;
    int backdropDepth(int x, int y) const;
    void paintBackdrop(QPoint position, bool erase);
    void drawBackdropSprite(QPainter &painter, const QImage &sprite, QPoint position, int depth);
    void recordBackdropStroke();
    bool saveBackdrop(const QString &path);
    bool loadBackdrop(const QString &path);
    bool confirmBackdropDiscard();
    void readWarMapDef();
    QImage exportImage(bool ground, bool building) const;
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
    QRect m_selectedRegion;
    QImage m_backdrop;
    int m_backdropMap = -1;
    QCheckBox *m_backdropEnabled = nullptr;
    QVector<qint32> m_backdropDepth;
    QVector<QVector<qint32>> m_backdropHistory;
    int m_backdropHistoryPos = -1;
    bool m_backdropDirty = false;
    bool m_maskStroke = false;
    QComboBox *m_backdropTool = nullptr;
    QCheckBox *m_backdropOverlay = nullptr, *m_actorVisible = nullptr;
    QSpinBox *m_brushRadius = nullptr, *m_anchorX = nullptr, *m_anchorY = nullptr;
    QSpinBox *m_originX = nullptr, *m_originY = nullptr;
    QLabel *m_backdropDepthInfo = nullptr;
    QPoint m_backdropCursor{-1, -1};
    OcclusionEditor *m_geometry = nullptr;
};
