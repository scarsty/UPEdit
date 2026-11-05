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
    static bool decodeRecords(const QByteArray &index, const QByteArray &data, QVector<QByteArray> &records);
    static bool encodeRecords(const QVector<QByteArray> &records, QByteArray &index, QByteArray &data);

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
    void onPasteEvent();

private:
    friend int runSelfTests(const QString &reportPath);
    QByteArray stateBytes() const;
    bool confirmDiscard();
    void closeEvent(QCloseEvent *event) override;
    QByteArray m_savedState;
    bool m_loaded = false;
    void loadKDEFIni();
    void readKDEFFile();
    void displayEventList();
    void displayInstructions(int eventIndex);
    void displayInstructionDetail(int instrIndex);
    QString getKDEFName(int code) const;
    int getParamCount(int code) const;
    QString getParamName(int code, int paramIndex) const;
    void mutateInstructions(int operation);
    void editTalks();

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
        int yesJump = -1, noJump = -1;
        QString guide;
        QVector<int> quoteTypes, quoteCounts;
    };
    QVector<KDEFInstrDef> m_instrDefs;
    QVector<QVector<QPair<int, QString>>> m_guideChoices;
    QVector<QPair<int, QString>> m_warChoices;
    QStringList m_subInstructions;

    // 事件数据
    struct KDEFInstruction {
        int code = 0;
        QVector<int16_t> params;
        int identity = 0;
    };
    struct KDEFEvent {
        int eventId = -1;
        QVector<KDEFInstruction> instructions;
    };
    QVector<KDEFEvent> m_events;
    KDEFEvent m_eventClipboard;
    bool m_hasEventClipboard = false;
    int m_currentEvent = -1;
    int m_currentInstr = -1;
    QVector<KDEFInstruction> m_clipboard;
    QMap<int, QMap<int, int>> m_clipboardTargets;
    int m_clipboardEvent = -1;
    int m_nextIdentity = 1;
};
