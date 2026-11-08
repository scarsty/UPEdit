#pragma once
#include <QWidget>
#include <QComboBox>
#include <QListWidget>
#include <QFormLayout>
#include <QLineEdit>
#include <QDoubleSpinBox>
#include <QCheckBox>
#include <QPushButton>
#include <QFileDialog>
#include <QColorDialog>
#include <QMessageBox>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QSaveFile>
#include <QPainter>
#include <QMouseEvent>
#include <QUuid>
#include <QShortcut>
#include <QSignalBlocker>
#include <functional>
#include <cmath>

class OcclusionEditor : public QWidget {
public:
    struct Shape {
        QString id, name, type = "wall";
        QColor color = QColor("#e6a52a");
        QPolygonF points;
        double height = 80, pivotY = 0;
        bool visible = true, locked = false;
        QPolygonF polygon() const {
            if (type != "wall") return points;
            if (points.size() != 2) return {};
            return QPolygonF{points[0], points[1], points[1] - QPointF(0, height), points[0] - QPointF(0, height)};
        }
        bool behind(QPointF foot) const {
            if (type != "wall") return foot.y() < pivotY;
            if (points.size() != 2) return false;
            const double span = points[1].x() - points[0].x();
            const double ratio = qAbs(span) < 0.001 ? 0.5 : qBound(0.0, (foot.x() - points[0].x()) / span, 1.0);
            return foot.y() < points[0].y() + ratio * (points[1].y() - points[0].y());
        }
    };
    QVector<Shape> shapes;
    bool dirty = false;
    std::function<void()> changed;
    std::function<QPoint()> getOrigin;
    std::function<void(QPoint)> setOrigin;
    std::function<QString()> binding;
    QComboBox *tool;
    QCheckBox *overlay;
    QCheckBox *grid;
    QDoubleSpinBox *hiddenAlpha;

