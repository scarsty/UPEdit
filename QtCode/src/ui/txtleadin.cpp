#include "txtleadin.h"
#include "luawrapper.h"
#include "iniconfig.h"
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QFileDialog>
#include <QMessageBox>
#include <QLabel>
#include <QFile>

TxtLeadIn::TxtLeadIn(QWidget *parent) : QWidget(parent)
{
    auto *mainLayout = new QVBoxLayout(this);

    auto *topBar = new QHBoxLayout;
    topBar->addWidget(new QLabel(tr("脚本文件:")));
    m_pathEdit = new QLineEdit;
    auto *btnSelect = new QPushButton(tr("选择"));
    auto *btnExec = new QPushButton(tr("执行导入"));
    topBar->addWidget(m_pathEdit, 1);
    topBar->addWidget(btnSelect);
    topBar->addWidget(btnExec);
    mainLayout->addLayout(topBar);

    auto *helpLabel = new QLabel(tr(
        "支持 Lua 5.1 脚本格式。脚本需定义函数 TXTLeadIn()。\n"
        "内置函数: getRname/getWname/createbyte/createdata/copydata\n"
        "getU32/get32/get16/getU16/get8/getU8/setU32/set32/set16/setU16/set8/setU8\n"
        "loadfile/savefile/getfilelen/GBKtoUnicode/BIG5toUnicode 等"
    ));
    helpLabel->setWordWrap(true);
    mainLayout->addWidget(helpLabel);

    m_logText = new QTextEdit;
    m_logText->setReadOnly(true);
    mainLayout->addWidget(m_logText, 1);

    connect(btnSelect, &QPushButton::clicked, this, &TxtLeadIn::onSelectFile);
    connect(btnExec, &QPushButton::clicked, this, &TxtLeadIn::onExecute);
}

void TxtLeadIn::onSelectFile()
{
    QString f = QFileDialog::getOpenFileName(this, tr("选择Lua脚本"), {},
        "Lua Scripts (*.lua *.txt);;All (*.*)");
    if (!f.isEmpty()) m_pathEdit->setText(f);
}

void TxtLeadIn::onExecute()
{
    QString path = m_pathEdit->text();
    if (path.isEmpty()) return;

    m_logText->clear();
    m_logText->append(tr("开始执行脚本: %1").arg(path));

    LuaWrapper lua;
    if (!lua.isLoaded()) {
        m_logText->append(tr("错误: 无法加载 lua5.1.dll"));
        return;
    }

    auto *L = lua.newState();
    if (!L) {
        m_logText->append(tr("错误: 创建 Lua 状态失败"));
        return;
    }

    lua.openLibs(L);

    // 注册自定义函数 (TODO: 完整实现30+个绑定函数)
    registerLuaFunctions();

    // 加载并执行主脚本库 lua.txt
    IniConfig &cfg = IniConfig::instance();
    QString luaTxtPath = cfg.startPath + "/lua.txt";
    QFile luaTxt(luaTxtPath);
    if (luaTxt.open(QIODevice::ReadOnly)) {
        QByteArray code = luaTxt.readAll();
        code.append('\0');
        if (lua.loadString(L, code.data()) != 0) {
            m_logText->append(tr("加载 lua.txt 失败: %1").arg(lua.toString(L, -1)));
            lua.closeState(L);
            return;
        }
        if (lua.pcall(L, 0, 0, 0) != 0) {
            m_logText->append(tr("执行 lua.txt 失败: %1").arg(lua.toString(L, -1)));
            lua.closeState(L);
            return;
        }
    }

    // 加载用户脚本
    QFile scriptFile(path);
    if (!scriptFile.open(QIODevice::ReadOnly)) {
        m_logText->append(tr("无法打开脚本文件"));
        lua.closeState(L);
        return;
    }

    QByteArray scriptData = scriptFile.readAll();

    // 处理 UTF-16LE BOM
    if (scriptData.size() >= 2 && (uint8_t)scriptData[0] == 0xFF && (uint8_t)scriptData[1] == 0xFE) {
        QString text = QString::fromUtf16(reinterpret_cast<const char16_t*>(scriptData.constData() + 2),
                                          (scriptData.size() - 2) / 2);
        scriptData = text.toUtf8();
    }

    if (lua.loadString(L, scriptData.data()) != 0) {
        m_logText->append(tr("脚本加载失败: %1").arg(lua.toString(L, -1)));
        lua.closeState(L);
        return;
    }

    if (lua.pcall(L, 0, 0, 0) != 0) {
        m_logText->append(tr("脚本执行失败: %1").arg(lua.toString(L, -1)));
        lua.closeState(L);
        return;
    }

    // 调用 TXTLeadIn 函数
    lua.getGlobal(L, "TXTLeadIn");
    if (lua.pcall(L, 0, 0, 0) != 0) {
        m_logText->append(tr("TXTLeadIn() 执行失败: %1").arg(lua.toString(L, -1)));
    } else {
        m_logText->append(tr("脚本执行成功。"));
    }

    lua.closeState(L);
}

void TxtLeadIn::registerLuaFunctions()
{
    // TODO: 注册30+个Lua C函数绑定:
    // lua_GBKtoUnicode, lua_BIG5toUnicode, lua_UnicodetoGBK, lua_UnicodetoBIG5
    // lua_getRname, lua_getRnamepos, lua_getWname, lua_getWnamepos
    // lua_createbyte, lua_createdata, lua_copydata
    // lua_getU32, lua_get32, lua_get16, lua_getU16, lua_get8, lua_getU8
    // lua_setU32, lua_set32, lua_set16, lua_setU16, lua_set8, lua_setU8
    // lua_loadfile, lua_savefile, lua_getfilelen
    // lua_gettalkname, lua_getkdefname
}
