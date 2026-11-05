#pragma once
#include "mapdata.h"
#include "imzdata.h"
#include "eventdata.h"
#include "scenemapedit.h"
#include "mainmapedit.h"
#include "imagezform.h"
#include "fileio.h"
#include "iniconfig.h"
#include "picedit.h"
#include "grpdata.h"
#include "kdefedit.h"
#include "sqlite3wrapper.h"
#include "waredit.h"
#include "redit.h"
#include "takein.h"
#include "cyhead.h"
#include <limits>
#include <QStringConverter>
#include <QTimer>
#include <QMessageBox>
#include <QBuffer>
#include <QScopedValueRollback>
#include <QMouseEvent>
#include "ZipFile.h"
#include <QTemporaryDir>
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
        {
            for (bool utf16 : {false, true}) {
                QString text = QString::fromUtf8("; config \xe4\xb8\xad\xe6\x96\x87\r\n[run]\r\ngamepath=D:\\games\\kys\\\r\ndatacode=1; keep\r\n[file]\r\nFile0=a,b,c");
                QStringEncoder encoder(utf16 ? QStringConverter::Utf16LE : QStringConverter::Utf8);
                QByteArray bytes = encoder(text);
                bytes.prepend(QByteArray::fromHex(utf16 ? "fffe" : "efbbbf"));
                QString path = temporary.filePath(utf16 ? "settings16.ini" : "settings8.ini");
                require(FileIO::writeFileAll(path, bytes), "Cannot create settings fixture");
                require(saveRunSettings(path, {{"datacode", 3}, {"talkcode", 2}}), "Settings save failed");
                QByteArray saved = FileIO::readFileAll(path);
                require(saved.startsWith(QByteArray::fromHex(utf16 ? "fffe" : "efbbbf")), "Settings BOM lost");
                QStringDecoder decoder(utf16 ? QStringConverter::Utf16LE : QStringConverter::Utf8);
                QString result = decoder(saved);
                require(!decoder.hasError() && result.contains("datacode=3; keep\r\n")
                    && result.contains("talkcode=2\r\n[file]") && result.contains("gamepath=D:\\games\\kys\\\r\n")
                    && result.endsWith("File0=a,b,c"), "Settings changed unrelated text or sections");
            }
        }
        output << "PASS: UTF16/UTF8 settings BOM, paths, comments and unrelated sections\n";
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
            QMouseEvent press(QEvent::MouseButtonPress, QPointF(3, 4), QPointF(3, 4), Qt::LeftButton, Qt::LeftButton, Qt::NoModifier);
            QCoreApplication::sendEvent(editor.m_imageLabel, &press);
            QMouseEvent release(QEvent::MouseButtonRelease, QPointF(7, 8), QPointF(7, 8), Qt::LeftButton, Qt::NoButton, Qt::NoModifier);
            QCoreApplication::sendEvent(editor.m_imageLabel, &release);
            require(editor.m_sourceImage.size() == QSize(5, 5) && editor.m_sourceImage.pixelColor(0, 0) == QColor(Qt::red),
                "Image crop mouse selection did not modify import source");
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
            editor.onWarChanged(1);
            require(editor.m_selectedPerson == -1, "War selection leaked across records");
        }
        output << "PASS: war position mouse selection, movement, redraw and record switch\n";
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
        }
        output << "PASS: scene single building layer and elevation isolation\n";
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