    explicit OcclusionEditor(QWidget *parent = nullptr) : QWidget(parent) {
        auto *form = new QFormLayout(this);
        tool = new QComboBox;
        tool->addItems({tr("原地图编辑"), tr("选择标注"), tr("墙根两点 + 高度"),
            tr("树木 / 屋檐多边形"), tr("点选树根基准"), tr("模拟人物")});
        form->addRow(tr("几何标注工具"), tool);
        tool->setToolTip(tr("墙体：点击墙根 A、B，再向上移动点击确定高度。多边形：逐点点击，右键闭合；Esc 取消。"));
        overlay = new QCheckBox(tr("显示几何标注")); overlay->setChecked(true);
        form->addRow(overlay);
        grid = new QCheckBox(tr("等轴辅助网格")); form->addRow(grid);
        hiddenAlpha = new QDoubleSpinBox; hiddenAlpha->setRange(0, 1); hiddenAlpha->setSingleStep(0.1); hiddenAlpha->setValue(0);
        form->addRow(tr("被挡人物透明度"), hiddenAlpha);
        list = new QListWidget; list->setMinimumHeight(90); list->setMaximumHeight(180);
        form->addRow(tr("遮挡对象"), list);
        name = new QLineEdit; form->addRow(tr("名称"), name);
        type = new QComboBox; type->addItems({tr("墙体"), tr("树木"), tr("屋檐")}); form->addRow(tr("类型"), type);
        height = new QDoubleSpinBox; height->setRange(1, 32767); form->addRow(tr("墙高（像素）"), height);
        pivot = new QDoubleSpinBox; pivot->setRange(-32767, 32767); form->addRow(tr("树根基准 Y"), pivot);
        visible = new QCheckBox(tr("显示并参与遮挡")); locked = new QCheckBox(tr("锁定标注"));
        form->addRow(visible, locked);
        auto *color = new QPushButton(tr("标注颜色")); auto *remove = new QPushButton(tr("删除标注")); form->addRow(color, remove);
        auto *undo = new QPushButton(tr("撤销标注")); auto *redo = new QPushButton(tr("重做标注")); form->addRow(undo, redo);
        auto *load = new QPushButton(tr("导入标注 JSON")); auto *save = new QPushButton(tr("导出标注 JSON")); form->addRow(load, save);
        connect(tool, &QComboBox::currentIndexChanged, this, [this] { pending.clear(); notify(); });
        connect(overlay, &QCheckBox::toggled, this, [this] { notify(); });
        connect(grid, &QCheckBox::toggled, this, [this] { notify(); });
        connect(hiddenAlpha, &QDoubleSpinBox::valueChanged, this, [this] { dirty = true; notify(); });
        connect(list, &QListWidget::currentRowChanged, this, [this] { inspect(); notify(); });
        connect(name, &QLineEdit::editingFinished, this, [this] { edit([this](Shape &shape) { shape.name = name->text(); }); });
        connect(height, &QDoubleSpinBox::editingFinished, this, [this] { edit([this](Shape &shape) { shape.height = height->value(); }); });
        connect(pivot, &QDoubleSpinBox::editingFinished, this, [this] { edit([this](Shape &shape) { shape.pivotY = pivot->value(); }); });
        connect(type, &QComboBox::activated, this, [this](int index) {
            edit([index](Shape &shape) {
                const QString next = index == 0 ? "wall" : index == 1 ? "tree" : "roof";
                if (next == shape.type || next == "wall") return;
                shape.points = shape.polygon(); shape.type = next;
            });
        });
        connect(visible, &QCheckBox::clicked, this, [this](bool checked) { edit([checked](Shape &shape) { shape.visible = checked; }); });
        connect(locked, &QCheckBox::clicked, this, [this](bool checked) {
            const int index = list->currentRow(); if (index < 0) return;
            checkpoint(); shapes[index].locked = checked; commit();
        });
        connect(color, &QPushButton::clicked, this, [this] {
            const int index = list->currentRow(); if (index < 0 || shapes[index].locked) return;
            const QColor next = QColorDialog::getColor(shapes[index].color, this);
            if (next.isValid()) edit([next](Shape &shape) { shape.color = next; });
        });
        connect(remove, &QPushButton::clicked, this, [this] {
            const int index = list->currentRow(); if (index < 0 || shapes[index].locked) return;
            checkpoint(); shapes.removeAt(index); commit();
        });
        connect(undo, &QPushButton::clicked, this, [this] {
            if (past.isEmpty()) return;
            future.append(shapes); shapes = past.takeLast(); dirty = true; pending.clear(); refresh(); notify();
        });
        connect(redo, &QPushButton::clicked, this, [this] {
            if (future.isEmpty()) return;
            past.append(shapes); shapes = future.takeLast(); dirty = true; pending.clear(); refresh(); notify();
        });
        connect(save, &QPushButton::clicked, this, [this] {
            QString path = QFileDialog::getSaveFileName(this, tr("导出遮挡标注"), {}, "JSON (*.json)");
            if (path.isEmpty()) return;
            if (!path.endsWith(".json", Qt::CaseInsensitive)) path += ".json";
            if (!saveJson(path)) QMessageBox::warning(this, tr("遮挡标注"), tr("保存失败，原文件未替换"));
        });
        connect(load, &QPushButton::clicked, this, [this] {
            const QString path = QFileDialog::getOpenFileName(this, tr("导入遮挡标注"), {}, "JSON (*.json)");
            if (path.isEmpty() || !confirmDiscard()) return;
            if (!loadJson(path)) QMessageBox::warning(this, tr("遮挡标注"), tr("数据无效或地图不匹配，保留原标注"));
        });
        inspect();
        auto *escape = new QShortcut(QKeySequence(Qt::Key_Escape), this);
        escape->setContext(Qt::WindowShortcut);
        connect(escape, &QShortcut::activated, this, [this] { cancel(); });
    }
    bool active() const { return tool->currentIndex() != 0; }
    bool simulating() const { return tool->currentIndex() == 5; }
    bool confirmDiscard() {
        return !dirty || QMessageBox::question(this, tr("几何遮挡标注"), tr("标注尚未导出 JSON，放弃修改？"),
            QMessageBox::Discard | QMessageBox::Cancel, QMessageBox::Cancel) == QMessageBox::Discard;
    }
    void reset() { shapes.clear(); pending.clear(); past.clear(); future.clear(); dirty = false; refresh(); }
    bool press(QPointF point, Qt::MouseButton button) {
        if (!active()) return false;
        cursor = point;
        const int mode = tool->currentIndex();
        if (mode == 1 && button == Qt::LeftButton) {
            int selected = -1;
            for (int index = shapes.size() - 1; index >= 0; --index)
                if (shapes[index].visible && shapes[index].polygon().containsPoint(point, Qt::OddEvenFill)) { selected = index; break; }
            list->setCurrentRow(selected);
        } else if (mode == 2 && button == Qt::LeftButton) {
            if (pending.size() < 2) pending << point;
            else if (qAbs(pending[1].x() - pending[0].x()) >= 1) {
                Shape shape; shape.points = pending; shape.height = qMax(1.0, pending[1].y() - point.y()); append(shape);
            }
        } else if (mode == 3) {
            if (button == Qt::LeftButton) pending << point;
            else if (button == Qt::RightButton && pending.size() >= 3) {
                Shape shape; shape.type = "tree"; shape.points = pending; shape.color = QColor("#24a67a");
                shape.pivotY = pending.boundingRect().bottom(); append(shape);
            }
        } else if (mode == 4 && button == Qt::LeftButton) {
            edit([point](Shape &shape) { if (shape.type != "wall") shape.pivotY = point.y(); });
        }
        notify(); return true;
    }
    void move(QPointF point) { cursor = point; if (active()) notify(); }
    void cancel() { pending.clear(); notify(); }
    void draw(QPainter &painter, QPoint offset, QPointF foot) const {
        painter.save(); painter.translate(offset);
        if (grid->isChecked()) {
            const QPoint origin = getOrigin ? getOrigin() : QPoint(1152, 18);
            auto project = [origin](int column, int row) { return origin + QPoint((column - row) * 18, (column + row) * 9); };
            painter.setPen(QPen(QColor(90, 180, 200, 65), 1));
            for (int index = 0; index <= 64; ++index) {
                painter.drawLine(project(index, 0), project(index, 64));
                painter.drawLine(project(0, index), project(64, index));
            }
        }
        if (!overlay->isChecked()) { painter.restore(); return; }
        for (int index = 0; index < shapes.size(); ++index) {
            const auto &shape = shapes[index]; if (!shape.visible) continue;
            const QPolygonF polygon = shape.polygon();
            QColor fill = shape.color;
            fill.setAlpha(shape.behind(foot) && polygon.containsPoint(foot, Qt::OddEvenFill) ? 55 : 95);
            painter.setBrush(fill); painter.setPen(QPen(index == list->currentRow() ? Qt::white : shape.color, 2));
            painter.drawPolygon(polygon);
            painter.setPen(QPen(QColor("#29b9d0"), 2));
            if (shape.type == "wall") {
                painter.drawLine(shape.points[0], shape.points[1]);
                painter.setBrush(QColor("#24a67a")); painter.drawEllipse(shape.points[0], 3, 3);
                painter.setBrush(QColor("#ea4561")); painter.drawEllipse(shape.points[1], 3, 3);
            } else {
                painter.drawLine(QPointF(polygon.boundingRect().left(), shape.pivotY), QPointF(polygon.boundingRect().right(), shape.pivotY));
                painter.setBrush(QColor("#ea4561")); painter.drawEllipse(QPointF(polygon.boundingRect().center().x(), shape.pivotY), 3, 3);
            }
            painter.setPen(shape.color); painter.drawText(polygon.boundingRect().topLeft() - QPointF(0, 4), shape.name);
        }
        if (!pending.isEmpty()) {
            painter.setPen(QPen(QColor("#29b9d0"), 2, Qt::DashLine)); painter.setBrush(Qt::NoBrush);
            QPolygonF preview = pending;
            if (tool->currentIndex() == 2 && pending.size() == 2) {
                Shape wall; wall.points = pending; wall.height = qMax(1.0, pending[1].y() - cursor.y()); preview = wall.polygon();
                painter.drawPolygon(preview);
            } else { preview << cursor; painter.drawPolyline(preview); }
            for (auto point : pending) painter.drawEllipse(point, 3, 3);
        }
        painter.restore();
    }
    QImage maskSprite(const QImage &sprite, QPoint position, QPointF foot) const {
        QImage result = sprite.convertToFormat(QImage::Format_ARGB32);
        QImage applied(result.size(), QImage::Format_Grayscale8); applied.fill(0);
        for (const auto &shape : shapes) {
            if (!shape.visible || !shape.behind(foot)) continue;
            const QPolygonF polygon = shape.polygon();
            const QRect bounds = polygon.boundingRect().toAlignedRect().translated(-position).intersected(result.rect());
            for (int row = bounds.top(); row <= bounds.bottom(); ++row) {
                auto *pixels = reinterpret_cast<QRgb *>(result.scanLine(row));
                for (int column = bounds.left(); column <= bounds.right(); ++column)
                    if (!applied.scanLine(row)[column]
                        && polygon.containsPoint(QPointF(position + QPoint(column, row)) + QPointF(0.5, 0.5), Qt::OddEvenFill)) {
                        pixels[column] = qRgba(qRed(pixels[column]), qGreen(pixels[column]), qBlue(pixels[column]),
                            qRound(qAlpha(pixels[column]) * hiddenAlpha->value()));
                        applied.scanLine(row)[column] = 1;
                    }
            }
        }
        return result;
    }
    bool saveJson(const QString &path) {
        QJsonArray items;
        for (const auto &shape : shapes) {
            auto encode = [](const QPolygonF &points) { QJsonArray array; for (auto point : points)
                array.append(QJsonObject{{"x", point.x()}, {"y", point.y()}}); return array; };
            items.append(QJsonObject{{"id", shape.id}, {"name", shape.name}, {"type", shape.type},
                {"color", shape.color.name()}, {"visible", shape.visible}, {"locked", shape.locked},
                {"occlusionData", QJsonObject{{"wallBase", shape.type == "wall" ? encode(shape.points) : QJsonArray()},
                    {"wallHeight", shape.height}, {"rootPivotY", shape.pivotY}, {"polygon", encode(shape.polygon())}}}});
        }
        const QPoint origin = getOrigin ? getOrigin() : QPoint(1152, 18);
        const QJsonObject root{{"version", "2.1.0"}, {"coordinateSystem", "image-pixels"},
            {"map", binding ? binding() : QString()}, {"origin", QJsonObject{{"x", origin.x()}, {"y", origin.y()}}},
            {"hiddenActorAlpha", hiddenAlpha->value()}, {"items", items}};
        QSaveFile file(path); const QByteArray bytes = QJsonDocument(root).toJson();
        if (!file.open(QIODevice::WriteOnly) || file.write(bytes) != bytes.size() || !file.commit()) return false;
        dirty = false; return true;
    }
    bool loadJson(const QString &path) {
        QFile file(path); if (!file.open(QIODevice::ReadOnly) || file.size() > 16 * 1024 * 1024) return false;
        QJsonParseError error; const auto document = QJsonDocument::fromJson(file.readAll(), &error);
        if (error.error != QJsonParseError::NoError || !document.isObject()) return false;
        const auto root = document.object();
        if (!root.value("items").isArray() || root["items"].toArray().size() > 10000) return false;
        if (root.contains("map") && binding && root["map"].toString() != binding()) return false;
        auto number = [](QJsonValue value) { return value.isDouble() && std::isfinite(value.toDouble()) && qAbs(value.toDouble()) <= 32767; };
        QPoint origin = getOrigin ? getOrigin() : QPoint(1152, 18);
        if (root.contains("origin")) {
            const auto object = root["origin"].toObject();
            if (!number(object["x"]) || !number(object["y"])) return false;
            origin = QPoint(qRound(object["x"].toDouble()), qRound(object["y"].toDouble()));
        }
        QVector<Shape> candidate;
        for (auto value : root["items"].toArray()) {
            const auto object = value.toObject(); const auto data = object["occlusionData"].toObject();
            Shape shape; shape.type = object["type"].toString();
            if (shape.type != "wall" && shape.type != "tree" && shape.type != "roof") return false;
            const auto points = data[shape.type == "wall" ? "wallBase" : "polygon"];
            if (!points.isArray() || points.toArray().size() > 4096) return false;
            for (auto vertex : points.toArray()) {
                const auto point = vertex.toObject(); if (!number(point["x"]) || !number(point["y"])) return false;
                shape.points << QPointF(point["x"].toDouble(), point["y"].toDouble());
            }
            if ((shape.type == "wall" && shape.points.size() != 2) || (shape.type != "wall" && shape.points.size() < 3)) return false;
            if (shape.type == "wall") {
                if (!number(data["wallHeight"]) || data["wallHeight"].toDouble() <= 0
                    || qAbs(shape.points[1].x() - shape.points[0].x()) < 1) return false;
                shape.height = data["wallHeight"].toDouble();
            } else {
                if (!number(data["rootPivotY"])) return false;
                shape.pivotY = data["rootPivotY"].toDouble();
            }
            shape.id = object["id"].toString(QUuid::createUuid().toString(QUuid::WithoutBraces));
            shape.name = object["name"].toString(); shape.color = QColor(object["color"].toString("#e6a52a"));
            if (!shape.color.isValid()) return false;
            shape.visible = object["visible"].toBool(true); shape.locked = object["locked"].toBool(false);
            candidate << shape;
        }
        const double alpha = root["hiddenActorAlpha"].toDouble(0);
        if (!std::isfinite(alpha) || alpha < 0 || alpha > 1) return false;
        shapes = candidate; past.clear(); future.clear(); pending.clear();
        if (setOrigin) setOrigin(origin);
        hiddenAlpha->setValue(alpha); dirty = false; refresh(); notify(); return true;
    }
private:
    QListWidget *list;
    QLineEdit *name;
    QComboBox *type;
    QDoubleSpinBox *height, *pivot;
    QCheckBox *visible, *locked;
    QPolygonF pending;
    QPointF cursor;
    QVector<QVector<Shape>> past, future;
    void notify() { if (changed) changed(); }
    void checkpoint() { past.append(shapes); if (past.size() > 40) past.removeFirst(); future.clear(); }
    void refresh() {
        const int selected = list->currentRow(); const QSignalBlocker block(list); list->clear();
        for (const auto &shape : shapes) list->addItem(shape.name + (shape.locked ? tr(" [锁定]") : QString()));
        list->setCurrentRow(shapes.isEmpty() ? -1 : qBound(0, selected, shapes.size() - 1)); inspect();
    }
    void inspect() {
        const int index = list->currentRow(); const bool valid = index >= 0 && index < shapes.size();
        for (QWidget *widget : QList<QWidget *>{name, type, height, pivot, visible, locked}) widget->setEnabled(valid);
        if (!valid) return;
        const auto &shape = shapes[index]; name->setText(shape.name); type->setCurrentIndex(shape.type == "wall" ? 0 : shape.type == "tree" ? 1 : 2);
        height->setValue(shape.height); pivot->setValue(shape.pivotY); visible->setChecked(shape.visible); locked->setChecked(shape.locked);
        height->setEnabled(shape.type == "wall" && !shape.locked); pivot->setEnabled(shape.type != "wall" && !shape.locked);
    }
    void commit() { dirty = true; refresh(); notify(); }
    void edit(const std::function<void(Shape &)> &action) {
        const int index = list->currentRow(); if (index < 0 || shapes[index].locked) { inspect(); return; }
        checkpoint(); action(shapes[index]); commit();
    }
    void append(Shape shape) {
        checkpoint(); shape.id = QUuid::createUuid().toString(QUuid::WithoutBraces);
        shape.name = (shape.type == "wall" ? tr("墙体 ") : tr("遮挡区 ")) + QString::number(shapes.size() + 1);
        shapes << shape; pending.clear(); commit(); list->setCurrentRow(shapes.size() - 1);
    }
};