#include "luawrapper.h"
#include <cstring>

LuaWrapper::LuaWrapper() {}

LuaWrapper::~LuaWrapper() { close(); }

bool LuaWrapper::load(const QString &dllPath)
{
    m_lib.setFileName(dllPath);
    if (!m_lib.load()) return false;

    m_newState    = reinterpret_cast<FnNewState>(m_lib.resolve("lua_newstate"));
    m_close       = reinterpret_cast<FnClose>(m_lib.resolve("lua_close"));
    m_openLibs    = reinterpret_cast<FnOpenLibs>(m_lib.resolve("luaL_openlibs"));
    m_getTop      = reinterpret_cast<FnGetTop>(m_lib.resolve("lua_gettop"));
    m_setTop      = reinterpret_cast<FnSetTop>(m_lib.resolve("lua_settop"));
    m_pushNil     = reinterpret_cast<FnPushNil>(m_lib.resolve("lua_pushnil"));
    m_pushNumber  = reinterpret_cast<FnPushNumber>(m_lib.resolve("lua_pushnumber"));
    m_pushLString = reinterpret_cast<FnPushLString>(m_lib.resolve("lua_pushlstring"));
    m_pushCClosure = reinterpret_cast<FnPushCClosure>(m_lib.resolve("lua_pushcclosure"));
    m_pushBoolean = reinterpret_cast<FnPushBoolean>(m_lib.resolve("lua_pushboolean"));
    m_toNumber    = reinterpret_cast<FnToNumber>(m_lib.resolve("lua_tonumber"));
    m_toLString   = reinterpret_cast<FnToLString>(m_lib.resolve("lua_tolstring"));
    m_toBoolean   = reinterpret_cast<FnToBoolean>(m_lib.resolve("lua_toboolean"));
    m_type        = reinterpret_cast<FnType>(m_lib.resolve("lua_type"));
    m_getField    = reinterpret_cast<FnGetField>(m_lib.resolve("lua_getfield"));
    m_setField    = reinterpret_cast<FnSetField>(m_lib.resolve("lua_setfield"));
    m_createTable = reinterpret_cast<FnCreateTable>(m_lib.resolve("lua_createtable"));
    m_setTable    = reinterpret_cast<FnSetTable>(m_lib.resolve("lua_settable"));
    m_getTable    = reinterpret_cast<FnGetTable>(m_lib.resolve("lua_gettable"));
    m_rawSetI     = reinterpret_cast<FnRawSetI>(m_lib.resolve("lua_rawseti"));
    m_rawGetI     = reinterpret_cast<FnRawGetI>(m_lib.resolve("lua_rawgeti"));
    m_pcall       = reinterpret_cast<FnPcall>(m_lib.resolve("lua_pcall"));
    m_loadString  = reinterpret_cast<FnLoadString>(m_lib.resolve("luaL_loadstring"));
    m_loadFile    = reinterpret_cast<FnLoadFile>(m_lib.resolve("luaL_loadfile"));

    m_loaded = (m_newState && m_close && m_openLibs);
    return m_loaded;
}

void LuaWrapper::close()
{
    if (m_lib.isLoaded()) m_lib.unload();
    m_loaded = false;
}

lua_State *LuaWrapper::newState()
{
    if (!m_newState) return nullptr;
    // 使用默认分配器
    auto defaultAlloc = [](void *, void *ptr, size_t, size_t nsize) -> void * {
        if (nsize == 0) { free(ptr); return nullptr; }
        return realloc(ptr, nsize);
    };
    return m_newState(defaultAlloc, nullptr);
}

void LuaWrapper::closeState(lua_State *L)  { if (m_close && L) m_close(L); }
void LuaWrapper::openLibs(lua_State *L)    { if (m_openLibs) m_openLibs(L); }
int  LuaWrapper::getTop(lua_State *L)      { return m_getTop ? m_getTop(L) : 0; }
void LuaWrapper::setTop(lua_State *L, int idx)  { if (m_setTop) m_setTop(L, idx); }
void LuaWrapper::pop(lua_State *L, int n)  { setTop(L, -(n) - 1); }
void LuaWrapper::pushNil(lua_State *L)     { if (m_pushNil) m_pushNil(L); }
void LuaWrapper::pushNumber(lua_State *L, double n) { if (m_pushNumber) m_pushNumber(L, n); }

