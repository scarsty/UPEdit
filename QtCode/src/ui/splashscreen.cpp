#include "splashscreen.h"
#include <QPainter>

SplashScreen::SplashScreen(QWidget *parent)
    : QWidget(parent, Qt::FramelessWindowHint | Qt::WindowStaysOnTopHint)
{
    setAttribute(Qt::WA_TranslucentBackground);
    setAttribute(Qt::WA_DeleteOnClose);

    connect(&m_timer, &QTimer::timeout, [this]() {
        m_alpha += m_alphaStep;
        if (m_alpha >= 1.0) {
            m_alpha = 1.0;
            m_timer.stop();
            // 显示一段时间后关闭
            QTimer::singleShot(2000, this, [this]() {
                m_alphaStep = -0.05;
                m_timer.start(30);
                connect(&m_timer, &QTimer::timeout, [this]() {
                    m_alpha += m_alphaStep;
                    if (m_alpha <= 0.0) {
                        m_timer.stop();
                        emit finished();
                        close();
                    }
                    update();
                });
            });
        }
        update();
    });
}

void SplashScreen::showSplash(const QPixmap &pixmap, int fadeMs)
{
    m_pixmap = pixmap;
    m_alpha = 0.0;
    m_alphaStep = 1.0 / (fadeMs / 30.0);

    resize(pixmap.size());
    // 居中
    QRect screen = QGuiApplication::primaryScreen()->geometry();
    move((screen.width() - width()) / 2, (screen.height() - height()) / 2);

    show();
    m_timer.start(30);
}

void SplashScreen::paintEvent(QPaintEvent *)
{
    QPainter p(this);
    p.setOpacity(m_alpha);
    p.drawPixmap(0, 0, m_pixmap);
}
