#pragma once
#include <QWidget>
#include <QScrollBar>
#include <QComboBox>
#include <QLineEdit>
#include <QPushButton>
#include <QLabel>

// 关联列表编辑器 (对应 Delphi TForm86)
// 四个列表: 离队列表/效果列表/武器武功配合/升级经验
class ReplicatedList : public QWidget {
    Q_OBJECT
public:
    explicit ReplicatedList(QWidget *parent = nullptr);

private slots:
    void onSave();
    void onLeaveScroll(int val);
    void onEffectScroll(int val);
    void onMatchScroll(int val);
    void onExpScroll(int val);

private:
    void loadData();
    void displayLeave(int index);
    void displayEffect(int index);
    void displayMatch(int index);
    void displayExp(int index);
    QString calRName(int typeIndex, int dataIndex);

    // 离队列表
    QScrollBar *m_leaveScroll;
    QComboBox *m_leaveCombo;
    QLabel *m_leaveLabel;
    // 效果列表
    QScrollBar *m_effectScroll;
    QLineEdit *m_effectEdit;
    QLabel *m_effectLabel;
    // 武器武功配合
    QScrollBar *m_matchScroll;
    QComboBox *m_matchWeaponCombo, *m_matchSkillCombo;
    QLineEdit *m_matchValueEdit;
    // 升级经验
    QScrollBar *m_expScroll;
    QLineEdit *m_expEdit;
    QLabel *m_expLabel;

    QVector<int16_t> m_leaveList;   // 100 entries
    QVector<int16_t> m_effectList;  // 200 entries
    QVector<int16_t> m_matchList;   // 300 entries (triplets)
    QVector<int16_t> m_expList;     // 100 entries
};
