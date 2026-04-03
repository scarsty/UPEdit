#pragma once

/*
 * Lua 5.1 动态加载封装
 * 对应原 Delphi 版 Lua.pas
 * 运行时从 lua5.1.dll 加载所有函数指针
 */

#include <QLibrary>
#include <QString>
#include <functional>
#include <cstdint>

struct lua_State;

class LuaWrapper {
public:
    LuaWrapper();
    ~LuaWrapper();

    bool load(const QString &dllPath = "lua5.1");
    bool isLoaded() const { return m_loaded; }
    void close();

    // ── 状态管理 ────────────────────────────────────────
    lua_State *newState();
    void closeState(lua_State *L);
    void openLibs(lua_State *L);

    // ── 栈操作 ──────────────────────────────────────────
    int  getTop(lua_State *L);
    void setTop(lua_State *L, int idx);
    void pop(lua_State *L, int n);
    void pushNil(lua_State *L);
    void pushNumber(lua_State *L, double n);
    void pushString(lua_State *L, const char *s);
    void pushString(lua_State *L, const char *s, size_t len);
    void pushCFunction(lua_State *L, int (*fn)(lua_State *), int nUpValues = 0);
    void pushBoolean(lua_State *L, bool b);

    // ── 取值 ────────────────────────────────────────────
    double      toNumber(lua_State *L, int idx);
    const char *toString(lua_State *L, int idx, size_t *len = nullptr);
    bool        toBoolean(lua_State *L, int idx);
    int         type(lua_State *L, int idx);

    // ── 全局表 ──────────────────────────────────────────
    void getGlobal(lua_State *L, const char *name);
    void setGlobal(lua_State *L, const char *name);

    // ── 表操作 ──────────────────────────────────────────
    void createTable(lua_State *L, int narr = 0, int nrec = 0);
    void setTable(lua_State *L, int idx);
    void getTable(lua_State *L, int idx);
    void setField(lua_State *L, int idx, const char *k);
    void getField(lua_State *L, int idx, const char *k);
    void rawSetI(lua_State *L, int idx, int n);
    void rawGetI(lua_State *L, int idx, int n);

    // ── 执行 ────────────────────────────────────────────
    int pcall(lua_State *L, int nargs, int nresults, int errfunc = 0);
    int loadString(lua_State *L, const char *s);
    int loadFile(lua_State *L, const char *filename);
    int doString(lua_State *L, const char *s);
    int doFile(lua_State *L, const char *filename);

    // ── 错误信息 ────────────────────────────────────────
    QString lastError(lua_State *L);

    // 注册 C 函数到全局
    void registerFunction(lua_State *L, const char *name, int (*fn)(lua_State *));

    // ── 常量 ────────────────────────────────────────────
    static constexpr int LUA_REGISTRYINDEX = -10000;
    static constexpr int LUA_GLOBALSINDEX  = -10002;
    static constexpr int LUA_MULTRET       = -1;
    static constexpr int LUA_TNONE     = -1;
    static constexpr int LUA_TNIL      = 0;
    static constexpr int LUA_TBOOLEAN  = 1;
    static constexpr int LUA_TNUMBER   = 3;
    static constexpr int LUA_TSTRING   = 4;
    static constexpr int LUA_TTABLE    = 5;
    static constexpr int LUA_TFUNCTION = 6;

private:
    QLibrary m_lib;
    bool m_loaded = false;

    // 函数指针类型
    using FnNewState    = lua_State *(*)(void *(*)(void *, void *, size_t, size_t), void *);
    using FnClose       = void (*)(lua_State *);
    using FnOpenLibs    = void (*)(lua_State *);
    using FnGetTop      = int (*)(lua_State *);
    using FnSetTop      = void (*)(lua_State *, int);
    using FnPushNil     = void (*)(lua_State *);
    using FnPushNumber  = void (*)(lua_State *, double);
    using FnPushLString = void (*)(lua_State *, const char *, size_t);
    using FnPushCClosure = void (*)(lua_State *, int (*)(lua_State *), int);
    using FnPushBoolean = void (*)(lua_State *, int);
    using FnToNumber    = double (*)(lua_State *, int);
    using FnToLString   = const char *(*)(lua_State *, int, size_t *);
    using FnToBoolean   = int (*)(lua_State *, int);
    using FnType        = int (*)(lua_State *, int);
    using FnGetField    = void (*)(lua_State *, int, const char *);
    using FnSetField    = void (*)(lua_State *, int, const char *);
    using FnCreateTable = void (*)(lua_State *, int, int);
    using FnSetTable    = void (*)(lua_State *, int);
    using FnGetTable    = void (*)(lua_State *, int);
    using FnRawSetI     = void (*)(lua_State *, int, int);
    using FnRawGetI     = void (*)(lua_State *, int, int);
    using FnPcall       = int (*)(lua_State *, int, int, int);
    using FnLoadString  = int (*)(lua_State *, const char *);
    using FnLoadFile    = int (*)(lua_State *, const char *);

    FnNewState    m_newState    = nullptr;
    FnClose       m_close       = nullptr;
    FnOpenLibs    m_openLibs    = nullptr;
    FnGetTop      m_getTop      = nullptr;
    FnSetTop      m_setTop      = nullptr;
    FnPushNil     m_pushNil     = nullptr;
    FnPushNumber  m_pushNumber  = nullptr;
    FnPushLString m_pushLString = nullptr;
    FnPushCClosure m_pushCClosure = nullptr;
    FnPushBoolean m_pushBoolean = nullptr;
    FnToNumber    m_toNumber    = nullptr;
    FnToLString   m_toLString   = nullptr;
    FnToBoolean   m_toBoolean   = nullptr;
    FnType        m_type        = nullptr;
    FnGetField    m_getField    = nullptr;
    FnSetField    m_setField    = nullptr;
    FnCreateTable m_createTable = nullptr;
    FnSetTable    m_setTable    = nullptr;
    FnGetTable    m_getTable    = nullptr;
    FnRawSetI     m_rawSetI     = nullptr;
    FnRawGetI     m_rawGetI     = nullptr;
    FnPcall       m_pcall       = nullptr;
    FnLoadString  m_loadString  = nullptr;
    FnLoadFile    m_loadFile    = nullptr;
};
