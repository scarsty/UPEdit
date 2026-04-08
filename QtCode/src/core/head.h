#pragma once

/*
 * UPEdit - 金庸群侠传编辑器 (Qt C++ 版)
 * 原作者: Upwinded.L. (2011)
 * Qt 移植版
 *
 * 核心数据结构定义，对应原 Delphi 版 head.pas
 */

#include <QByteArray>
#include <QString>
#include <QVector>
#include <QPixmap>
#include <cstdint>

// ── 编码方案 ─────────────────────────────────────────────
enum DataCode {
    CodeGBK     = 0, // 简体 GBK (codepage 936)
    CodeBIG5    = 1, // 繁体 BIG5 (codepage 950)
    CodeUTF16LE = 2, // UTF-16LE
    CodeUTF8    = 3  // UTF-8
};

// ── 游戏版本 ─────────────────────────────────────────────
enum GameVersionType {
    GameOriginal = 0, // 原版金庸群侠传
    GameShuiHu   = 1  // 水浒
};

// ── 地图编辑模式 ─────────────────────────────────────────
enum class MapEditMode {
    RLEMode,
    IMZMode,
    PNGMode
};

// ── 图片数据 ─────────────────────────────────────────────
struct BmpData {
    int pixelPerBit = 0;
    int height = 0;
    int width  = 0;
    QVector<QByteArray> data; // [row][col*bpp]
};

struct PicData {
    int picType    = 0;
    int xs         = 0;
    int ys         = 0;
    int background = 0;
    int dataSize   = 0;
    QByteArray data;
};

// ── R 文件数据结构（核心记录编辑） ─────────────────────────
struct RDataSingle {
    int16_t dataType = 0; // 0=整数, 1=字符串
    int     dataLen  = 0;
    QByteArray data;
};

struct RArray {
    int16_t incNum = 0;
    QVector<RDataSingle> dataArray;
};

struct RDataLine {
    int16_t len = 0;
    QVector<RArray> rArray;
};

struct RData {
    int16_t num = 0;
    QVector<RDataLine> rDataLine;
};

struct RType {
    int dataNum  = 0;
    int namePos  = -1;
    int mapPos   = -1;
    QVector<RData> rData;
};

struct RFile {
    int typeNumber = 0;
    QVector<RType> rType;
};

// ── R 文件 INI 配置结构 ─────────────────────────────────
struct RTermini {
    int16_t datanum = 0;
    int16_t incnum  = 0;
    int16_t datalen = 0;
    int16_t isstr   = 0;
    int16_t isname  = 0;
    int16_t quote   = 0;
    QString name;
    QString note;
};

struct RIni {
    QVector<RTermini> rTerm;
};

// ── W 文件（战斗数据）──────────────────────────────────
struct WField {
    QVector<int64_t> values;
    QVector<QByteArray> rawBytes;  // 用于 isstr==1 的字符串字段
};

struct WRecord {
    QVector<WField> fields;
};

struct WFile {
    RType wType;
    int typeCount = 0;
    QVector<WRecord> records;
};

struct WTermini {
    int16_t datanum    = 0;
    int16_t incnum     = 0;
    int16_t datalen    = 0;
    int16_t isstr      = 0;
    int16_t isname     = 0;
    int16_t quote      = 0;
    QString name;
    QString note;
    int16_t ismapnum   = 0;
    int16_t labeltype  = 0;
    int16_t labelnum   = 0;
};

struct WIni {
    QVector<WTermini> wTerm;
};

// ── KDEF 事件配置 ───────────────────────────────────────
struct KDEFItem {
    int16_t index     = 0;
    int16_t paramount = 0;
    int16_t ifjump    = 0;
    int16_t yesjump   = 0;
    int16_t nojump    = 0;
    QString note;
};

struct KDEFIni {
    int kdefNum     = 0;
    QVector<KDEFItem> kdefItem;
    int talkArrange = 0;
};

// ── 事件指令 ─────────────────────────────────────────────
struct Attrib {
    int16_t attribNum   = 0;  // 指令序号
    int16_t parCount    = 0;  // 参数个数
    int16_t labelStatus = -2; // -2:无跳转，-1:label，>=0:跳转源
    int16_t labelWay    = 0;  // 1向下，-1向前
    int16_t labelFrom   = 0;
    int16_t labelTo     = 0;
    QVector<int16_t> par;
};

struct Event {
    int16_t attribAmount = 0;
    QVector<Attrib> attrib;
};

struct EventData {
    int dataLen = 0;
    QByteArray data;
};

struct TalkStr {
    int len = 0;
    QByteArray str;
};

