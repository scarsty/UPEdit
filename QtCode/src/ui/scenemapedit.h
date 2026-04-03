#pragma once
#include "warmapedit.h"
#include <QUndoStack>
#include <QSpinBox>
#include <QCheckBox>
#include <QLineEdit>

// 场景地图编辑器 (对应 Delphi TForm12)
class SceneMapEdit : public IsoMapEditor {
    Q_OBJECT
public:
    explicit SceneMapEdit(QWidget *parent = nullptr);

private slots:
    void onLoadScene(int index);
    void onSaveScene();
    void onNewScene();
    void onDeleteScene();
    void onImportScene();
    void onExportScene();
    void onExportImage();
    void onUndo();
    void onRedo();
    void onEventConfirm();

protected:
    void renderMap() override;
    void onTileClicked(int ix, int iy, Qt::MouseButton btn) override;

private:
    void readSceneData(int sceneIndex);
    void readSceneGrp();
    void addUndoSave();

    QComboBox *m_saveCombo;   // 进度选择
    QComboBox *m_sceneCombo;  // 场景选择
    QCheckBox *m_deleteMode;
    QSpinBox *m_undoLimitSpin;

    // 事件编辑面板
    QLineEdit *m_evtCanWalk, *m_evtIndex;
    QLineEdit *m_evtEvent1, *m_evtEvent2, *m_evtEvent3;
    QLineEdit *m_evtBeginPic, *m_evtEndPic;
    QLineEdit *m_evtAnim, *m_evtX, *m_evtY;

    // 场景事件数据
    struct SceneEventLocal {
        int16_t canWalk = 0, index = 0;
        int16_t event1 = 0, event2 = 0, event3 = 0;
        int16_t beginPic = 0, endPic = 0;
        int16_t animFrames = 0;
        int16_t x = 0, y = 0;
        int16_t unused = 0;
    };
    QVector<QVector<SceneEventLocal>> m_sceneEvents; // [scene][index]

    // 撤销系统
    struct UndoState {
        MapStruct mapData;
        QVector<SceneEventLocal> events;
    };
    QVector<UndoState> m_undoStack;
    int m_undoPos = -1;
    int m_undoLimit = 20;

    int m_currentScene = -1;
};
