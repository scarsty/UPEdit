#pragma once
#include <QWidget>
#include <QPaintEvent>
#include <QTimer>

// 启动画面 (对应 Delphi TFlashForm opendisplay)
class SplashScreen : public QWidget {
    Q_OBJECT
public:
    explicit SplashScreen(QWidget *parent = nullptr);
    void showSplash(const QPixmap &pixmap, int fadeMs = 1000);

signals:
    void finished();

protected:
    void paintEvent(QPaintEvent *event) override;

private:
    QPixmap m_pixmap;
    QTimer m_timer;
    qreal m_alpha = 0.0;
    qreal m_alphaStep = 0.05;
};
