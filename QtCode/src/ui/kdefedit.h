#pragma once
#include <QWidget>
#include <QTableWidget>
#include <QComboBox>
#include <QPushButton>
#include <QTextEdit>
#include <QSplitter>
#include "head.h"

// KDEF 事件指令编辑器 (合并 Delphi 50+ 个事件窗体为表格驱动方式)
class KDEFEdit : public QWidget {
    Q_OBJECT
public:
    explicit KDEFEdit(QWidget *parent = nullptr);

private slots:
    void onLoadKDEF();
    void onSaveKDEF();
    void onEventSelected(int row, int col);
    void onInstructionSelected(int row, int col);
    void onAddInstruction();
    void onDeleteInstruction();
    void onInsertInstruction();
    void onMoveUp();
    void onMoveDown();
    void onCopyInstruction();
    void onPasteInstruction();

private:
    void loadKDEFIni();
    void readKDEFFile();
    void displayEventList();
    void displayInstructions(int eventIndex);
    void displayInstructionDetail(int instrIndex);
    QString getKDEFName(int code) const;
    int getParamCount(int code) const;
    QString getParamName(int code, int paramIndex) const;

    QComboBox *m_sceneCombo;
    QTableWidget *m_eventTable;     // 事件列表
    QTableWidget *m_instrTable;     // 指令列表
    QTableWidget *m_paramTable;     // 参数编辑
    QTextEdit *m_previewText;       // 预览文本

    // KDEF INI 定义
    struct KDEFInstrDef {
        int code;
        QString name;
        QStringList paramNames;
    };
    QVector<KDEFInstrDef> m_instrDefs;

    // 事件数据
    struct KDEFInstruction {
        int code = 0;
        QVector<int16_t> params;
    };
    struct KDEFEvent {
        int eventId = -1;
        QVector<KDEFInstruction> instructions;
    };
    QVector<KDEFEvent> m_events;
    int m_currentEvent = -1;
    int m_currentInstr = -1;
    QVector<KDEFInstruction> m_clipboard;
};
