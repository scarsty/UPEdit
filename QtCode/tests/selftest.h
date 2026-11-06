#pragma once
#include "mapdata.h"
#include "imzdata.h"
#include "eventdata.h"
#include "scenemapedit.h"
#include "mainmapedit.h"
#include "imagezform.h"
#include "fileio.h"
#include "iniconfig.h"
#include "encoding.h"
#include "picedit.h"
#include "grpdata.h"
#include "grpedit.h"
#include "grplist.h"
#include "pngimport.h"
#include <QColorDialog>
#include <QFontDialog>
#include <QDialogButtonBox>
#include <QProgressDialog>
#include "kdefedit.h"
#include "sqlite3wrapper.h"
#include "waredit.h"
#include "redit.h"
#include "reditform.h"
#include "replicatedlist.h"
#include "takein.h"
#include "outputmap.h"
#include "cyhead.h"
#include "filerelation.h"
#include "mainwindow.h"
#include <QMdiSubWindow>
#include "xlsxiowrapper.h"
#include <limits>
#include <QStringConverter>
#include <QTimer>
#include <QMessageBox>
#include <QInputDialog>
#include <QBuffer>
#include <QMimeData>
#include <QClipboard>
#include <QFileDialog>
#include <QScopedValueRollback>
#include <QMouseEvent>
#include "ZipFile.h"
#include <QTemporaryDir>
#include <QDirIterator>
#include <QTemporaryFile>
#include <QFile>
#include <QTextStream>
#include <QtEndian>
#include <stdexcept>
#ifdef Q_OS_WIN
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#include <cstdlib>
#ifdef _MSC_VER
#include <crtdbg.h>
#endif
#endif

inline int verifyResources(const QString &iniPath, const QString &reportPath)
{
#ifdef Q_OS_WIN
    SetUnhandledExceptionFilter([](EXCEPTION_POINTERS *exception) -> LONG {
        fprintf(stderr, "Unhandled exception %08lx at %p\n", exception->ExceptionRecord->ExceptionCode,
            exception->ExceptionRecord->ExceptionAddress);
        void *frames[64];
        USHORT count = CaptureStackBackTrace(0, 64, frames, nullptr);
        for (USHORT frame = 0; frame < count; ++frame) {
            HMODULE module = nullptr;
            char path[MAX_PATH] = {};
            GetModuleHandleExA(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS | GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
                reinterpret_cast<LPCSTR>(frames[frame]), &module);
            GetModuleFileNameA(module, path, MAX_PATH);
            fprintf(stderr, "%s + %llx\n", path,
                static_cast<unsigned long long>(reinterpret_cast<uintptr_t>(frames[frame]) - reinterpret_cast<uintptr_t>(module)));
        }
        fflush(stderr);
        return EXCEPTION_EXECUTE_HANDLER;
    });
    SetErrorMode(SEM_FAILCRITICALERRORS | SEM_NOGPFAULTERRORBOX | SEM_NOOPENFILEERRORBOX);
#ifdef _MSC_VER
    _set_error_mode(_OUT_TO_STDERR);
#ifdef _DEBUG
    _CrtSetReportMode(_CRT_ASSERT, _CRTDBG_MODE_FILE);
    _CrtSetReportFile(_CRT_ASSERT, _CRTDBG_FILE_STDERR);
#endif
#endif
#endif
    QFile report(reportPath);
    if (!report.open(QIODevice::WriteOnly | QIODevice::Text)) return 2;
    QTextStream output(&report);
    int failures = 0;
    QTemporaryDir roundtrip;
    if (!roundtrip.isValid()) return 2;
    bool savingCopy = false;
    auto check = [&](bool valid, const QString &message) {
        output << (valid ? "PASS: " : "FAIL: ") << message << '\n';
        output.flush();
        if (!valid) ++failures;
    };
    QTimer dialogs;
    QObject::connect(&dialogs, &QTimer::timeout, &dialogs, [&] {
        for (auto *widget : QApplication::topLevelWidgets())
            if (auto *message = qobject_cast<QMessageBox *>(widget); message && message->isVisible()) {
                if (!savingCopy || message->icon() != QMessageBox::Information)
                    check(false, message->text());
                message->reject();
            }
    });
    dialogs.start(10);
    auto &config = IniConfig::instance();
    config.load(iniPath);
    output << "INI: " << iniPath << "\nResources: " << config.gamePath << '\n';
    RFileIO::readIni(config.rGlobals, iniPath);
    SQLite3Database::loadLibrary("sqlite3");
    for (const QString &tilePath : {config.wmapImz, config.mmapImz}) {
        if (tilePath.isEmpty()) continue;
        QVector<GrpPic> pictures;
        QVector<QImage> tiles;
        check(MapIO::loadPngTiles(config.gamePath + tilePath, pictures, tiles),
            "Configured PNG tile container: " + tilePath);
    }
    check(config.rGlobals.typeNumber > 0, "R schema loaded");
    for (int slot = 0; slot < config.rFileName.size(); ++slot) {
        RFile records;
        if (config.rFileName[slot].endsWith(".db", Qt::CaseInsensitive)) {
            QString source = config.gamePath + config.rFileName[slot];
            if (!QFile::exists(source)) {
                output << "SKIP: SQLite slot " << slot << " not provided: " << source << '\n';
                continue;
            }
            QString copy = roundtrip.filePath(QString("database-%1.db").arg(slot));
            bool loaded = QFile::exists(source) && RFileIO::readDB(source, &records, config.rGlobals);
            check(loaded, QString("SQLite slot %1 read").arg(slot));
            if (!loaded) continue;
            bool valid = QFile::copy(source, copy) && RFileIO::saveDB(copy, &records, config.rGlobals);
            RFile reopened;
            valid = valid && RFileIO::readDB(copy, &reopened, config.rGlobals)
                && records.rType.size() == reopened.rType.size();
            for (int type = 0; valid && type < records.rType.size(); ++type) {
                valid = records.rType[type].rData.size() == reopened.rType[type].rData.size();
                for (int row = 0; valid && row < records.rType[type].rData.size(); ++row) {
                    const auto &before = records.rType[type].rData[row].rDataLine;
                    const auto &after = reopened.rType[type].rData[row].rDataLine;
                    valid = before.size() == after.size();
                    for (int field = 0; valid && field < before.size(); ++field)
                        valid = RFileIO::readRDataStr(before[field].rArray[0].dataArray[0])
                            == RFileIO::readRDataStr(after[field].rArray[0].dataArray[0]);
                }
            }
            check(valid, QString("SQLite slot %1 all field values save/reopen").arg(slot));
            if (slot == 0) config.rGlobals.rFile = records;
            continue;
        }
        bool loaded = slot < config.rIdxFileName.size() && RFileIO::readR(
            config.gamePath + config.rIdxFileName[slot], config.gamePath + config.rFileName[slot],
            &records, config.rGlobals);
        check(loaded, QString("R slot %1: %2 types").arg(slot).arg(records.rType.size()));
        if (loaded) {
            QString indexCopy = roundtrip.filePath(QString("r%1.idx").arg(slot));
            QString dataCopy = roundtrip.filePath(QString("r%1.grp").arg(slot));
            bool saved = RFileIO::saveR(indexCopy, dataCopy, &records, config.rGlobals);
            QByteArray sourceBytes = FileIO::readFileAll(config.gamePath + config.rFileName[slot]);
            QByteArray savedBytes = FileIO::readFileAll(dataCopy);
            int firstDifference = 0;
            while (firstDifference < sourceBytes.size() && firstDifference < savedBytes.size()
                && sourceBytes[firstDifference] == savedBytes[firstDifference]) ++firstDifference;
            output << "R bytes slot " << slot << ": source=" << sourceBytes.size() << " saved=" << savedBytes.size()
                << " first-difference=" << firstDifference << '\n';
            check(saved && FileIO::readFileAll(indexCopy) == FileIO::readFileAll(config.gamePath + config.rIdxFileName[slot])
                && FileIO::readFileAll(dataCopy) == FileIO::readFileAll(config.gamePath + config.rFileName[slot]),
                QString("R slot %1 byte-exact save").arg(slot));
            RFile reopened;
            check(saved && RFileIO::readR(indexCopy, dataCopy, &reopened, config.rGlobals),
                QString("R slot %1 reopen").arg(slot));
            bool numberTested = false, stringTested = false;
            for (int type = 0; type < records.rType.size(); ++type)
                for (int record = 0; record < records.rType[type].rData.size(); ++record)
                    for (int line = 0; line < records.rType[type].rData[record].rDataLine.size(); ++line)
                        for (int array = 0; array < records.rType[type].rData[record].rDataLine[line].rArray.size(); ++array)
                            for (int member = 0; member < records.rType[type].rData[record].rDataLine[line].rArray[array].dataArray.size(); ++member) {
                                auto &field = records.rType[type].rData[record].rDataLine[line].rArray[array].dataArray[member];
                                bool text = field.dataType == 1;
                                if ((text ? stringTested : numberTested) || field.dataLen < (text ? 4 : 1)) continue;
                                QByteArray original = field.data;
                                if (text) RFileIO::writeRDataStr(field, QString::fromUtf8("\xe6\xb8\xac\xe8\xa9\xa6"));
                                else RFileIO::writeRDataInt(field, RFileIO::readRDataInt(field) == 0 ? 1 : 0);
                                QByteArray expected = field.data;
                                QString expectedText = RFileIO::readRDataStr(field);
                                bool edited = RFileIO::saveR(indexCopy, dataCopy, &records, config.rGlobals)
                                    && RFileIO::readR(indexCopy, dataCopy, &reopened, config.rGlobals);
                                check(edited && (text
                                    ? RFileIO::readRDataStr(reopened.rType[type].rData[record].rDataLine[line].rArray[array].dataArray[member]).trimmed() == expectedText.trimmed()
                                    : reopened.rType[type].rData[record].rDataLine[line].rArray[array].dataArray[member].data == expected),
                                    QString("R slot %1 edited %2 survives save/reopen").arg(slot).arg(text ? "text" : "number"));
                                field.data = original;
                                if (text) stringTested = true; else numberTested = true;
                            }
            check(numberTested && stringTested, QString("R slot %1 numeric/text coverage").arg(slot));
        }
        if (slot == 0 && loaded) config.rGlobals.rFile = records;
    }
    QVector<QByteArray> talks;
    if (config.talkGrp.endsWith(".txt", Qt::CaseInsensitive)) {
        QString originalPath = config.gamePath + config.talkGrp;
        QByteArray original = FileIO::readFileAll(originalPath);
        QString copyName = "verified-talk.txt";
        bool copied = QFile::exists(originalPath) && FileIO::writeFileAll(roundtrip.filePath(copyName), original);
        check(copied, "UTF8 line-based Talk source copied");
        if (copied) {
            QScopedValueRollback<QString> pathGuard(config.gamePath, roundtrip.path() + "/");
            QScopedValueRollback<QString> nameGuard(config.talkGrp, copyName);
            KDEFEdit textEditor;
            QTimer::singleShot(0, [] {
                for (auto *widget : QApplication::topLevelWidgets())
                    if (auto *dialog = qobject_cast<QDialog *>(widget); dialog && dialog->isVisible())
                        if (auto *buttons = dialog->findChild<QDialogButtonBox *>())
                            buttons->button(QDialogButtonBox::Save)->click();
            });
            textEditor.editTalks();
            check(FileIO::readFileAll(roundtrip.filePath(copyName)) == original,
                "UTF8 line-based Talk actual UI unchanged save is byte-exact");
        }
    } else {
    bool talksLoaded = KDEFEdit::decodeRecords(FileIO::readFileAll(config.gamePath + config.talkIdx),
        FileIO::readFileAll(config.gamePath + config.talkGrp), talks) && !talks.isEmpty();
    check(talksLoaded,
        QString("Talk IDX/GRP: %1 records").arg(talks.size()));
    QByteArray talkIndex, talkData;
    check(talksLoaded && KDEFEdit::encodeRecords(talks, talkIndex, talkData)
        && talkIndex == FileIO::readFileAll(config.gamePath + config.talkIdx)
        && talkData == FileIO::readFileAll(config.gamePath + config.talkGrp), "Talk byte-exact record re-encoding");
    if (talksLoaded) {
        TalkStr edited;
        QString expected = QString::fromUtf8("\xe6\xb8\xac\xe8\xa9\xa6");
        RFileIO::writeTalkStr(edited, expected);
        auto modified = talks;
        modified[0] = edited.str;
        QVector<QByteArray> reopened;
        bool valid = KDEFEdit::encodeRecords(modified, talkIndex, talkData)
            && FileIO::writeFileAll(roundtrip.filePath("talk.idx"), talkIndex)
            && FileIO::writeFileAll(roundtrip.filePath("talk.grp"), talkData)
            && KDEFEdit::decodeRecords(FileIO::readFileAll(roundtrip.filePath("talk.idx")),
                FileIO::readFileAll(roundtrip.filePath("talk.grp")), reopened);
        if (valid) { edited.str = reopened[0]; edited.len = edited.str.size(); }
        check(valid && RFileIO::readTalkStr(edited) == expected, "Talk edited text encoded/saved/reopened");
    }
    }
    KDEFEdit editor;
    bool hasKdef = QFile::exists(config.gamePath + config.kdefIdx) || QFile::exists(config.gamePath + config.kdefGrp);
    if (hasKdef) {
        editor.readKDEFFile();
        check(editor.m_loaded && !editor.m_events.isEmpty(), QString("KDEF: %1 events").arg(editor.m_events.size()));
    } else output << "SKIP: legacy KDEF pair absent; script compatibility is not tested\n";
    QSet<QString> layouts;
    int instructionCount = 0;
    for (int eventIndex = 0; eventIndex < editor.m_events.size(); ++eventIndex) {
        editor.displayInstructions(eventIndex);
        const auto &event = editor.m_events[eventIndex];
        for (int instruction = 0; instruction < event.instructions.size(); ++instruction) {
            const auto &entry = event.instructions[instruction];
            ++instructionCount;
            QString layout = QString::number(entry.code) + ":" + QString::number(entry.params.size());
            if (entry.code == 50) layout += ":" + QString::number(entry.params.value(0)) + ":" + QString::number(entry.params.value(1));
            if (layouts.contains(layout)) continue;
            layouts.insert(layout);
            editor.displayInstructionDetail(instruction);
            check(editor.m_paramTable->rowCount() == entry.params.size(), "KDEF layout " + layout);
        }
    }
    output << "Instructions: " << instructionCount << "; layouts: " << layouts.size() << '\n';
    WarEdit war;
    check(war.m_loaded && !war.m_warFile.records.isEmpty(),
        QString("War records: %1").arg(war.m_warFile.records.size()));
    {
        QString originalPath = config.gamePath;
        QScopedValueRollback<QString> gamePath(config.gamePath, roundtrip.path() + "/");
        QDir().mkpath(QFileInfo(config.gamePath + config.warData).absolutePath());
        QDir().mkpath(QFileInfo(config.gamePath + config.kdefIdx).absolutePath());
        QDir().mkpath(QFileInfo(config.gamePath + config.kdefGrp).absolutePath());
        QScopedValueRollback<bool> saveGuard(savingCopy, true);
        war.onSave();
        check(FileIO::readFileAll(config.gamePath + config.warData) == FileIO::readFileAll(originalPath + config.warData),
            "War byte-exact actual save");
        check(war.readW(), "War saved copy reopen");
        if (hasKdef) {
        editor.onSaveKDEF();
        check(FileIO::readFileAll(config.gamePath + config.kdefIdx) == FileIO::readFileAll(originalPath + config.kdefIdx)
            && FileIO::readFileAll(config.gamePath + config.kdefGrp) == FileIO::readFileAll(originalPath + config.kdefGrp),
            "KDEF byte-exact actual save");
        editor.m_loaded = false;
        editor.readKDEFFile();
        check(editor.m_loaded, "KDEF saved copy reopen");
        }
        if (!war.m_warFile.records.isEmpty() && !war.m_warFile.records[0].fields.isEmpty()
            && !war.m_warFile.records[0].fields[0].values.isEmpty()) {
            auto expected = war.m_warFile.records[0].fields[0].values[0] == 0 ? 1 : 0;
            war.m_warFile.records[0].fields[0].values[0] = expected;
            war.onSave();
            check(war.readW() && war.m_warFile.records[0].fields[0].values[0] == expected,
                "War edited numeric field survives save/reopen");
        }
        int selectedEvent = -1, selectedInstruction = -1;
        for (int eventIndex = 0; eventIndex < editor.m_events.size() && selectedEvent < 0; ++eventIndex)
            for (int instructionIndex = 0; instructionIndex < editor.m_events[eventIndex].instructions.size(); ++instructionIndex)
                if (!editor.m_events[eventIndex].instructions[instructionIndex].params.isEmpty()) {
                    selectedEvent = eventIndex;
                    selectedInstruction = instructionIndex;
                    break;
                }
        if (hasKdef) check(selectedEvent >= 0, "KDEF editable parameter present");
        if (selectedEvent >= 0) {
            qint16 expected = editor.m_events[selectedEvent].instructions[selectedInstruction].params[0] == 0 ? 1 : 0;
            editor.m_events[selectedEvent].instructions[selectedInstruction].params[0] = expected;
            editor.onSaveKDEF();
            editor.m_loaded = false;
            editor.readKDEFFile();
            check(editor.m_loaded && editor.m_events[selectedEvent].instructions[selectedInstruction].params[0] == expected,
                "KDEF edited parameter survives save/reopen");
        }
    }
    if (QFile::exists(config.gamePath + config.mmapFileIdx) || QFile::exists(config.gamePath + config.mmapFileGrp)) {
        QVector<GrpPic> original, reopened;
        bool loaded = GrpIO::readGrp(config.gamePath + config.mmapFileIdx, config.gamePath + config.mmapFileGrp, original);
        QString indexCopy = roundtrip.filePath("mmap.idx"), dataCopy = roundtrip.filePath("mmap.grp");
        bool valid = loaded && GrpIO::saveGrp(indexCopy, dataCopy, original)
            && GrpIO::readGrp(indexCopy, dataCopy, reopened) && original.size() == reopened.size();
        for (int picture = 0; valid && picture < original.size(); ++picture)
            valid = original[picture].data == reopened[picture].data
                && original[picture].xoff == reopened[picture].xoff && original[picture].yoff == reopened[picture].yoff;
        check(valid, "Main GRP all image bytes/offsets survive save/reopen; reserved IDX slots normalized");
    } else output << "SKIP: legacy main GRP pair absent; PNG tile container checked separately\n";
    auto checkMap = [&](IsoMapEditor &map, const QString &name) {
        int decoded = 0;
        for (const auto &tile : map.m_tileCache) if (!tile.isNull()) ++decoded;
        check(!map.m_mapData.map.isEmpty() && decoded > 0 && !map.m_mapImage.isNull(),
            QString("%1: %2 maps, %3 decoded tiles, render %4x%5").arg(name)
                .arg(map.m_mapData.map.size()).arg(decoded)
                .arg(map.m_mapImage.width()).arg(map.m_mapImage.height()));
    };
    auto saveMapCopy = [&](const QStringList &paths, const std::function<void()> &save) {
        QString originalPath = config.gamePath;
        QScopedValueRollback<QString> pathGuard(config.gamePath, roundtrip.path() + "/");
        for (const auto &path : paths) QDir().mkpath(QFileInfo(config.gamePath + path).absolutePath());
        QScopedValueRollback<bool> saveGuard(savingCopy, true);
        save();
        for (const auto &path : paths)
            check(QFile::exists(config.gamePath + path)
                && FileIO::readFileAll(config.gamePath + path) == FileIO::readFileAll(originalPath + path),
                "Map byte-exact actual save: " + path);
    };
    { WarMapEdit map; checkMap(map, "War map");
        saveMapCopy({config.warMapDefIdx, config.warMapDefGrp}, [&] { map.onSaveMap(); });
        bool rendered = true;
        for (int index = 0; index < map.m_mapData.map.size(); ++index) {
            map.onLoadMap(index);
            rendered = rendered && !map.m_mapImage.isNull();
        }
        check(rendered, "All war maps rendered");
        QScopedValueRollback<QString> pathGuard(config.gamePath, roundtrip.path() + "/");
        QScopedValueRollback<bool> saveGuard(savingCopy, true);
        qint16 expected = map.m_mapData.map[0].mapLayer[0].pic[0][0] == 0 ? 2 : 0;
        map.m_mapData.map[0].mapLayer[0].pic[0][0] = expected;
        map.onSaveMap(); map.readWarMapDef();
        check(!map.m_mapData.map.isEmpty() && map.m_mapData.map[0].mapLayer[0].pic[0][0] == expected,
            "War map edited cell survives save/reopen"); }
    { SceneMapEdit map; checkMap(map, "Scene map");
        for (int slot = 0; slot < config.sGrp.size(); ++slot) {
            if (!QFile::exists(config.gamePath + config.sGrp[slot])) {
                output << "SKIP: scene slot " << slot << " not provided\n";
                continue;
            }
            map.loadSceneGrpFile(slot);
            bool valid = map.m_sceneCount > 0;
            for (int scene = 0; scene < map.m_sceneCount; ++scene) {
                map.readSceneData(scene);
                valid = valid && MapIO::encodeMap(map.m_mapData.map[0])
                    == map.m_sceneRawData.mid(scene * 49152, 49152);
            }
            check(valid, QString("Scene slot %1: all %2 maps decode/re-encode").arg(slot).arg(map.m_sceneCount));
            if (!valid) continue;
            if (slot < config.sIdx.size() && slot < config.dIdx.size() && slot < config.dGrp.size()) {
                saveMapCopy({config.sGrp[slot], config.dGrp[slot]}, [&] { map.onSaveScene(); });
                QScopedValueRollback<QString> pathGuard(config.gamePath, roundtrip.path() + "/");
                QScopedValueRollback<bool> saveGuard(savingCopy, true);
                int scene = map.m_currentScene;
                qint16 expected = map.m_mapData.map[0].mapLayer[0].pic[0][0] == 0 ? 2 : 0;
                qint16 eventExpected = map.m_dFile.mapEvent[scene].sceneEvent[0].event1 == 0 ? 1 : 0;
                map.m_mapData.map[0].mapLayer[0].pic[0][0] = expected;
                map.m_dFile.mapEvent[scene].sceneEvent[0].event1 = eventExpected;
                map.onSaveScene();
                Map reopenedMap; DFile reopenedEvents;
                bool edited = MapIO::readSingleMap(FileIO::readFileAll(config.gamePath + config.sGrp[slot]),
                    scene * 49152, reopenedMap, 6, 64, 64)
                    && EventIO::readEvents(config.gamePath + config.dIdx[slot], config.gamePath + config.dGrp[slot], reopenedEvents);
                check(edited && reopenedMap.mapLayer[0].pic[0][0] == expected
                    && reopenedEvents.mapEvent[scene].sceneEvent[0].event1 == eventExpected,
                    QString("Scene slot %1 edited cell/event survives save/reopen").arg(slot));
                    } else check(false, QString("Scene slot %1 missing save paths").arg(slot));
        }
    }
    { MainMapEdit map; checkMap(map, "Main map");
        if (!map.m_mapData.map.isEmpty()) {
        saveMapCopy({config.mEarth, config.mSurface, config.mBuilding, config.mBuildX, config.mBuildY}, [&] { map.onSaveMap(); });
        QScopedValueRollback<QString> pathGuard(config.gamePath, roundtrip.path() + "/");
        QScopedValueRollback<bool> saveGuard(savingCopy, true);
        qint16 expected = map.m_mapData.map[0].mapLayer[0].pic[0][0] == 0 ? 2 : 0;
        map.m_mapData.map[0].mapLayer[0].pic[0][0] = expected;
        map.onSaveMap(); map.readMainMapFile();
        check(!map.m_mapData.map.isEmpty() && map.m_mapData.map[0].mapLayer[0].pic[0][0] == expected,
            "Main map edited cell survives save/reopen"); } }
    if (!QApplication::arguments().contains("--data-only")) {
    for (const QString &directory : {QString("resource"), QString("fight"), QString("head"), QString("item")}) {
        QDirIterator files(config.gamePath + directory, {"*.idx"}, QDir::Files, QDirIterator::Subdirectories);
        while (files.hasNext()) {
            QString index = files.next();
            QString data = index.left(index.size() - 4) + ".grp";
            QString base = QFileInfo(index).baseName().toLower();
            if (!QFile::exists(data) || base.startsWith("talk") || base == "kdef" || base == "warfld" || base == "name") continue;
            QVector<GrpPic> pictures, reopened;
            bool valid = GrpIO::readGrp(index, data, pictures);
            if (valid) valid = GrpIO::saveGrp(roundtrip.filePath("images.idx"), roundtrip.filePath("images.grp"), pictures)
                && GrpIO::readGrp(roundtrip.filePath("images.idx"), roundtrip.filePath("images.grp"), reopened)
                && pictures.size() == reopened.size();
            for (int entry = 0; valid && entry < pictures.size(); ++entry)
                valid = pictures[entry].data == reopened[entry].data
                    && pictures[entry].xoff == reopened[entry].xoff && pictures[entry].yoff == reopened[entry].yoff;
            check(valid, "Real GRP image roundtrip: " + QDir(config.gamePath).relativeFilePath(index));
        }
    }
    QDirIterator pngFiles(config.gamePath, {"*.png"}, QDir::Files, QDirIterator::Subdirectories);
    int pngCount = 0;
    bool pngValid = true;
    while (pngFiles.hasNext()) {
        QString imagePath = pngFiles.next();
        QString relative = QDir(config.gamePath).relativeFilePath(imagePath);
        if (relative.startsWith("exported", Qt::CaseInsensitive)) continue;
        QImage image(imagePath);
        bool valid = !image.isNull() && image.save(roundtrip.filePath("image.png"), "PNG");
        if (valid) valid = image.convertToFormat(QImage::Format_ARGB32)
            == QImage(roundtrip.filePath("image.png")).convertToFormat(QImage::Format_ARGB32);
        pngValid = pngValid && valid;
        ++pngCount;
    }
    check(pngValid && pngCount > 0, QString("Real PNG decode/export pixel roundtrip: %1 files").arg(pngCount));
    } else output << "SKIP: bulk GRP/PNG checks (--data-only); see separate full resource report\n";
    output << "Failures: " << failures << '\n';
    return failures ? 1 : 0;
}

