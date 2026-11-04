#pragma once
#include "mapdata.h"
#include "imzdata.h"
#include "eventdata.h"
#include "scenemapedit.h"
#include "mainmapedit.h"
#include "imagezform.h"
#include "fileio.h"
#include "iniconfig.h"
#include <QScopedValueRollback>
#include <QMouseEvent>
#include "ZipFile.h"
#include <QTemporaryDir>
#include <QFile>
#include <QTextStream>
#include <QtEndian>
#include <stdexcept>
#ifdef Q_OS_WIN
#ifndef NOMINMAX
#define NOMINMAX
#endif
#include <windows.h>
#endif

inline int runSelfTests(const QString &reportPath)
{
    QFile report(reportPath);
    if (!report.open(QIODevice::WriteOnly | QIODevice::Text)) return 2;
    QTextStream output(&report);
    auto require = [](bool value, const char *message) { if (!value) throw std::runtime_error(message); };
    try {
        QTemporaryDir temporary;
        require(temporary.isValid(), "Temporary directory unavailable");
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
        QVector<QImage> tiles(2);
        tiles[1] = QImage(4, 4, QImage::Format_ARGB32);
        tiles[1].fill(Qt::red);
        visual.mapLayer[0].pic[1][2] = 2;
        QImage visible = MapIO::renderMainMap(visual, tiles, {}, true, false, false);
        QImage hidden = MapIO::renderMainMap(visual, tiles, {}, false, false, false);
        require(!visible.isNull() && visible.size() == QSize(170, 105), "Full map dimensions wrong");
        require(visible.pixelColor(85, 57).alpha() == 255 && hidden.pixelColor(85, 57).alpha() == 0, "Layer selection or pixels wrong");
        output << "PASS: full-map dimensions, visible sprite pixels and layer toggles\n";
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
        output << "PASS: event cumulative offsets and scene event roundtrip\n";
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
            for (auto &event : editor.m_dFile.mapEvent[0].sceneEvent) {
                event.num = event.event1 = event.event2 = event.event3 = -1;
            }
            editor.onLoadScene(0);
            for (auto &column : editor.m_mapData.map[0].mapLayer[3].pic) column.fill(-1);
            editor.m_undoStack.clear(); editor.m_undoPos = -1; editor.addUndoSave();
            editor.m_layerCombo->setCurrentIndex(3);
            editor.onTileClicked(2, 3, Qt::LeftButton);
            require(editor.eventIndexAt(2, 3) == 0 && editor.m_selectedEventIndex == 0, "Cannot create event on empty tile");
            editor.m_evtEvent1->setText("123");
            editor.m_evtX->setText("4"); editor.m_evtY->setText("5");
            editor.onEventConfirm();
            require(editor.eventIndexAt(2, 3) == -1 && editor.eventIndexAt(4, 5) == 0
                && editor.m_dFile.mapEvent[0].sceneEvent[0].event1 == 123, "Event edit/move failed");
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
            editor.m_selectionStart = QPoint(240, 240);
            QPoint end = editor.mapToScreen(241, 240);
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
        output << "PASS: sparse multi-frame ZIP/folder roundtrip and fightframe preservation\n";
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
        output << "ALL TESTS PASSED\n";
        return 0;
    } catch (const std::exception &error) {
        output << "FAIL: " << error.what() << '\n';
        return 1;
    }
}