struct Kdef50 {
    int num = 0;
    QString other;
    QVector<QString> sub;
};

struct EventCopy {
    int copyEvent  = 0;
    int copyAttrib = -1; // -1没复制，1可复制
};

// ── 事件指令引导 ─────────────────────────────────────────
struct InstructGuideComboboxList {
    int value = 0;
    QString str;
};

struct InstructGuideCombobox {
    int listAmount = 0;
    QVector<InstructGuideComboboxList> list;
};

struct InstructGuideComboboxes {
    int amount = 0;
    QVector<InstructGuideCombobox> combobox;
};

struct InstructGuideParam {
    QString quoteLabel;
    int quoteType  = 0;
    int quoteCount = 0;
};

struct InstructGuideItem {
    int paramAmount = 0;
    int needGuide   = 0;
    QVector<InstructGuideParam> param;
    QString guideStr;
};

struct InstructGuide {
    int amount = 0;
    QVector<InstructGuideItem> instruct;
};

struct DIni {
    int num = 0;
    QVector<QString> attrib;
};

struct K50MemoryList {
    int num = 0;
    QVector<uint32_t> addr;
    QVector<QString> note;
};

// ── 选择项 ───────────────────────────────────────────────
struct Select {
    int16_t pos1  = 0;
    int16_t pos2  = 0;
    int16_t pos3  = 0;
    QString name;
    int16_t quote = 0;
    QString note;
};

struct WSelect {
    int16_t pos1       = 0;
    int16_t pos2       = 0;
    int16_t pos3       = 0;
    QString name;
    int16_t quote      = 0;
    QString note;
    int16_t ismap      = 0;
    int16_t labeltype  = 0;
    int16_t labelnum   = 0;
    int16_t labelcount = 0;
};

// ── 战斗位置 ─────────────────────────────────────────────
struct WarPos {
    int personNum = 0;
    int x         = 0;
    int y         = 0;
};

// ── GRP 图片 ─────────────────────────────────────────────
struct GrpPic {
    int size   = 0;
    int width  = 0;
    int height = 0;
    int xoff   = 0;  // x 偏移
    int yoff   = 0;  // y 偏移
    QByteArray data;
};

// ── 地图结构 ─────────────────────────────────────────────
struct MapLayer {
    QVector<QVector<int16_t>> pic; // [x][y]
};

struct Map {
    int layerNum = 0;
    int x        = 0;
    int y        = 0;
    QVector<MapLayer> mapLayer;
};

struct MapStruct {
    int num = 0;
    QVector<Map> map;
};

// ── 场景事件 ─────────────────────────────────────────────
struct SceneEvent {
    int16_t canWalk   = 0;
    int16_t num       = 0;
    int16_t event1    = 0;
    int16_t event2    = 0;
    int16_t event3    = 0;
    int16_t beginPic1 = 0;
    int16_t endPic    = 0;
    int16_t beginPic2 = 0;
    int16_t picDelay  = 0;
    int16_t xPos      = 0;
    int16_t yPos      = 0;
};

struct MapEvent {
    SceneEvent sceneEvent[200];
};

struct DFile {
    int mapNum = 0;
    QVector<MapEvent> mapEvent;
};

// ── GRP 列表分节 ─────────────────────────────────────────
struct GRPListSection {
    int num = 0;
    QVector<QString> tag;
    QVector<int> beginNum;
    QVector<int> endNum;
};

struct Position {
    int x = 0;
    int y = 0;
};

// ── PNG / IMZ 数据 ──────────────────────────────────────
struct PNGData {
    QByteArray data;
};

struct PNGBuf {
    int width  = 0;
    int height = 0;
    QVector<QByteArray> data;  // BGRA 行数据
    QVector<QByteArray> alpha; // Alpha 行数据
};

struct ImzPng {
    int len     = 0;
    int fileNum = 0;     // 原始文件编号 ("5.png" → 5)
    int16_t x   = 0;
    int16_t y   = 0;
    int frame   = 0;
    QVector<int> frameLen;
    QVector<PNGData> frameData;
    QVector<PNGBuf>  png;
};

struct Imz {
    int pngNum = 0;
    QVector<ImzPng> imzPng;
};

struct ScenePNGBuf {
    int width  = 0;
    int height = 0;
    QVector<QByteArray> data;
};

struct PNGAlpha {
    int width  = 0;
    int height = 0;
    int alpha  = 0;
};

// ── 列表 ─────────────────────────────────────────────────
struct SmallList {
    int num = 0;
    QVector<int16_t> data;
};