inline int runSelfTests(const QString &reportPath)
{
#ifdef Q_OS_WIN
    SetErrorMode(SEM_FAILCRITICALERRORS | SEM_NOGPFAULTERRORBOX | SEM_NOOPENFILEERRORBOX);
#ifdef _MSC_VER
    _set_error_mode(_OUT_TO_STDERR);
    _set_abort_behavior(0, _WRITE_ABORT_MSG | _CALL_REPORTFAULT);
#ifdef _DEBUG
    for (int reportType : {_CRT_WARN, _CRT_ERROR, _CRT_ASSERT}) {
        _CrtSetReportMode(reportType, _CRTDBG_MODE_FILE);
        _CrtSetReportFile(reportType, _CRTDBG_FILE_STDERR);
    }
#endif
#endif
#endif
    QFile report(reportPath);
    if (!report.open(QIODevice::WriteOnly | QIODevice::Text)) return 2;
    QTextStream output(&report);
    bool dialogTimedOut = false;
    QTimer dialogWatchdog;
    dialogWatchdog.setInterval(100);
    QObject::connect(&dialogWatchdog, &QTimer::timeout, &dialogWatchdog, [&] {
        output.flush();
        for (QWidget *widget : QApplication::topLevelWidgets()) {
            auto *dialog = qobject_cast<QDialog *>(widget);
            if (!dialog || !dialog->isVisible()) continue;
            int ticks = dialog->property("selfTestVisibleTicks").toInt() + 1;
            dialog->setProperty("selfTestVisibleTicks", ticks);
            if (ticks < 50) continue;
            dialogTimedOut = true;
            output << "FAIL: Unhandled dialog timed out: " << dialog->windowTitle() << '\n';
            output.flush();
            dialog->reject();
        }
    });
    dialogWatchdog.start();
    auto require = [](bool value, const char *message) { if (!value) throw std::runtime_error(message); };
    try {
        QTemporaryDir temporary;
        {
            for (int code = 0; code <= 3; ++code) {
                QScopedValueRollback<int> codeGuard(Encoding::talkCode, code);
                TalkStr talk;
                QString expected = QString::fromUtf8("\xe6\xb8\xac\xe8\xa9\xa6");
                RFileIO::writeTalkStr(talk, expected);
                require(!talk.str.isEmpty() && RFileIO::readTalkStr(talk) == expected,
                    "Talk encoding write/read failed");
            }
        }
        require(temporary.isValid(), "Temporary directory unavailable");
        {
            QByteArray bytes("keep");
            require(!Encoding::writeInStrWithCode(QString::fromUtf8("\xe6\xb8\xac"), bytes.data(), 2, 3)
                && bytes == "keep", "Short UTF8 field changed after rejected write");
            QString unsupported = QString::fromUtf8("\xf0\x9f\x98\x80");
            require(!Encoding::writeInStrWithCode(unsupported, bytes.data(), bytes.size(), 1)
                && bytes == "keep", "Unrepresentable Big5 write changed buffer");
            QScopedValueRollback<int> codeGuard(Encoding::talkCode, 1);
            TalkStr talk;
            talk.str = "original";
            talk.len = talk.str.size();
            require(!RFileIO::writeTalkStr(talk, unsupported) && talk.str == "original" && talk.len == 8,
                "Rejected Talk conversion changed existing record");
            output << "PASS: rejected encoding writes preserve original buffers and Talk records\n";
        }
        {
            QString folder = temporary.filePath("mixed-image-format");
            require(QDir().mkpath(folder), "Cannot create mixed image fixture");
            QImage image(4, 4, QImage::Format_RGB32);
            image.fill(Qt::red);
            require(image.save(folder + "/0.png", "JPEG"), "Cannot create JPEG with PNG filename");
            QVector<GrpPic> pictures;
            QVector<QImage> tiles;
            require(MapIO::loadPngTiles(folder, pictures, tiles) && tiles.size() == 1 && !tiles[0].isNull(),
                "JPEG content with PNG extension rejected");
            require(QDir(folder).removeRecursively(), "Cannot remove mixed image fixture");
            output << "PASS: image containers identify content independently of PNG extension\n";
        }
        {
            QLibrary library("libwebp");
            using Encode = size_t (*)(const unsigned char *, int, int, int, unsigned char **);
            using Free = void (*)(void *);
            auto encode = reinterpret_cast<Encode>(library.resolve("WebPEncodeLosslessRGBA"));
            auto release = reinterpret_cast<Free>(library.resolve("WebPFree"));
            require(encode && release, "WebP runtime or transitive dependency unavailable");
            QImage image(3, 2, QImage::Format_RGBA8888);
            image.fill(QColor(27, 83, 149, 255));
            unsigned char *encoded = nullptr;
            size_t size = encode(image.constBits(), image.width(), image.height(), image.bytesPerLine(), &encoded);
            QByteArray bytes(reinterpret_cast<const char *>(encoded), size);
            release(encoded);
            QImage restored = ImzIO::decodeImage(bytes);
            require(size > 0 && restored.convertToFormat(QImage::Format_RGBA8888) == image,
                "WebP fallback failed lossless pixel roundtrip");
            output << "PASS: deployed WebP runtime lossless pixel roundtrip\n";
        }
        {
            auto &config = IniConfig::instance();
            QScopedValueRollback<int> typeCount(config.rGlobals.typeNumber, 0);
            QScopedValueRollback<QString> palette(config.palette, QString());
            QScopedValueRollback<QString> gamePath(config.gamePath, temporary.path() + "/");
            MainWindow window;
            window.show();
            QAction *association = nullptr;
            for (auto *action : window.findChildren<QAction *>())
                if (action->text() == QString::fromUtf8("文件关联...")) association = action;
            require(association != nullptr, "File association menu is unreachable");
            bool associationOpened = false;
            QTimer::singleShot(0, [&associationOpened] {
                for (auto *widget : QApplication::topLevelWidgets())
                    if (auto *dialog = qobject_cast<FileRelation *>(widget); dialog && dialog->isVisible()) {
                        associationOpened = true;
                        dialog->reject();
                    }
            });
            association->trigger();
            require(associationOpened, "File association action did not open its dialog");
            require(QMetaObject::invokeMethod(&window, "onOpenGrpList", Qt::DirectConnection),
                "Cannot invoke GRP editor menu");
            require(window.mdiArea()->subWindowList().size() == 1, "GRP menu did not create one child");
            window.mdiArea()->closeAllSubWindows();
            QApplication::sendPostedEvents(nullptr, QEvent::DeferredDelete);
            require(window.mdiArea()->subWindowList().isEmpty(), "Closed MDI editor blocks directory changes");
            QMetaObject::invokeMethod(&window, "onOpenGrpList", Qt::DirectConnection);
            require(window.mdiArea()->subWindowList().size() == 1, "Closed editor cannot reopen");
            QMetaObject::invokeMethod(&window, "onOpenGrpList", Qt::DirectConnection);
            require(window.mdiArea()->subWindowList().size() == 1, "Repeated menu action duplicates editor");
            require(window.close(), "Main window did not close clean editors");
            QApplication::sendPostedEvents(nullptr, QEvent::DeferredDelete);
        }
        output << "PASS: file association menu and MDI close/reopen lifecycle\n";
        {
            for (bool utf16 : {false, true}) {
                QString text = QString::fromUtf8("; config \xe4\xb8\xad\xe6\x96\x87\r\n[run]\r\ngamepath=D:\\games\\kys\\\r\ndatacode=1; keep\r\n[file]\r\nFile0=a,b,c");
                QStringEncoder encoder(utf16 ? QStringConverter::Utf16LE : QStringConverter::Utf8);
                QByteArray bytes = encoder(text);
                bytes.prepend(QByteArray::fromHex(utf16 ? "fffe" : "efbbbf"));
                QString path = temporary.filePath(utf16 ? "settings16.ini" : "settings8.ini");
                require(FileIO::writeFileAll(path, bytes), "Cannot create settings fixture");
                QTemporaryFile pathTemporary;
                QString readablePath;
                require(prepareIniPath(path, pathTemporary, readablePath), "Cannot prepare path fixture");
                QSettings pathSettings(readablePath, QSettings::IniFormat);
                require(pathSettings.value("run/gamepath").toString() == "D:\\games\\kys\\",
                    "INI path backslashes were interpreted as escapes");
                require(saveRunSettings(path, {{"datacode", 3}, {"talkcode", 2}}), "Settings save failed");
                QByteArray saved = FileIO::readFileAll(path);
                require(saved.startsWith(QByteArray::fromHex(utf16 ? "fffe" : "efbbbf")), "Settings BOM lost");
                QStringDecoder decoder(utf16 ? QStringConverter::Utf16LE : QStringConverter::Utf8);
                QString result = decoder(saved);
                require(!decoder.hasError() && result.contains("datacode=3; keep\r\n")
                    && result.contains("talkcode=2\r\n[file]") && result.contains("gamepath=D:\\games\\kys\\\r\n")
                    && result.endsWith("File0=a,b,c"), "Settings changed unrelated text or sections");
                require(saveRunPath(path, "D:/new games/kys/"), "Game path persistence failed");
                QByteArray persisted = FileIO::readFileAll(path);
                QStringDecoder pathDecoder(utf16 ? QStringConverter::Utf16LE : QStringConverter::Utf8);
                QString pathText = pathDecoder(persisted);
                require(pathText.contains("gamepath=D:/new games/kys/") && pathText.endsWith("File0=a,b,c")
                    && persisted.startsWith(QByteArray::fromHex(utf16 ? "fffe" : "efbbbf")),
                    "Persisting game path changed BOM or other sections");
                require(!saveRunPath(path, "bad\npath") && FileIO::readFileAll(path) == persisted,
                    "Invalid path damaged configuration");
                QString specialPath = "D:/new games/one;two#three,four/";
                require(saveRunPath(path, specialPath), "Cannot persist special-character game path");
                QTemporaryFile specialTemporary;
                QString specialSettingsPath;
                require(prepareIniPath(path, specialTemporary, specialSettingsPath), "Cannot prepare special path config");
                QSettings specialSettings(specialSettingsPath, QSettings::IniFormat);
                require(specialSettings.value("run/gamepath").toString() == specialPath,
                    "Special-character game path failed to round trip");
                require(saveRunPath(path, "D:/plain/"), "Cannot replace quoted game path");
                QTemporaryFile plainTemporary;
                QString plainSettingsPath;
                require(prepareIniPath(path, plainTemporary, plainSettingsPath), "Cannot prepare replaced path config");
                QSettings plainSettings(plainSettingsPath, QSettings::IniFormat);
                require(plainSettings.value("run/gamepath").toString() == "D:/plain/",
                    "Replacing quoted path retained old path as a comment");
                require(saveMapMode(path, 2), "Cannot persist original map mode key");
                QTemporaryFile modeTemporary;
                QString modePath;
                require(prepareIniPath(path, modeTemporary, modePath), "Cannot prepare map mode config");
                QSettings modeSettings(modePath, QSettings::IniFormat);
                require(modeSettings.value("file/MMapMode").toInt() == 2
                    && modeSettings.value("run/datacode").toInt() == 3
                    && FileIO::readFileAll(path).startsWith(QByteArray::fromHex(utf16 ? "fffe" : "efbbbf")),
                    "Map mode persistence changed other settings or encoding");
                QByteArray modeBytes = FileIO::readFileAll(path);
                require(!saveMapMode(path, 3) && FileIO::readFileAll(path) == modeBytes,
                    "Invalid map mode modified config");
            }
        }
        output << "PASS: UTF16/UTF8 settings BOM, paths, comments and unrelated sections\n";
        {
            auto &config = IniConfig::instance();
            QScopedValueRollback<QString> configPath(config.iniPath, temporary.filePath("map-mode.ini"));
            QScopedValueRollback<int> configMode(config.mainMapMode, 2);
            QScopedValueRollback<QString> sourcePath(config.mmapPNGPath, temporary.filePath("mode-tiles/"));
            QScopedValueRollback<QString> gamePath(config.gamePath, QString());
            require(QDir().mkpath(config.mmapPNGPath), "Cannot create source tiles folder");
            QImage sourceTile(2, 2, QImage::Format_ARGB32);
            sourceTile.fill(Qt::red);
            require(sourceTile.save(config.mmapPNGPath + "0.png"), "Cannot create source tile");
            require(FileIO::writeFileAll(config.iniPath, "[File]\nMMapMode=1\n"), "Cannot create mode fixture");
            {
                MainMapEdit editor;
                editor.m_timer->stop();
                require(editor.m_tileSourceCombo->currentIndex() == 3, "Original folder mode was not restored");
                editor.m_tileSourceCombo->setCurrentIndex(0);
                editor.m_tileSourceCombo->setCurrentIndex(3);
                require(config.mainMapMode == 2, "PNG folder mode was not retained");
                QTemporaryFile prepared;
                QString path;
                require(prepareIniPath(config.iniPath, prepared, path), "Cannot reload mode fixture");
                QSettings settings(path, QSettings::IniFormat);
                require(settings.value("File/MMapMode").toInt() == 2, "UI selection did not persist original mode value");
                QByteArray beforeFailure = FileIO::readFileAll(config.iniPath);
                auto dismissWarning = [] {
                    QTimer::singleShot(0, [] {
                        for (auto *widget : QApplication::topLevelWidgets())
                            if (auto *message = qobject_cast<QMessageBox *>(widget))
                                if (message->button(QMessageBox::Ok)) message->button(QMessageBox::Ok)->click();
                    });
                };
                {
                    QScopedValueRollback<QString> missingArchive(config.mmapImz, "missing-source.imz");
                    dismissWarning();
                    editor.m_tileSourceCombo->setCurrentIndex(2);
                    require(editor.m_tileSourceCombo->currentIndex() == 3 && config.mainMapMode == 2
                        && FileIO::readFileAll(config.iniPath) == beforeFailure
                        && editor.m_tileCache[0].pixelColor(0, 0) == QColor(Qt::red),
                        "Failed source load changed persisted mode or pixels");
                }
                {
                    QScopedValueRollback<QString> missingConfig(config.iniPath, temporary.filePath("absent/mode.ini"));
                    dismissWarning();
                    editor.m_tileSourceCombo->setCurrentIndex(0);
                    require(editor.m_tileSourceCombo->currentIndex() == 3 && config.mainMapMode == 2
                        && editor.m_tileCache[0].pixelColor(0, 0) == QColor(Qt::red),
                        "Failed config save changed source mode or pixels");
                }
            }
            MainMapEdit reopened;
            reopened.m_timer->stop();
            require(reopened.m_tileSourceCombo->currentIndex() == 3, "Reopened map lost source selection");
            require(!reopened.m_tileCache.isEmpty() && reopened.m_tileCache[0].pixelColor(0, 0) == QColor(Qt::red),
                "Reopened map did not load selected source pixels");
        }
        output << "PASS: main map source selection persistence and original mode mapping\n";
        {
            QVector<QRgb> palette(256, qRgb(0, 0, 0));
            palette[1] = qRgb(255, 0, 0);
            palette[2] = qRgb(0, 255, 0);
            uint8_t red[256]{}, green[256]{}, blue[256]{};
            red[1] = 255; green[2] = 255;
            QImage image(2, 3, QImage::Format_ARGB32);
            image.fill(Qt::red);
            image.setPixelColor(1, 2, Qt::green);
            GrpPic sprite = GrpIO::encodeRLE(image, red, green, blue);
            sprite.xoff = -32768; sprite.yoff = 32767;
            GrpEdit editor;
            editor.setSprite(sprite, palette);
            GrpPic saved;
            QObject::connect(&editor, &GrpEdit::spriteModified, &editor, [&](const GrpPic &result) { saved = result; });
            require(QMetaObject::invokeMethod(&editor, "onSave", Qt::DirectConnection)
                && saved.xoff == -32768 && saved.yoff == 32767
                && qFromLittleEndian<qint16>(saved.data.constData() + 4) == -32768
                && qFromLittleEndian<qint16>(saved.data.constData() + 6) == 32767,
                "GRP editor clamped valid int16 offsets");
            for (const auto &operation : {QString("onFlipH"), QString("onFlipV"), QString("onRotate90"), QString("onRotate270")}) {
                editor.setSprite(sprite, palette);
                QImage expected;
                if (operation == "onFlipH") expected = image.mirrored(true, false);
                else if (operation == "onFlipV") expected = image.mirrored(false, true);
                else { QTransform transform; transform.rotate(operation == "onRotate90" ? 90 : 270); expected = image.transformed(transform); }
                require(QMetaObject::invokeMethod(&editor, operation.toLatin1().constData(), Qt::DirectConnection)
                    && QMetaObject::invokeMethod(&editor, "onSave", Qt::DirectConnection)
                    && GrpIO::decodeRLE(saved, red, green, blue) == expected,
                    "GRP transform changed non-square sprite pixels");
            }
        }
        {
            QMimeData *previousClipboard = new QMimeData;
            const QMimeData *currentClipboard = QApplication::clipboard()->mimeData();
            if (currentClipboard) for (const auto &format : currentClipboard->formats())
                previousClipboard->setData(format, currentClipboard->data(format));
            QVector<QRgb> palette(256, qRgb(0, 0, 0));
            palette[1] = qRgb(255, 0, 0);
            uint8_t red[256]{}, green[256]{}, blue[256]{};
            red[1] = 255;
            QImage image(3, 2, QImage::Format_ARGB32);
            image.fill(Qt::transparent);
            image.setPixelColor(2, 1, Qt::red);
            GrpPic sprite = GrpIO::encodeRLE(image, red, green, blue);
            GrpEdit source, target;
            source.setSprite(sprite, palette);
            sprite.xoff = -123; sprite.yoff = 456;
            target.setSprite(sprite, palette);
            GrpPic saved;
            QObject::connect(&target, &GrpEdit::spriteModified, &target, [&](const GrpPic &result) { saved = result; });
            bool copied = QMetaObject::invokeMethod(&source, "onCopy", Qt::DirectConnection);
            bool pasted = QMetaObject::invokeMethod(&target, "onPaste", Qt::DirectConnection);
            bool committed = QMetaObject::invokeMethod(&target, "onSave", Qt::DirectConnection);
            QApplication::clipboard()->setMimeData(previousClipboard);
            require(copied && pasted && committed && saved.xoff == -123 && saved.yoff == 456
                && GrpIO::decodeRLE(saved, red, green, blue) == image,
                "GRP clipboard changed transparent pixels or target offsets");
        }
        output << "PASS: GRP editor full int16 offsets, transforms and cross-editor clipboard pixels\n";
        {
            QVector<QRgb> palette(256, qRgb(0, 0, 0));
            palette[1] = qRgb(255, 0, 0); palette[2] = qRgb(0, 255, 0);
            uint8_t red[256]{}, green[256]{}, blue[256]{};
            red[1] = 255; green[2] = 255;
            QImage image(3, 2, QImage::Format_ARGB32);
            image.fill(Qt::red);
            GrpEdit editor;
            editor.setSprite(GrpIO::encodeRLE(image, red, green, blue), palette);
            QLabel *paletteLabel = nullptr, *imageLabel = nullptr;
            for (auto *label : editor.findChildren<QLabel *>()) {
                if (label->size() == QSize(192, 192)) paletteLabel = label;
                else if (!label->pixmap().isNull()) imageLabel = label;
            }
            QComboBox *zoom = nullptr, *tool = nullptr;
            for (auto *combo : editor.findChildren<QComboBox *>()) {
                if (combo->count() == 5) zoom = combo;
                if (combo->count() == 4) tool = combo;
            }
            require(paletteLabel && imageLabel && zoom && tool, "GRP paint controls missing");
            auto click = [](QWidget *widget, const QPoint &position, Qt::MouseButton button) {
                QMouseEvent event(QEvent::MouseButtonPress, QPointF(position), QPointF(position), button, button, Qt::NoModifier);
                QCoreApplication::sendEvent(widget, &event);
            };
            GrpPic saved;
            QObject::connect(&editor, &GrpEdit::spriteModified, &editor, [&](const GrpPic &result) { saved = result; });
            zoom->setCurrentIndex(2);
            click(paletteLabel, QPoint(25, 1), Qt::LeftButton);
            click(imageLabel, QPoint(5, 1), Qt::LeftButton);
            QMetaObject::invokeMethod(&editor, "onSave", Qt::DirectConnection);
            QImage painted = GrpIO::decodeRLE(saved, red, green, blue);
            require(painted.pixelColor(1, 0) == QColor(Qt::green) && painted.pixelColor(0, 0) == QColor(Qt::red),
                "Zoomed GRP brush wrote the wrong pixel");
            QMouseEvent drag(QEvent::MouseMove, QPointF(1, 5), QPointF(1, 5), Qt::NoButton, Qt::LeftButton, Qt::NoModifier);
            QCoreApplication::sendEvent(imageLabel, &drag);
            QMouseEvent hover(QEvent::MouseMove, QPointF(1, 1), QPointF(1, 1), Qt::NoButton, Qt::NoButton, Qt::NoModifier);
            QCoreApplication::sendEvent(imageLabel, &hover);
            QMetaObject::invokeMethod(&editor, "onSave", Qt::DirectConnection);
            painted = GrpIO::decodeRLE(saved, red, green, blue);
            require(painted.pixelColor(0, 1) == QColor(Qt::green) && painted.pixelColor(0, 0) == QColor(Qt::red),
                "GRP drag failed to paint or unpressed movement painted a pixel");
            tool->setCurrentIndex(2);
            click(imageLabel, QPoint(5, 1), Qt::LeftButton);
            click(imageLabel, QPoint(9, 5), Qt::RightButton);
            QMetaObject::invokeMethod(&editor, "onSave", Qt::DirectConnection);
            require(GrpIO::decodeRLE(saved, red, green, blue).pixelColor(2, 1) == QColor(Qt::green),
                "GRP eyedropper/right brush failed");
            tool->setCurrentIndex(3);
            click(imageLabel, QPoint(5, 1), Qt::LeftButton);
            QMetaObject::invokeMethod(&editor, "onSave", Qt::DirectConnection);
            QImage transparent = GrpIO::decodeRLE(saved, red, green, blue);
            require(transparent.pixelColor(1, 0).alpha() == 0 && transparent.pixelColor(2, 1).alpha() == 0
                && transparent.pixelColor(0, 0) == QColor(Qt::red), "GRP transparent replacement changed unrelated colors");
        }
        output << "PASS: GRP zoomed brush, eyedropper and transparent replacement mouse pixels\n";
        {
            QImage image(3, 2, QImage::Format_ARGB32);
            image.fill(Qt::blue);
            GrpPic picture;
            QBuffer buffer(&picture.data);
            require(image.save(&buffer, "PNG"), "Cannot create canvas PNG");
            picture.width = 3; picture.height = 2; picture.size = picture.data.size();
            GrpEdit editor;
            editor.setSprite(picture, QVector<QRgb>(256, qRgb(0, 0, 0)));
            auto *width = editor.findChild<QSpinBox *>("canvasWidth");
            auto *height = editor.findChild<QSpinBox *>("canvasHeight");
            auto *resize = editor.findChild<QPushButton *>("resizeCanvas");
            auto *custom = editor.findChild<QPushButton *>("customColor");
            require(width && height && resize && custom, "Canvas controls missing");
            GrpPic saved;
            QObject::connect(&editor, &GrpEdit::spriteModified, &editor, [&](const GrpPic &result) { saved = result; });
            width->setValue(5); height->setValue(4); resize->click();
            QMetaObject::invokeMethod(&editor, "onSave", Qt::DirectConnection);
            QImage expanded = QImage::fromData(saved.data);
            require(expanded.size() == QSize(5, 4) && expanded.pixelColor(0, 0) == QColor(Qt::blue)
                && expanded.pixelColor(4, 3).alpha() == 0, "Canvas expansion lost pixels or transparency");
            width->setValue(2); height->setValue(1); resize->click();
            QMetaObject::invokeMethod(&editor, "onSave", Qt::DirectConnection);
            require(QImage::fromData(saved.data).size() == QSize(2, 1), "Canvas crop failed");
            bool native = QApplication::testAttribute(Qt::AA_DontUseNativeDialogs);
            QApplication::setAttribute(Qt::AA_DontUseNativeDialogs, true);
            QTimer::singleShot(0, [] {
                for (auto *widget : QApplication::topLevelWidgets())
                    if (auto *dialog = qobject_cast<QColorDialog *>(widget); dialog && dialog->isVisible()) {
                        dialog->setCurrentColor(QColor(23, 45, 67)); dialog->accept();
                    }
            });
            custom->click();
            QApplication::setAttribute(Qt::AA_DontUseNativeDialogs, native);
            QLabel *preview = nullptr;
            for (auto *label : editor.findChildren<QLabel *>())
                if (!label->pixmap().isNull() && label->size() != QSize(192, 192)) preview = label;
            require(preview, "Canvas preview missing");
            QMouseEvent click(QEvent::MouseButtonPress, QPointF(1, 0), QPointF(1, 0), Qt::LeftButton, Qt::LeftButton, Qt::NoModifier);
            QCoreApplication::sendEvent(preview, &click);
            QMetaObject::invokeMethod(&editor, "onSave", Qt::DirectConnection);
            require(QImage::fromData(saved.data).pixelColor(1, 0) == QColor(23, 45, 67), "Custom RGB brush failed");
            auto *offset = editor.findChild<QCheckBox *>();
            require(offset, "Offset toggle missing");
            offset->setChecked(false);
            require(preview->pixmap().toImage().pixelColor(0, 0) == QColor(Qt::blue), "Offset toggle did not hide cross");
            QWheelEvent wheel(QPointF(0, 0), QPointF(0, 0), QPoint(), QPoint(0, 120), Qt::NoButton, Qt::NoModifier, Qt::NoScrollPhase, false);
            QCoreApplication::sendEvent(preview, &wheel);
            require(preview->pixmap().size() == QSize(4, 2), "Wheel zoom did not change preview scale");
            width->setValue(1024); height->setValue(257); resize->click();
            QComboBox *zoom = nullptr;
            for (auto *combo : editor.findChildren<QComboBox *>())
                if (combo->findText("16x") >= 0) zoom = combo;
            require(zoom, "Zoom control missing");
            zoom->setCurrentIndex(zoom->count() - 1);
            int scale = 1 << zoom->currentIndex();
            require(qint64(1024) * 257 * scale * scale <= 67108864
                && preview->pixmap().size() == QSize(1024 * scale, 257 * scale),
                "Budget-limited zoom left stale preview coordinates");
        }
        output << "PASS: GRP canvas crop/expand, custom RGB, offset visibility and wheel zoom\n";
        {
            auto &config = IniConfig::instance();
            QScopedValueRollback<QString> restorePath(config.iniPath);
            bool nativeDialogsDisabled = QApplication::testAttribute(Qt::AA_DontUseNativeDialogs);
            QApplication::setAttribute(Qt::AA_DontUseNativeDialogs, true);
            bool valid = true;
            for (bool utf16 : {false, true}) {
                config.iniPath = temporary.filePath(utf16 ? "grp-colors16.ini" : "grp-colors8.ini");
                QStringEncoder encoder(utf16 ? QStringConverter::Utf16LE : QStringConverter::Utf8);
                QByteArray bytes = encoder(QString("; keep\r\n[file]\r\nGRPListBackGround=255\r\nGRPListTextCol=65280\r\nother=value\r\n"));
                bytes.prepend(QByteArray::fromHex(utf16 ? "fffe" : "efbbbf"));
                require(FileIO::writeFileAll(config.iniPath, bytes), "Cannot create GRP color fixture");
                GrpList editor;
                auto containsColor = [](GrpList &list, const QColor &color) {
                    for (auto *label : list.findChildren<QLabel *>())
                        if (label->size() == QSize(60, 18) && label->palette().color(QPalette::Window) == color) return true;
                    return false;
                };
                valid = valid && containsColor(editor, Qt::red) && containsColor(editor, Qt::green);
                auto chooseColor = [](const QColor &color, bool dismissWarning) {
                    QTimer::singleShot(0, [color, dismissWarning] {
                        for (auto *widget : QApplication::topLevelWidgets()) {
                            auto *dialog = qobject_cast<QColorDialog *>(widget);
                            if (!dialog || !dialog->isVisible()) continue;
                            dialog->setCurrentColor(color);
                            if (dismissWarning) QTimer::singleShot(0, [] {
                                for (auto *candidate : QApplication::topLevelWidgets())
                                    if (auto *message = qobject_cast<QMessageBox *>(candidate))
                                        if (message->button(QMessageBox::Ok)) message->button(QMessageBox::Ok)->click();
                            });
                            dialog->accept();
                        }
                    });
                };
                chooseColor(Qt::cyan, false);
                QMetaObject::invokeMethod(&editor, "onBgColorPick", Qt::DirectConnection);
                chooseColor(Qt::magenta, false);
                QMetaObject::invokeMethod(&editor, "onTextColorPick", Qt::DirectConnection);
                GrpList reopened;
                QByteArray saved = FileIO::readFileAll(config.iniPath);
                QStringDecoder decoder(utf16 ? QStringConverter::Utf16LE : QStringConverter::Utf8);
                QString text = decoder(saved);
                valid = valid && containsColor(reopened, Qt::cyan) && containsColor(reopened, Qt::magenta)
                    && saved.startsWith(QByteArray::fromHex(utf16 ? "fffe" : "efbbbf"))
                    && text.contains("; keep\r\n") && text.contains("other=value\r\n");
                {
                    QScopedValueRollback<QString> blocked(config.iniPath, temporary.filePath("absent/colors.ini"));
                    chooseColor(Qt::yellow, true);
                    QMetaObject::invokeMethod(&editor, "onBgColorPick", Qt::DirectConnection);
                    valid = valid && containsColor(editor, Qt::cyan) && !containsColor(editor, Qt::yellow);
                }
            }
            QApplication::setAttribute(Qt::AA_DontUseNativeDialogs, nativeDialogsDisabled);
            require(valid, "GRP colors lost encoding, did not reload or changed after failed save");
            config.iniPath = temporary.filePath("missing-grp-colors.ini");
            GrpList missingConfig;
            require(missingConfig.m_bgColor == QColor(Qt::white) && missingConfig.m_textColor == QColor(Qt::red),
                "Missing GRP configuration did not preserve default colors");
        }
        output << "PASS: GRP color dialogs, UTF8/UTF16 persistence and failed-save preservation\n";
        {
            uint8_t red[256]{}, green[256]{}, blue[256]{};
            red[1] = 255;
            QImage image(2, 2, QImage::Format_ARGB32);
            image.fill(Qt::red);
            GrpPic sprite = GrpIO::encodeRLE(image, red, green, blue);
            sprite.xoff = 5; sprite.yoff = 6;
            QString idx = temporary.filePath("batch-offset.idx"), grp = temporary.filePath("batch-offset.grp");
            require(GrpIO::saveGrp(idx, grp, {sprite, sprite, sprite}), "Cannot create batch offset fixture");
            GrpList editor;
            editor.loadGrpFiles(idx, grp);
            QAction *batch = nullptr;
            for (auto *menu : editor.findChildren<QMenu *>())
                for (auto *action : menu->actions())
                    if (action->text() == QString::fromUtf8("批量偏移")) batch = action;
            require(batch, "Batch offset menu entry missing");
            int prompt = 0;
            QTimer inputs;
            inputs.setInterval(10);
            QObject::connect(&inputs, &QTimer::timeout, &inputs, [&] {
                for (auto *widget : QApplication::topLevelWidgets()) {
                    auto *dialog = qobject_cast<QInputDialog *>(widget);
                    if (!dialog || !dialog->isVisible()) continue;
                    const int values[] = {1, 2, -32768, 32767};
                    if (prompt < 4) { dialog->setIntValue(values[prompt++]); dialog->accept(); }
                }
            });
            inputs.start();
            batch->trigger();
            inputs.stop();
            const auto &pics = editor.grpPics();
            require(prompt == 4 && pics[0].xoff == 5 && pics[0].yoff == 6
                && pics[1].xoff == -32768 && pics[2].yoff == 32767,
                "Batch offsets changed wrong range or clamped boundaries");
            require(editor.savePictures(), "Cannot persist batch offsets");
            QVector<GrpPic> reread;
            require(GrpIO::readGrp(idx, grp, reread) && reread[0].xoff == 5
                && reread[1].xoff == -32768 && reread[2].yoff == 32767, "Batch offsets not saved in RLE headers");
            QTimer::singleShot(0, [] {
                for (auto *widget : QApplication::topLevelWidgets())
                    if (auto *dialog = qobject_cast<QInputDialog *>(widget)) dialog->reject();
            });
            batch->trigger();
            require(editor.grpPics()[0].xoff == 5 && editor.grpPics()[1].xoff == -32768,
                "Cancelling batch offsets changed sprites");
            GrpPic png;
            QBuffer pngBuffer(&png.data);
            pngBuffer.open(QIODevice::WriteOnly);
            require(image.save(&pngBuffer, "PNG"), "Cannot create batch PNG fixture");
            png.width = image.width(); png.height = image.height(); png.size = png.data.size();
            require(GrpIO::saveGrp(idx, grp, {sprite, sprite, png}), "Cannot create mixed batch fixture");
            editor.loadGrpFiles(idx, grp);
            prompt = 0;
            QTimer warnings;
            warnings.setInterval(10);
            QObject::connect(&warnings, &QTimer::timeout, &warnings, [] {
                for (auto *widget : QApplication::topLevelWidgets())
                    if (auto *message = qobject_cast<QMessageBox *>(widget))
                        if (message->isVisible() && message->button(QMessageBox::Ok)) message->button(QMessageBox::Ok)->click();
            });
            inputs.start(); warnings.start();
            batch->trigger();
            inputs.stop(); warnings.stop();
            require(prompt == 4 && editor.grpPics()[1].xoff == 5 && editor.grpPics()[1].yoff == 6
                && editor.grpPics()[2].data == png.data, "Mixed PNG batch offset partially modified sprites");
        }
        output << "PASS: GRP batch offset menu, range isolation, int16 save and cancellation\n";
        {
            QString idx = temporary.filePath("grp-session.idx"), grp = temporary.filePath("grp-session.grp");
            require(GrpIO::saveGrp(idx, grp, {GrpPic()}), "Cannot create GRP session fixture");
            GrpList editor;
            editor.loadGrpFiles(idx, grp);
            editor.m_nowPic = 0;
            editor.onInsertBefore();
            QByteArray dirty = editor.stateBytes();
            editor.m_palette = QVector<QRgb>(256, qRgb(255, 0, 0));
            QString palettePath = temporary.filePath("grp-session.col");
            require(FileIO::writeFileAll(palettePath, QByteArray(768, '\0')),
                "Cannot create GRP session palette");
            auto answer = [](QMessageBox::StandardButton choice) {
                QTimer::singleShot(0, [choice] {
                    for (auto *widget : QApplication::topLevelWidgets())
                        if (auto *message = qobject_cast<QMessageBox *>(widget); message && message->isVisible())
                            if (auto *button = message->button(choice)) button->click();
                });
            };
            answer(QMessageBox::Cancel);
            editor.loadGrpFiles(idx, grp, palettePath);
            require(editor.stateBytes() == dirty && editor.m_palette[0] == qRgb(255, 0, 0),
                "Cancelled GRP reload discarded changes or palette");
            require(FileIO::writeFileAll(palettePath, QByteArray(767, '\0')),
                "Cannot truncate GRP session palette");
            editor.loadPalette(palettePath);
            require(editor.m_palette[0] == qRgb(255, 0, 0), "Short COL replaced active GRP palette");
            editor.show();
            answer(QMessageBox::Cancel);
            require(!editor.close() && editor.isVisible() && editor.stateBytes() == dirty,
                "Cancelled GRP close discarded changes");
            QString otherIdx = temporary.filePath("unloaded-grp.idx");
            editor.m_idxEdit->setText(otherIdx);
            editor.m_grpEdit->setText(temporary.filePath("unloaded-grp.grp"));
            answer(QMessageBox::Save);
            require(editor.confirmDiscard() && editor.m_savedState == editor.stateBytes()
                && !QFileInfo::exists(otherIdx), "GRP save changed target or failed to clean session");
            QVector<GrpPic> saved;
            require(GrpIO::readGrp(idx, grp, saved) && saved.size() == 2,
                "GRP session edits not saved to original target");
            bool nativeDialogsDisabled = QApplication::testAttribute(Qt::AA_DontUseNativeDialogs);
            QApplication::setAttribute(Qt::AA_DontUseNativeDialogs, true);
            QImage replacement(3, 2, QImage::Format_ARGB32);
            replacement.fill(Qt::cyan);
            QString replacementPath = temporary.filePath("grp-replacement.png");
            require(replacement.save(replacementPath), "Cannot create GRP replacement");
            editor.m_nowPic = 1;
            QTimer::singleShot(0, [replacementPath] {
                for (auto *widget : QApplication::topLevelWidgets())
                    if (auto *dialog = qobject_cast<QFileDialog *>(widget); dialog && dialog->isVisible()) {
                        dialog->selectFile(replacementPath);
                        QMetaObject::invokeMethod(dialog, "accept", Qt::DirectConnection);
                    }
            });
            editor.onReplacePNG();
            QApplication::setAttribute(Qt::AA_DontUseNativeDialogs, nativeDialogsDisabled);
            QByteArray replaced = editor.m_grpPics[1].data;
            require(editor.m_grpPics[0].data.isEmpty() && QImage::fromData(replaced, "PNG").size() == QSize(3, 2),
                "GRP replacement modified wrong slot");
            editor.onInsertBefore();
            require(editor.m_grpPics.size() == 3 && editor.m_grpPics[1].data.isEmpty()
                && editor.m_grpPics[2].data == replaced, "GRP insertion changed sprite order");
            editor.m_nowPic = 1;
            editor.onDeleteCurrent();
            require(editor.m_grpPics.size() == 2 && editor.m_grpPics[1].data == replaced,
                "GRP deletion changed following sprite");
            auto *originalClipboard = new QMimeData;
            const auto *clipboard = QApplication::clipboard()->mimeData();
            if (clipboard) for (const auto &format : clipboard->formats())
                originalClipboard->setData(format, clipboard->data(format));
            editor.m_nowPic = 1;
            editor.onCopyCurrent();
            GrpList receiver;
            receiver.m_grpPics = {GrpPic()};
            receiver.m_nowPic = 0;
            receiver.onPasteCurrent();
            require(receiver.m_grpPics[0].data == replaced && receiver.m_grpPics[0].width == 3,
                "GRP raw clipboard changed PNG bytes across windows");
            auto *invalidClipboard = new QMimeData;
            invalidClipboard->setData("application/x-upedit-grp-record", QByteArray("truncated"));
            QApplication::clipboard()->setMimeData(invalidClipboard);
            receiver.onPasteCurrent();
            require(receiver.m_grpPics[0].data == replaced, "Invalid GRP clipboard changed destination");
            QApplication::clipboard()->setMimeData(originalClipboard);
            editor.onAppend();
            require(editor.m_grpPics.size() == 3 && editor.m_grpPics.last().data.isEmpty()
                && editor.m_grpPics[1].data == replaced, "GRP append changed existing records");
            editor.m_nowPic = 1;
            editor.m_palette.fill(qRgb(0, 255, 255), 256);
            QApplication::setAttribute(Qt::AA_DontUseNativeDialogs, true);
            QTimer::singleShot(0, [replacementPath] {
                for (auto *widget : QApplication::topLevelWidgets())
                    if (auto *dialog = qobject_cast<QFileDialog *>(widget); dialog && dialog->isVisible()) {
                        dialog->selectFile(replacementPath);
                        QMetaObject::invokeMethod(dialog, "accept", Qt::DirectConnection);
                    }
            });
            editor.replacePNG(true);
            QApplication::setAttribute(Qt::AA_DontUseNativeDialogs, nativeDialogsDisabled);
            uint8_t red[256]{}, green[256], blue[256];
            std::fill_n(green, 256, uint8_t(255));
            std::fill_n(blue, 256, uint8_t(255));
            QImage encoded = GrpIO::decodeRLE(editor.m_grpPics[1], red, green, blue);
            require(!GrpIO::isPNG(editor.m_grpPics[1]) && encoded.size() == QSize(3, 2)
                && encoded.pixelColor(1, 1) == QColor(Qt::cyan), "GRP PNG-to-RLE replacement failed");
            require(editor.savePictures(), "Cannot save GRP replacement workflow");
            QVector<GrpPic> persisted;
            require(GrpIO::readGrp(idx, grp, persisted) && persisted.size() == 3
                && persisted[1].data == editor.m_grpPics[1].data && persisted[2].data.isEmpty(),
                "GRP appended and converted records did not survive reload");
            editor.close();
        }
        output << "PASS: GRP unsaved reload/close cancellation and original-target save\n";
        {
            auto &config = IniConfig::instance();
            QScopedValueRollback<QVector<GRPListSection>> sections(config.grpListSection);
            config.grpListSection.resize(1);
            auto &section = config.grpListSection[0];
            section.num = 3;
            section.tag = {"outside", "negative"};
            section.beginNum = {999, -10};
            section.endNum = {1000, 2};
            GrpList editor;
            editor.m_grpPics.resize(25);
            if (editor.m_presetCombo->count() == 0) {
                QSignalBlocker blocker(editor.m_presetCombo);
                editor.m_presetCombo->addItem("fixture");
            }
            {
                QSignalBlocker blocker(editor.m_presetCombo);
                editor.m_presetCombo->setCurrentIndex(0);
            }
            editor.updateSectionCombo();
            require(editor.m_sectionCombo->count() == 3, "Incomplete GRP section was exposed");
            editor.onSectionChanged(1);
            require(editor.m_beginPic == 24 && editor.m_endPic == 24, "Oversized GRP section not clipped");
            editor.onSectionChanged(2);
            require(editor.m_beginPic == 0 && editor.m_endPic == 2, "Negative GRP section not clipped");
            editor.onSectionChanged(0);
            editor.m_imageLabel->setFixedSize(1003, 250);
            editor.m_nowPic = 3;
            QPoint margin = editor.m_imageLabel->mapTo(&editor, QPoint(1002, 20));
            QMouseEvent event(QEvent::MouseButtonPress, QPointF(margin), QPointF(margin),
                Qt::LeftButton, Qt::LeftButton, Qt::NoModifier);
            QCoreApplication::sendEvent(&editor, &event);
            require(editor.m_nowPic == 3, "GRP right margin selected next row sprite");
            editor.onContextMenu(QPoint(1002, 20));
            require(editor.m_nowPic == 3, "GRP margin context menu changed selection");
            editor.onScroll(1);
            QPoint scrolled = editor.m_imageLabel->mapTo(&editor, QPoint(150, 20));
            QMouseEvent scrolledClick(QEvent::MouseButtonPress, QPointF(scrolled), QPointF(scrolled),
                Qt::LeftButton, Qt::LeftButton, Qt::NoModifier);
            QCoreApplication::sendEvent(&editor, &scrolledClick);
            require(editor.m_nowPic == 11, "GRP scrolled click selected wrong sprite");
        }
        output << "PASS: GRP section clipping, incomplete sections and right-margin hit testing\n";
        {
            QImage image(2, 3, QImage::Format_ARGB32);
            image.fill(Qt::cyan);
            QByteArray png;
            QBuffer buffer(&png);
            buffer.open(QIODevice::WriteOnly);
            require(image.save(&buffer, "PNG"), "Cannot create PIC metadata image");
            QString path = temporary.filePath("pic-metadata.pic");
            require(FileIO::writeFileAll(path, PicEdit::encodeFile({{12, 34, 0x12345678, png}})),
                "Cannot create PIC metadata fixture");
            PicEdit editor;
            editor.openFile(path);
            editor.m_xoffSpin->setValue(INT_MIN);
            editor.m_yoffSpin->setValue(INT_MAX);
            require(editor.m_pics[0].background == 0x12345678 && editor.m_pics[0].xoff == INT_MIN
                && editor.m_pics[0].yoff == INT_MAX && editor.m_pics[0].data == png,
                "PIC offset controls changed unrelated background metadata or image bytes");
            QVector<PicEdit::PicData> decoded;
            require(PicEdit::decodeFile(PicEdit::encodeFile(editor.m_pics), decoded)
                && decoded[0].background == 0x12345678 && decoded[0].xoff == INT_MIN && decoded[0].yoff == INT_MAX,
                "PIC metadata UI did not survive serialization");
            editor.m_backgroundCheck->setChecked(true);
            require(editor.m_pics[0].background == 1, "PIC explicit background checkbox did not update metadata");
            editor.m_backgroundCheck->setChecked(false);
            require(editor.m_pics[0].background == 0, "PIC explicit background clear did not update metadata");
        }
        output << "PASS: PIC offset UI int32 boundaries and unknown background preservation\n";
        {
            PicEdit editor;
            QImage image(3, 2, QImage::Format_ARGB32);
            image.fill(Qt::green);
            QByteArray png;
            QBuffer buffer(&png); buffer.open(QIODevice::WriteOnly);
            require(image.save(&buffer, "PNG"), "Cannot create PIC editing fixture");
            editor.m_pics = {{11, 22, 9, png}, {33, 44, 1, png}, {55, 66, 0, png}};
            editor.m_currentIndex = 0;
            editor.displayCurrent(); editor.drawThumbnails();
            QMouseEvent click(QEvent::MouseButtonPress, QPointF(55, 10), QPointF(55, 10),
                Qt::LeftButton, Qt::LeftButton, Qt::NoModifier);
            QCoreApplication::sendEvent(editor.m_thumbLabel, &click);
            require(editor.m_currentIndex == 1 && editor.m_xoffSpin->value() == 33
                && editor.m_pics[0].background == 9, "PIC thumbnail selection changed another record");
            auto *clipboard = QApplication::clipboard();
            auto *original = new QMimeData;
            if (const auto *mime = clipboard->mimeData())
                for (const auto &format : mime->formats()) original->setData(format, mime->data(format));
            image.fill(Qt::cyan);
            clipboard->setImage(image);
            editor.onPaste();
            clipboard->setMimeData(original);
            require(editor.m_pics[1].xoff == 0 && editor.m_pics[1].yoff == 0 && editor.m_pics[1].background == 0
                && QImage::fromData(editor.m_pics[1].data) == image && editor.m_pics[0].xoff == 11,
                "PIC paste did not reset metadata or changed another record");
            editor.onDelete();
            require(editor.m_pics.size() == 2 && editor.m_currentIndex == 1 && editor.m_pics[1].xoff == 55,
                "PIC middle deletion selected wrong remaining record");
            editor.onDelete(); editor.onDelete();
            require(editor.m_pics.isEmpty() && editor.m_currentIndex == -1, "PIC deletion to empty retained stale record");
        }
        output << "PASS: PIC thumbnail selection, paste metadata reset and deletion to empty\n";
        {
            QImage image(4, 2, QImage::Format_ARGB32);
            image.fill(Qt::red);
            image.setPixelColor(1, 0, Qt::green);
            QString path = temporary.filePath("png-import-ui.png");
            require(image.save(path), "Cannot create PNG import UI fixture");
            PNGImport editor;
            PNGImport::PNGEntry entry;
            entry.fileName = path;
            editor.m_entries = {entry, entry};
            editor.m_fileList->addItems({"first", "second"});
            editor.m_fileList->setCurrentRow(0);
            bool optionsRestored = false;
            auto editOptions = [&](bool acceptChanges) {
                QTimer::singleShot(0, [&, acceptChanges] {
                    for (auto *widget : QApplication::topLevelWidgets()) {
                        auto *dialog = qobject_cast<PNGImportModify *>(widget);
                        if (!dialog || !dialog->isVisible()) continue;
                        optionsRestored = dialog->xOffset() == 0 && dialog->yOffset() == 0 && !dialog->keepPNG();
                        dialog->setOptions(-32768, 32767, false, true, Qt::green);
                        for (auto *check : dialog->findChildren<QCheckBox *>())
                            if (check->text() == QString::fromUtf8("应用到全部")) check->setChecked(true);
                        if (acceptChanges) dialog->accept(); else dialog->reject();
                    }
                });
                editor.onModifyEntry();
            };
            editOptions(false);
            require(optionsRestored && editor.m_entries[0].xOff == 0 && !editor.m_entries[1].transparent,
                "Cancelled PNG settings changed entries");
            editOptions(true);
            require(optionsRestored && editor.m_entries[0].xOff == -32768 && editor.m_entries[1].yOff == 32767
                && editor.m_entries[1].transparent && editor.m_entries[1].transColor == QColor(Qt::green).rgb(),
                "PNG apply-all settings did not preserve full offset range or transparency");
            PNGImportModify positioning(image);
            QLabel *preview = nullptr;
            for (auto *label : positioning.findChildren<QLabel *>())
                if (label->size() == QSize(400, 400)) preview = label;
            require(preview, "PNG offset preview missing");
            QMouseEvent click(QEvent::MouseButtonPress, QPointF(200, 105), QPointF(200, 105),
                Qt::LeftButton, Qt::LeftButton, Qt::NoModifier);
            QCoreApplication::sendEvent(preview, &click);
            require(positioning.xOffset() == 2 && positioning.yOffset() == 1, "PNG preview click mapped wrong source coordinates");
            editor.m_palette.resize(256, qRgb(0, 0, 0));
            editor.m_palette[1] = qRgb(255, 0, 0); editor.m_palette[2] = qRgb(0, 255, 0);
            QString idx = temporary.filePath("png-ui.idx"), grp = temporary.filePath("png-ui.grp");
            editor.m_idxEdit->setText(idx); editor.m_grpEdit->setText(grp);
            editor.m_entries[1].keepPNG = true;
            editor.m_entries[1].xOff = editor.m_entries[1].yOff = 0;
            QTimer messages;
            messages.setInterval(10);
            QObject::connect(&messages, &QTimer::timeout, &messages, [] {
                for (auto *widget : QApplication::topLevelWidgets())
                    if (auto *message = qobject_cast<QMessageBox *>(widget))
                        if (message->isVisible() && message->button(QMessageBox::Ok)) message->button(QMessageBox::Ok)->click();
            });
            messages.start(); editor.onStartImport(); messages.stop();
            QVector<GrpPic> imported;
            require(GrpIO::readGrp(idx, grp, imported) && imported.size() == 2
                && !GrpIO::isPNG(imported[0]) && GrpIO::isPNG(imported[1])
                && imported[0].xoff == -32768 && imported[0].yoff == 32767,
                "PNG import output did not preserve format choices or offsets");
            uint8_t red[256]{}, green[256]{}, blue[256]{};
            red[1] = 255; green[2] = 255;
            QImage rle = GrpIO::decodeRLE(imported[0], red, green, blue);
            QImage png = GrpIO::decodePNG(imported[1]);
            require(rle.pixelColor(1, 0).alpha() == 0 && png.pixelColor(1, 0).alpha() == 0
                && rle.pixelColor(0, 0) == QColor(Qt::red) && png.pixelColor(0, 0) == QColor(Qt::red),
                "PNG transparent color conversion changed unrelated pixels");
            QByteArray indexBefore = FileIO::readFileAll(idx), dataBefore = FileIO::readFileAll(grp);
            editor.m_entries[1].xOff = 1;
            messages.start(); editor.onStartImport(); messages.stop();
            require(FileIO::readFileAll(idx) == indexBefore && FileIO::readFileAll(grp) == dataBefore,
                "Failed PNG offset import partially appended earlier entries");
            editor.m_entries[1].keepPNG = false;
            editor.m_entries[1].xOff = 32768;
            messages.start(); editor.onStartImport(); messages.stop();
            require(FileIO::readFileAll(idx) == indexBefore && FileIO::readFileAll(grp) == dataBefore,
                "Out-of-range PNG import offset changed files");
            editor.m_entries.clear();
            QString emptyIndex = temporary.filePath("empty-import.idx");
            editor.m_idxEdit->setText(emptyIndex);
            editor.m_grpEdit->setText(temporary.filePath("empty-import.grp"));
            editor.onStartImport();
            require(!QFileInfo::exists(emptyIndex), "Empty PNG import created an output group");
        }
        output << "PASS: PNG settings cancel/apply-all, preview coordinates, formats and atomic import rejection\n";
        {
            PNGImport importer;
            QString palettePath = temporary.filePath("validated-palette.col");
            QByteArray paletteBytes(768, '\0');
            paletteBytes[0] = 63;
            paletteBytes[767] = 32;
            require(FileIO::writeFileAll(palettePath, paletteBytes) && importer.loadPalette(palettePath),
                "Complete COL palette failed to load");
            const auto previousPalette = importer.m_palette;
            require(previousPalette.size() == 256 && previousPalette[0] == qRgb(252, 0, 0)
                && previousPalette[255] == qRgb(0, 0, 128), "COL channels decoded incorrectly");
            require(FileIO::writeFileAll(palettePath, paletteBytes.left(767)), "Cannot truncate test palette");
            require(!importer.loadPalette(palettePath) && importer.m_palette == previousPalette,
                "Truncated COL replaced the active palette");
            require(!importer.loadPalette(temporary.filePath("missing-palette.col"))
                && importer.m_palette == previousPalette, "Missing COL replaced the active palette");
        }
        output << "PASS: COL complete palette decoding and failed-load state preservation\n";
        {
            QString directory = temporary.filePath("png-export-atomic");
            QScopedValueRollback<QString> restoreIndexName(IniConfig::instance().imzIndexFileName, "index.ka");
            require(QDir().mkpath(directory), "Cannot create atomic PNG export directory");
            QString first = QDir(directory).filePath("0.png");
            QString second = QDir(directory).filePath("1.png");
            QString index = QDir(directory).filePath("index.ka");
            require(FileIO::writeFileAll(first, "previous image") && FileIO::writeFileAll(index, "previous index"),
                "Cannot create previous export files");
            QImage image(3, 2, QImage::Format_ARGB32);
            image.fill(Qt::cyan);
            GrpPic png;
            QBuffer buffer(&png.data); buffer.open(QIODevice::WriteOnly);
            require(image.save(&buffer, "PNG"), "Cannot create atomic export PNG");
            png.width = image.width(); png.height = image.height(); png.size = png.data.size();
            PNGExport exporter;
            exporter.m_pathEdit->setText(directory);
            exporter.m_pics = {png, png};
            auto unchanged = [&] {
                return FileIO::readFileAll(first) == "previous image"
                    && FileIO::readFileAll(index) == "previous index" && !QFile::exists(second);
            };
            QTimer::singleShot(0, [&] { exporter.onStop(); });
            exporter.onStart();
            require(unchanged() && !exporter.m_running, "Stopped PNG export modified target files");
            QTimer::singleShot(0, [&] {
                exporter.onStop();
                exporter.onStart();
                exporter.startExport({}, {});
            });
            exporter.onStart();
            require(unchanged() && !exporter.m_running && !exporter.m_exporting && exporter.m_pics.size() == 2,
                "Stopped PNG export reentered or replaced its active input");
            exporter.show();
            QTimer::singleShot(0, [&] { exporter.close(); });
            exporter.onStart();
            require(unchanged() && !exporter.m_running, "Closing PNG exporter committed partial files");
            exporter.m_pics[1].data = "invalid";
            exporter.onStart();
            require(unchanged(), "Invalid later PNG export modified earlier files");
            exporter.m_pics = {png, png};
            require(QDir().mkpath(second), "Cannot create blocked export target");
            exporter.onStart();
            require(FileIO::readFileAll(first) == "previous image" && FileIO::readFileAll(index) == "previous index"
                && QFileInfo(second).isDir(), "Failed PNG export transaction changed existing files");
            require(QDir().rmdir(second), "Cannot remove blocked export target");
            exporter.onStart();
            require(FileIO::readFileAll(first) == png.data && FileIO::readFileAll(second) == png.data
                && FileIO::readFileAll(index) == QByteArray(8, '\0') && !exporter.m_running,
                "Successful atomic PNG export changed image or index bytes");
            exporter.m_pics = {png, GrpPic(), png};
            exporter.onStart();
            require(FileIO::readFileAll(first) == png.data
                && FileIO::readFileAll(QDir(directory).filePath("2.png")) == png.data
                && FileIO::readFileAll(index) == QByteArray(12, '\0'),
                "Empty GRP slot rejected export or shifted later sprite IDs");
            IniConfig::instance().imzIndexFileName = "offsets.bin";
            exporter.onStart();
            require(FileIO::readFileAll(QDir(directory).filePath("offsets.bin")) == QByteArray(12, '\0'),
                "Configured PNG export index filename was ignored");
            IniConfig::instance().imzIndexFileName = "../escaped.ka";
            exporter.onStart();
            require(!QFile::exists(temporary.filePath("escaped.ka")) && !exporter.m_running,
                "PNG export index escaped its output directory");
            IniConfig::instance().imzIndexFileName = "index.ka";
            uint8_t red[256]{}, green[256]{}, blue[256]{};
            red[1] = 255;
            QImage rleImage(3, 2, QImage::Format_ARGB32);
            rleImage.fill(Qt::transparent);
            rleImage.setPixelColor(1, 1, Qt::red);
            GrpPic rle = GrpIO::encodeRLE(rleImage, red, green, blue);
            rle.xoff = -32768; rle.yoff = 32767;
            exporter.m_pics = {rle};
            QByteArray oldIndex = FileIO::readFileAll(index);
            exporter.onStart();
            require(FileIO::readFileAll(first) == png.data && FileIO::readFileAll(index) == oldIndex,
                "RLE export without a palette silently wrote incorrect colors");
            exporter.m_palette = QVector<QRgb>(256, qRgb(0, 0, 0));
            exporter.m_palette[1] = qRgb(255, 0, 0);
            exporter.onStart();
            require(QImage(first).convertToFormat(QImage::Format_ARGB32) == rleImage
                && FileIO::readFileAll(index) == QByteArray::fromHex("0080ff7f"),
                "RLE PNG export changed palette pixels, transparency or signed offsets");
        }
        output << "PASS: PNG export stop/close, invalid input, transaction rollback and complete output\n";
        {
            bool nativeDialogsDisabled = QApplication::testAttribute(Qt::AA_DontUseNativeDialogs);
            QApplication::setAttribute(Qt::AA_DontUseNativeDialogs, true);
            QString pngPath = temporary.filePath("pic-insert.png");
            QString bmpPath = temporary.filePath("pic-append.bmp");
            QString directory = temporary.filePath("pic-export");
            QImage image(3, 2, QImage::Format_ARGB32);
            image.fill(Qt::cyan);
            require(image.save(pngPath) && image.save(bmpPath) && QDir().mkpath(directory),
                "Cannot create PIC import/export fixtures");
            auto chooseFile = [](const QString &path) {
                QTimer::singleShot(0, [path] {
                    for (auto *widget : QApplication::topLevelWidgets()) {
                        auto *dialog = qobject_cast<QFileDialog *>(widget);
                        if (!dialog || !dialog->isVisible()) continue;
                        dialog->selectFile(path);
                        QMetaObject::invokeMethod(dialog, "accept", Qt::DirectConnection);
                    }
                });
            };
            PicEdit editor;
            editor.m_pics = {{5, -6, 7, FileIO::readFileAll(pngPath)}};
            editor.displayCurrent();
            chooseFile(pngPath);
            editor.insertImage(false);
            bool valid = editor.m_pics.size() == 2 && editor.m_currentIndex == 0
                && editor.m_pics[0].data == FileIO::readFileAll(pngPath) && editor.m_pics[1].xoff == 5;
            require(valid, "PIC insertion changed ordering or original metadata");
            chooseFile(bmpPath);
            editor.insertImage(true);
            valid = valid && editor.m_pics.size() == 3 && editor.m_currentIndex == 2
                && editor.m_pics[2].data.startsWith(QByteArray::fromHex("89504e470d0a1a0a"))
                && QImage::fromData(editor.m_pics[2].data).convertToFormat(QImage::Format_ARGB32) == image;
            require(valid, "PIC BMP append conversion changed pixels or ordering");
            chooseFile(directory);
            QTimer warnings;
            warnings.setInterval(10);
            QObject::connect(&warnings, &QTimer::timeout, &warnings, [] {
                for (auto *widget : QApplication::topLevelWidgets())
                    if (auto *message = qobject_cast<QMessageBox *>(widget))
                        if (message->isVisible() && message->button(QMessageBox::Ok)) message->button(QMessageBox::Ok)->click();
            });
            warnings.start();
            editor.onExportAll();
            warnings.stop();
            QByteArray metadata = FileIO::readFileAll(QDir(directory).filePath("index.ka"));
            valid = valid && metadata.size() == 12
                && qFromLittleEndian<qint16>(metadata.constData() + 4) == 5
                && qFromLittleEndian<qint16>(metadata.constData() + 6) == -6;
            for (int index = 0; index < editor.m_pics.size(); ++index)
                valid = valid && FileIO::readFileAll(QDir(directory).filePath(QString::number(index) + ".png")) == editor.m_pics[index].data;
            QApplication::setAttribute(Qt::AA_DontUseNativeDialogs, nativeDialogsDisabled);
            require(valid, "PIC insert/append/export changed ordering, image bytes or index metadata");
        }
        output << "PASS: PIC insert/append file dialogs, BMP conversion and complete export metadata\n";
        {
            QString first = temporary.filePath("pic-session.pic");
            QString second = temporary.filePath("pic-session-other.pic");
            QString broken = temporary.filePath("pic-session-broken.pic");
            require(FileIO::writeFileAll(first, PicEdit::encodeFile({{1, 2, 3, "original"}}))
                && FileIO::writeFileAll(second, PicEdit::encodeFile({{4, 5, 6, "other"}}))
                && FileIO::writeFileAll(broken, "bad"), "Cannot create PIC session fixtures");
            PicEdit editor;
            editor.openFile(first);
            require(editor.confirmDiscard(), "Unchanged PIC prompted");
            editor.m_xoffSpin->setValue(99);
            QByteArray dirty = editor.stateBytes();
            auto answer = [](QMessageBox::StandardButton button) {
                QTimer::singleShot(0, [button] {
                    for (auto *widget : QApplication::topLevelWidgets())
                        if (auto *message = qobject_cast<QMessageBox *>(widget))
                            if (message->isVisible() && message->button(button)) message->button(button)->click();
                });
            };
            answer(QMessageBox::Cancel);
            editor.openFile(second);
            require(editor.stateBytes() == dirty && editor.m_filePath == first,
                "Cancelling PIC switch changed session or save path");
            QTimer warnings;
            warnings.setInterval(10);
            QObject::connect(&warnings, &QTimer::timeout, &warnings, [] {
                for (auto *widget : QApplication::topLevelWidgets())
                    if (auto *message = qobject_cast<QMessageBox *>(widget))
                        if (message->isVisible() && message->button(QMessageBox::Ok)) message->button(QMessageBox::Ok)->click();
            });
            answer(QMessageBox::Discard);
            warnings.start();
            editor.openFile(broken);
            warnings.stop();
            require(editor.stateBytes() == dirty && editor.m_filePath == first,
                "Broken PIC load destroyed working data or path");
            answer(QMessageBox::Cancel);
            QCloseEvent close;
            QCoreApplication::sendEvent(&editor, &close);
            require(!close.isAccepted() && editor.stateBytes() == dirty, "PIC close cancellation lost changes");
            bool nativeDialogsDisabled = QApplication::testAttribute(Qt::AA_DontUseNativeDialogs);
            QApplication::setAttribute(Qt::AA_DontUseNativeDialogs, true);
            QTimer fileDialogs;
            fileDialogs.setInterval(10);
            bool cancelSave = true;
            QString savedPath = temporary.filePath("pic-session-saved.pic");
            QObject::connect(&fileDialogs, &QTimer::timeout, &fileDialogs, [&] {
                for (auto *widget : QApplication::topLevelWidgets()) {
                    auto *dialog = qobject_cast<QFileDialog *>(widget);
                    if (!dialog || !dialog->isVisible()) continue;
                    if (cancelSave) dialog->reject();
                    else {
                        dialog->selectFile(savedPath);
                        QMetaObject::invokeMethod(dialog, "accept", Qt::DirectConnection);
                    }
                }
            });
            answer(QMessageBox::Save);
            fileDialogs.start();
            editor.openFile(second);
            fileDialogs.stop();
            bool cancelledSavePreserved = editor.stateBytes() == dirty && editor.m_filePath == first;
            cancelSave = false;
            answer(QMessageBox::Save);
            fileDialogs.start(); warnings.start();
            editor.openFile(second);
            fileDialogs.stop(); warnings.stop();
            QApplication::setAttribute(Qt::AA_DontUseNativeDialogs, nativeDialogsDisabled);
            require(cancelledSavePreserved && FileIO::readFileAll(savedPath) == dirty
                && editor.m_filePath == second && editor.confirmDiscard(),
                "PIC save cancellation or save-before-switch lost session data");
            editor.m_xoffSpin->setValue(100);
            answer(QMessageBox::Discard);
            editor.openFile(second);
            require(editor.m_filePath == second && editor.m_pics[0].xoff == 4 && editor.confirmDiscard(),
                "PIC discard did not load new clean session");
        }
        output << "PASS: PIC unsaved switch/close cancellation and corrupt-load session preservation\n";
        {
            auto &config = IniConfig::instance();
            QScopedValueRollback<QString> pathGuard(config.gamePath, temporary.path());
            QScopedValueRollback<QString> dataGuard(config.talkGrp, "plain-talk.txt");
            QString path = temporary.filePath(config.talkGrp);
            require(FileIO::writeFileAll(path, "first\r\nsecond\r\n"), "Cannot create plain Talk fixture");
            KDEFEdit editor;
            bool edited = false;
            QTimer::singleShot(0, [&] {
                for (auto *widget : QApplication::topLevelWidgets()) {
                    auto *dialog = qobject_cast<QDialog *>(widget);
                    if (!dialog || !dialog->isVisible()) continue;
                    auto *text = dialog->findChild<QTextEdit *>();
                    auto *buttons = dialog->findChild<QDialogButtonBox *>();
                    if (!text || !buttons) continue;
                    text->setPlainText("changed");
                    edited = true;
                    buttons->button(QDialogButtonBox::Save)->click();
                }
            });
            editor.editTalks();
            require(edited && FileIO::readFileAll(path) == "changed\r\nsecond\r\n",
                "Plain Talk UI changed line numbering or CRLF");
            output << "PASS: UTF8 line-based Talk UI save preserves line numbering and CRLF\n";
        }
        {
            auto &config = IniConfig::instance();
            QScopedValueRollback<QString> restorePath(config.gamePath, temporary.path());
            QScopedValueRollback<QString> restoreIdx(config.talkIdx, "talk-ui.idx");
            QScopedValueRollback<QString> restoreGrp(config.talkGrp, "talk-ui.grp");
            QScopedValueRollback<int> restoreCode(config.talkCode);
            QScopedValueRollback<int> restoreInvert(config.talkInvert);
            QScopedValueRollback<QString> restoreIni(config.iniPath, temporary.filePath("talk-arrange.ini"));
            require(FileIO::writeFileAll(config.iniPath, QByteArray("; keep\r\n[KDEF]\r\ntalkarrange=1\r\n[other]\r\nvalue=7\r\n")),
                "Cannot create talk arrange configuration");
            QString indexPath = temporary.filePath(config.talkIdx), dataPath = temporary.filePath(config.talkGrp);
            for (int code : {0, 1, 2, 3}) for (int invert : {0, 1}) {
                config.talkCode = code; config.talkInvert = invert;
                auto encode = [&](const QString &text) {
                    QByteArray bytes(Encoding::encodedByteLengthWithCode(text, code) + (code == 2 ? 2 : 1), '\0');
                    Encoding::writeInStrWithCode(text, bytes.data(), bytes.size(), code);
                    if (invert == 0) for (char &value : bytes) {
                        value = char(quint8(value) ^ 0xff); if (quint8(value) == 0xff) value = 0;
                    }
                    return bytes;
                };
                QVector<QByteArray> original{encode("first"), encode("second"), QByteArray()};
                original[1].append("opaque trailing bytes");
                QByteArray index, data;
                require(KDEFEdit::encodeRecords(original, index, data)
                    && FileIO::writeFiles({{indexPath, index}, {dataPath, data}}), "Cannot prepare talk UI records");
                KDEFEdit editor;
                bool operated = false;
                auto operate = [&](bool save) {
                    QTimer::singleShot(0, [&editor, &operated, save] {
                        auto *dialog = editor.findChild<QDialog *>();
                        if (!dialog || !dialog->isVisible()) return;
                        auto *list = dialog->findChild<QListWidget *>();
                        auto *text = dialog->findChild<QTextEdit *>();
                        auto *buttons = dialog->findChild<QDialogButtonBox *>();
                        if (!list || !text || !buttons || list->count() != 3) { dialog->reject(); return; }
                        text->setPlainText(QString::fromUtf8("edited\n\xe4\xb8\xad\xe6\x96\x87"));
                        list->setCurrentRow(1);
                        list->setCurrentRow(0);
                        operated = text->toPlainText() == QString::fromUtf8("edited\n\xe4\xb8\xad\xe6\x96\x87");
                        QPushButton *add = nullptr, *remove = nullptr;
                        for (auto *button : dialog->findChildren<QPushButton *>()) {
                            if (button->text() == QString::fromUtf8("\xe8\xbf\xbd\xe5\x8a\xa0\xe5\xaf\xb9\xe8\xaf\x9d")) add = button;
                            if (button->text() == QString::fromUtf8("\xe5\x88\xa0\xe9\x99\xa4\xe6\x9c\xab\xe5\xb0\xbe\xe5\xaf\xb9\xe8\xaf\x9d")) remove = button;
                        }
                        if (!add || !remove) { operated = false; dialog->reject(); return; }
                        add->click();
                        operated = operated && list->count() == 4 && list->currentRow() == 3 && text->toPlainText().isEmpty();
                        text->setPlainText("temporary appended talk");
                        QTimer::singleShot(0, [] {
                            for (auto *widget : QApplication::topLevelWidgets())
                                if (auto *message = qobject_cast<QMessageBox *>(widget); message && message->isVisible())
                                    if (auto *yes = message->button(QMessageBox::Yes)) yes->click();
                        });
                        remove->click();
                        operated = operated && list->count() == 3;
                        list->setCurrentRow(0);
                        operated = operated && text->toPlainText() == QString::fromUtf8("edited\n\xe4\xb8\xad\xe6\x96\x87");
                        buttons->button(save ? QDialogButtonBox::Save : QDialogButtonBox::Cancel)->click();
                    });
                    editor.editTalks();
                };
                operate(false);
                require(operated && FileIO::readFileAll(indexPath) == index && FileIO::readFileAll(dataPath) == data,
                    "Cancelled talk dialog changed files or lost row edits");
                operated = false;
                operate(true);
                QVector<QByteArray> saved;
                require(operated && KDEFEdit::decodeRecords(FileIO::readFileAll(indexPath), FileIO::readFileAll(dataPath), saved)
                    && saved.size() == 3 && saved[0] == encode(QString::fromUtf8("edited\n\xe4\xb8\xad\xe6\x96\x87"))
                    && saved[1] == original[1] && saved[2].isEmpty(), "Talk UI encoding, inversion or untouched record bytes changed");
            }
            {
                QScopedValueRollback<QString> restoreNameIdx(config.nameIdx, "name-ui.idx");
                QScopedValueRollback<QString> restoreNameGrp(config.nameGrp, "name-ui.grp");
                QScopedValueRollback<int> nameCode(config.talkCode, 3);
                QScopedValueRollback<int> nameInvert(config.talkInvert, 1);
                QString nameIndex = temporary.filePath(config.nameIdx), nameData = temporary.filePath(config.nameGrp);
                QByteArray index, data;
                require(KDEFEdit::encodeRecords({QByteArray("original\0", 9)}, index, data)
                    && FileIO::writeFiles({{nameIndex, index}, {nameData, data}}), "Cannot prepare name records");
                QByteArray talkBefore = FileIO::readFileAll(dataPath);
                KDEFEdit nameEditor;
                for (bool save : {false, true}) {
                    QTimer::singleShot(0, [&nameEditor, save] {
                        auto *dialog = nameEditor.findChild<QDialog *>();
                        if (!dialog || !dialog->isVisible()) return;
                        auto *text = dialog->findChild<QTextEdit *>();
                        text->setPlainText("updated");
                        for (auto *button : dialog->findChildren<QPushButton *>())
                            if (button->text() == QString::fromUtf8("\xe8\xbf\xbd\xe5\x8a\xa0\xe5\xa7\x93\xe5\x90\x8d")) button->click();
                        text->setPlainText("new name");
                        dialog->findChild<QDialogButtonBox *>()->button(save ? QDialogButtonBox::Save : QDialogButtonBox::Cancel)->click();
                    });
                    nameEditor.editTextRecords(true);
                    QVector<QByteArray> saved;
                    require(KDEFEdit::decodeRecords(FileIO::readFileAll(nameIndex), FileIO::readFileAll(nameData), saved)
                        && (save ? saved == QVector<QByteArray>{QByteArray("updated\0", 8), QByteArray("new name\0", 9)}
                                 : saved == QVector<QByteArray>{QByteArray("original\0", 9)})
                        && FileIO::readFileAll(dataPath) == talkBefore,
                        "Name edit save/cancel changed wrong records or talk resource");
                }
            }
            KDEFEdit editor;
            QString exportPath = temporary.filePath("talk-export.txt");
            QByteArray beforeData = FileIO::readFileAll(dataPath);
            bool checked = false;
            bool nativeDisabled = QApplication::testAttribute(Qt::AA_DontUseNativeDialogs);
            QApplication::setAttribute(Qt::AA_DontUseNativeDialogs, true);
            QTimer::singleShot(0, [&] {
                auto *dialog = editor.findChild<QDialog *>();
                if (!dialog) return;
                auto *text = dialog->findChild<QTextEdit *>();
                auto *width = dialog->findChild<QSpinBox *>("talkArrangeWidth");
                auto *arrange = dialog->findChild<QPushButton *>("talkArrange");
                auto *exportButton = dialog->findChild<QPushButton *>("talkExport");
                if (!text || !width || !arrange || !exportButton) { dialog->reject(); return; }
                text->setPlainText("ab*cd");
                width->setValue(2);
                arrange->click();
                checked = text->toPlainText() == "ab*cd*";
                width->setValue(0);
                arrange->click();
                checked = checked && text->toPlainText() == "abcd";
                QTimer::singleShot(0, [exportPath] {
                    for (auto *widget : QApplication::topLevelWidgets())
                        if (auto *file = qobject_cast<QFileDialog *>(widget); file && file->isVisible()) {
                            file->selectFile(exportPath);
                            QMetaObject::invokeMethod(file, "accept", Qt::DirectConnection);
                        }
                });
                exportButton->click();
                dialog->reject();
            });
            editor.editTalks();
            QApplication::setAttribute(Qt::AA_DontUseNativeDialogs, nativeDisabled);
            QByteArray exported = FileIO::readFileAll(exportPath);
            QStringDecoder decoder(QStringConverter::Utf16LE);
            QString decoded = decoder(exported);
            require(checked && exported.startsWith(QByteArray::fromHex("fffe")) && !decoder.hasError()
                && decoded.contains("0:abcd") && decoded.contains("1:second") && decoded.contains("2:")
                && FileIO::readFileAll(dataPath) == beforeData
                && FileIO::readFileAll(config.iniPath).contains("talkarrange=0\r\n")
                && FileIO::readFileAll(config.iniPath).contains("[other]\r\nvalue=7"),
                "Talk arrange/export lost records, changed source or damaged configuration");
        }
        output << "PASS: talk dialog row edits, cancel, CP936/CP950/UTF inversion and untouched bytes\n";
#ifdef Q_OS_WIN
        {
            QString registryName = QDir(temporary.path()).dirName();
            QString registryPath = "HKEY_CURRENT_USER\\Software\\UPEditSelfTests\\" + registryName;
            bool valid = false;
            {
                QSettings registry(registryPath, QSettings::NativeFormat);
                QString executable = "C:\\Program Files\\UPEdit\\UPEdit.exe";
                valid = FileRelation::registerFileType(registry, "imz", "IMZ container", executable)
                    && FileRelation::registerFileType(registry, "zip", "PNG archive", executable)
                    && FileRelation::registerFileType(registry, "jpeg", "JPEG image", executable);
                QSettings reread(registryPath, QSettings::NativeFormat);
                valid = valid && reread.value(".imz/Default").toString() == "UPEdit.imz"
                    && reread.value("UPEdit.imz/shell/open/command/Default").toString() == "\"" + executable + "\" \"%1\""
                    && reread.value("UPEdit.imz/DefaultIcon/Default").toString() == "\"" + executable + "\",0"
                    && reread.contains(".zip/OpenWithProgids/UPEdit.zip")
                    && reread.value(".jpeg/Default").toString() == "UPEdit.jpeg";
                QStringList keys = registry.allKeys();
                valid = valid && !FileRelation::registerFileType(registry, "../bad", "bad", executable)
                    && !FileRelation::registerFileType(registry, "png", "bad", "bad\"path")
                    && registry.allKeys() == keys;
            }
            QSettings parent("HKEY_CURRENT_USER\\Software\\UPEditSelfTests", QSettings::NativeFormat);
            parent.remove(registryName);
            parent.sync();
            require(valid && parent.status() == QSettings::NoError, "Isolated association registration or cleanup failed");
            QSettings blocked(temporary.filePath("registry-parent/missing/association.ini"), QSettings::IniFormat);
            blocked.setFallbacksEnabled(false);
            require(FileIO::writeFileAll(temporary.filePath("registry-parent"), "not a directory"), "Cannot create blocked registry fixture");
            require(!FileRelation::registerFileType(blocked, "grp", "GRP", "C:\\UPEdit.exe"),
                "Association writer ignored persistent storage failure");
        }
        output << "PASS: isolated HKCU associations, quoted commands, validation and write failure\n";
#endif
        {
            IniConfig savedConfig = IniConfig::instance();
            int savedDataCode = Encoding::dataCode, savedTalkCode = Encoding::talkCode;
            int savedInvert = Encoding::talkInvert, savedLanguage = Encoding::language;
            QString path = temporary.filePath("memory-config.ini");
            require(FileIO::writeFileAll(path, "[run]\ngamepath=D:/new games/one,two/\n[50memory]\nmemnum=3\n"
                "mem0=FEDCBA98 test address with spaces\nmem1=100000000 overflow\nmem2=1234 another\n[file]\nImzIndexFileName=custom-offsets.ka\n"),
                "Cannot create memory config");
            IniConfig::instance().load(path);
            bool valid = IniConfig::instance().gamePath == "D:/new games/one,two/"
                && IniConfig::instance().imzIndexFileName == "custom-offsets.ka"
                && IniConfig::instance().memoryList.num == 2
                && IniConfig::instance().memoryList.addr[0] == 0xfedcba98
                && IniConfig::instance().memoryList.note[0] == "test address with spaces";
            IniConfig::instance() = savedConfig;
            Encoding::dataCode = savedDataCode;
            Encoding::talkCode = savedTalkCode;
            Encoding::talkInvert = savedInvert;
            Encoding::language = savedLanguage;
            require(valid, "Memory config or persisted game path did not reload correctly");
        }
        output << "PASS: configured memory address parsing and game path reload\n";
        {
            QString path = temporary.filePath("missing-run.ini");
            require(FileIO::writeFileAll(path, "[file]\npath=C:\\test") && saveRunSettings(path, {{"datacode", 3}}),
                "Cannot add missing run section");
            QTemporaryFile converted;
            QString settingsPath;
            require(prepareIniPath(path, converted, settingsPath), "Cannot read updated settings");
            QSettings settings(settingsPath, QSettings::IniFormat);
            require(settings.value("run/datacode").toInt() == 3, "Missing run section appended to previous key");
        }
        {
            QImage picture(3, 2, QImage::Format_ARGB32);
            picture.fill(Qt::green);
            QByteArray png;
            QBuffer buffer(&png);
            require(picture.save(&buffer, "PNG"), "PIC fixture encoding failed");
            QVector<PicEdit::PicData> source{{-17, 29, 1, png}, {5, -8, 0, QByteArray("unknown")}};
            QByteArray bytes = PicEdit::encodeFile(source);
            require(qFromLittleEndian<qint32>(bytes.constData()) == 2
                && qFromLittleEndian<qint32>(bytes.constData() + 4) == 24 + png.size()
                && qFromLittleEndian<qint32>(bytes.constData() + 8) == bytes.size(), "PIC cumulative offsets incorrect");
            QVector<PicEdit::PicData> restored;
            require(PicEdit::decodeFile(bytes, restored) && restored.size() == 2
                && restored[0].xoff == -17 && restored[0].yoff == 29 && restored[0].background == 1
                && restored[0].data == png && PicEdit::encodeFile(restored) == bytes, "PIC metadata/data roundtrip failed");
            require(!PicEdit::decodeFile(bytes.chopped(1), restored) && restored.size() == 2, "Truncated PIC changed current data");
            qToLittleEndian<qint32>(13, bytes.data() + 4);
            require(!PicEdit::decodeFile(bytes, restored), "Invalid PIC offset accepted");
            require(PicEdit::decodeFile(PicEdit::encodeFile({}), restored) && restored.isEmpty(), "Empty PIC failed");
        }
        output << "PASS: Delphi PIC cumulative offsets, metadata, opaque bytes, truncation and empty files\n";
        {
            uint8_t red[256]{}, green[256]{}, blue[256]{};
            red[1] = 255;
            QImage image(3, 2, QImage::Format_ARGB32);
            image.fill(Qt::red);
            GrpPic sprite = GrpIO::encodeRLE(image, red, green, blue);
            sprite.xoff = -12;
            sprite.yoff = 23;
            QString indexPath = temporary.filePath("sprites.idx"), dataPath = temporary.filePath("sprites.grp");
            require(GrpIO::saveGrp(indexPath, dataPath, {sprite}), "GRP save failed");
            QVector<GrpPic> restored;
            require(GrpIO::readGrp(indexPath, dataPath, restored) && restored.size() == 1
                && restored[0].xoff == -12 && restored[0].yoff == 23
                && GrpIO::decodeRLE(restored[0], red, green, blue).pixelColor(1, 1) == QColor(Qt::red), "GRP offsets or pixels lost");
            require(!GrpIO::saveGrp(indexPath, indexPath, {sprite}), "Identical GRP paths accepted");
            QByteArray reservedIndex(16, '\0');
            qToLittleEndian<qint32>(sprite.data.size(), reservedIndex.data());
            require(FileIO::writeFileAll(indexPath, reservedIndex)
                && GrpIO::readGrp(indexPath, dataPath, restored) && restored.size() == 4
                && restored[1].data.isEmpty() && restored[3].data.isEmpty(), "GRP reserved zero tail rejected");
            qToLittleEndian<qint32>(sprite.data.size(), reservedIndex.data() + 12);
            require(FileIO::writeFileAll(indexPath, reservedIndex)
                && !GrpIO::readGrp(indexPath, dataPath, restored), "GRP internal backward offset accepted");
            restored.resize(1);
            QByteArray invalidIndex(4, '\0');
            qToLittleEndian<qint32>(sprite.data.size() + 1, invalidIndex.data());
            require(FileIO::writeFileAll(indexPath, invalidIndex), "Cannot create invalid GRP index");
            require(!GrpIO::readGrp(indexPath, dataPath, restored) && restored.size() == 1
                && restored[0].xoff == -12, "Invalid GRP index replaced current data");
            QImage wide(300, 1, QImage::Format_ARGB32);
            wide.fill(Qt::transparent);
            wide.setPixelColor(299, 0, Qt::red);
            GrpPic sparse = GrpIO::encodeRLE(wide, red, green, blue);
            QImage decoded = GrpIO::decodeRLE(sparse, red, green, blue);
            require(!decoded.isNull() && decoded.pixelColor(299, 0) == QColor(Qt::red)
                && decoded.pixelColor(255, 0).alpha() == 0, "Long transparent RLE segment failed");
            wide.fill(Qt::red);
            require(GrpIO::encodeRLE(wide, red, green, blue).data.isEmpty(), "Oversized RLE row silently truncated");
            sparse.data.chop(1);
            require(GrpIO::decodeRLE(sparse, red, green, blue).isNull(), "Truncated RLE decoded using stale size");
        }
        output << "PASS: GRP paired save, persisted offsets and decoded pixels\n";
        {
            TakeIn editor;
            editor.m_sourceImage = QImage(12, 10, QImage::Format_ARGB32);
            editor.m_sourceImage.fill(Qt::green);
            editor.m_sourceImage.setPixelColor(3, 4, Qt::red);
            QMouseEvent press(QEvent::MouseButtonPress, QPointF(7, 8), QPointF(7, 8), Qt::LeftButton, Qt::LeftButton, Qt::NoModifier);
            QCoreApplication::sendEvent(editor.m_imageLabel, &press);
            QMouseEvent release(QEvent::MouseButtonRelease, QPointF(3, 4), QPointF(3, 4), Qt::LeftButton, Qt::NoButton, Qt::NoModifier);
            QCoreApplication::sendEvent(editor.m_imageLabel, &release);
            require(editor.m_sourceImage.size() == QSize(5, 5) && editor.m_sourceImage.pixelColor(0, 0) == QColor(Qt::red),
                "Image crop mouse selection did not modify import source");
            editor.m_cropX->setValue(4); editor.m_cropY->setValue(0);
            editor.m_widthEdit->setText("1"); editor.m_heightEdit->setText("5");
            editor.onCropImage();
            require(editor.m_sourceImage.size() == QSize(1, 5), "Exact crop rejected single-column selection");
            QImage cropBefore = editor.m_sourceImage;
            editor.m_cropX->setValue(1);
            QTimer::singleShot(0, [] {
                for (auto *widget : QApplication::topLevelWidgets())
                    if (auto *message = qobject_cast<QMessageBox *>(widget); message && message->isVisible())
                        if (auto *button = message->button(QMessageBox::Ok)) button->click();
            });
            editor.onCropImage();
            require(editor.m_sourceImage == cropBefore, "Out-of-bounds exact crop changed source");
            QString gifPath = temporary.filePath("takein-two-frames.gif");
            QByteArray gif = QByteArray::fromHex("47494638396101000100800000ff000000ff00"
                "21f904000a0000002c0000000001000100000202440100"
                "21f904000a0000002c00000000010001000002024c01003b");
            require(FileIO::writeFileAll(gifPath, gif), "Cannot create two-frame GIF");
            bool nativeDialogsDisabled = QApplication::testAttribute(Qt::AA_DontUseNativeDialogs);
            QApplication::setAttribute(Qt::AA_DontUseNativeDialogs, true);
            QTimer::singleShot(0, [gifPath] {
                for (auto *widget : QApplication::topLevelWidgets())
                    if (auto *dialog = qobject_cast<QFileDialog *>(widget); dialog && dialog->isVisible()) {
                        dialog->selectFile(gifPath);
                        QMetaObject::invokeMethod(dialog, "accept", Qt::DirectConnection);
                    }
            });
            editor.onOpenImage();
            QTimer::singleShot(0, [] {
                for (auto *widget : QApplication::topLevelWidgets())
                    if (auto *dialog = qobject_cast<QFileDialog *>(widget); dialog && dialog->isVisible()) dialog->reject();
            });
            editor.onOpenImage();
            QApplication::setAttribute(Qt::AA_DontUseNativeDialogs, nativeDialogsDisabled);
            require(editor.m_frames.size() == 2 && editor.m_frameSpin->maximum() == 1
                && editor.m_sourceImage.pixelColor(0, 0) == QColor(Qt::red), "GIF first frame or frame count incorrect");
            editor.m_frameSpin->setValue(1);
            require(editor.m_sourceImage.pixelColor(0, 0) == QColor(Qt::green)
                && editor.m_widthEdit->text() == "1" && editor.m_heightEdit->text() == "1",
                "GIF frame selection did not refresh source image and dimensions");
            QString invalidPath = temporary.filePath("takein-invalid.gif");
            require(FileIO::writeFileAll(invalidPath, "not an image"), "Cannot create invalid image input");
            editor.openImage(invalidPath);
            require(editor.m_frames.size() == 2 && editor.m_frameSpin->value() == 1
                && editor.m_sourceImage.pixelColor(0, 0) == QColor(Qt::green),
                "Invalid image input replaced current GIF session");
            const QImage beforeSize = editor.m_sourceImage;
            for (const QString &width : {QString("invalid"), QString("0"), QString("-1"), QString("2147483647"), QString("32767")}) {
                editor.m_widthEdit->setText(width);
                editor.m_heightEdit->setText("32767");
                QTimer::singleShot(0, [] {
                    for (auto *widget : QApplication::topLevelWidgets())
                        if (auto *message = qobject_cast<QMessageBox *>(widget); message && message->isVisible())
                            if (auto *ok = message->button(QMessageBox::Ok)) ok->click();
                });
                editor.onConfirmSize();
                require(editor.m_sourceImage == beforeSize, "Invalid dimensions changed ordinary image source");
            }
            editor.m_widthEdit->setText("2"); editor.m_heightEdit->setText("3");
            editor.onConfirmSize();
            require(editor.m_sourceImage.size() == QSize(2, 3)
                && editor.m_sourceImage.pixelColor(0, 0) == QColor(Qt::green)
                && editor.m_sourceImage.pixelColor(1, 2).alpha() == 0,
                "Valid image resize lost pixels or transparent padding");
            CYHead heads;
            heads.m_paletteReady = true;
            heads.m_red[1] = 255;
            QImage image(2, 2, QImage::Format_ARGB32);
            image.fill(Qt::red);
            auto sprite = GrpIO::encodeRLE(image, heads.m_red, heads.m_green, heads.m_blue);
            require(heads.imageFor(sprite).pixelColor(0, 0) == QColor(Qt::red), "Portrait ignored actual palette");
        }
        output << "PASS: image crop mouse selection and portrait palette pixels\n";
        {
            auto &config = IniConfig::instance();
            QScopedValueRollback<QString> restorePath(config.gamePath, temporary.path());
            QScopedValueRollback<QString> restorePalette(config.palette, "missing-portrait.col");
            CYHead editor;
            editor.m_paletteReady = true;
            editor.m_red[1] = 255;
            QImage image(2, 2, QImage::Format_ARGB32);
            image.fill(Qt::red);
            GrpPic sprite = GrpIO::encodeRLE(image, editor.m_red, editor.m_green, editor.m_blue);
            editor.m_heads = {sprite, GrpPic()};
            editor.m_savedState = editor.stateBytes();
            editor.drawPNG();
            require(!editor.m_imageLabel->pixmap().isNull(), "Portrait preview missing");
            editor.onNext();
            require(editor.m_imageLabel->pixmap().isNull(), "Empty portrait displayed previous image");
            editor.onPrev();
            QString idx = temporary.filePath("portrait.idx"), grp = temporary.filePath("portrait.grp");
            require(GrpIO::saveGrp(idx, grp, {sprite}), "Cannot prepare portrait group");
            editor.m_idxEdit->setText(idx); editor.m_grpEdit->setText(grp);
            auto dismiss = [] {
                QTimer::singleShot(0, [] {
                    for (auto *widget : QApplication::topLevelWidgets())
                        if (auto *message = qobject_cast<QMessageBox *>(widget); message && message->isVisible())
                            if (auto *ok = message->button(QMessageBox::Ok)) ok->click();
                });
            };
            dismiss(); editor.onLoad();
            require(editor.m_paletteReady && editor.m_heads.size() == 2
                && editor.imageFor(editor.m_heads[0]).pixelColor(0, 0) == QColor(Qt::red),
                "Failed portrait palette load modified active session");
            bool nativeDialogsDisabled = QApplication::testAttribute(Qt::AA_DontUseNativeDialogs);
            QApplication::setAttribute(Qt::AA_DontUseNativeDialogs, true);
            QString directory = temporary.filePath("portrait-export");
            require(QDir().mkpath(directory), "Cannot prepare portrait export directory");
            auto exportAll = [&] {
                QTimer dismissError;
                QObject::connect(&dismissError, &QTimer::timeout, [] {
                    for (auto *widget : QApplication::topLevelWidgets())
                        if (auto *message = qobject_cast<QMessageBox *>(widget); message && message->isVisible())
                            if (auto *ok = message->button(QMessageBox::Ok)) ok->click();
                });
                dismissError.start(10);
                QTimer::singleShot(0, [directory] {
                    for (auto *widget : QApplication::topLevelWidgets())
                        if (auto *dialog = qobject_cast<QFileDialog *>(widget); dialog && dialog->isVisible()) {
                            dialog->setDirectory(directory);
                            QMetaObject::invokeMethod(dialog, "accept", Qt::DirectConnection);
                        }
                });
                editor.onExportAll();
            };
            exportAll();
            QString first = QDir(directory).filePath(QString::fromUtf8("\xe5\xa4\xb4\xe5\x83\x8f") + "0.png");
            require(QImage(first).convertToFormat(QImage::Format_ARGB32) == image, "Portrait export palette pixels changed");
            require(FileIO::writeFileAll(first, "previous portrait"), "Cannot prepare previous portrait output");
            QString second = QDir(directory).filePath(QString::fromUtf8("\xe5\xa4\xb4\xe5\x83\x8f") + "1.png");
            require(QDir().mkpath(second), "Cannot block second portrait output");
            editor.m_heads = {sprite, sprite};
            exportAll();
            QApplication::setAttribute(Qt::AA_DontUseNativeDialogs, nativeDialogsDisabled);
            require(FileIO::readFileAll(first) == "previous portrait" && QFileInfo(second).isDir(),
                "Portrait export failure partially replaced existing output");
            editor.m_loadedIdx = idx; editor.m_loadedGrp = grp;
            editor.m_savedState = editor.stateBytes();
            editor.m_heads[0].xoff = -123;
            QByteArray dirty = editor.stateBytes();
            auto answer = [](QMessageBox::StandardButton choice) {
                QTimer::singleShot(0, [choice] {
                    for (auto *widget : QApplication::topLevelWidgets())
                        if (auto *message = qobject_cast<QMessageBox *>(widget); message && message->isVisible())
                            if (auto *button = message->button(choice)) button->click();
                });
            };
            answer(QMessageBox::Cancel);
            editor.onLoad();
            require(editor.stateBytes() == dirty && editor.m_loadedIdx == idx,
                "Cancelled portrait reload lost edits or loaded path");
            editor.show();
            answer(QMessageBox::Cancel);
            bool closed = editor.close();
            require(!closed && editor.isVisible() && editor.stateBytes() == dirty,
                "Cancelled portrait close lost session");
            editor.m_idxEdit->setText(temporary.filePath("unloaded-portrait.idx"));
            editor.m_grpEdit->setText(temporary.filePath("unloaded-portrait.grp"));
            answer(QMessageBox::Save);
            require(editor.confirmDiscard() && editor.stateBytes() == editor.m_savedState
                && !QFile::exists(editor.m_idxEdit->text()), "Portrait save used unconfirmed target path");
            QVector<GrpPic> savedHeads;
            require(GrpIO::readGrp(idx, grp, savedHeads) && savedHeads[0].xoff == -123,
                "Portrait save did not persist edits to loaded group");
            editor.close();
            QApplication::setAttribute(Qt::AA_DontUseNativeDialogs, true);
            QString replacement = temporary.filePath("portrait-replacement.png");
            QImage replacementImage(3, 4, QImage::Format_ARGB32);
            replacementImage.fill(Qt::cyan);
            require(replacementImage.save(replacement), "Cannot prepare portrait replacement");
            auto replace = [&](const QString &fileName) {
                QTimer dismissError;
                QObject::connect(&dismissError, &QTimer::timeout, [] {
                    for (auto *widget : QApplication::topLevelWidgets())
                        if (auto *message = qobject_cast<QMessageBox *>(widget); message && message->isVisible())
                            if (auto *ok = message->button(QMessageBox::Ok)) ok->click();
                });
                dismissError.start(10);
                QTimer::singleShot(0, [fileName] {
                    for (auto *widget : QApplication::topLevelWidgets())
                        if (auto *dialog = qobject_cast<QFileDialog *>(widget); dialog && dialog->isVisible()) {
                            if (fileName.isEmpty()) dialog->reject();
                            else {
                                dialog->selectFile(fileName);
                                QMetaObject::invokeMethod(dialog, "accept", Qt::DirectConnection);
                            }
                        }
                });
                editor.onReplacePNG();
            };
            replace(replacement);
            bool replacementValid = editor.m_heads[0].data == FileIO::readFileAll(replacement)
                && editor.m_heads[0].width == 3 && editor.m_heads[0].height == 4
                && editor.m_heads[0].xoff == 0 && editor.m_heads[0].yoff == 0;
            QByteArray afterReplacement = editor.stateBytes();
            replace(QString());
            require(FileIO::writeFileAll(replacement, "invalid PNG"), "Cannot corrupt portrait replacement");
            replace(replacement);
            QApplication::setAttribute(Qt::AA_DontUseNativeDialogs, nativeDialogsDisabled);
            require(replacementValid && editor.stateBytes() == afterReplacement,
                "Portrait replacement failed or cancelled/invalid input changed active data");
        }
        output << "PASS: portrait empty preview, failed palette load and atomic batch export\n";
        {
            auto &config = IniConfig::instance();
            QScopedValueRollback<QString> restorePath(config.gamePath, temporary.path());
            QScopedValueRollback<QString> restorePalette(config.palette, "takein.col");
            QScopedValueRollback<int> restoreCount(config.grpListNum, 1);
            QScopedValueRollback<QVector<QString>> restoreIdx(config.grpListIdx, {"takein.idx"});
            QScopedValueRollback<QVector<QString>> restoreGrp(config.grpListGrp, {"takein.grp"});
            QScopedValueRollback<QVector<QString>> restoreNames(config.grpListName, {"synthetic"});
            QByteArray palette(768, '\0'); palette[3] = 63; palette[7] = 63;
            require(FileIO::writeFileAll(temporary.filePath(config.palette), palette), "Cannot create ordinary image palette");
            TakeIn editor;
            editor.m_sourceImage = QImage(3, 2, QImage::Format_ARGB32);
            editor.m_sourceImage.fill(QColor(252, 0, 0));
            editor.m_sourceImage.setPixelColor(1, 1, QColor(0, 252, 0));
            editor.m_transCheck->setChecked(true);
            editor.m_transColorEdit->setText("00fc00");
            editor.m_xoffEdit->setText("-32768"); editor.m_yoffEdit->setText("32767");
            auto import = [&] {
                QTimer::singleShot(0, [] {
                    for (auto *widget : QApplication::topLevelWidgets())
                        if (auto *message = qobject_cast<QMessageBox *>(widget); message && message->isVisible())
                            if (auto *ok = message->button(QMessageBox::Ok)) ok->click();
                });
                editor.onImportToGrp();
            };
            import();
            QString indexPath = temporary.filePath("takein.idx"), dataPath = temporary.filePath("takein.grp");
            QVector<GrpPic> pictures;
            uint8_t red[256]{}, green[256]{}, blue[256]{}; red[1] = 252; green[2] = 252;
            require(GrpIO::readGrp(indexPath, dataPath, pictures) && pictures.size() == 1
                && pictures[0].xoff == -32768 && pictures[0].yoff == 32767,
                "Ordinary image import lost signed offsets");
            QImage decoded = GrpIO::decodeRLE(pictures[0], red, green, blue);
            require(decoded.pixelColor(0, 0) == QColor(252, 0, 0) && decoded.pixelColor(1, 1).alpha() == 0
                && editor.m_sourceImage.pixelColor(1, 1) == QColor(0, 252, 0),
                "Ordinary image import changed palette colors, transparency or source pixels");
            QByteArray firstRecord = pictures[0].data;
            import();
            require(GrpIO::readGrp(indexPath, dataPath, pictures) && pictures.size() == 2 && pictures[0].data == firstRecord,
                "Ordinary image append replaced existing GRP data");
            QByteArray indexBefore = FileIO::readFileAll(indexPath), dataBefore = FileIO::readFileAll(dataPath);
            editor.m_xoffEdit->setText("32768"); import();
            require(FileIO::readFileAll(indexPath) == indexBefore && FileIO::readFileAll(dataPath) == dataBefore,
                "Invalid ordinary image offset modified GRP files");
            editor.m_xoffEdit->setText("0");
            require(FileIO::writeFileAll(temporary.filePath(config.palette), palette.left(767)), "Cannot truncate ordinary image palette");
            import();
            require(FileIO::readFileAll(indexPath) == indexBefore && FileIO::readFileAll(dataPath) == dataBefore,
                "Invalid ordinary image palette modified GRP files");
        }
        output << "PASS: ordinary image GRP append, transparency, signed offsets and rejected input preservation\n";
        {
            TakeIn editor;
            editor.m_sourceImage = QImage(3, 2, QImage::Format_ARGB32);
            editor.m_sourceImage.fill(Qt::blue);
            QImage original = editor.m_sourceImage;
            QTimer::singleShot(0, [] {
                for (auto *widget : QApplication::topLevelWidgets())
                    if (auto *dialog = qobject_cast<QDialog *>(widget); dialog && dialog->isVisible()
                        && dialog->findChild<GrpEdit *>()) dialog->reject();
            });
            editor.onEditImage();
            require(editor.m_sourceImage == original, "Cancelled region edit changed source image");
            QTimer::singleShot(0, [] {
                for (auto *widget : QApplication::topLevelWidgets()) {
                    auto *dialog = qobject_cast<QDialog *>(widget);
                    if (!dialog || !dialog->isVisible()) continue;
                    auto *imageEditor = dialog->findChild<GrpEdit *>();
                    if (!imageEditor) continue;
                    imageEditor->findChild<QSpinBox *>("canvasWidth")->setValue(4);
                    imageEditor->findChild<QSpinBox *>("canvasHeight")->setValue(5);
                    imageEditor->findChild<QPushButton *>("resizeCanvas")->click();
                    QMetaObject::invokeMethod(imageEditor, "onSave", Qt::DirectConnection);
                }
            });
            editor.onEditImage();
            require(editor.m_sourceImage.size() == QSize(4, 5)
                && editor.m_sourceImage.pixelColor(0, 0) == QColor(Qt::blue)
                && editor.m_sourceImage.pixelColor(3, 4).alpha() == 0,
                "Region editor did not write back accepted canvas changes");
            QByteArray palette(768, '\0'); palette[5] = 63;
            QString palettePath = temporary.filePath("independent.col");
            QString indexPath = temporary.filePath("independent.idx");
            QString dataPath = temporary.filePath("independent.grp");
            require(FileIO::writeFileAll(palettePath, palette), "Cannot create independent palette");
            editor.m_idxPath->setText(indexPath);
            editor.m_grpPath->setText(dataPath);
            editor.m_palettePath->setText(palettePath);
            QTimer::singleShot(0, [] {
                for (auto *widget : QApplication::topLevelWidgets())
                    if (auto *message = qobject_cast<QMessageBox *>(widget); message && message->isVisible())
                        if (auto *button = message->button(QMessageBox::Ok)) button->click();
            });
            editor.onImportToGrp();
            QVector<GrpPic> pictures;
            require(GrpIO::readGrp(indexPath, dataPath, pictures) && pictures.size() == 1
                && pictures[0].width == 4 && pictures[0].height == 5,
                "Independent COL/IDX/GRP paths were not used");
            QImage frame(2, 2, QImage::Format_ARGB32);
            frame.fill(Qt::blue);
            editor.m_frames = {frame, frame};
            editor.m_frames[1].fill(Qt::transparent);
            editor.m_allFrames->setChecked(true);
            auto importFrames = [&] {
                QTimer::singleShot(0, [] {
                    for (auto *widget : QApplication::topLevelWidgets())
                        if (auto *message = qobject_cast<QMessageBox *>(widget); message && message->isVisible())
                            if (auto *button = message->button(QMessageBox::Ok)) button->click();
                });
                editor.onImportToGrp();
            };
            importFrames();
            uint8_t red[256]{}, green[256]{}, blue[256]{}; blue[1] = 252;
            require(GrpIO::readGrp(indexPath, dataPath, pictures) && pictures.size() == 3
                && GrpIO::decodeRLE(pictures[1], red, green, blue).pixelColor(0, 0) == QColor(0, 0, 252)
                && GrpIO::decodeRLE(pictures[2], red, green, blue).pixelColor(0, 0).alpha() == 0,
                "All-frame append lost order, colors or transparency");
            QByteArray indexBefore = FileIO::readFileAll(indexPath), dataBefore = FileIO::readFileAll(dataPath);
            editor.m_frames[1] = QImage(300, 1, QImage::Format_ARGB32);
            editor.m_frames[1].fill(Qt::blue);
            importFrames();
            require(FileIO::readFileAll(indexPath) == indexBefore && FileIO::readFileAll(dataPath) == dataBefore,
                "Failed later frame partially appended batch");
        }
        output << "PASS: ordinary image region edit acceptance/cancellation and independent COL/IDX/GRP paths\n";
        {
            QVector<QByteArray> source{QByteArray::fromHex("0100ffff0200"), QByteArray(), QByteArray::fromHex("ffff")};
            QByteArray index, data;
            require(KDEFEdit::encodeRecords(source, index, data), "KDEF record encoding failed");
            require(index == QByteArray::fromHex("060000000600000008000000"), "KDEF cumulative offsets incorrect");
            QVector<QByteArray> restored;
            require(KDEFEdit::decodeRecords(index, data, restored) && restored == source, "KDEF IDX boundaries lost");
            require(!KDEFEdit::decodeRecords(index, data.chopped(1), restored) && restored == source, "Truncated KDEF accepted");
        }
        output << "PASS: KDEF/talk IDX boundaries, embedded terminators and empty records\n";
        {
            KDEFEdit editor;
            KDEFEdit::KDEFInstrDef jump;
            jump.code = 1;
            jump.paramNames = {"target"};
            jump.yesJump = 0;
            editor.m_instrDefs = {jump};
            KDEFEdit::KDEFEvent event;
            event.eventId = 0;
            event.instructions = {{1, {1}, 1}, {2, {}, 2}, {-1, {}, 3}};
            editor.m_events = {event};
            editor.m_nextIdentity = 4;
            editor.displayInstructions(0);
            editor.displayInstructionDetail(0);
            editor.onCopyInstruction();
            editor.onPasteInstruction();
            const auto &instructions = editor.m_events[0].instructions;
            require(instructions.size() == 4 && instructions[0].params[0] == 3
                && instructions[1].params[0] == 1, "Copied KDEF jump lost target identity");
            editor.displayInstructionDetail(2);
            editor.onMoveUp();
            require(editor.m_events[0].instructions[0].params[0] == 3
                && editor.m_events[0].instructions[2].params[0] == 0, "Reordered KDEF jump lost target");
        }
        output << "PASS: KDEF copy and reorder preserve jump target identities\n";
        {
            KDEFEdit editor;
            KDEFEdit::KDEFInstrDef jump;
            jump.code = 1;
            jump.paramNames = {"target"};
            jump.yesJump = 0;
            editor.m_instrDefs = {jump};
            KDEFEdit::KDEFEvent source, destination;
            source.instructions = {{1, {1}, 1}, {2, {}, 2}, {-1, {}, 3}};
            destination.instructions = {{2, {}, 4}, {-1, {}, 5}};
            editor.m_events = {source, destination};
            editor.m_nextIdentity = 6;
            editor.displayInstructions(0);
            editor.displayInstructionDetail(0);
            editor.onCopyInstruction();
            editor.displayInstructions(1);
            editor.displayInstructionDetail(0);
            QTimer::singleShot(0, [] {
                for (QWidget *widget : QApplication::topLevelWidgets())
                    if (auto *dialog = qobject_cast<QInputDialog *>(widget)) {
                        dialog->setTextValue(dialog->comboBoxItems().last());
                        dialog->accept();
                    }
            });
            editor.onPasteInstruction();
            require(editor.m_events[1].instructions.size() == 3
                && editor.m_events[1].instructions[1].params[0] == 1,
                "Cross-event paste did not resolve end target");
            editor.displayInstructionDetail(1);
            QTimer::singleShot(0, [] {
                for (QWidget *widget : QApplication::topLevelWidgets())
                    if (auto *dialog = qobject_cast<QInputDialog *>(widget)) {
                        dialog->setTextValue(dialog->comboBoxItems().first());
                        dialog->accept();
                    }
            });
            editor.onPasteInstruction();
            require(editor.m_events[1].instructions.size() == 4
                && editor.m_events[1].instructions[2].params[0] == -5
                && editor.m_events[1].instructions[1].params[0] == 3,
                "Cross-event paste lost instruction or existing end target");
            QByteArray before = editor.stateBytes();
            QTimer::singleShot(0, [] {
                for (QWidget *widget : QApplication::topLevelWidgets())
                    if (auto *dialog = qobject_cast<QInputDialog *>(widget)) dialog->reject();
            });
            editor.onPasteInstruction();
            require(editor.stateBytes() == before, "Cancelled jump selection changed events");
        }
        output << "PASS: KDEF cross-event jump target selection and cancel preservation\n";
        {
            KDEFEdit editor;
            KDEFEdit::KDEFInstrDef definition;
            definition.code = 7;
            definition.paramNames = {"mode"};
            definition.quoteTypes = {5};
            definition.quoteCounts = {0};
            editor.m_instrDefs = {definition};
            editor.m_guideChoices = {{{0, "off"}, {5, "on"}}};
            KDEFEdit::KDEFEvent event;
            event.eventId = 0;
            event.instructions = {{7, {0}, 1}, {8, {9}, 2}};
            editor.m_events = {event};
            editor.displayInstructions(0);
            editor.displayInstructionDetail(0);
            auto *combo = qobject_cast<QComboBox *>(editor.m_paramTable->cellWidget(0, 1));
            require(combo && combo->count() == 2, "KDEF guide choices missing");
            combo->setCurrentIndex(1);
            require(editor.m_events[0].instructions[0].params[0] == 5, "KDEF guide selection not committed");
            editor.displayInstructionDetail(1);
            require(!editor.m_paramTable->cellWidget(0, 1), "Old KDEF guide widget leaked into numeric instruction");
            editor.m_paramTable->item(0, 1)->setText("123");
            require(editor.m_events[0].instructions[1].params[0] == 123
                && editor.m_events[0].instructions[0].params[0] == 5, "KDEF parameter switch changed wrong instruction");
            for (const QString &invalid : {QString("invalid"), QString("32768"), QString("-32769")}) {
                editor.m_paramTable->item(0, 1)->setText(invalid);
                require(editor.m_events[0].instructions[1].params[0] == 123
                    && editor.m_paramTable->item(0, 1)->text() == "123",
                    "Invalid KDEF parameter changed data or left misleading table text");
            }
            for (int value : {-32768, 32767}) {
                editor.m_paramTable->item(0, 1)->setText(QString::number(value));
                require(editor.m_events[0].instructions[1].params[0] == value
                    && editor.m_events[0].instructions[0].params[0] == 5,
                    "KDEF int16 parameter boundary was clamped or changed another instruction");
            }
            editor.m_loaded = true;
            editor.m_savedState = editor.stateBytes();
            require(editor.confirmDiscard(), "Unmodified KDEF prompted");
            editor.m_events[0].instructions[1].params[0] = 124;
            QByteArray dirty = editor.stateBytes();
            QTimer::singleShot(0, [] {
                for (QWidget *widget : QApplication::topLevelWidgets())
                    if (auto *message = qobject_cast<QMessageBox *>(widget)) message->button(QMessageBox::Cancel)->click();
            });
            require(!editor.confirmDiscard() && editor.stateBytes() == dirty, "Cancel discarded KDEF changes");
        }
        output << "PASS: KDEF guide selection, numeric editing and instruction switch isolation\n";
        {
            auto &config = IniConfig::instance();
            QScopedValueRollback<QString> gamePath(config.gamePath, temporary.path());
            QScopedValueRollback<QString> iniPath(config.iniPath, temporary.filePath("war-guide.ini"));
            QScopedValueRollback<QString> warData(config.warData, "war-guide.dat");
            QScopedValueRollback<int> dataCode(config.dataCode, 3);
            QByteArray ini("[W_Modify]\ntypedataitem=3\ndata(0)=1 1 2 0 0 -1 id\n"
                "data(1)=1 1 8 1 1 -1 name\ndata(2)=2 1 2 0 0 -1 extra\n");
            require(FileIO::writeFileAll(config.iniPath, ini), "Cannot write war guide schema");
            QByteArray records = QByteArray::fromHex("0100");
            records.append(QByteArray("First", 5).leftJustified(8, '\0'));
            records.append(QByteArray(4, '\0'));
            records.append(QByteArray::fromHex("0200"));
            records.append(QByteArray("Second", 6).leftJustified(8, '\0'));
            records.append(QByteArray(4, '\0'));
            QString path = temporary.filePath(config.warData);
            require(FileIO::writeFileAll(path, records), "Cannot write war guide records");
            KDEFEdit editor;
            KDEFEdit::KDEFInstrDef definition;
            definition.code = 9;
            definition.paramNames = {"battle"};
            definition.quoteTypes = {2};
            editor.m_instrDefs = {definition};
            KDEFEdit::KDEFEvent event;
            event.instructions = {{9, {-2}, 1}};
            editor.m_events = {event};
            editor.displayInstructions(0);
            editor.displayInstructionDetail(0);
            auto *combo = qobject_cast<QComboBox *>(editor.m_paramTable->cellWidget(0, 1));
            require(combo && combo->count() == 4 && combo->itemData(0).toInt() == -2
                && combo->itemData(1).toInt() == -1 && combo->itemText(3).contains("Second"),
                "War guide names, record stride or sentinel values incorrect");
            combo->setCurrentIndex(3);
            require(editor.m_events[0].instructions[0].params[0] == 1, "War guide selection not committed");
            require(FileIO::writeFileAll(path, records.chopped(1)), "Cannot truncate war guide fixture");
            editor.loadKDEFIni();
            require(editor.m_warChoices.size() == 2, "Truncated war records exposed partial choices");
            require(FileIO::writeFileAll(config.iniPath, QByteArray("[W_Modify]\ntypedataitem=1\ndata(0)=32768 1 8 1 1 -1 name\n")),
                "Cannot write invalid war guide schema");
            editor.loadKDEFIni();
            require(editor.m_warChoices.size() == 2, "Invalid war layout accepted");
            require(FileIO::writeFileAll(config.iniPath, "[KdefAttrib]\nnumber=3\nattrib0=0A 2 0 0 0 explicit\nattrib2=invalid\n"
                "[kdef50]\nnum=3\nother=fallback\nsub0=explicit\nsub1=\n"),
                "Cannot write subinstruction fallback config");
            editor.loadKDEFIni();
            require(editor.m_subInstructions == QStringList({"explicit", "", "fallback"}),
                "KDEF missing subinstruction did not use configured fallback");
            require(editor.m_instrDefs.size() == 3 && editor.m_instrDefs[0].code == 10
                && editor.m_instrDefs[0].paramNames.size() == 1 && editor.m_instrDefs[1].code == 1
                && editor.m_instrDefs[1].paramNames.isEmpty() && editor.m_instrDefs[2].code == 2,
                "KDEF missing definition did not preserve default opcode slots");
            require(FileIO::writeFileAll(config.iniPath,
                "[KdefAttrib]\nnumber=1\nattrib0=0A 4 1 2 3 branch\n"
                "guidestring0=guide text\nguidelabel0=opcode first second third\n"
                "guidequotetype0=0 1 2 3\nguidequotecount0=0 4 5 6\n"
                "GuideComboBoxAmount=1\nGuideComboBox0=-1 none 7 seven\n"),
                "Cannot write KDEF guide configuration");
            editor.loadKDEFIni();
            require(editor.m_instrDefs.size() == 1 && editor.m_instrDefs[0].code == 10
                && editor.m_instrDefs[0].paramNames == QStringList({"first", "second", "third"})
                && editor.m_instrDefs[0].quoteTypes == QVector<int>({1, 2, 3})
                && editor.m_instrDefs[0].quoteCounts == QVector<int>({4, 5, 6})
                && editor.m_instrDefs[0].guide == "guide text"
                && editor.m_instrDefs[0].yesJump == 1 && editor.m_instrDefs[0].noJump == 2
                && editor.m_guideChoices.size() == 1 && editor.m_guideChoices[0].size() == 2
                && editor.m_guideChoices[0][0].first == -1 && editor.m_guideChoices[0][1].second == "seven",
                "KDEF configured guides, labels, references or jump indices shifted");
        }
        output << "PASS: KDEF battle references, name stride, selection and malformed input\n";
        {
            KDEFEdit editor;
            editor.m_instrDefs.clear();
            editor.m_subInstructions = {"assign", "array write", "array read"};
            KDEFEdit::KDEFEvent event;
            event.instructions = {{50, {1, 0, 0, 12, 13, 14, 15}, 1}};
            editor.m_events = {event};
            editor.displayInstructions(0);
            editor.displayInstructionDetail(0);
            auto *flags = qobject_cast<QComboBox *>(editor.m_paramTable->cellWidget(1, 1));
            auto *width = qobject_cast<QComboBox *>(editor.m_paramTable->cellWidget(2, 1));
            require(flags && flags->count() == 4 && width && width->count() == 2,
                "50-1 flags or operand width missing");
            flags->setCurrentIndex(3);
            width->setCurrentIndex(1);
            require(editor.m_events[0].instructions[0].params[1] == 3
                && editor.m_events[0].instructions[0].params[2] == 1, "50-1 guide values not committed");
            auto *sub = qobject_cast<QComboBox *>(editor.m_paramTable->cellWidget(0, 1));
            sub->setCurrentIndex(2);
            QApplication::processEvents();
            flags = qobject_cast<QComboBox *>(editor.m_paramTable->cellWidget(1, 1));
            require(flags && flags->count() == 2 && flags->currentText().startsWith("3")
                && editor.m_events[0].instructions[0].params[5] == 14,
                "50-2 switch lost unknown flag or unrelated parameters");
            flags->setCurrentIndex(1);
            require(editor.m_events[0].instructions[0].params[1] == 1, "50-2 variable flag not committed");
            sub = qobject_cast<QComboBox *>(editor.m_paramTable->cellWidget(0, 1));
            sub->setCurrentIndex(0);
            QApplication::processEvents();
            require(!editor.m_paramTable->cellWidget(1, 1) && !editor.m_paramTable->cellWidget(2, 1)
                && editor.m_events[0].instructions[0].params[2] == 1,
                "50-0 switch retained old widgets or changed operand");
        }
        output << "PASS: KDEF 50-0/1/2 flags, operand width and subinstruction switching\n";
        {
            KDEFEdit editor;
            editor.m_instrDefs.clear();
            KDEFEdit::KDEFEvent event;
            event.instructions = {{50, {3, 0, 0, 11, 12, 13, 14}, 1}};
            editor.m_events = {event};
            editor.displayInstructions(0);
            const QMap<int, int> masks = {{3, 1}, {4, 1}, {8, 1}, {9, 1}, {12, 1},
                {16, 7}, {17, 3}, {18, 3}, {19, 1}, {20, 1}, {21, 15}, {22, 7}, {23, 31},
                {24, 15}, {25, 3}, {26, 1}, {27, 1}, {29, 3}, {30, 3}, {31, 7}, {32, 1},
                {33, 7}, {34, 31}, {36, 7}, {37, 1}, {38, 1}, {39, 7},
                {41, 7}, {42, 3}, {43, 31}, {44, 7}, {45, 1}, {46, 31}, {47, 1}};
            for (auto entry = masks.cbegin(); entry != masks.cend(); ++entry) {
                editor.m_events[0].instructions[0].params[0] = entry.key();
                editor.displayInstructionDetail(0);
                auto *flags = qobject_cast<QComboBox *>(editor.m_paramTable->cellWidget(1, 1));
                require(flags && flags->count() == entry.value() + 1, "50 variable mask choices incorrect");
                flags->setCurrentIndex(entry.value());
                require(editor.m_events[0].instructions[0].params[1] == entry.value()
                    && editor.m_events[0].instructions[0].params[3] == 11, "50 flag selection damaged operands");
                if (entry.key() == 3 || entry.key() == 4) {
                    auto *operation = qobject_cast<QComboBox *>(editor.m_paramTable->cellWidget(2, 1));
                    int count = entry.key() == 3 ? 5 : 8;
                    require(operation && operation->count() == count, "50 arithmetic/comparison operations missing");
                    operation->setCurrentIndex(count - 1);
                    require(editor.m_events[0].instructions[0].params[2] == count - 1, "50 operation not committed");
                }
            }
        }
        output << "PASS: KDEF 50 variable masks, arithmetic and comparison guides\n";
        {
            KDEFEdit editor;
            KDEFEdit::KDEFEvent source, destination;
            source.eventId = 0;
            source.instructions = {{1, {7, -2}, 10}, {0, {}, 11}};
            destination.eventId = 1;
            destination.instructions = {{0, {}, 12}};
            editor.m_events = {source, destination};
            editor.m_eventClipboard = source;
            editor.m_hasEventClipboard = true;
            editor.m_nextIdentity = 20;
            editor.displayInstructions(1);
            auto answer = [](QMessageBox::StandardButton button) {
                QTimer::singleShot(0, [button] {
                    for (QWidget *widget : QApplication::topLevelWidgets())
                        if (auto *message = qobject_cast<QMessageBox *>(widget))
                            if (auto *control = message->button(button)) control->click();
                });
            };
            QByteArray before = editor.stateBytes();
            answer(QMessageBox::Cancel);
            editor.onPasteEvent();
            require(editor.stateBytes() == before, "Cancelled event paste changed data");
            answer(QMessageBox::Yes);
            editor.onPasteEvent();
            require(editor.m_events[1].eventId == 1 && editor.m_events[1].instructions.size() == 2
                && editor.m_events[1].instructions[0].params == source.instructions[0].params
                && editor.m_events[1].instructions[0].identity == 20
                && editor.m_events[0].instructions[0].identity == 10,
                "Event paste changed ID, source or relative parameters");
        }
        output << "PASS: KDEF event overwrite confirmation, cancel and identity isolation\n";
        {
            KDEFEdit editor;
            editor.m_instrDefs.clear();
            KDEFEdit::KDEFEvent event;
            event.instructions = {{7, {10}, 1}, {8, {20}, 2}, {9, {30}, 3}};
            editor.m_events = {event};
            editor.m_nextIdentity = 4;
            editor.displayInstructions(0);
            editor.m_instrTable->selectionModel()->select(editor.m_instrTable->model()->index(2, 0),
                QItemSelectionModel::Select | QItemSelectionModel::Rows);
            editor.m_instrTable->selectionModel()->select(editor.m_instrTable->model()->index(0, 0),
                QItemSelectionModel::Select | QItemSelectionModel::Rows);
            editor.onCopyInstruction();
            require(editor.m_clipboard.size() == 2 && editor.m_clipboard[0].code == 7
                && editor.m_clipboard[1].code == 9, "Multiple instruction copy lost list order");
            editor.displayInstructionDetail(2);
            editor.onPasteInstruction();
            require(editor.m_events[0].instructions.size() == 5
                && editor.m_events[0].instructions[3].params[0] == 10
                && editor.m_events[0].instructions[4].params[0] == 30
                && editor.m_events[0].instructions[3].identity == 4
                && editor.m_events[0].instructions[4].identity == 5,
                "Multiple instruction paste lost values or identities");
        }
        output << "PASS: KDEF noncontiguous instruction copy order and paste identities\n";
        {
            KDEFEdit editor;
            KDEFEdit::KDEFInstrDef definition;
            definition.code = 1;
            definition.yesJump = 0;
            editor.m_instrDefs = {definition};
            KDEFEdit::KDEFEvent source, destination;
            source.instructions = {{2, {}, 1}, {1, {-3}, 2}};
            destination.instructions = {{2, {}, 3}};
            editor.m_events = {source, destination};
            editor.m_nextIdentity = 4;
            editor.displayInstructions(0);
            for (int row = 0; row < 2; ++row)
                editor.m_instrTable->selectionModel()->select(editor.m_instrTable->model()->index(row, 0),
                    QItemSelectionModel::Select | QItemSelectionModel::Rows);
            editor.onCopyInstruction();
            editor.displayInstructions(1);
            editor.displayInstructionDetail(0);
            editor.onPasteInstruction();
            require(editor.m_events[1].instructions.size() == 3
                && editor.m_events[1].instructions[1].identity == 4
                && editor.m_events[1].instructions[2].identity == 5
                && editor.m_events[1].instructions[2].params[0] == -3,
                "Cross-event block jump did not target copied instruction");
        }
        output << "PASS: KDEF cross-event copied block internal backward jump remapping\n";
        {
            KDEFEdit editor;
            editor.m_instrDefs.clear();
            KDEFEdit::KDEFEvent event;
            event.instructions = {{50, {40, qint16(0xabfa), 12, 13, 14, 15, 16}, 1}};
            editor.m_events = {event};
            editor.displayInstructions(0);
            editor.displayInstructionDetail(0);
            auto *flags = editor.findChild<QComboBox *>("kdef40Flags");
            auto *extra = editor.findChild<QSpinBox *>("kdef40Extra");
            require(flags && extra && flags->currentIndex() == 2 && extra->value() == 0xab,
                "50-40 packed fields decoded incorrectly");
            extra->setValue(255);
            flags->setCurrentIndex(5);
            require(quint16(editor.m_events[0].instructions[0].params[1]) == 0xfffd
                && editor.m_events[0].instructions[0].params[2] == 12,
                "50-40 packed fields lost unknown bits or operands");
        }
        output << "PASS: KDEF 50-40 high byte, variable flags and unknown-bit preservation\n";
        {
            KDEFEdit editor;
            editor.m_instrDefs.clear();
            KDEFEdit::KDEFEvent event;
            event.instructions = {{50, {33, 0, 1, 2, 3, qint16(0xabcd), 0}, 1}};
            editor.m_events = {event};
            editor.displayInstructions(0);
            editor.displayInstructionDetail(0);
            auto *foreground = editor.findChild<QComboBox *>("kdefForeground");
            auto *background = editor.findChild<QComboBox *>("kdefBackground");
            require(foreground && background && foreground->currentIndex() == 0xcd
                && background->currentIndex() == 0xab, "Packed palette indices decoded incorrectly");
            foreground->setCurrentIndex(17);
            background->setCurrentIndex(255);
            require(quint16(editor.m_events[0].instructions[0].params[5]) == 0xff11,
                "Palette selection lost high byte");
            editor.m_events[0].instructions[0].params[1] = 4;
            editor.displayInstructionDetail(0);
            require(!editor.m_paramTable->cellWidget(5, 1)
                && quint16(editor.m_events[0].instructions[0].params[5]) == 0xff11,
                "Variable color kept direct palette controls or changed value");
        }
        output << "PASS: KDEF packed foreground/background palette and variable mode\n";
        {
            KDEFEdit editor;
            editor.m_instrDefs.clear();
            KDEFEdit::KDEFEvent event;
            event.instructions = {{44, {9, 10, -2, 1, 0, qint16(0xabcd), 12}, 1}};
            editor.m_events = {event};
            editor.displayInstructions(0);
            editor.displayInstructionDetail(0);
            auto *foreground = editor.findChild<QComboBox *>("kdefForeground");
            auto *background = editor.findChild<QComboBox *>("kdefBackground");
            require(foreground && background && foreground->currentIndex() == 0xcd
                && background->currentIndex() == 0xab, "New-dialog palette indices decoded incorrectly");
            foreground->setCurrentIndex(17);
            background->setCurrentIndex(255);
            require(editor.m_events[0].instructions[0].params == QVector<int16_t>{9, 10, -2, 1, 0, qint16(0xff11), 12},
                "New-dialog palette changed unrelated parameters");
        }
        output << "PASS: KDEF new-dialog packed palette and unrelated parameter preservation\n";
        {
            auto &config = IniConfig::instance();
            QScopedValueRollback<QString> path(config.gamePath, temporary.path());
            QScopedValueRollback<QString> head(config.headPicName, "guide-head.pic");
            QScopedValueRollback<QString> nameIdx(config.nameIdx, "guide-name.idx");
            QScopedValueRollback<QString> nameGrp(config.nameGrp, "guide-name.grp");
            QScopedValueRollback<QString> talkIdx(config.talkIdx, "guide-talk.idx");
            QScopedValueRollback<QString> talkGrp(config.talkGrp, "guide-talk.grp");
            QScopedValueRollback<int> code(config.talkCode, 3);
            QScopedValueRollback<int> invert(config.talkInvert, 1);
            QImage image(3, 4, QImage::Format_ARGB32); image.fill(Qt::green);
            QByteArray png;
            QBuffer buffer(&png);
            require(image.save(&buffer, "PNG"), "Cannot create guide portrait");
            require(FileIO::writeFileAll(temporary.filePath(config.headPicName),
                PicEdit::encodeFile({{0, 0, 0, png}, {0, 0, 0, png}})), "Cannot create guide PIC");
            QByteArray index, data;
            require(KDEFEdit::encodeRecords({QByteArray("entry\0", 6)}, index, data)
                && FileIO::writeFiles({{temporary.filePath(config.nameIdx), index}, {temporary.filePath(config.nameGrp), data},
                    {temporary.filePath(config.talkIdx), index}, {temporary.filePath(config.talkGrp), data}}),
                "Cannot create guide text references");
            KDEFEdit editor;
            editor.m_instrDefs.clear();
            KDEFEdit::KDEFEvent event;
            event.instructions = {{44, {0, 0, -2, 1, 0, 0, 12}, 1}};
            editor.m_events = {event};
            editor.displayInstructions(0);
            editor.displayInstructionDetail(0);
            auto *portraits = editor.findChild<QComboBox *>("kdefPortrait");
            auto *talk = qobject_cast<QComboBox *>(editor.m_paramTable->cellWidget(1, 1));
            auto *name = qobject_cast<QComboBox *>(editor.m_paramTable->cellWidget(2, 1));
            require(portraits && portraits->count() == 2 && !portraits->itemIcon(1).isNull()
                && talk && talk->findData(0) >= 0 && name && name->findData(-2) >= 0 && name->findData(0) >= 0,
                "New-dialog portrait or text references missing");
            portraits->setCurrentIndex(1);
            name->setCurrentIndex(name->findData(0));
            require(editor.m_events[0].instructions[0].params == QVector<int16_t>{1, 0, 0, 1, 0, 0, 12},
                "New-dialog reference selection changed unrelated parameters");
        }
        output << "PASS: KDEF new-dialog portrait thumbnails and talk/name references\n";
        {
            auto &globals = IniConfig::instance().rGlobals;
            QScopedValueRollback<RFile> restore(globals.rFile);
            globals.rFile.rType.resize(5);
            globals.rFile.rType[1].rData.resize(1);
            globals.rFile.rType[2].rData.resize(3);
            globals.rFile.rType[3].rData.resize(2);
            KDEFEdit editor;
            editor.m_instrDefs.clear();
            KDEFEdit::KDEFEvent event;
            event.instructions = {{45, {0, 0, 0}, 1}, {46, {0, qint16(0xabcd)}, 2}, {47, {0, 12, 13}, 3}};
            editor.m_events = {event};
            editor.displayInstructions(0);
            editor.displayInstructionDetail(0);
            auto *type = qobject_cast<QComboBox *>(editor.m_paramTable->cellWidget(0, 1));
            auto *record = qobject_cast<QComboBox *>(editor.m_paramTable->cellWidget(1, 1));
            require(type && record && record->findData(0) >= 0 && record->findData(1) < 0,
                "Replacement guide initial R type incorrect");
            type->setCurrentIndex(type->findData(1));
            QApplication::processEvents();
            record = qobject_cast<QComboBox *>(editor.m_paramTable->cellWidget(1, 1));
            require(record && record->findData(1) >= 0, "Replacement guide did not refresh R records");
            record->setCurrentIndex(record->findData(1));
            require(editor.m_events[0].instructions[0].params == QVector<int16_t>{1, 1, 0},
                "Replacement guide wrote wrong parameters");
            editor.displayInstructionDetail(1);
            auto *container = editor.m_paramTable->cellWidget(1, 1);
            require(container, "Subtitle color controls missing");
            auto *foreground = container->findChild<QComboBox *>("kdefForeground");
            auto *background = container->findChild<QComboBox *>("kdefBackground");
            require(foreground && background, "Subtitle palette controls missing");
            foreground->setCurrentIndex(17); background->setCurrentIndex(255);
            require(editor.m_events[0].instructions[1].params == QVector<int16_t>{0, qint16(0xff11)},
                "Subtitle palette wrote wrong parameter");
            editor.displayInstructionDetail(2);
            auto *scene = qobject_cast<QComboBox *>(editor.m_paramTable->cellWidget(0, 1));
            require(scene && scene->findData(2) >= 0, "Scene jump reference missing");
            scene->setCurrentIndex(scene->findData(2));
            require(editor.m_events[0].instructions[2].params == QVector<int16_t>{2, 12, 13},
                "Scene jump reference changed coordinates");
        }
        output << "PASS: KDEF replacement type refresh, subtitle palette and scene jump references\n";
        {
            auto &globals = IniConfig::instance().rGlobals;
            QScopedValueRollback<RFile> restore(globals.rFile);
            globals.rFile.rType.resize(5);
            globals.rFile.rType[1].rData.resize(2);
            globals.rFile.rType[2].rData.resize(2);
            globals.rFile.rType[3].rData.resize(2);
            globals.rFile.rType[4].rData.resize(2);
            auto &config = IniConfig::instance();
            QScopedValueRollback<QString> path(config.gamePath, temporary.path());
            QScopedValueRollback<QString> talkIdx(config.talkIdx, "legacy-guide.idx");
            QScopedValueRollback<QString> talkGrp(config.talkGrp, "legacy-guide.grp");
            QScopedValueRollback<int> code(config.talkCode, 3);
            QScopedValueRollback<int> invert(config.talkInvert, 1);
            QByteArray index, data;
            require(KDEFEdit::encodeRecords({QByteArray("talk\0", 5)}, index, data)
                && FileIO::writeFiles({{temporary.filePath(config.talkIdx), index}, {temporary.filePath(config.talkGrp), data}}),
                "Cannot create legacy guide text");
            KDEFEdit editor;
            editor.m_instrDefs.clear();
            KDEFEdit::KDEFEvent event;
            event.instructions = {
                {1, {0, 0, 0}, 1}, {2, {0, 0}, 2}, {48, {0, 12, 13}, 5}, {49, {0, 14, 15}, 6},
                {0x11, {0, 0, 0, 0, 0, 0}, 3}, {0x21, {0, 0, 0, 0}, 4},
                {36, {0, 0}, 7}, {40, {0}, 8}};
            editor.m_events = {event};
            editor.displayInstructions(0);
            editor.displayInstructionDetail(0);
            auto *talk = qobject_cast<QComboBox *>(editor.m_paramTable->cellWidget(0, 1));
            auto *person = qobject_cast<QComboBox *>(editor.m_paramTable->cellWidget(1, 1));
            require(talk && talk->findData(0) >= 0 && person && person->findData(1) >= 0,
                "Legacy dialogue/item selectors missing");
            talk->setCurrentIndex(talk->findData(0));
            editor.displayInstructionDetail(1);
            person = qobject_cast<QComboBox *>(editor.m_paramTable->cellWidget(0, 1));
            person->setCurrentIndex(person->findData(1));
            require(editor.m_events[0].instructions[1].params[0] == 1,
                "Legacy item selector did not write record index");
            editor.displayInstructionDetail(2);
            auto *attribute = qobject_cast<QComboBox *>(editor.m_paramTable->cellWidget(0, 1));
            require(attribute && attribute->findData(1) >= 0, "Legacy 48 person selector missing");
            attribute->setCurrentIndex(attribute->findData(1));
            require(editor.m_events[0].instructions[2].params[0] == 1,
                "Legacy 48 person selector did not write record index");
            editor.displayInstructionDetail(3);
            attribute = qobject_cast<QComboBox *>(editor.m_paramTable->cellWidget(0, 1));
            require(attribute && attribute->findData(1) >= 0, "Legacy 49 person selector missing");
            editor.displayInstructionDetail(4);
            auto *scene = qobject_cast<QComboBox *>(editor.m_paramTable->cellWidget(0, 1));
            require(scene && scene->findData(1) >= 0, "Legacy scene selector missing");
            editor.displayInstructionDetail(5);
            auto *personForSkill = qobject_cast<QComboBox *>(editor.m_paramTable->cellWidget(0, 1));
            auto *skill = qobject_cast<QComboBox *>(editor.m_paramTable->cellWidget(1, 1));
            require(personForSkill && skill && skill->findData(1) >= 0,
                "Legacy skill selector missing");
            editor.displayInstructionDetail(6);
            auto *gender = qobject_cast<QComboBox *>(editor.m_paramTable->cellWidget(0, 1));
            require(gender && gender->findData(0) >= 0 && gender->findData(256) >= 0,
                "Legacy gender selector missing");
            editor.displayInstructionDetail(7);
            auto *direction = qobject_cast<QComboBox *>(editor.m_paramTable->cellWidget(0, 1));
            require(direction && direction->count() == 4 && direction->findData(3) >= 0,
                "Legacy direction selector missing");
        }
        output << "PASS: KDEF legacy dialogue/item/scene/skill selectors\n";
        {
            QScopedValueRollback<K50MemoryList> savedMemory(IniConfig::instance().memoryList);
            IniConfig::instance().memoryList = {1, {0xfedcba98}, {"test address"}};
            KDEFEdit editor;
            editor.m_instrDefs.clear();
            KDEFEdit::KDEFEvent event;
            event.instructions = {{50, {25, 0, 0, 0x1234, 0x5678, 0, 0}, 1}};
            editor.m_events = {event};
            editor.displayInstructions(0);
            editor.displayInstructionDetail(0);
            auto *address = editor.m_paramTable->cellWidget(3, 1)->findChild<QLineEdit *>();
            require(address && address->text() == "0x56781234", "50 memory address assembly incorrect");
            address->setText("0xfedcba98");
            QMetaObject::invokeMethod(address, "editingFinished", Qt::DirectConnection);
            require(quint16(editor.m_events[0].instructions[0].params[3]) == 0xba98
                && quint16(editor.m_events[0].instructions[0].params[4]) == 0xfedc,
                "50 memory address high word lost");
            address->setText("0x100000000");
            QMetaObject::invokeMethod(address, "editingFinished", Qt::DirectConnection);
            require(quint16(editor.m_events[0].instructions[0].params[4]) == 0xfedc,
                "Overflow memory address changed operands");
            auto *presets = editor.findChild<QComboBox *>("kdefMemoryPresets");
            require(presets && presets->count() == 2, "Configured memory preset missing");
            QMetaObject::invokeMethod(presets, "activated", Qt::DirectConnection, Q_ARG(int, 1));
            require(address->text() == "0xfedcba98"
                && quint16(editor.m_events[0].instructions[0].params[3]) == 0xba98,
                "Memory preset did not write address words");
        }
        output << "PASS: KDEF 50 memory address high/low words and overflow rejection\n";
        {
            auto &config = IniConfig::instance();
            QScopedValueRollback<RFileGlobals> globals(config.rGlobals);
            QScopedValueRollback<DIni> eventFields(config.dIni);
            config.rGlobals = RFileGlobals();
            config.rGlobals.typeName = {"general", "people"};
            config.rGlobals.rFile.rType.resize(2);
            config.rGlobals.rIni.resize(2);
            RTermini first;
            first.datanum = 2; first.incnum = 2; first.datalen = 2; first.name = "short";
            RTermini second;
            second.datanum = 0; second.incnum = 1; second.datalen = 4; second.name = "long";
            config.rGlobals.rIni[1].rTerm = {first, second};
            config.dIni.attrib = {"walk", "number", "script"};
            KDEFEdit editor;
            editor.m_instrDefs.clear();
            KDEFEdit::KDEFEvent event;
            event.instructions = {{50, {16, 0, 0, 0, 0, 0, 0}, 1}};
            editor.m_events = {event};
            editor.displayInstructions(0);
            editor.displayInstructionDetail(0);
            auto *offsets = qobject_cast<QComboBox *>(editor.m_paramTable->cellWidget(4, 1));
            require(offsets && offsets->count() == 4 && offsets->itemData(3).toInt() == 8,
                "50 R compound field byte offsets incorrect");
            offsets->setCurrentIndex(3);
            require(editor.m_events[0].instructions[0].params[4] == 8, "50 R offset selection not committed");
            auto *flags = qobject_cast<QComboBox *>(editor.m_paramTable->cellWidget(1, 1));
            flags->setCurrentIndex(2);
            QApplication::processEvents();
            require(!editor.m_paramTable->cellWidget(4, 1), "Variable R offset retained direct selector");
            editor.m_events[0].instructions[0].params = {21, 0, 0, 0, 0, 0, 0};
            editor.displayInstructionDetail(0);
            auto *fields = qobject_cast<QComboBox *>(editor.m_paramTable->cellWidget(4, 1));
            require(fields && fields->count() == 3 && fields->itemText(2).contains("script"),
                "50 event field choices missing");
            fields->setCurrentIndex(2);
            require(editor.m_events[0].instructions[0].params[4] == 2, "50 event field not committed");
            for (int sub = 41; sub <= 46; ++sub) {
                editor.m_events[0].instructions[0].params[0] = sub;
                editor.displayInstructionDetail(0);
                flags = qobject_cast<QComboBox *>(editor.m_paramTable->cellWidget(1, 1));
                int count = sub == 42 ? 4 : sub == 45 ? 2 : (sub == 43 || sub == 46) ? 32 : 8;
                require(flags && flags->count() == count, "50 final subinstruction flag mask incorrect");
            }
        }
        output << "PASS: KDEF 50 compound offsets, variable references and event field guides\n";
        {
            require(XlsxWriter::loadLibrary("xlsxwriter") && XlsxReader::loadLibrary("libxlsxio_read"),
                "XLSX runtime unavailable");
            QString path = temporary.filePath("roundtrip.xlsx");
            XlsxWriter writer;
            require(writer.create(path) && writer.addWorksheet("records"), "Cannot create XLSX fixture");
            writer.writeString(0, 0, "name");
            writer.writeString(0, 1, "value");
            writer.writeString(1, 0, QString::fromUtf8("\xe4\xb8\xad\xe6\x96\x87 ' text"));
            writer.writeNumber(1, 1, -32768);
            writer.writeString(2, 0, "tail");
            writer.writeNumber(2, 2, 42);
            require(writer.close(), "XLSX finalization failed");
            XlsxReader reader;
            require(reader.open(path), "Cannot reopen XLSX fixture");
            auto rows = reader.readAll("records");
            require(rows.size() == 3 && rows[1].size() >= 2 && rows[1][0].contains("' text")
                && rows[1][1] == "-32768" && rows[2].size() >= 3 && rows[2][2] == "42",
                "XLSX Unicode, negative number or sparse column roundtrip failed");
            reader.close();
            require(writer.create(temporary.filePath("invalid.xlsx")) && writer.addWorksheet("bounds"), "Cannot create invalid XLSX fixture");
            writer.writeNumber(-1, 0, 1);
            require(!writer.close(), "Invalid XLSX coordinates reported success");
            require(writer.create(temporary.filePath("duplicate.xlsx")) && writer.addWorksheet("same"),
                "Cannot create duplicate sheet fixture");
            require(!writer.addWorksheet("same") && !writer.close(), "Duplicate worksheet reported success");
            require(writer.create(temporary.filePath("missing/output.xlsx")) && writer.addWorksheet("records"),
                "Cannot initialize missing-directory fixture");
            writer.writeNumber(0, 0, 1);
            require(!writer.close(), "XLSX finalization failure reported success");
        }
        output << "PASS: XLSX runtime roundtrip, sparse columns and write failure propagation\n";
        {
            auto &config = IniConfig::instance();
            QScopedValueRollback<RFileGlobals> globals(config.rGlobals);
            auto &schema = config.rGlobals;
            schema = RFileGlobals();
            schema.typeNumber = 2;
            schema.typeName = {"general", "people"};
            schema.typeDataItem = {2, 2};
            schema.rIni.resize(2);
            RTermini text;
            text.datanum = text.incnum = 1;
            text.datalen = 32;
            text.isstr = 1;
            text.name = "name";
            RTermini number = text;
            number.isstr = 0;
            number.datalen = 2;
            number.name = "value";
            for (auto &definition : schema.rIni) definition.rTerm = {text, number};
            QString path = temporary.filePath("r-import.xlsx");
            auto makeWorkbook = [&](const QString &value) {
                XlsxWriter writer;
                require(writer.create(path) && writer.addWorksheet("general"), "Cannot create R transposed sheet");
                writer.writeString(0, 0, "name"); writer.writeString(1, 0, "value");
                writer.writeString(0, 1, "first"); writer.writeString(0, 2, "second");
                writer.writeNumber(1, 1, -32768); writer.writeNumber(1, 2, 32767);
                require(writer.addWorksheet("people"), "Cannot create R standard sheet");
                writer.writeString(0, 0, "name"); writer.writeString(0, 1, "value");
                writer.writeString(1, 0, "person"); writer.writeString(1, 1, value);
                require(writer.close(), "Cannot finalize R workbook");
            };
            makeWorkbook("123");
            REditWidget editor;
            require(editor.importXlsx(path) && editor.m_rFile.rType[0].rData.size() == 2
                && editor.m_rFile.rType[1].rData.size() == 1, "R XLSX layouts lost records");
            require(RFileIO::readRDataInt(editor.m_rFile.rType[0].rData[0].rDataLine[1].rArray[0].dataArray[0]) == -32768
                && RFileIO::readRDataInt(editor.m_rFile.rType[0].rData[1].rDataLine[1].rArray[0].dataArray[0]) == 32767
                && RFileIO::readRDataStr(editor.m_rFile.rType[1].rData[0].rDataLine[0].rArray[0].dataArray[0]) == "person",
                "R XLSX field mapping changed");
            QByteArray before = editor.stateBytes();
            QString exported = temporary.filePath("r-export.xlsx");
            require(editor.exportXlsx(exported), "R XLSX export failed");
            require(editor.importXlsx(exported) && editor.stateBytes() == before,
                "R editor XLSX export/import roundtrip changed records");
            QByteArray originalWorkbook = FileIO::readFileAll(exported);
            schema.typeName[1] = schema.typeName[0];
            require(!editor.exportXlsx(exported) && FileIO::readFileAll(exported) == originalWorkbook,
                "Failed R export replaced original workbook");
            schema.typeName[1] = "people";
            for (const QString &invalid : {QString("32768"), QString("not-a-number")}) {
                makeWorkbook(invalid);
                require(!editor.importXlsx(path) && editor.stateBytes() == before, "Invalid R XLSX damaged working copy");
            }
            for (auto &definition : schema.rIni) definition.rTerm[1].datalen = 8;
            for (auto &type : editor.m_rFile.rType)
                for (auto &record : type.rData)
                    record.rDataLine[1].rArray[0].dataArray[0].dataLen = 8;
            for (qint64 value : {(std::numeric_limits<qint64>::min)(),
                (std::numeric_limits<qint64>::max)(), qint64(1000000000000001LL)}) {
                for (auto &type : editor.m_rFile.rType)
                    for (auto &record : type.rData)
                        RFileIO::writeRDataInt(record.rDataLine[1].rArray[0].dataArray[0], value);
                QByteArray wideState = editor.stateBytes();
                require(editor.exportXlsx(exported) && editor.importXlsx(exported) && editor.stateBytes() == wideState,
                    "R XLSX rounded wide integers in transposed or standard layout");
            }
        }
        output << "PASS: R XLSX transposed/standard layouts, integer limits and atomic rejection\n";
        {
            WarEdit editor;
            WTermini text;
            text.datanum = text.incnum = 1;
            text.datalen = 16;
            text.isstr = text.isname = 1;
            WTermini number = text;
            number.isstr = number.isname = 0;
            number.datalen = 2;
            editor.m_wIni.wTerm = {text, number};
            QString path = temporary.filePath("w-import.xlsx");
            auto makeWorkbook = [&](const QString &value) {
                XlsxWriter writer;
                require(writer.create(path) && writer.addWorksheet("Sheet1"), "Cannot create W XLSX fixture");
                writer.writeString(0, 0, "name"); writer.writeString(0, 1, "value");
                writer.writeString(1, 0, "battle"); writer.writeString(1, 1, value);
                require(writer.close(), "Cannot finalize W XLSX fixture");
            };
            makeWorkbook("-32768");
            require(editor.importExcel(path) && editor.m_warFile.records.size() == 1
                && editor.m_warFile.records[0].fields[1].values[0] == -32768,
                "W XLSX signed value import failed");
            QByteArray name = editor.m_warFile.records[0].fields[0].rawBytes[0];
            QString exported = temporary.filePath("w-export.xlsx");
            require(editor.exportExcel(exported) && editor.importExcel(exported)
                && editor.m_warFile.records[0].fields[1].values[0] == -32768
                && editor.m_warFile.records[0].fields[0].rawBytes[0] == name,
                "W XLSX export/import changed record values");
            for (const QString &invalid : {QString("32768"), QString("bad")}) {
                makeWorkbook(invalid);
                require(!editor.importExcel(path) && editor.m_warFile.records.size() == 1
                    && editor.m_warFile.records[0].fields[1].values[0] == -32768
                    && editor.m_warFile.records[0].fields[0].rawBytes[0] == name,
                    "Invalid W XLSX changed working records");
            }
        }
        output << "PASS: W XLSX signed values, overflow and atomic rejection\n";
        {
            WarEdit editor;
            WTermini number;
            number.datanum = number.incnum = 1;
            number.datalen = 8;
            number.isstr = 0;
            editor.m_wIni.wTerm = {number};
            editor.m_warFile.records.resize(1);
            editor.m_warFile.records[0].fields.resize(1);
            QString path = temporary.filePath("w-wide.xlsx");
            for (qint64 value : {(std::numeric_limits<qint64>::min)(),
                (std::numeric_limits<qint64>::max)(), qint64(1000000000000001LL)}) {
                editor.m_warFile.records[0].fields[0].values = {value};
                require(editor.exportExcel(path) && editor.importExcel(path)
                    && editor.m_warFile.records[0].fields[0].values[0] == value,
                    "W XLSX rounded a wide integer during export/import");
            }
        }
        output << "PASS: W XLSX full-width signed integer precision preservation\n";
        {
            WarEdit editor;
            WTermini term;
            term.datanum = term.incnum = term.datalen = 1;
            term.isstr = 0;
            editor.m_wIni.wTerm = {term};
            editor.m_warFile.records.resize(1);
            editor.m_warFile.records[0].fields.resize(1);
            editor.m_warFile.records[0].fields[0].values = {7};
            editor.m_currentWar = 0;
            editor.displayW();
            for (const QString &text : {QString("128"), QString("invalid"), QString("-128")}) {
                QTimer::singleShot(0, [text] {
                    for (auto *widget : QApplication::topLevelWidgets())
                        if (auto *dialog = qobject_cast<QInputDialog *>(widget)) {
                            dialog->setTextValue(text);
                            dialog->accept();
                        }
                });
                editor.onCellDoubleClicked(0, 1);
                require(editor.m_warFile.records[0].fields[0].values[0] == (text == "-128" ? -128 : 7),
                    "W numeric dialog accepted invalid value or rejected boundary");
            }
            QScopedValueRollback<RFileGlobals> globals(IniConfig::instance().rGlobals);
            IniConfig::instance().rGlobals.rFile.rType.resize(2);
            IniConfig::instance().rGlobals.rFile.rType[1].rData.resize(129);
            editor.m_wIni.wTerm[0].quote = 1;
            QTimer::singleShot(0, [] {
                for (auto *widget : QApplication::topLevelWidgets())
                    if (auto *dialog = qobject_cast<QInputDialog *>(widget)) {
                        if (auto *combo = dialog->findChild<QComboBox *>()) combo->setCurrentIndex(129);
                        dialog->accept();
                    }
            });
            editor.onCellDoubleClicked(0, 1);
            require(editor.m_warFile.records[0].fields[0].values[0] == -128,
                "W reference dialog accepted overflowing byte reference");
        }
        output << "PASS: W numeric and reference dialogs reject invalid and overflowing values\n";
        {
            WarEdit editor;
            auto &config = IniConfig::instance();
            QScopedValueRollback<QString> iniPath(config.iniPath, temporary.filePath("compound-war.ini"));
            QScopedValueRollback<QString> gamePath(config.gamePath, temporary.path());
            QScopedValueRollback<QString> warPath(config.warData, "compound-war.dat");
            QByteArray definition = "[W_Modify]\ntypedataitem=3\n"
                "data(0)=2 3 1 0 0 -1 person none 0 1 1\n"
                "data(1)=0 1 2 0 0 -1 xpos none 0 1 2\n"
                "data(2)=0 1 4 1 0 -1 text none 0 0 0\n";
            QByteArray bytes = QByteArray::fromHex("07feff6162630008ff7f78797a00");
            require(FileIO::writeFileAll(config.iniPath, definition)
                && FileIO::writeFileAll(temporary.filePath(config.warData), bytes)
                && editor.readWIni() && editor.readW(), "Cannot load compound W schema");
            require(editor.m_wIni.wTerm.size() == 6 && editor.m_warFile.records.size() == 1,
                "Compound W schema expanded incorrectly");
            const auto &fields = editor.m_warFile.records[0].fields;
            require(fields[0].values[0] == 7 && fields[1].values[0] == -2
                && fields[2].rawBytes[0] == QByteArray("abc\0", 4)
                && fields[3].values[0] == 8 && fields[4].values[0] == 32767
                && fields[5].rawBytes[0] == QByteArray("xyz\0", 4),
                "Compound W member widths, ordering or string types changed");
            QTimer::singleShot(0, [] {
                for (auto *widget : QApplication::topLevelWidgets())
                    if (auto *message = qobject_cast<QMessageBox *>(widget))
                        if (message->button(QMessageBox::Ok)) message->button(QMessageBox::Ok)->click();
            });
            editor.onSave();
            require(FileIO::readFileAll(temporary.filePath(config.warData)) == bytes,
                "Compound W binary save did not preserve bytes");
            QByteArray state = editor.stateBytes();
            require(editor.exportExcel(temporary.filePath("compound-war.xlsx"))
                && editor.importExcel(temporary.filePath("compound-war.xlsx")) && editor.stateBytes() == state,
                "Compound W XLSX roundtrip changed member data");
            for (const QByteArray &invalid : {QByteArray("[W_Modify]\ntypedataitem=1\ndata(0)=40000 1 2 0 0 0 bad\n"),
                QByteArray("[W_Modify]\ntypedataitem=1\ndata(0)=1 2 2 0 0 0 bad\n")}) {
                require(FileIO::writeFileAll(config.iniPath, invalid) && !editor.readWIni()
                    && editor.stateBytes() == state && editor.m_wIni.wTerm.size() == 6,
                    "Invalid W schema changed current session");
            }
        }
        output << "PASS: compound W schema member widths, ordering, binary/XLSX roundtrip and rejection\n";
        {
            WarEdit editor;
            editor.m_warFile.records.resize(1);
            editor.m_warFile.records[0].fields.resize(1);
            editor.m_warFile.records[0].fields[0].values = {7};
            editor.m_loaded = true;
            editor.m_savedState = editor.stateBytes();
            require(editor.confirmDiscard(), "Unchanged W session prompted");
            editor.m_warFile.records[0].fields[0].values[0] = 9;
            auto answer = [](QMessageBox::StandardButton button) {
                QTimer::singleShot(0, [button] {
                    for (QWidget *widget : QApplication::topLevelWidgets())
                        if (auto *message = qobject_cast<QMessageBox *>(widget))
                            if (auto *control = message->button(button)) control->click();
                });
            };
            answer(QMessageBox::Cancel);
            require(!editor.confirmDiscard() && editor.m_warFile.records[0].fields[0].values[0] == 9,
                "W cancel discarded modifications");
            answer(QMessageBox::Discard);
            require(editor.confirmDiscard() && editor.stateBytes() != editor.m_savedState,
                "W discard changed save baseline");
            auto &config = IniConfig::instance();
            QScopedValueRollback<QString> gamePath(config.gamePath, temporary.path());
            QScopedValueRollback<QString> warData(config.warData, "truncated-war.dat");
            editor.m_wIni.wTerm.resize(1);
            editor.m_wIni.wTerm[0].datanum = editor.m_wIni.wTerm[0].incnum = 1;
            editor.m_wIni.wTerm[0].datalen = 2;
            editor.m_currentWar = 0;
            editor.displayW();
            editor.m_table->item(0, 1)->setText("32768");
            require(editor.m_warFile.records[0].fields[0].values[0] == 9
                && editor.m_table->item(0, 1)->text() == "9", "W table accepted overflowing integer");
            editor.m_table->item(0, 1)->setText("-32768");
            require(editor.m_warFile.records[0].fields[0].values[0] == -32768,
                "W table rejected signed lower boundary");
            require(FileIO::writeFileAll(temporary.filePath(config.warData), "x"), "Cannot create truncated W");
            QByteArray before = editor.stateBytes(), baseline = editor.m_savedState;
            editor.readW();
            require(editor.stateBytes() == before && editor.m_savedState == baseline,
                "Truncated W changed working state or baseline");
        }
        output << "PASS: W unsaved cancel, discard and truncated-load preservation\n";
        {
            RFileGlobals schema;
            schema.typeNumber = 1;
            schema.typeDataItem = {1};
            schema.rIni.resize(1);
            RTermini term;
            term.datanum = term.incnum = 1;
            term.datalen = 4;
            term.isstr = 1;
            schema.rIni[0].rTerm = {term};
            QByteArray index = QByteArray::fromHex("06000000aabbccdd");
            QByteArray data = QByteArray::fromHex("4100deadbeeffeed");
            QString idxPath = temporary.filePath("opaque-r.idx"), grpPath = temporary.filePath("opaque-r.grp");
            require(FileIO::writeFiles({{idxPath, index}, {grpPath, data}}), "Cannot create opaque R fixture");
            QScopedValueRollback<int> codeGuard(Encoding::dataCode, 3);
            RFile records;
            require(RFileIO::readR(idxPath, grpPath, &records, schema)
                && RFileIO::saveR(idxPath, grpPath, &records, schema)
                && FileIO::readFileAll(idxPath) == index && FileIO::readFileAll(grpPath) == data,
                "R save discarded padding, block remainder, extra indices or trailing bytes");
            output << "PASS: R opaque text padding and unknown block/index/file tails preserved\n";
        }
        {
            require(SQLite3Database::loadLibrary("sqlite3"), "SQLite runtime unavailable");
            RFileGlobals schema;
            schema.typeNumber = 1;
            schema.typeName = {"records"};
            schema.typeDataItem = {2};
            schema.rIni.resize(1);
            RTermini textTerm;
            textTerm.datanum = textTerm.incnum = 1;
            textTerm.datalen = 32;
            textTerm.isstr = 1;
            textTerm.name = "name";
            RTermini numberTerm = textTerm;
            numberTerm.isstr = 0;
            numberTerm.datalen = 4;
            numberTerm.name = "value";
            schema.rIni[0].rTerm = {textTerm, numberTerm};
            RFile source;
            source.typeNumber = 1;
            source.rType.resize(1);
            RFileIO::addNewRData(&source, 0, schema);
            RFileIO::writeRDataStr(source.rType[0].rData[0].rDataLine[0].rArray[0].dataArray[0], "A'B\"C");
            RFileIO::writeRDataInt(source.rType[0].rData[0].rDataLine[1].rArray[0].dataArray[0], -123);
            QString path = temporary.filePath("records.db");
            require(RFileIO::saveDB(path, &source, schema), "SQLite staged save failed");
            {
                SQLite3Database database;
                require(database.open(path), "Cannot inspect SQLite fixture");
                auto statement = database.prepare("select name,value from records");
                require(statement.isValid() && statement.step() == SQLite3Statement::SQLITE_ROW
                    && statement.columnText(0) == "A'B\"C" && statement.columnInt(1) == -123, "SQLite values changed");
            }
            QByteArray original = FileIO::readFileAll(path);
            schema.rIni[0].rTerm[1].name = "name";
            require(!RFileIO::saveDB(path, &source, schema) && FileIO::readFileAll(path) == original, "Failed SQL damaged original database");
        }
        output << "PASS: SQLite staged save, quoted text and SQL failure preservation\n";
        {
            auto &config = IniConfig::instance();
            QScopedValueRollback<QString> ini(config.iniPath, temporary.filePath("war-selection.ini"));
            require(FileIO::writeFileAll(config.iniPath, QByteArray("[W_Modify]\r\nselectcontinue=0\r\n; keep\r\n")),
                "Cannot create war selection settings");
            WarEdit editor;
            editor.m_wIni.wTerm.resize(6);
            const int labels[] = {1, 2, 3, 4, 5, 6};
            for (int field = 0; field < 6; ++field) {
                auto &term = editor.m_wIni.wTerm[field];
                term.datanum = term.incnum = 1;
                term.datalen = 2;
                term.labelnum = labels[field];
                term.labeltype = field == 2 || field == 3 || field == 5 ? 2 : 1;
            }
            editor.m_warFile.records.resize(2);
            for (auto &record : editor.m_warFile.records) {
                record.fields.resize(6);
                for (auto &field : record.fields) field.values = {0};
                record.fields[0].values[0] = 2;
                record.fields[1].values[0] = 3;
                record.fields[2].values[0] = 6;
                record.fields[3].values[0] = 7;
            }
            editor.m_warTileCache.resize(1);
            editor.rebuildWSelect();
            editor.onWarChanged(0);
            auto click = [&](int x, int y) {
                QPointF point = (editor.m_positionOrigin + QPointF((x - y) * 18 * editor.m_scaleSpin->value(),
                    (x + y) * 9 * editor.m_scaleSpin->value())) * editor.m_positionScale;
                QMouseEvent event(QEvent::MouseButtonPress, point, point, Qt::LeftButton, Qt::LeftButton, Qt::NoModifier);
                QCoreApplication::sendEvent(editor.m_posImage, &event);
            };
            click(2, 3);
            click(4, 5);
            require(editor.m_warFile.records[0].fields[0].values[0] == 4
                && editor.m_warFile.records[0].fields[1].values[0] == 5
                && editor.m_warFriend[0].x == 4 && editor.m_warFriend[0].y == 5, "War mouse move did not refresh friend coordinates");
            require(editor.m_selectedPerson == -1, "War move did not clear selection by default");
            editor.m_keepSelection->setChecked(true);
            require(FileIO::readFileAll(config.iniPath).contains("selectcontinue=1")
                && FileIO::readFileAll(config.iniPath).contains("; keep"), "War selection mode did not persist safely");
            for (int scale : {1, 2, 3}) {
                editor.m_scaleSpin->setValue(scale);
                editor.drawWarPos();
                click(editor.m_warEnemy[0].x, editor.m_warEnemy[0].y);
                click(8 + scale, 9 + scale);
                require(editor.m_warFile.records[0].fields[2].values[0] == 8 + scale
                    && editor.m_warFile.records[0].fields[3].values[0] == 9 + scale
                    && editor.m_warEnemy[0].x == 8 + scale && editor.m_warEnemy[0].y == 9 + scale,
                    "Scaled war mouse move changed wrong enemy coordinates");
                require(editor.m_selectedPerson >= 0, "War move did not retain selection when enabled");
                QByteArray beforeInvalid = editor.stateBytes();
                click(-1, 0); click(64, 63);
                require(editor.stateBytes() == beforeInvalid, "Out-of-bounds war position click changed records");
            }
            editor.m_mapFieldPos = 4;
            editor.m_warMapData.num = 1;
            editor.m_warMapData.map.resize(1);
            editor.m_warMapData.map[0].x = 64;
            editor.m_warMapData.map[0].y = 64;
            editor.m_warMapData.map[0].layerNum = 0;
            editor.m_showMap->setChecked(true);
            editor.drawWarPos();
            require(editor.m_positionScale > 0 && editor.m_positionScale < 1,
                "War map preview did not exercise downscaled coordinates");
            click(editor.m_warFriend[0].x, editor.m_warFriend[0].y);
            click(20, 21);
            require(editor.m_warFile.records[0].fields[0].values[0] == 20
                && editor.m_warFile.records[0].fields[1].values[0] == 21,
                "Downscaled war map preview wrote incorrect coordinates");
            editor.onWarChanged(1);
            require(editor.m_selectedPerson == -1, "War selection leaked across records");
            WarEdit reopened;
            require(reopened.m_keepSelection->isChecked(), "War selection setting lost after reopen");
        }
        output << "PASS: war position mouse selection, movement, redraw and record switch\n";
        {
            auto &config = IniConfig::instance();
            QScopedValueRollback<QString> restorePath(config.gamePath, temporary.path());
            QScopedValueRollback<QString> restoreIdx(config.warMapDefIdx, "preview-map.idx");
            QScopedValueRollback<QString> restoreGrp(config.warMapDefGrp, "preview-map.grp");
            QString indexPath = temporary.filePath(config.warMapDefIdx), dataPath = temporary.filePath(config.warMapDefGrp);
            QByteArray data(16384, '\0');
            qToLittleEndian<qint16>(42, data.data() + (3 * 64 + 2) * 2);
            QByteArray index(8, '\0');
            qToLittleEndian<quint32>(16384, index.data());
            require(FileIO::writeFiles({{indexPath, index}, {dataPath, data}}), "Cannot create war preview map fixture");
            WarEdit editor;
            editor.readWarMapDef();
            auto preserved = [&] {
                return editor.m_warMapData.num == 1 && editor.m_warMapData.map.size() == 1
                    && editor.m_warMapData.map[0].mapLayer.size() == 2
                    && editor.m_warMapData.map[0].mapLayer[0].pic[2][3] == 42;
            };
            require(preserved(), "War preview map decoded wrong little-endian pixel");
            require(FileIO::writeFileAll(dataPath, data.chopped(1)), "Cannot truncate war preview map");
            editor.readWarMapDef();
            require(preserved(), "Truncated war preview map replaced active data");
            require(FileIO::writeFileAll(dataPath, data), "Cannot restore war preview map");
            for (const QByteArray &invalid : {QByteArray::fromHex("0040000001000000"),
                QByteArray::fromHex("0000000000400000"), QByteArray("bad")}) {
                require(FileIO::writeFileAll(indexPath, invalid), "Cannot write invalid preview map index");
                editor.readWarMapDef();
                require(preserved(), "Invalid war preview index replaced active map");
            }
            data.resize(24576);
            qToLittleEndian<qint16>(77, data.data() + 16384);
            index = QByteArray(4, '\0');
            qToLittleEndian<quint32>(data.size(), index.data());
            require(FileIO::writeFiles({{indexPath, index}, {dataPath, data}}), "Cannot create three-layer war map");
            WarMapEdit layered;
            require(layered.m_mapData.map.size() == 1 && layered.m_mapData.map[0].layerNum == 3
                && layered.m_mapData.map[0].mapLayer[2].pic[0][0] == 77, "Extra war map layer lost");
            QTimer::singleShot(0, [] {
                for (auto *widget : QApplication::topLevelWidgets())
                    if (auto *message = qobject_cast<QMessageBox *>(widget)) message->accept();
            });
            layered.onSaveMap();
            require(FileIO::readFileAll(dataPath) == data && FileIO::readFileAll(indexPath) == index,
                "Three-layer war map save lost bytes");
            for (const QByteArray &invalid : {QByteArray::fromHex("0060000001000000"),
                QByteArray::fromHex("0000000000600000"), QByteArray("bad")}) {
                require(FileIO::writeFileAll(indexPath, invalid), "Cannot create malformed war index");
                layered.readWarMapDef();
                require(layered.m_mapData.map.size() == 1 && layered.m_mapData.map[0].layerNum == 3
                    && layered.m_mapData.map[0].mapLayer[2].pic[0][0] == 77,
                    "Malformed index replaced active WarMapEdit data");
            }
        }
        output << "PASS: war preview map strict offsets, truncated input and active-map preservation\n";
        {
            RDataSingle field;
            field.dataLen = 8;
            const qint64 minimum = (std::numeric_limits<qint64>::min)();
            const qint64 maximum = (std::numeric_limits<qint64>::max)();
            for (auto boundary : {minimum, maximum}) {
                RFileIO::writeRDataInt(field, boundary);
                QByteArray original = field.data;
                require(!REditWidget::applyFieldOperation(field, boundary == minimum ? 2 : 1, "1")
                    && field.data == original, "Overflow changed field");
                require(!REditWidget::applyFieldOperation(field, 3, "2") && field.data == original, "Multiplication overflow accepted");
                require(!REditWidget::applyFieldOperation(field, 4, "0") && field.data == original, "Division by zero accepted");
            }
            RFileIO::writeRDataInt(field, minimum);
            require(!REditWidget::applyFieldOperation(field, 4, "-1"), "Minimum divided by minus one accepted");
            RFileIO::writeRDataInt(field, -12);
            require(REditWidget::applyFieldOperation(field, 3, "-3") && RFileIO::readRDataInt(field) == 36, "Signed multiplication failed");
            field.dataLen = 2;
            RFileIO::writeRDataInt(field, 32767);
            require(!REditWidget::applyFieldOperation(field, 1, "1") && RFileIO::readRDataInt(field) == 32767, "Short integer overflow accepted");
            require(REditWidget::applyFieldOperation(field, 0, "-32768") && RFileIO::readRDataInt(field) == -32768, "Short integer assignment failed");
        }
        output << "PASS: R batch arithmetic boundaries, signed multiplication and failure preservation\n";
        {
            REditWidget editor;
            editor.m_currentType = 0;
            editor.m_currentRecord = 0;
            editor.m_rFile.rType.resize(1);
            editor.m_rFile.rType[0].rData.resize(1);
            auto &record = editor.m_rFile.rType[0].rData[0];
            record.rDataLine.resize(2);
            for (auto &line : record.rDataLine) {
                line.rArray.resize(1);
                line.rArray[0].dataArray.resize(2);
                for (auto &field : line.rArray[0].dataArray) {
                    field.dataType = 0;
                    field.dataLen = 2;
                    RFileIO::writeRDataInt(field, 10);
                }
            }
            QPushButton *openBatch = nullptr;
            for (auto *button : editor.findChildren<QPushButton *>())
                if (button->text() == QString::fromUtf8("当前记录字段批量")) openBatch = button;
            require(openBatch != nullptr, "R field batch command unavailable");
            bool controlsValid = false;
            QTimer::singleShot(0, [&] {
                auto *dialog = qobject_cast<QDialog *>(QApplication::activeModalWidget());
                if (!dialog) return;
                auto *list = dialog->findChild<QListWidget *>();
                auto ranges = dialog->findChildren<QSpinBox *>();
                auto *operation = dialog->findChild<QComboBox *>();
                auto *value = dialog->findChild<QLineEdit *>();
                if (!list || list->count() != 4 || ranges.size() != 2 || !operation || !value) {
                    dialog->reject(); return;
                }
                auto click = [&](const QString &text) {
                    for (auto *button : dialog->findChildren<QPushButton *>())
                        if (button->text() == text) { button->click(); return true; }
                    return false;
                };
                ranges[0]->setValue(2);
                ranges[1]->setValue(1);
                controlsValid = click(QString::fromUtf8("选择范围"))
                    && list->item(0)->checkState() == Qt::Unchecked
                    && list->item(1)->checkState() == Qt::Checked
                    && list->item(2)->checkState() == Qt::Checked
                    && list->item(3)->checkState() == Qt::Unchecked;
                controlsValid = click(QString::fromUtf8("反选")) && controlsValid
                    && list->item(0)->checkState() == Qt::Checked
                    && list->item(1)->checkState() == Qt::Unchecked
                    && list->item(2)->checkState() == Qt::Unchecked
                    && list->item(3)->checkState() == Qt::Checked;
                operation->setCurrentIndex(1);
                value->setText("5");
                if (!click(QString::fromUtf8("执行"))) dialog->reject();
            });
            openBatch->click();
            require(controlsValid
                && RFileIO::readRDataInt(record.rDataLine[0].rArray[0].dataArray[0]) == 15
                && RFileIO::readRDataInt(record.rDataLine[0].rArray[0].dataArray[1]) == 10
                && RFileIO::readRDataInt(record.rDataLine[1].rArray[0].dataArray[0]) == 10
                && RFileIO::readRDataInt(record.rDataLine[1].rArray[0].dataArray[1]) == 15,
                "R field batch range/inversion modified wrong fields");
            QByteArray beforeCancel = editor.stateBytes();
            QTimer::singleShot(0, [] {
                if (auto *dialog = qobject_cast<QDialog *>(QApplication::activeModalWidget())) dialog->reject();
            });
            openBatch->click();
            require(editor.stateBytes() == beforeCancel, "Cancelled R field batch changed data");
        }
        output << "PASS: R field batch dialog range, inversion, compound fields and cancellation\n";
        {
            auto &config = IniConfig::instance();
            QScopedValueRollback<QString> gamePath(config.gamePath, temporary.path());
            QScopedValueRollback<QString> leavePath(config.leaveListFile, "relation-leave.dat");
            QScopedValueRollback<QString> effectPath(config.effectListFile, "relation-effect.dat");
            QScopedValueRollback<QString> matchPath(config.matchListFile, "relation-match.dat");
            QScopedValueRollback<QString> expPath(config.expListFile, "relation-exp.dat");
            QScopedValueRollback<RFile> rFile(config.rGlobals.rFile);
            config.rGlobals.rFile.rType.resize(5);
            for (int type : {1, 2, 4}) config.rGlobals.rFile.rType[type].rData.resize(2);
            require(FileIO::writeFiles({
                {temporary.filePath(config.leaveListFile), QByteArray(200, '\0')},
                {temporary.filePath(config.effectListFile), QByteArray(400, '\0')},
                {temporary.filePath(config.matchListFile), QByteArray(600, '\0')},
                {temporary.filePath(config.expListFile), QByteArray(200, '\0')}}),
                "Cannot create relation list fixtures");
            ReplicatedList editor;
            editor.m_leaveScroll->setValue(3);
            editor.m_leaveCombo->setCurrentIndex(editor.m_leaveCombo->findData(1));
            QMetaObject::invokeMethod(editor.m_leaveCombo, "activated", Qt::DirectConnection,
                Q_ARG(int, editor.m_leaveCombo->currentIndex()));
            editor.m_matchScroll->setValue(2);
            for (auto *combo : {editor.m_matchWeaponCombo, editor.m_matchSkillCombo}) {
                combo->setCurrentIndex(combo->findData(1));
                QMetaObject::invokeMethod(combo, "activated", Qt::DirectConnection, Q_ARG(int, combo->currentIndex()));
            }
            editor.m_effectScroll->setValue(4);
            editor.m_expScroll->setValue(5);
            for (auto *edit : {editor.m_effectEdit, editor.m_matchValueEdit, editor.m_expEdit}) {
                edit->setText("-32768");
                QMetaObject::invokeMethod(edit, "textEdited", Qt::DirectConnection, Q_ARG(QString, edit->text()));
            }
            editor.m_effectScroll->setValue(0);
            editor.m_effectScroll->setValue(4);
            require(editor.m_effectEdit->text() == "-32768" && editor.m_leaveList[3] == 1
                && editor.m_matchList[6] == 1 && editor.m_matchList[7] == 1,
                "Relation controls did not write selected references or preserve scrolling edits");
            QTimer::singleShot(0, [] {
                for (auto *widget : QApplication::topLevelWidgets())
                    if (auto *message = qobject_cast<QMessageBox *>(widget); message && message->isVisible())
                        if (auto *button = message->button(QMessageBox::Ok)) button->click();
            });
            editor.onSave();
            QByteArray leave = FileIO::readFileAll(temporary.filePath(config.leaveListFile));
            QByteArray effect = FileIO::readFileAll(temporary.filePath(config.effectListFile));
            QByteArray match = FileIO::readFileAll(temporary.filePath(config.matchListFile));
            QByteArray exp = FileIO::readFileAll(temporary.filePath(config.expListFile));
            require(leave.size() == 200 && effect.size() == 400 && match.size() == 600 && exp.size() == 200
                && qFromLittleEndian<qint16>(leave.constData() + 6) == 1
                && qFromLittleEndian<qint16>(effect.constData() + 8) == -32768
                && qFromLittleEndian<qint16>(match.constData() + 12) == 1
                && qFromLittleEndian<qint16>(match.constData() + 16) == -32768
                && qFromLittleEndian<qint16>(exp.constData() + 10) == -32768,
                "Relation four-file save changed layout or lost edits");
            editor.m_expList[5] = 12;
            editor.show();
            auto answerClose = [](QMessageBox::StandardButton choice) {
                QTimer::singleShot(0, [choice] {
                    for (auto *widget : QApplication::topLevelWidgets())
                        if (auto *message = qobject_cast<QMessageBox *>(widget); message && message->isVisible())
                            if (auto *button = message->button(choice)) button->click();
                });
            };
            answerClose(QMessageBox::Cancel);
            require(!editor.close() && editor.isVisible() && editor.m_expList[5] == 12,
                "Cancelled relation close discarded edits");
            answerClose(QMessageBox::Discard);
            require(editor.close() && FileIO::readFileAll(temporary.filePath(config.expListFile)) == exp,
                "Discard relation close unexpectedly saved changes");
            require(FileIO::writeFileAll(temporary.filePath(config.effectListFile), effect.chopped(1)),
                "Cannot truncate relation fixture");
            ReplicatedList invalid;
            require(!invalid.m_loadValid, "Truncated relation list accepted");
            QTimer::singleShot(0, [] {
                for (auto *widget : QApplication::topLevelWidgets())
                    if (auto *message = qobject_cast<QMessageBox *>(widget); message && message->isVisible())
                        if (auto *button = message->button(QMessageBox::Ok)) button->click();
            });
            invalid.onSave();
            require(FileIO::readFileAll(temporary.filePath(config.effectListFile)) == effect.chopped(1)
                && FileIO::readFileAll(temporary.filePath(config.leaveListFile)) == leave,
                "Invalid relation load allowed destructive save");
        }
        output << "PASS: relation list references, numeric controls, scrolling and four-file save\n";
        {
            RFile records;
            records.rType.resize(1);
            records.rType[0].rData.resize(1);
            auto &record = records.rType[0].rData[0];
            record.rDataLine.resize(1);
            record.rDataLine[0].rArray.resize(1);
            auto &fields = record.rDataLine[0].rArray[0].dataArray;
            fields.resize(2);
            fields[0].dataType = 0;
            fields[0].dataLen = 2;
            fields[0].data = QByteArray(2, '\0');
            fields[1].dataType = 1;
            fields[1].dataLen = 8;
            fields[1].data = QByteArray(8, '\0');
            RFileIO::writeRDataInt(fields[0], 7);
            RFileIO::writeRDataStr(fields[1], "text");
            REditForm editor;
            editor.setRFile(&records);
            editor.displayRecord(0, 0);
            auto *table = editor.findChild<QTableWidget *>();
            require(table && table->rowCount() == 2, "R detail fields missing");
            table->item(0, 1)->setText("32768");
            require(RFileIO::readRDataInt(fields[0]) == 7 && table->item(0, 1)->text() == "7",
                "R detail accepted integer overflow");
            table->item(0, 1)->setText("-32768");
            table->item(1, 1)->setText("");
            require(RFileIO::readRDataInt(fields[0]) == -32768 && RFileIO::readRDataStr(fields[1]).isEmpty(),
                "R detail rejected lower boundary or empty text");
        }
        output << "PASS: R detail numeric boundaries and empty text editing\n";
        {
            auto &globals = IniConfig::instance().rGlobals;
            QScopedValueRollback<RFileGlobals> restoreGlobals(globals);
            globals.rIni.resize(1);
            globals.rIni[0].rTerm.resize(1);
            globals.rIni[0].rTerm[0].quote = 1;
            RFile records;
            records.rType.resize(2);
            records.rType[0].rData.resize(1);
            records.rType[1].rData.resize(129);
            records.rType[0].rData[0].rDataLine.resize(1);
            auto &line = records.rType[0].rData[0].rDataLine[0];
            line.rArray.resize(1);
            line.rArray[0].dataArray.resize(1);
            auto &field = line.rArray[0].dataArray[0];
            field.dataType = 0;
            field.dataLen = 1;
            RFileIO::writeRDataInt(field, 7);
            REditForm editor;
            editor.setRFile(&records);
            editor.displayRecord(0, 0);
            auto selectReference = [](int selectedIndex, bool expectWarning) {
                QTimer::singleShot(0, [selectedIndex, expectWarning] {
                    for (auto *widget : QApplication::topLevelWidgets()) {
                        auto *dialog = qobject_cast<QInputDialog *>(widget);
                        if (!dialog || !dialog->isVisible()) continue;
                        auto *combo = dialog->findChild<QComboBox *>();
                        if (!combo) continue;
                        combo->setCurrentIndex(selectedIndex + 1);
                        if (expectWarning) QTimer::singleShot(0, [] {
                            for (auto *messageWidget : QApplication::topLevelWidgets())
                                if (auto *message = qobject_cast<QMessageBox *>(messageWidget))
                                    if (message->button(QMessageBox::Ok)) message->button(QMessageBox::Ok)->click();
                        });
                        dialog->accept();
                    }
                });
            };
            selectReference(128, true);
            require(QMetaObject::invokeMethod(&editor, "onCellDoubleClicked", Qt::DirectConnection,
                Q_ARG(int, 0), Q_ARG(int, 1)) && RFileIO::readRDataInt(field) == 7,
                "Reference picker truncated an out-of-range byte value");
            selectReference(127, false);
            require(QMetaObject::invokeMethod(&editor, "onCellDoubleClicked", Qt::DirectConnection,
                Q_ARG(int, 0), Q_ARG(int, 1)) && RFileIO::readRDataInt(field) == 127,
                "Reference picker rejected the largest byte reference");
        }
        output << "PASS: R reference picker byte boundary and overflow preservation\n";
        {
            ImagezForm editor;
            editor.m_imz.imzPng.resize(1);
            editor.m_imz.pngNum = 1;
            editor.m_currentIndex = 0;
            bool opened = false, safeControls = false;
            QTimer::singleShot(0, [&] {
                for (auto *widget : QApplication::topLevelWidgets()) {
                    auto *dialog = qobject_cast<QDialog *>(widget);
                    if (!dialog || !dialog->isVisible() || dialog->parentWidget() != &editor) continue;
                    opened = true;
                    auto buttons = dialog->findChildren<QPushButton *>();
                    int enabledOperations = 0, disabledOperations = 0;
                    for (auto *button : buttons) {
                        if (button->text() == QString::fromUtf8("插入") || button->text() == QString::fromUtf8("追加"))
                            enabledOperations += button->isEnabled();
                        if (button->text() == QString::fromUtf8("替换") || button->text() == QString::fromUtf8("删除")
                            || button->text() == QString::fromUtf8("导出")) disabledOperations += !button->isEnabled();
                    }
                    safeControls = enabledOperations == 2 && disabledOperations == 3;
                    auto spins = dialog->findChildren<QSpinBox *>();
                    for (auto *spin : spins) if (spin->minimum() == -32768) spin->setValue(-12);
                    dialog->accept();
                }
            });
            editor.onEditSprite();
            require(opened && safeControls && editor.m_imz.imzPng[0].x == -12
                && editor.m_imz.imzPng[0].y == -12 && editor.m_imz.imzPng[0].frameData.isEmpty(),
                "Empty sprite editor inaccessible or unsafe controls enabled");
            QTimer::singleShot(0, [&] {
                for (auto *widget : QApplication::topLevelWidgets()) {
                    auto *dialog = qobject_cast<QDialog *>(widget);
                    if (!dialog || !dialog->isVisible() || dialog->parentWidget() != &editor) continue;
                    for (auto *spin : dialog->findChildren<QSpinBox *>())
                        if (spin->minimum() == -32768) spin->setValue(20);
                    dialog->reject();
                }
            });
            editor.onEditSprite();
            require(editor.m_imz.imzPng[0].x == -12 && editor.m_imz.imzPng[0].frameData.isEmpty(),
                "Cancelling empty sprite edit changed data");
        }
        output << "PASS: empty sprite frame editor controls, offsets and cancel preservation\n";
        {
            bool native = QApplication::testAttribute(Qt::AA_DontUseNativeDialogs);
            QApplication::setAttribute(Qt::AA_DontUseNativeDialogs, true);
            QString path = temporary.filePath("direct-sprite.png");
            QImage image(12, 10, QImage::Format_ARGB32);
            image.fill(Qt::green);
            require(image.save(path), "Cannot create direct sprite fixture");
            ImagezForm editor;
            auto choose = [path](bool cancel) {
                QTimer::singleShot(0, [path, cancel] {
                    for (auto *widget : QApplication::topLevelWidgets())
                        if (auto *dialog = qobject_cast<QFileDialog *>(widget); dialog && dialog->isVisible()) {
                            if (cancel) dialog->reject();
                            else {
                                dialog->selectFile(path);
                                QMetaObject::invokeMethod(dialog, "accept", Qt::DirectConnection);
                            }
                        }
                });
            };
            choose(false); editor.insertPNG(true);
            editor.m_imz.imzPng[0].fileNum = 7;
            choose(false); editor.insertPNG(false);
            require(editor.m_imz.pngNum == 2 && editor.m_imz.imzPng[1].fileNum == 7
                && editor.m_imz.imzPng[0].frameData[0].data == FileIO::readFileAll(path),
                "Direct PNG insertion lost bytes or changed following ID");
            QByteArray state = editor.stateBytes();
            choose(true); editor.insertPNG(true);
            require(editor.stateBytes() == state, "Cancelled direct PNG import changed data");
            editor.m_currentIndex = 0;
            editor.m_imz.imzPng[0].frameData.append(editor.m_imz.imzPng[0].frameData[0]);
            bool clicked = false;
            QTimer::singleShot(0, [&] {
                for (auto *widget : QApplication::topLevelWidgets()) {
                    auto *dialog = qobject_cast<QDialog *>(widget);
                    if (!dialog || !dialog->isVisible() || dialog->parentWidget() != &editor) continue;
                    auto *frames = dialog->findChild<QListWidget *>("spriteFrames");
                    auto *preview = dialog->findChild<QLabel *>("spritePreview");
                    if (!frames || !preview || frames->count() != 2) { dialog->reject(); return; }
                    frames->setCurrentRow(1);
                    QPointF point(4, 5);
                    QMouseEvent event(QEvent::MouseButtonPress, point, point, Qt::LeftButton, Qt::LeftButton, Qt::NoModifier);
                    QCoreApplication::sendEvent(preview, &event);
                    clicked = frames->currentRow() == 1;
                    dialog->accept();
                }
            });
            editor.onEditSprite();
            QApplication::setAttribute(Qt::AA_DontUseNativeDialogs, native);
            require(clicked && editor.m_imz.imzPng[0].x == 4 && editor.m_imz.imzPng[0].y == 5,
                "Sprite thumbnails or preview offset click failed");
        }
        output << "PASS: direct PNG insertion/cancel, frame thumbnails and preview offset click\n";
        {
            bool nativeDialogsDisabled = QApplication::testAttribute(Qt::AA_DontUseNativeDialogs);
            QApplication::setAttribute(Qt::AA_DontUseNativeDialogs, true);
            QString framePath = temporary.filePath("frame-ui.png");
            QImage image(3, 2, QImage::Format_ARGB32);
            image.fill(Qt::cyan);
            require(image.save(framePath), "Cannot create frame UI fixture");
            QByteArray frameBytes = FileIO::readFileAll(framePath);
            QString replacementPath = temporary.filePath("frame-replacement.png");
            QString exportedPath = temporary.filePath("frame-export.png");
            image.fill(Qt::magenta);
            require(image.save(replacementPath), "Cannot create replacement frame");
            ImagezForm editor;
            editor.m_imz.imzPng.resize(1);
            editor.m_imz.pngNum = 1;
            editor.m_currentIndex = 0;
            bool controlsWorked = false;
            auto editFrames = [&](bool acceptChanges) {
                QFile::remove(exportedPath);
                QTimer::singleShot(0, [&, acceptChanges] {
                    for (auto *widget : QApplication::topLevelWidgets()) {
                        auto *dialog = qobject_cast<QDialog *>(widget);
                        if (!dialog || !dialog->isVisible() || dialog->parentWidget() != &editor) continue;
                        auto click = [&](const QString &text, const QString &selectedPath) {
                            for (auto *button : dialog->findChildren<QPushButton *>()) {
                                if (button->text() != text || !button->isEnabled()) continue;
                                if (!selectedPath.isEmpty()) QTimer::singleShot(0, [selectedPath] {
                                    for (auto *candidate : QApplication::topLevelWidgets())
                                        if (auto *fileDialog = qobject_cast<QFileDialog *>(candidate)) {
                                            if (!fileDialog->isVisible()) continue;
                                            fileDialog->selectFile(selectedPath);
                                            QMetaObject::invokeMethod(fileDialog, "accept", Qt::DirectConnection);
                                        }
                                });
                                button->click();
                                return true;
                            }
                            return false;
                        };
                        controlsWorked = click(QString::fromUtf8("追加"), framePath)
                            && click(QString::fromUtf8("插入"), replacementPath);
                        auto *frameSpin = dialog->findChild<QSpinBox *>();
                        if (frameSpin) frameSpin->setValue(1);
                        controlsWorked = controlsWorked && click(QString::fromUtf8("替换"), replacementPath)
                            && click(QString::fromUtf8("导出"), exportedPath)
                            && click(QString::fromUtf8("删除"), QString());
                        if (acceptChanges) dialog->accept(); else dialog->reject();
                    }
                });
                editor.onEditSprite();
            };
            editFrames(false);
            bool cancelled = controlsWorked && editor.m_imz.imzPng[0].frameData.isEmpty();
            editFrames(true);
            QApplication::setAttribute(Qt::AA_DontUseNativeDialogs, nativeDialogsDisabled);
            const auto &sprite = editor.m_imz.imzPng[0];
            require(cancelled && controlsWorked && sprite.frame == 1 && sprite.frameData.size() == 1
                && sprite.frameData[0].data == FileIO::readFileAll(replacementPath)
                && FileIO::readFileAll(exportedPath) == sprite.frameData[0].data
                && sprite.frameLen[0] == sprite.frameData[0].data.size()
                && sprite.len == sprite.frameData[0].data.size(), "Frame UI operations or cancel corrupted sprite");
        }
        output << "PASS: sprite frame UI file selection, append, insert, delete and cancellation\n";
        {
            auto *clipboard = QApplication::clipboard();
            auto *original = new QMimeData;
            if (const auto *mime = clipboard->mimeData())
                for (const auto &format : mime->formats()) original->setData(format, mime->data(format));
            ImagezForm source, target;
            source.m_imz.imzPng.resize(1);
            target.m_imz.imzPng.resize(1);
            source.m_imz.pngNum = target.m_imz.pngNum = 1;
            source.m_currentIndex = target.m_currentIndex = 0;
            auto &sprite = source.m_imz.imzPng[0];
            sprite.x = -123; sprite.y = 321; sprite.fileNum = 8;
            target.m_imz.imzPng[0].fileNum = 99;
            for (const auto &color : {QColor(Qt::red), QColor(Qt::green)}) {
                QImage frame(2, 3, QImage::Format_ARGB32);
                frame.fill(color);
                QByteArray bytes;
                QBuffer buffer(&bytes);
                buffer.open(QIODevice::WriteOnly);
                require(frame.save(&buffer, "PNG"), "Cannot create clipboard frame");
                sprite.frameData.append({bytes});
            }
            source.onCopySprite();
            QByteArray payload = clipboard->mimeData()->data("application/x-upedit-sprite");
            target.onPasteSprite();
            bool valid = target.m_imz.imzPng[0].fileNum == 99
                && target.m_imz.imzPng[0].x == -123 && target.m_imz.imzPng[0].y == 321
                && target.m_imz.imzPng[0].frameData.size() == 2
                && target.m_imz.imzPng[0].frameData[1].data == sprite.frameData[1].data;
            QByteArray state = target.stateBytes();
            for (const auto &invalid : {payload.chopped(1), payload + "trailing"}) {
                auto *mime = new QMimeData;
                mime->setData("application/x-upedit-sprite", invalid);
                clipboard->setMimeData(mime);
                target.onPasteSprite();
                valid = valid && target.stateBytes() == state;
            }
            sprite.frameData.clear();
            source.onCopySprite();
            target.onPasteSprite();
            valid = valid && target.m_imz.imzPng[0].frameData.isEmpty()
                && target.m_imz.imzPng[0].fileNum == 99 && target.m_imz.imzPng[0].x == -123;
            clipboard->setMimeData(original);
            require(valid, "Cross-window sprite clipboard changed frames, offsets, ID or accepted invalid data");
        }
        output << "PASS: cross-window sprite clipboard, empty frames and malformed payload preservation\n";
        {
            ImagezForm editor;
            editor.m_imz.imzPng.resize(3);
            editor.m_imz.pngNum = 3;
            for (int index = 0; index < 3; ++index) {
                editor.m_imz.imzPng[index].fileNum = index * 3;
                editor.m_imz.imzPng[index].x = 10;
                editor.m_imz.imzPng[index].y = 20;
            }
            require(editor.applyBatchOffset(2, 1, 0, 1, 5)
                && editor.m_imz.imzPng[0].x == 10 && editor.m_imz.imzPng[1].x == 15
                && editor.m_imz.imzPng[2].y == 20, "Container batch range or axis isolation failed");
            require(editor.applyBatchOffset(1, 2, 2, 0, 8)
                && editor.applyBatchOffset(1, 2, 2, 2, 2)
                && editor.applyBatchOffset(1, 2, 2, 3, 3)
                && editor.applyBatchOffset(1, 2, 2, 4, 2)
                && editor.m_imz.imzPng[1].x == 9 && editor.m_imz.imzPng[2].y == 9,
                "Container batch arithmetic failed");
            QByteArray state = editor.stateBytes();
            require(!editor.applyBatchOffset(0, 2, 2, 4, 0)
                && !editor.applyBatchOffset(0, 2, 2, 3, 32767) && editor.stateBytes() == state,
                "Invalid container batch operation partially changed data");
            auto setCount = [&](int count, bool accept) {
                QTimer::singleShot(0, [count, accept] {
                    for (auto *widget : QApplication::topLevelWidgets())
                        if (auto *dialog = qobject_cast<QInputDialog *>(widget); dialog && dialog->isVisible()) {
                            dialog->setIntValue(count);
                            if (accept) dialog->accept(); else dialog->reject();
                        }
                });
                editor.onSetSpriteCount();
            };
            setCount(5, false);
            require(editor.stateBytes() == state, "Cancelled container resize changed data");
            setCount(5, true);
            require(editor.m_imz.pngNum == 5 && editor.m_imz.imzPng[2].fileNum == 6
                && editor.m_imz.imzPng[3].fileNum == 7 && editor.m_imz.imzPng[4].fileNum == 8,
                "Growing container changed sparse IDs");
            QTimer confirmations;
            confirmations.setInterval(10);
            QObject::connect(&confirmations, &QTimer::timeout, &confirmations, [] {
                for (auto *widget : QApplication::topLevelWidgets())
                    if (auto *message = qobject_cast<QMessageBox *>(widget); message && message->isVisible())
                        if (auto *yes = message->button(QMessageBox::Yes)) yes->click();
            });
            confirmations.start();
            setCount(2, true);
            confirmations.stop();
            require(editor.m_imz.pngNum == 2 && editor.m_imz.imzPng.size() == 2
                && editor.m_imz.imzPng[1].fileNum == 3 && editor.m_imz.imzPng[1].x == 9,
                "Shrinking container damaged retained sprites");
        }
        output << "PASS: container batch arithmetic, atomic rejection, count growth/shrink and cancellation\n";
        {
            auto &config = IniConfig::instance();
            QScopedValueRollback<int> count(config.rFileNum, 0);
            QScopedValueRollback<QVector<QString>> dataPaths(config.rFileName, {"missing.grp"});
            QScopedValueRollback<QVector<QString>> indexPaths(config.rIdxFileName, {"missing.idx"});
            REditWidget editor;
            editor.m_rFile.typeNumber = 1;
            editor.m_rFile.rType.resize(1);
            editor.m_loadedSlot = 0;
            editor.m_savedState = editor.stateBytes();
            require(editor.confirmDiscard(), "Unchanged R record prompted");
            editor.m_rFile.rType[0].rData.resize(1);
            QByteArray dirty = editor.stateBytes();
            require(dirty != editor.m_savedState, "R record insertion not detected");
            QTimer::singleShot(0, [] {
                for (QWidget *widget : QApplication::topLevelWidgets())
                    if (auto *message = qobject_cast<QMessageBox *>(widget)) message->button(QMessageBox::Cancel)->click();
            });
            require(!editor.confirmDiscard() && editor.stateBytes() == dirty, "Cancel discarded R edits");
            config.rFileNum = 1;
            RFileGlobals previous = config.rGlobals;
            editor.loadProgress(0);
            require(editor.stateBytes() == dirty && config.rGlobals.typeNumber == previous.typeNumber,
                "Failed R loading destroyed working record or schema");
        }
        output << "PASS: R unsaved detection, cancel dialog and failed-load preservation\n";
        for (int layers : {2, 5, 6}) {
            Map source;
            require(MapIO::readSingleMap(QByteArray(2 * 3 * layers * 2, '\0'), 0, source, layers, 2, 3), "Map initialization failed");
            for (int layer = 0; layer < layers; ++layer)
                for (int column = 0; column < 2; ++column)
                    for (int row = 0; row < 3; ++row) source.mapLayer[layer].pic[column][row] = layer * 100 + row * 10 + column - 5;
            QByteArray encoded = MapIO::encodeMap(source, true);
            require(encoded.size() == 8 + layers * 12 && qFromLittleEndian<qint32>(encoded.constData()) == 2
                && qFromLittleEndian<qint32>(encoded.constData() + 4) == 3, "Module header mismatch");
            require(qFromLittleEndian<qint16>(encoded.constData() + 12) == 5, "Map row order transposed");
            Map decoded;
            require(MapIO::decodeModule(encoded, layers, decoded), "Module decoding failed");
            require(MapIO::encodeMap(decoded, true) == encoded, "Module roundtrip mismatch");
            require(!MapIO::decodeModule(encoded.chopped(1), layers, decoded), "Truncated module accepted");
            QByteArray invalid = encoded;
            qToLittleEndian<qint32>(1000000, invalid.data());
            require(!MapIO::decodeModule(invalid, layers, decoded), "Oversized module accepted");
            Map region = MapIO::extractRegion(source, QRect(QPoint(1, 1), QPoint(1, 2)));
            require(region.x == 1 && region.y == 2 && region.mapLayer[0].pic[0][1] == 16, "Region extraction mismatch");
            MapIO::pasteRegion(source, region, QPoint(0, 1));
            require(source.mapLayer[0].pic[0][0] == 6 && source.mapLayer[0].pic[0][1] == 16, "Region anchor mismatch");
            MapIO::pasteRegion(source, region, QPoint(-1, -1));
        }
        output << "PASS: WMD/MMD/SMD non-square roundtrip, truncation, bounds and clipboard\n";
        Map visual;
        MapIO::readSingleMap(QByteArray(3 * 2 * 3 * 2, '\0'), 0, visual, 3, 2, 3);
        {
            Map target = visual;
            target.mapLayer[0].pic[0][0] = 123;
            QByteArray bytes(37, '\0');
            qToLittleEndian<qint16>(-321, bytes.data() + 1);
            require(!MapIO::readSingleMap(bytes.left(35), 0, target, 3, 2, 3)
                && !MapIO::readSingleMap(bytes, -1, target, 3, 2, 3)
                && !MapIO::readSingleMap(bytes, 38, target, 3, 2, 3)
                && !MapIO::readSingleMap(bytes, 0, target, 3, 0, 3)
                && !MapIO::readSingleMap(bytes, 0, target, 65, 2, 3)
                && target.x == 2 && target.y == 3 && target.mapLayer[0].pic[0][0] == 123,
                "Invalid raw map input modified the destination");
            require(MapIO::readSingleMap(bytes, 1, target, 3, 2, 3)
                && target.mapLayer[0].pic[0][0] == -321, "Unaligned map input lost little-endian signed values");
        }
        QVector<QImage> tiles(2);
        tiles[1] = QImage(4, 4, QImage::Format_ARGB32);
        tiles[1].fill(Qt::red);
        visual.mapLayer[0].pic[1][2] = 2;
        QImage visible = MapIO::renderMainMap(visual, tiles, {}, true, false, false);
        QImage hidden = MapIO::renderMainMap(visual, tiles, {}, false, false, false);
        require(!visible.isNull() && visible.size() == QSize(170, 105), "Full map dimensions wrong");
        require(visible.pixelColor(85, 57).alpha() == 255 && hidden.pixelColor(85, 57).alpha() == 0, "Layer selection or pixels wrong");
        int lastProgress = -1;
        bool cancelled = false;
        QImage interrupted = MapIO::renderMainMap(visual, tiles, {}, true, true, true, 1, 100, [&](int progress) {
            require(progress >= lastProgress, "Map progress moved backwards");
            lastProgress = progress;
            if (progress >= 30) { cancelled = true; return false; }
            return true;
        });
        require(cancelled && interrupted.isNull(), "Cancelled map rendering returned partial output");
        require(!MapIO::renderMainMap(visual, tiles, {}, true, true, true, 1, 100, [&](int progress) {
            lastProgress = progress; return true;
        }).isNull() && lastProgress == 100, "Map completion progress missing");
        output << "PASS: full-map dimensions, visible sprite pixels and layer toggles\n";
        {
            Map malformed = visual;
            malformed.mapLayer[0].pic[0].clear();
            require(MapIO::renderMainMap(malformed, tiles, {}, true, true, true).isNull()
                && MapIO::renderMainMap(visual, tiles, {}, true, true, true, INT_MAX, INT_MAX).isNull(),
                "Invalid full map structure or scale was accepted");
            OutputMap exporter;
            bool nativeFontDialogsDisabled = QApplication::testAttribute(Qt::AA_DontUseNativeDialogs);
            QApplication::setAttribute(Qt::AA_DontUseNativeDialogs, true);
            QFont selectedFont("Courier New", 17);
            selectedFont.setBold(true);
            auto selectFont = [&](bool accepted) {
                QTimer::singleShot(0, [selectedFont, accepted] {
                    for (auto *widget : QApplication::topLevelWidgets())
                        if (auto *dialog = qobject_cast<QFontDialog *>(widget); dialog && dialog->isVisible()) {
                            dialog->setCurrentFont(selectedFont);
                            if (accepted) dialog->accept(); else dialog->reject();
                        }
                });
                exporter.onSelectFont();
            };
            QFont originalFont = exporter.m_mapFont;
            selectFont(false);
            bool fontValid = exporter.m_mapFont == originalFont;
            selectFont(true);
            fontValid = fontValid && exporter.m_mapFont.pointSize() == 17 && exporter.m_mapFont.bold();
            QApplication::setAttribute(Qt::AA_DontUseNativeDialogs, nativeFontDialogsDisabled);
            require(fontValid, "Full map font dialog cancellation or selection changed wrong state");
            exporter.setMapData(visual, tiles, {}, 1);
            QString pngPath = temporary.filePath("full-map.png");
            exporter.m_fileEdit->setText(pngPath);
            exporter.m_surfaceCheck->setChecked(false);
            exporter.m_buildingCheck->setChecked(false);
            exporter.onExport();
            require(QImage(pngPath).convertToFormat(QImage::Format_ARGB32) == visible,
                "Full map dialog PNG output changed layer pixels");
            QString bmpPath = temporary.filePath("full-map.bmp");
            exporter.m_fileEdit->setText(bmpPath);
            exporter.onExport();
            QImage bitmap(bmpPath);
            require(!bitmap.isNull() && bitmap.size() == visible.size()
                && bitmap.pixelColor(0, 0) == QColor(Qt::black) && bitmap.pixelColor(85, 57) == QColor(Qt::red),
                "Full map BMP output lost opaque background or sprite pixels");
            QString invalidPath = temporary.filePath("full-map.invalid-format");
            require(FileIO::writeFileAll(invalidPath, "existing output"), "Cannot create previous full map output");
            exporter.m_fileEdit->setText(invalidPath);
            QTimer dismissExportError;
            QObject::connect(&dismissExportError, &QTimer::timeout, [] {
                for (auto *widget : QApplication::topLevelWidgets())
                    if (auto *message = qobject_cast<QMessageBox *>(widget); message && message->isVisible())
                        if (auto *ok = message->button(QMessageBox::Ok)) ok->click();
            });
            dismissExportError.start(10);
            exporter.onExport();
            dismissExportError.stop();
            require(FileIO::readFileAll(invalidPath) == "existing output" && !exporter.m_exporting,
                "Failed full map encoding damaged existing output or left export locked");
            auto &globals = IniConfig::instance().rGlobals;
            QScopedValueRollback<RFile> restoreRecords(globals.rFile);
            globals.rFile.rType.resize(4);
            auto &scenes = globals.rFile.rType[3];
            scenes.namePos = 0;
            scenes.rData.resize(1);
            scenes.rData[0].rDataLine.resize(8);
            for (auto &line : scenes.rData[0].rDataLine) {
                line.rArray.resize(1);
                line.rArray[0].dataArray.resize(1);
                line.rArray[0].dataArray[0].dataLen = 8;
            }
            auto &fields = scenes.rData[0].rDataLine;
            auto &name = fields[0].rArray[0].dataArray[0];
            name.dataLen = 64;
            RFileIO::writeRDataStr(name, "Scene");
            RFileIO::writeRDataInt(fields[6].rArray[0].dataArray[0], 1);
            RFileIO::writeRDataInt(fields[7].rArray[0].dataArray[0], 1);
            exporter.m_fileEdit->setText(pngPath);
            exporter.m_drawNamesCheck->setChecked(true);
            exporter.m_mapFont = QFont("Segoe UI", 12);
            exporter.m_mapColor = Qt::green;
            exporter.onExport();
            require(QImage(pngPath).convertToFormat(QImage::Format_ARGB32) != visible,
                "Enabled scene names did not change exported pixels");
            RFileIO::writeRDataInt(fields[6].rArray[0].dataArray[0], (std::numeric_limits<qint64>::max)());
            exporter.onExport();
            require(QImage(pngPath).convertToFormat(QImage::Format_ARGB32) == visible,
                "Out-of-range scene coordinate drew an unexpected label");
            exporter.m_zoomEdit->setText("200");
            exporter.onExport();
            require(QImage(pngPath).size() == visible.size() * 2, "Full map dialog zoom did not resize exported image");
            QByteArray beforeCancel = FileIO::readFileAll(pngPath);
            bool cancelled = false;
            QTimer::singleShot(0, [&] {
                exporter.onExport();
                exporter.setMapData(Map(), {}, {}, 1);
                exporter.reject();
                for (auto *progress : exporter.findChildren<QProgressDialog *>()) {
                    progress->cancel();
                    cancelled = true;
                }
            });
            exporter.onExport();
            require(cancelled && !exporter.m_exporting && exporter.m_map.x == visual.x
                && FileIO::readFileAll(pngPath) == beforeCancel,
                "Cancelled or reentrant full map export changed input or output");
        }
        output << "PASS: full-map dialog PNG/BMP output, malformed map rejection and failed-encode preservation\n";
        DFile events;
        events.mapNum = 2;
        events.mapEvent.resize(2);
        events.mapEvent[0].sceneEvent[0].event1 = -1;
        events.mapEvent[1].sceneEvent[0].event1 = 42;
        QString idx = temporary.filePath("events.idx"), grp = temporary.filePath("events.grp");
        EventIO::saveEvents(idx, grp, events);
        QFile index(idx);
        require(index.open(QIODevice::ReadOnly), "Cannot open event index");
        QByteArray offsets = index.readAll();
        require(offsets.size() == 8 && qFromLittleEndian<quint32>(offsets.constData()) == 4400
            && qFromLittleEndian<quint32>(offsets.constData() + 4) == 8800, "Event cumulative end offsets wrong");
        DFile restored;
        require(EventIO::readEvents(idx, grp, restored) && restored.mapEvent.size() == 2
            && restored.mapEvent[1].sceneEvent[0].event1 == 42, "Event roundtrip failed");
        QByteArray validEvents = FileIO::readFileAll(grp);
        require(FileIO::writeFileAll(grp, validEvents.chopped(1)) && !EventIO::readEvents(idx, grp, restored)
            && restored.mapEvent.size() == 2 && restored.mapEvent[1].sceneEvent[0].event1 == 42,
            "Truncated event input replaced active data");
        require(FileIO::writeFileAll(grp, validEvents), "Cannot restore event fixture");
        require(EventIO::readEvents(temporary.filePath("absent-event.idx"), grp, restored)
            && restored.mapEvent[1].sceneEvent[0].event1 == 42, "Fixed-size event stream requires obsolete index");
        {
            SceneMapEdit guarded;
            guarded.m_invalidSaveSlots.insert(guarded.m_currentSave);
            bool rejected = false;
            QTimer::singleShot(0, [&] {
                for (auto *widget : QApplication::topLevelWidgets())
                    if (auto *message = qobject_cast<QMessageBox *>(widget)) {
                        rejected = message->icon() == QMessageBox::Warning;
                        message->accept();
                    }
            });
            guarded.onSaveScene();
            require(rejected && FileIO::readFileAll(grp) == validEvents,
                "Invalid scene session did not reject save");
        }
        output << "PASS: event cumulative offsets and scene event roundtrip\n";
        {
            auto &config = IniConfig::instance();
            QScopedValueRollback<QString> gamePath(config.gamePath, temporary.path() + "/");
            QScopedValueRollback<QStringList> maps(config.sGrp, {"shared-s0.grp", "shared-s1.grp"});
            QScopedValueRollback<QStringList> mapIndices(config.sIdx, {"shared-s.idx", "shared-s.idx"});
            QScopedValueRollback<QStringList> eventFiles(config.dGrp, {"shared-d0.grp", "shared-d1.grp"});
            QScopedValueRollback<QStringList> eventIndices(config.dIdx, {"shared-d.idx", "shared-d.idx"});
            require(FileIO::writeFiles({{temporary.filePath("shared-s0.grp"), QByteArray(49152, '\0')},
                {temporary.filePath("shared-d0.grp"), validEvents.left(4400)},
                {temporary.filePath("shared-s.idx"), "shared-map-index"},
                {temporary.filePath("shared-d.idx"), "shared-event-index"}}), "Cannot create shared index fixture");
            SceneMapEdit editor;
            QTimer::singleShot(0, [] {
                for (auto *widget : QApplication::topLevelWidgets())
                    if (auto *message = qobject_cast<QMessageBox *>(widget)) message->accept();
            });
            editor.onSaveScene();
            require(FileIO::readFileAll(temporary.filePath("shared-s.idx")) == "shared-map-index"
                && FileIO::readFileAll(temporary.filePath("shared-d.idx")) == "shared-event-index",
                "Scene save overwrote shared indices");
        }
        {
            bool nativeDialogsDisabled = QApplication::testAttribute(Qt::AA_DontUseNativeDialogs);
            QApplication::setAttribute(Qt::AA_DontUseNativeDialogs, true);
            SceneMapEdit editor;
            Map module;
            require(MapIO::readSingleMap(QByteArray(48, '\0'), 0, module, 6, 2, 2), "Cannot create scene module fixture");
            for (auto &column : module.mapLayer[3].pic) column.fill(-1);
            module.mapLayer[3].pic[0][0] = 7;
            QString path = temporary.filePath("atomic-scene.smd");
            QByteArray mapBytes = MapIO::encodeMap(module, true);
            QByteArray companion;
            QDataStream stream(&companion, QIODevice::WriteOnly);
            stream.setByteOrder(QDataStream::LittleEndian);
            stream << mapBytes << quint32(1) << qint16(7);
            for (int field = 0; field < 11; ++field) stream << qint16(field);
            require(FileIO::writeFiles({{path, mapBytes}, {path + ".events", companion}}), "Cannot create scene module files");
            auto import = [&] {
                QTimer dismiss;
                QObject::connect(&dismiss, &QTimer::timeout, [] {
                    for (auto *widget : QApplication::topLevelWidgets())
                        if (auto *message = qobject_cast<QMessageBox *>(widget); message && message->isVisible())
                            if (auto *ok = message->button(QMessageBox::Ok)) ok->click();
                });
                dismiss.start(10);
                QTimer::singleShot(0, [path] {
                    for (auto *widget : QApplication::topLevelWidgets())
                        if (auto *dialog = qobject_cast<QFileDialog *>(widget); dialog && dialog->isVisible()) {
                            dialog->selectFile(path);
                            QMetaObject::invokeMethod(dialog, "accept", Qt::DirectConnection);
                        }
                });
                editor.onImportModule();
            };
            import();
            bool valid = editor.m_moduleEvents.contains(7) && editor.m_moduleEvents[7].event1 == 2;
            QByteArray before = MapIO::encodeMap(editor.m_moduleMap, true);
            for (const QByteArray &invalid : {companion.chopped(1), companion + QByteArray("garbage")}) {
                require(FileIO::writeFileAll(path + ".events", invalid), "Cannot corrupt scene module companion");
                import();
                valid = valid && MapIO::encodeMap(editor.m_moduleMap, true) == before
                    && editor.m_moduleEvents.size() == 1 && editor.m_moduleEvents[7].event1 == 2;
            }
            QByteArray undefined;
            QDataStream missingDefinitions(&undefined, QIODevice::WriteOnly);
            missingDefinitions.setByteOrder(QDataStream::LittleEndian);
            missingDefinitions << mapBytes << quint32(0);
            require(FileIO::writeFileAll(path + ".events", undefined), "Cannot create missing module event definitions");
            import();
            valid = valid && MapIO::encodeMap(editor.m_moduleMap, true) == before
                && editor.m_moduleEvents.size() == 1;
            require(QFile::remove(path + ".events"), "Cannot remove scene module companion");
            import();
            valid = valid && editor.m_moduleEvents.isEmpty() && editor.m_moduleMap.x == 2;
            for (const auto &column : editor.m_moduleMap.mapLayer[3].pic)
                for (int reference : column) valid = valid && reference == -1;
            editor.m_moduleMap = module;
            SceneEvent exportedEvent{};
            exportedEvent.event1 = 2;
            editor.m_moduleEvents.insert(7, exportedEvent);
            editor.m_exportLayers = 3;
            QString exportPath = temporary.filePath("exported-scene.smd");
            QTimer::singleShot(0, [exportPath] {
                for (auto *widget : QApplication::topLevelWidgets())
                    if (auto *dialog = qobject_cast<QFileDialog *>(widget); dialog && dialog->isVisible()) {
                        dialog->selectFile(exportPath);
                        QMetaObject::invokeMethod(dialog, "accept", Qt::DirectConnection);
                    }
            });
            editor.onExportModule();
            valid = valid && FileIO::readFileAll(exportPath) == mapBytes
                && QFileInfo::exists(exportPath + ".events") && !QImage(exportPath + ".png").isNull()
                && editor.m_exportLayers == 3 && !editor.m_exporting;
            QApplication::setAttribute(Qt::AA_DontUseNativeDialogs, nativeDialogsDisabled);
            require(valid, "Scene module companion failure changed previous module or event data");
        }
        output << "PASS: scene module companion UI import, truncation and trailing-data preservation\n";
        {
            SceneMapEdit editor;
            editor.m_sceneCount = 2;
            editor.m_sceneRawData = QByteArray(2 * 64 * 64 * 6 * 2, '\0');
            editor.m_dFile.mapEvent.resize(2);
            editor.onLoadScene(0);
            editor.m_mapData.map[0].mapLayer[0].pic[2][3] = 123;
            editor.addUndoSave();
            editor.onUndo();
            require(editor.m_mapData.map[0].mapLayer[0].pic[2][3] == 0, "Scene undo lost initial state");
            editor.onRedo();
            require(editor.m_mapData.map[0].mapLayer[0].pic[2][3] == 123, "Scene redo lost latest state");
            editor.onLoadScene(1);
            editor.m_mapData.map[0].mapLayer[5].pic[4][5] = -27;
            editor.addUndoSave();
            editor.onLoadScene(0);
            require(editor.m_mapData.map[0].mapLayer[0].pic[2][3] == 123, "Switching scenes discarded edits");
            editor.onLoadScene(1);
            require(editor.m_mapData.map[0].mapLayer[5].pic[4][5] == -27, "Second scene elevation lost");
            editor.syncCurrentScene();
            Map scene;
            MapIO::readSingleMap(editor.m_sceneRawData, 64 * 64 * 6 * 2, scene, 6, 64, 64);
            require(scene.mapLayer[5].pic[4][5] == -27, "Export/save cache omitted latest edits");
        }
        output << "PASS: scene switching, undo/redo and export cache synchronization\n";
        {
            SceneMapEdit editor;
            editor.m_sceneCount = 1;
            editor.m_sceneRawData = QByteArray(64 * 64 * 6 * 2, '\0');
            editor.m_dFile.mapEvent.resize(1);
            editor.onLoadScene(0);
            editor.m_dFile.mapEvent[0].sceneEvent[0].event1 = 123;
            editor.addUndoSave();
            Map imported = editor.m_mapData.map[0];
            imported.mapLayer[0].pic[2][3] = 42;
            QString path = temporary.filePath("standalone-scene.map");
            QByteArray bytes = MapIO::encodeMap(imported);
            require(FileIO::writeFileAll(path, bytes), "Cannot create standalone scene fixture");
            bool nativeDialogsDisabled = QApplication::testAttribute(Qt::AA_DontUseNativeDialogs);
            QApplication::setAttribute(Qt::AA_DontUseNativeDialogs, true);
            auto import = [&](bool cancel) {
                QTimer dismiss;
                QObject::connect(&dismiss, &QTimer::timeout, [] {
                    for (auto *widget : QApplication::topLevelWidgets())
                        if (auto *message = qobject_cast<QMessageBox *>(widget); message && message->isVisible())
                            if (auto *button = message->button(QMessageBox::Ok)) button->click();
                });
                dismiss.start(10);
                QTimer::singleShot(0, [path, cancel] {
                    for (auto *widget : QApplication::topLevelWidgets())
                        if (auto *dialog = qobject_cast<QFileDialog *>(widget); dialog && dialog->isVisible()) {
                            if (cancel) dialog->reject();
                            else {
                                dialog->selectFile(path);
                                QMetaObject::invokeMethod(dialog, "accept", Qt::DirectConnection);
                            }
                        }
                });
                editor.onImportScene();
            };
            import(false);
            bool valid = editor.m_mapData.map[0].mapLayer[0].pic[2][3] == 42
                && editor.m_dFile.mapEvent[0].sceneEvent[0].event1 == -1;
            for (const auto &column : editor.m_mapData.map[0].mapLayer[3].pic)
                for (int reference : column) valid = valid && reference == -1;
            QByteArray before = editor.m_sceneRawData;
            require(FileIO::writeFileAll(path, bytes.chopped(1)), "Cannot truncate standalone scene");
            import(false);
            import(true);
            valid = valid && editor.m_sceneRawData == before;
            editor.onUndo();
            valid = valid && editor.m_mapData.map[0].mapLayer[0].pic[2][3] == 0
                && editor.m_dFile.mapEvent[0].sceneEvent[0].event1 == 123;
            QApplication::setAttribute(Qt::AA_DontUseNativeDialogs, nativeDialogsDisabled);
            require(valid, "Standalone scene import lost events, failure state or undo history");
        }
        output << "PASS: standalone scene file dialog, event reset, invalid/cancel preservation and undo\n";
        {
            SceneMapEdit editor;
            SceneEvent event{};
            event.beginPic1 = 20;
            event.endPic = 40;
            event.picDelay = 7;
            require(editor.displayedEventPic(event) == 20 && event.picDelay == 7,
                "Scene preview interpreted animation delay as current frame");
        }
        output << "PASS: scene static event preview preserves animation delay semantics\n";
        {
            SceneMapEdit editor;
            editor.m_sceneCount = 1;
            editor.m_sceneRawData = QByteArray(64 * 64 * 6 * 2, '\0');
            editor.m_dFile.mapEvent.resize(1);
            editor.onLoadScene(0);
            auto &map = editor.m_mapData.map[0];
            for (int layer = 0; layer < 6; ++layer) map.mapLayer[layer].pic[2][3] = layer + 10;
            editor.m_moduleMap = MapIO::extractRegion(map, QRect(2, 3, 1, 1));
            editor.m_layerCombo->setCurrentIndex(1);
            require(editor.pasteModule(QPoint(8, 9)), "Single scene layer paste failed");
            const auto &result = editor.m_mapData.map[0];
            require(result.mapLayer[1].pic[8][9] == 11 && result.mapLayer[4].pic[8][9] == 14
                && result.mapLayer[0].pic[8][9] == 0 && result.mapLayer[2].pic[8][9] == 0
                && result.mapLayer[3].pic[8][9] == 0 && result.mapLayer[5].pic[8][9] == 0,
                "Single scene layer paste changed unrelated layers");
            auto drag = [&](QPoint first, QPoint last) {
                QPointF start = editor.isoToScreen(first.x(), first.y());
                QPointF finish = editor.isoToScreen(last.x(), last.y());
                QMouseEvent press(QEvent::MouseButtonPress, start, start, Qt::LeftButton, Qt::LeftButton, Qt::NoModifier);
                QCoreApplication::sendEvent(editor.m_mapLabel, &press);
                QMouseEvent release(QEvent::MouseButtonRelease, finish, finish, Qt::LeftButton, Qt::NoButton, Qt::NoModifier);
                QCoreApplication::sendEvent(editor.m_mapLabel, &release);
            };
            editor.m_selectedTileId = -1;
            drag(QPoint(3, 4), QPoint(2, 3));
            require(editor.m_moduleMap.x == 2 && editor.m_moduleMap.y == 2
                && editor.m_moduleMap.mapLayer[1].pic[0][0] == 11,
                "Scene drag handlers copied wrong region");
            editor.m_layerCombo->setCurrentIndex(4);
            editor.m_altitude->setValue(23);
            editor.m_undoStack.clear(); editor.m_undoPos = -1; editor.addUndoSave();
            drag(QPoint(6, 7), QPoint(5, 6));
            const auto &elevated = editor.m_mapData.map[0];
            require(elevated.mapLayer[4].pic[5][6] == 23 && elevated.mapLayer[4].pic[6][7] == 23
                && elevated.mapLayer[4].pic[4][6] == 0 && elevated.mapLayer[5].pic[5][6] == 0,
                "Scene altitude drag changed wrong cells or layers");
            editor.onUndo();
            require(editor.m_mapData.map[0].mapLayer[4].pic[5][6] == 0,
                "Scene altitude drag was not undoable");
            drag(QPoint(5, 6), QPoint(5, 6));
            require(editor.m_mapData.map[0].mapLayer[4].pic[5][6] == 1,
                "Scene altitude left click did not increment once");
            QPointF point = editor.isoToScreen(5, 6);
            QMouseEvent down(QEvent::MouseButtonPress, point, point, Qt::RightButton, Qt::RightButton, Qt::NoModifier);
            QMouseEvent up(QEvent::MouseButtonRelease, point, point, Qt::RightButton, Qt::NoButton, Qt::NoModifier);
            QCoreApplication::sendEvent(editor.m_mapLabel, &down);
            QCoreApplication::sendEvent(editor.m_mapLabel, &up);
            require(editor.m_mapData.map[0].mapLayer[4].pic[5][6] == 0,
                "Scene altitude right click did not decrement once");
            editor.m_mapData.map[0].mapLayer[4].pic[5][6] = 32767;
            drag(QPoint(5, 6), QPoint(5, 6));
            require(editor.m_mapData.map[0].mapLayer[4].pic[5][6] == 32767,
                "Scene altitude click overflowed int16");
            bool undoShortcut = false, redoShortcut = false;
            for (auto *button : editor.findChildren<QPushButton *>()) {
                undoShortcut |= button->shortcut() == QKeySequence("Ctrl+Z");
                redoShortcut |= button->shortcut() == QKeySequence("Ctrl+Shift+Z");
            }
            require(undoShortcut && redoShortcut, "Scene undo/redo shortcuts are missing");
        }
        output << "PASS: scene single layer isolation, reverse mouse drag, altitude region and undo\n";
        {
            SceneMapEdit editor;
            editor.m_sceneCount = 1;
            editor.m_sceneRawData = QByteArray(64 * 64 * 6 * 2, '\0');
            editor.m_dFile.mapEvent.resize(1);
            for (auto &event : editor.m_dFile.mapEvent[0].sceneEvent) {
                event.num = event.event1 = event.event2 = event.event3 = -1;
            }
            editor.onLoadScene(0);
            for (auto &column : editor.m_mapData.map[0].mapLayer[3].pic) column.fill(-1);
            editor.m_undoStack.clear(); editor.m_undoPos = -1; editor.addUndoSave();
            editor.m_layerCombo->setCurrentIndex(3);
            editor.onTileClicked(2, 3, Qt::LeftButton);
            require(editor.eventIndexAt(2, 3) == -1, "Left-click on empty event tile changed data");
            editor.onTileClicked(2, 3, Qt::RightButton);
            require(editor.eventIndexAt(2, 3) == 0 && editor.m_selectedEventIndex == 0, "Cannot create event on empty tile");
            editor.m_evtEvent1->setText("123");
            editor.m_evtIndex->setText("17");
            editor.m_evtX->setText("4"); editor.m_evtY->setText("5");
            editor.onEventConfirm();
            require(editor.eventIndexAt(2, 3) == -1 && editor.eventIndexAt(4, 5) == 0
                && editor.m_dFile.mapEvent[0].sceneEvent[0].event1 == 123
                && editor.m_dFile.mapEvent[0].sceneEvent[0].num == 17,
                "Event edit/move confused D slot with editable num field");
            editor.m_moduleMap = MapIO::extractRegion(editor.m_mapData.map[0], QRect(4, 5, 1, 1));
            editor.m_moduleEvents[0] = editor.m_dFile.mapEvent[0].sceneEvent[0];
            require(editor.pasteModule(QPoint(8, 9)), "Cannot paste event module");
            int copied = editor.eventIndexAt(8, 9);
            require(copied == 1 && editor.m_dFile.mapEvent[0].sceneEvent[copied].event1 == 123
                && editor.m_dFile.mapEvent[0].sceneEvent[copied].xPos == 8, "Module event reference not remapped");
            editor.addUndoSave();
            editor.m_deleteMode->setChecked(true);
            editor.onTileClicked(8, 9, Qt::LeftButton);
            require(editor.eventIndexAt(8, 9) == -1, "Event deletion failed");
            editor.onUndo();
            require(editor.eventIndexAt(8, 9) == copied, "Event deletion undo failed");
            auto &config = IniConfig::instance();
            QScopedValueRollback<QStringList> paths(config.sGrp, QStringList{"missing-a", "missing-b"});
            editor.m_sessionLoaded = true;
            editor.m_currentSave = 0;
            editor.loadSceneGrpFile(1);
            editor.loadSceneGrpFile(0);
            require(editor.eventIndexAt(8, 9) == copied && editor.m_dFile.mapEvent[0].sceneEvent[copied].event1 == 123,
                "Save-slot switching discarded map or event changes");
            require(editor.hasUnsavedChanges(), "Unsaved session was not detected");
            editor.m_savedSessions = editor.m_sessions;
            require(!editor.hasUnsavedChanges(), "Unchanged sessions marked dirty");
            editor.m_layerCombo->setCurrentIndex(3);
            editor.m_mapData.map[0].mapLayer[3].pic[10][11] = copied;
            SceneEvent preserved = editor.m_dFile.mapEvent[0].sceneEvent[copied];
            editor.m_deleteMode->setChecked(true);
            editor.onTileClicked(8, 9, Qt::LeftButton);
            require(editor.eventIndexAt(8, 9) == -1 && editor.eventIndexAt(10, 11) == copied
                && editor.m_dFile.mapEvent[0].sceneEvent[copied].event1 == preserved.event1,
                "Deleting one reference changed another reference or event definition");
            editor.onTileClicked(10, 11, Qt::LeftButton);
            require(editor.eventIndexAt(10, 11) == -1
                && editor.m_dFile.mapEvent[0].sceneEvent[copied].event1 == preserved.event1
                && editor.m_dFile.mapEvent[0].sceneEvent[copied].num == preserved.num,
                "Deleting the last reference destroyed the D event definition");
            editor.m_deleteMode->setChecked(false);
            editor.onTileClicked(12, 13, Qt::RightButton);
            require(editor.eventIndexAt(12, 13) == 2
                && editor.m_dFile.mapEvent[0].sceneEvent[copied].event1 == preserved.event1,
                "New event overwrote an unreferenced D definition");
        }
        output << "PASS: event creation, move, module remapping, deletion undo and save-slot sessions\n";
        {
            ImagezForm editor;
            editor.m_imageLabel->resize(1000, 400);
            editor.m_imz.imzPng.resize(40); editor.m_imz.pngNum = 40;
            editor.m_scrollOffset = 1;
            require(editor.spriteIndexAt(QPoint(201, 150)) == 22, "Sprite hit testing disagrees with rendered grid");
            require(editor.spriteIndexAt(QPoint(-1, 0)) == -1 && editor.spriteIndexAt(QPoint(1000, 0)) == -1,
                "Out-of-grid sprite selected");
            WarMapEdit war;
            war.m_mapData.map = {visual}; war.m_mapData.num = 1; war.m_currentMapIndex = 0;
            war.m_tileCache = tiles;
            war.m_selIsoX = 1; war.m_selIsoY = 2;
            QImage clean = war.exportImage(true, false);
            require(!clean.isNull() && clean.pixelColor(0, 0).alpha() == 0
                && clean.pixelColor(85, 57) == QColor(Qt::red), "War export contains background or omitted tile");
            war.m_hasClipboard = true;
            war.selectTile(1);
            require(!war.m_hasClipboard && war.m_selectedTileId == 1, "Tile picker did not exit clipboard mode");
        }
        output << "PASS: sprite hit testing, clean war export and clipboard mode\n";
        {
            MainMapEdit editor;
            editor.m_timer->stop();
            editor.m_layerCombo->setCurrentIndex(1);
            editor.m_hoverIX = -1;
            editor.m_hoverIY = -1;
            editor.m_selectedTileId = 12;
            QPoint position = editor.mapToScreen(240, 240);
            QMouseEvent click(QEvent::MouseButtonPress, QPointF(position), QPointF(position),
                Qt::RightButton, Qt::RightButton, Qt::NoModifier);
            editor.handleMousePress(&click);
            require(editor.m_mapData.map[0].mapLayer[0].pic[240][240] == 24, "Main map click used stale hover coordinates");
            editor.m_mapData.map[0].mapLayer[2].pic[240][240] = 2;
            editor.m_mapData.map[0].mapLayer[3].pic[241][240] = 240;
            editor.m_mapData.map[0].mapLayer[4].pic[241][240] = 240;
            editor.m_layerCombo->setCurrentIndex(5);
            editor.m_selectionStart = QPoint(241, 240);
            QPoint end = editor.mapToScreen(240, 240);
            QMouseEvent release(QEvent::MouseButtonRelease, QPointF(end), QPointF(end),
                Qt::LeftButton, Qt::NoButton, Qt::NoModifier);
            editor.handleMouseRelease(&release);
            require(editor.m_moduleMap.x == 2 && editor.m_moduleMap.y == 1
                && editor.m_moduleMap.mapLayer[3].pic[1][0] == 0, "Module reference was not made relative");
            editor.onTileClicked(244, 244, Qt::RightButton);
            require(editor.m_mapData.map[0].mapLayer[3].pic[244][244] == 243
                && editor.m_mapData.map[0].mapLayer[4].pic[244][244] == 244,
                "Pasted module reference did not follow destination");
        }
        output << "PASS: main-map mouse coordinates and module building reference relocation\n";
        {
            MainMapEdit editor;
            editor.m_timer->stop();
            auto &map = editor.m_mapData.map[0];
            editor.m_layerCombo->setCurrentIndex(3);
            editor.m_selectedTileId = 7;
            editor.onTileClicked(240, 240, Qt::RightButton);
            map.mapLayer[3].pic[241][240] = 240;
            map.mapLayer[4].pic[241][240] = 240;
            editor.m_selectedTileId = 0;
            editor.onTileClicked(240, 240, Qt::RightButton);
            require(map.mapLayer[2].pic[240][240] == 0 && map.mapLayer[3].pic[241][240] == 0
                && map.mapLayer[4].pic[241][240] == 0, "Deleted building left dangling references");
            editor.m_moduleMap = MapIO::extractRegion(map, QRect(240, 240, 2, 2));
            for (int layer = 0; layer < 5; ++layer)
                for (int column = 0; column < 2; ++column)
                    for (int row = 0; row < 2; ++row)
                        editor.m_moduleMap.mapLayer[layer].pic[column][row] = layer < 3 ? 10 + layer : -1;
            editor.m_moduleMap.mapLayer[3].pic[1][1] = 1;
            editor.m_moduleMap.mapLayer[4].pic[1][1] = 1;
            editor.m_selectedTileId = -1;
            for (int layer = 0; layer < 3; ++layer) {
                editor.m_layerCombo->setCurrentIndex(layer + 1);
                for (int reset = 0; reset < 5; ++reset) map.mapLayer[reset].pic[0][0] = 20 + reset;
                editor.onTileClicked(0, 0, Qt::RightButton);
                for (int checked = 0; checked < 5; ++checked) {
                    int expected = checked == layer ? 10 + layer : 20 + checked;
                    if (layer == 2 && checked >= 3) expected = 0;
                    require(map.mapLayer[checked].pic[0][0] == expected, "Single-layer paste leaked layers or failed edge clipping");
                }
            }
        }
        output << "PASS: main-map single-layer clipping and building deletion reference cleanup\n";
        Imz sprites;
        sprites.pngNum = 2;
        sprites.imzPng.resize(2);
        for (int index = 0; index < 2; ++index) {
            auto &sprite = sprites.imzPng[index];
            sprite.fileNum = index == 0 ? 2 : 7;
            sprite.x = -3 - index;
            sprite.y = 5 + index;
            sprite.frame = 2;
            sprite.frameData.resize(2);
            for (int frame = 0; frame < 2; ++frame) {
                QImage image(3, 2, QImage::Format_ARGB32);
                image.fill(frame == 0 ? Qt::red : Qt::green);
                sprite.frameData[frame].data = ImzIO::encodePng(image);
            }
        }
        QString archive = temporary.filePath("sprites.zip");
        {
            Imz legacy = sprites;
            for (int index = 0; index < legacy.imzPng.size(); ++index) legacy.imzPng[index].fileNum = index;
            ImzPng empty;
            empty.fileNum = 2;
            empty.frame = 0;
            legacy.imzPng.append(empty);
            legacy.pngNum = 3;
            QString path = temporary.filePath("legacy.imz");
            require(ImzIO::saveImz(path, legacy), "Cannot save legacy binary IMZ");
            QByteArray bytes = FileIO::readFileAll(path);
            require(qFromLittleEndian<qint32>(bytes.constData()) == 3
                && qFromLittleEndian<qint32>(bytes.constData() + 4) == 16,
                "Legacy IMZ count or absolute sprite offset incorrect");
            Imz restored;
            require(ImzIO::readImz(path, restored) && restored.pngNum == 3
                && restored.imzPng[2].frame == 0 && restored.imzPng[1].x == -4
                && restored.imzPng[1].frameData[1].data == legacy.imzPng[1].frameData[1].data,
                "Legacy IMZ frames, empty sprite or offsets changed");
            require(ImzIO::saveImz(path, restored) && FileIO::readFileAll(path) == bytes,
                "Legacy IMZ byte roundtrip changed");
            {
                ImagezForm editor;
                editor.openImzFile(path);
                editor.m_currentIndex = 0;
                editor.onDeleteSprite();
                editor.onInsertSprite();
                require(editor.m_legacyImz && editor.m_imz.pngNum == 3
                    && editor.m_imz.imzPng[0].fileNum == 0 && editor.m_imz.imzPng[2].fileNum == 2
                    && ImzIO::saveImz(temporary.filePath("edited-legacy.imz"), editor.m_imz),
                    "Legacy sprite insert/delete broke continuous IDs");
            }
            require(FileIO::writeFileAll(path, bytes.chopped(1)), "Cannot truncate legacy fixture");
            require(!ImzIO::readImz(path, restored) && restored.pngNum == 3,
                "Truncated legacy IMZ accepted or destroyed previous state");
            require(!ImzIO::saveImz(temporary.filePath("sparse.imz"), sprites),
                "Legacy save silently lost sparse sprite IDs");
        }
        output << "PASS: legacy binary IMZ absolute offsets, empty sprites and strict roundtrip\n";
        require(ImzIO::saveImz(archive, sprites), "Cannot save sprites");
        {
            ZipFile zip;
            zip.openWrite(archive.toLocal8Bit().toStdString());
            require(zip.addData("fightframe.txt", "0, 5\n", 5) && zip.commit(), "Cannot write fightframe metadata");
        }
        require(ImzIO::saveImz(archive, sprites), "Cannot overwrite sprites");
        Imz loaded;
        require(ImzIO::readImz(archive, loaded) && loaded.imzPng.size() == 2, "Cannot reload sprites");
        require(loaded.imzPng[1].fileNum == 7 && loaded.imzPng[1].x == -4
            && loaded.imzPng[1].frame == 2 && loaded.imzPng[1].frameData[1].data == sprites.imzPng[1].frameData[1].data, "Sparse ID/frame/offset mismatch");
        {
            ZipFile zip;
            zip.openRead(archive.toLocal8Bit().toStdString());
            require(zip.readFile("fightframe.txt") == "0, 5\n", "Fightframe metadata lost");
        }
        require(ImzIO::saveFolder(temporary.filePath("png"), loaded), "Cannot save PNG folder");
        Imz folder;
        require(ImzIO::readImzFromFolder(temporary.filePath("png"), folder)
            && folder.imzPng[1].fileNum == 7 && folder.imzPng[1].x == -4 && folder.imzPng[1].frame == 2, "PNG folder roundtrip failed");
        require(folder.metadata.value("fightframe.txt") == "0, 5\n", "Folder lost fightframe metadata");
        folder.metadata.insert("custom.bin", QByteArray::fromHex("0001ff80"));
        folder.metadata.insert("extras/nested/custom.bin", QByteArray::fromHex("ff0002abcd"));
        QString metadataArchive = temporary.filePath("metadata.zip");
        Imz metadataReloaded;
        require(ImzIO::saveImz(metadataArchive, folder) && ImzIO::readImz(metadataArchive, metadataReloaded)
            && metadataReloaded.metadata == folder.metadata, "Cross-container metadata roundtrip failed");
        require(ImzIO::saveFolder(temporary.filePath("metadata-folder"), metadataReloaded)
            && FileIO::readFileAll(temporary.filePath("metadata-folder/custom.bin")) == QByteArray::fromHex("0001ff80"),
            "Binary folder metadata changed");
        Imz nestedFolder;
        require(FileIO::readFileAll(temporary.filePath("metadata-folder/extras/nested/custom.bin")) == QByteArray::fromHex("ff0002abcd")
            && ImzIO::readImzFromFolder(temporary.filePath("metadata-folder"), nestedFolder)
            && nestedFolder.metadata == folder.metadata,
            "Nested metadata was lost during folder extraction or recursive reload");
        QString blockedFolder = temporary.filePath("metadata-blocked");
        require(QDir().mkpath(blockedFolder) && FileIO::writeFileAll(QDir(blockedFolder).filePath("extras"), "blocked"),
            "Cannot create nested metadata parent conflict");
        require(!ImzIO::saveFolder(blockedFolder, folder)
            && FileIO::readFileAll(QDir(blockedFolder).filePath("extras")) == "blocked"
            && !QFile::exists(QDir(blockedFolder).filePath("index.ka")),
            "Nested metadata parent conflict modified existing output");
        metadataReloaded.metadata.insert("../escape.txt", "unsafe");
        {
            Imz conflicting = nestedFolder;
            conflicting.metadata.insert("case.bin", "first");
            conflicting.metadata.insert("CASE.bin", "second");
            QString target = temporary.filePath("case-metadata.zip");
            require(FileIO::writeFileAll(target, "previous") && !ImzIO::saveImz(target, conflicting)
                && FileIO::readFileAll(target) == "previous"
                && !ImzIO::saveFolder(temporary.filePath("metadata-folder"), conflicting),
                "Case-colliding metadata was accepted for Windows output");
        }
        for (const QString &invalidName : {QString("extras/CON.bin"), QString("extras/com1.txt"),
            QString("extras/bad?.bin"), QString("INDEX.KA")}) {
            Imz invalid = nestedFolder;
            invalid.metadata.insert(invalidName, "unsafe");
            QString target = temporary.filePath("invalid-metadata.zip");
            require(FileIO::writeFileAll(target, "previous") && !ImzIO::saveImz(target, invalid)
                && FileIO::readFileAll(target) == "previous", "Unsafe Windows metadata name replaced ZIP");
        }
        QString unsafeArchive = temporary.filePath("unsafe-metadata.zip");
        {
            ZipFile unsafe;
            unsafe.create(unsafeArchive.toLocal8Bit().toStdString());
            require(unsafe.addData("../escape.txt", "unsafe", 6) && unsafe.commit(), "Cannot create unsafe metadata ZIP");
        }
        Imz preservedMetadata = nestedFolder;
        require(!ImzIO::readImz(unsafeArchive, preservedMetadata)
            && preservedMetadata.metadata == nestedFolder.metadata && preservedMetadata.pngNum == nestedFolder.pngNum,
            "Unsafe metadata archive was accepted or replaced active sprites");
        require(!ImzIO::saveFolder(temporary.filePath("metadata-folder"), metadataReloaded)
            && !QFile::exists(temporary.filePath("escape.txt")), "Metadata escaped output folder");
        require(!ImzIO::saveImz(temporary.filePath("metadata.imz"), metadataReloaded),
            "Legacy IMZ silently discarded metadata");
        output << "PASS: sparse multi-frame ZIP/folder roundtrip and fightframe preservation\n";
        {
            ImagezForm editor;
            editor.openImzFile(archive);
            QString previousPath = editor.m_currentPath;
            QByteArray previousFrame = editor.m_imz.imzPng[1].frameData[1].data;
            QTimer::singleShot(0, [] {
                for (QWidget *widget : QApplication::topLevelWidgets())
                    if (auto *message = qobject_cast<QMessageBox *>(widget)) message->accept();
            });
            editor.openImzFile(temporary.filePath("missing-image.zip"));
            require(editor.m_currentPath == previousPath && editor.m_imz.pngNum == loaded.pngNum
                && editor.m_imz.imzPng[1].frameData[1].data == previousFrame,
                "Failed image load changed session or save path");
        }
        output << "PASS: failed image load preserves sprites and save path\n";
        {
            ImagezForm editor;
            editor.openImzFile(archive);
            require(editor.confirmDiscard(), "Unmodified image session prompted");
            editor.m_imz.imzPng[0].x = -32768;
            QByteArray dirty = editor.stateBytes();
            QTimer::singleShot(0, [] {
                for (QWidget *widget : QApplication::topLevelWidgets())
                    if (auto *message = qobject_cast<QMessageBox *>(widget))
                        message->button(QMessageBox::Cancel)->click();
            });
            editor.openImzFile(metadataArchive);
            require(editor.stateBytes() == dirty && editor.m_currentPath == archive,
                "Cancelled image switch discarded data or changed path");
        }
        output << "PASS: image unsaved cancel preserves offset, sprites and path\n";
        {
            QString brokenArchive = temporary.filePath("broken-image.zip");
            ZipFile zip;
            zip.create(brokenArchive.toLocal8Bit().toStdString());
            require(zip.opened() && zip.addData("0.png", "invalid", 7) && zip.commit(),
                "Cannot create broken PNG archive");
            Imz preserved = loaded;
            require(!ImzIO::readImz(brokenArchive, preserved)
                && preserved.metadata == loaded.metadata
                && preserved.imzPng[1].frameData[1].data == loaded.imzPng[1].frameData[1].data,
                "Broken archive image changed previous data");
            QString brokenFolder = temporary.filePath("broken-images");
            require(QDir().mkpath(brokenFolder) && FileIO::writeFileAll(brokenFolder + "/0.png", "invalid"),
                "Cannot create broken PNG folder");
            require(!ImzIO::readImzFromFolder(brokenFolder, preserved)
                && preserved.metadata == loaded.metadata && preserved.pngNum == loaded.pngNum,
                "Broken folder image changed previous data");
        }
        output << "PASS: corrupt ZIP/folder PNG rejection preserves previous image data\n";
        QVector<GrpPic> pictures;
        QVector<QImage> cache;
        require(MapIO::loadPngTiles(archive, pictures, cache) && cache.size() == 8 && !cache[7].isNull()
            && cache[3].isNull() && pictures[7].xoff == -4, "Sparse tile cache IDs or offsets wrong");
        output << "PASS: sparse PNG/ZIP map tile IDs and offsets\n";
        Imz reduced = loaded;
        reduced.imzPng.removeLast();
        reduced.pngNum = reduced.imzPng.size();
        require(ImzIO::saveFolder(temporary.filePath("png"), reduced)
            && ImzIO::readImzFromFolder(temporary.filePath("png"), folder)
            && folder.pngNum == 1 && folder.imzPng[0].fileNum == 2, "Deleted folder sprite reappeared");
        output << "PASS: deleted PNG folder sprite remains deleted after reload\n";
        {
            QString directory = temporary.filePath("png");
            QByteArray original = FileIO::readFileAll(directory + "/2_0.png");
            require(FileIO::writeFileAll(directory + "/999.png", original), "Cannot create unrelated image");
            Imz invalid = reduced;
            invalid.imzPng[0].frameData[0].data = "invalid";
            require(!ImzIO::saveFolder(directory, invalid) && FileIO::readFileAll(directory + "/2_0.png") == original,
                "Invalid save damaged existing image");
            QString lockedPath = directory + "/index.ka";
#ifdef Q_OS_WIN
            HANDLE locked = CreateFileW(reinterpret_cast<LPCWSTR>(lockedPath.utf16()), GENERIC_READ, FILE_SHARE_READ,
                nullptr, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr);
            require(locked != INVALID_HANDLE_VALUE, "Cannot lock image index");
            bool saved = ImzIO::saveFolder(directory, reduced);
            CloseHandle(locked);
            require(!saved && FileIO::readFileAll(directory + "/2_0.png") == original,
                "Failed folder commit did not restore images");
#endif
            require(ImzIO::saveFolder(directory, reduced) && FileIO::readFileAll(directory + "/999.png") == original,
                "Save removed unrelated image");
            QString legacy = temporary.filePath("legacy");
            require(ImzIO::saveFolder(legacy, loaded), "Cannot prepare legacy folder");
            require(QFile::remove(legacy + "/.upedit-images.json"), "Cannot remove test manifest");
            require(ImzIO::saveFolder(legacy, reduced, {"2_0.png", "2_1.png", "7_0.png", "7_1.png"})
                && !QFile::exists(legacy + "/7_0.png") && QFile::exists(legacy + "/2_0.png"),
                "First legacy folder save did not persist deletion");
            QString first = temporary.filePath("a.bin"), last = temporary.filePath("z.bin");
            require(FileIO::writeFileAll(first, "first") && FileIO::writeFileAll(last, "last"), "Cannot prepare batch test");
#ifdef Q_OS_WIN
            locked = CreateFileW(reinterpret_cast<LPCWSTR>(last.utf16()), GENERIC_READ, FILE_SHARE_READ,
                nullptr, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr);
            require(locked != INVALID_HANDLE_VALUE, "Cannot lock batch target");
            saved = FileIO::writeFiles({{first, "changed"}, {last, "changed"}});
            CloseHandle(locked);
            require(!saved && FileIO::readFileAll(first) == "first" && FileIO::readFileAll(last) == "last",
                "Failed multi-file commit damaged original files");
#endif
            require(FileIO::writeFiles({{first, "changed"}, {last, "changed"}})
                && FileIO::readFileAll(first) == "changed", "Batch commit failed");
        }
        output << "PASS: folder validation, locked-file rollback, unrelated images and multi-file rollback\n";
        require(!dialogTimedOut, "Unhandled test dialog required automatic dismissal");
        output << "ALL TESTS PASSED\n";
        return 0;
    } catch (const std::exception &error) {
        output << "FAIL: " << error.what() << '\n';
        return 1;
    }
}