void LuaWrapper::pushString(lua_State *L, const char *s)
{
    if (m_pushLString && s) m_pushLString(L, s, strlen(s));
}

void LuaWrapper::pushString(lua_State *L, const char *s, size_t len)
{
    if (m_pushLString) m_pushLString(L, s, len);
}

void LuaWrapper::pushCFunction(lua_State *L, int (*fn)(lua_State *), int nUpValues)
{
    if (m_pushCClosure) m_pushCClosure(L, fn, nUpValues);
}

void LuaWrapper::pushBoolean(lua_State *L, bool b)
{
    if (m_pushBoolean) m_pushBoolean(L, b ? 1 : 0);
}

double LuaWrapper::toNumber(lua_State *L, int idx)
{
    return m_toNumber ? m_toNumber(L, idx) : 0.0;
}

const char *LuaWrapper::toString(lua_State *L, int idx, size_t *len)
{
    return m_toLString ? m_toLString(L, idx, len ? len : nullptr) : nullptr;
}

bool LuaWrapper::toBoolean(lua_State *L, int idx)
{
    return m_toBoolean ? (m_toBoolean(L, idx) != 0) : false;
}

int LuaWrapper::type(lua_State *L, int idx)
{
    return m_type ? m_type(L, idx) : LUA_TNONE;
}

void LuaWrapper::getGlobal(lua_State *L, const char *name) { getField(L, LUA_GLOBALSINDEX, name); }
void LuaWrapper::setGlobal(lua_State *L, const char *name) { setField(L, LUA_GLOBALSINDEX, name); }

void LuaWrapper::createTable(lua_State *L, int narr, int nrec)
{
    if (m_createTable) m_createTable(L, narr, nrec);
}

void LuaWrapper::setTable(lua_State *L, int idx) { if (m_setTable) m_setTable(L, idx); }
void LuaWrapper::getTable(lua_State *L, int idx) { if (m_getTable) m_getTable(L, idx); }
void LuaWrapper::setField(lua_State *L, int idx, const char *k) { if (m_setField) m_setField(L, idx, k); }
void LuaWrapper::getField(lua_State *L, int idx, const char *k) { if (m_getField) m_getField(L, idx, k); }
void LuaWrapper::rawSetI(lua_State *L, int idx, int n) { if (m_rawSetI) m_rawSetI(L, idx, n); }
void LuaWrapper::rawGetI(lua_State *L, int idx, int n) { if (m_rawGetI) m_rawGetI(L, idx, n); }

int LuaWrapper::pcall(lua_State *L, int nargs, int nresults, int errfunc)
{
    return m_pcall ? m_pcall(L, nargs, nresults, errfunc) : -1;
}

int LuaWrapper::loadString(lua_State *L, const char *s)
{
    return m_loadString ? m_loadString(L, s) : -1;
}

int LuaWrapper::loadFile(lua_State *L, const char *filename)
{
    return m_loadFile ? m_loadFile(L, filename) : -1;
}

int LuaWrapper::doString(lua_State *L, const char *s)
{
    int r = loadString(L, s);
    if (r != 0) return r;
    return pcall(L, 0, LUA_MULTRET);
}

int LuaWrapper::doFile(lua_State *L, const char *filename)
{
    int r = loadFile(L, filename);
    if (r != 0) return r;
    return pcall(L, 0, LUA_MULTRET);
}

QString LuaWrapper::lastError(lua_State *L)
{
    const char *msg = toString(L, -1);
    return msg ? QString::fromUtf8(msg) : QString();
}

void LuaWrapper::registerFunction(lua_State *L, const char *name, int (*fn)(lua_State *))
{
    pushCFunction(L, fn);
    setGlobal(L, name);
}
