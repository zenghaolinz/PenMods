// SPDX-License-Identifier: GPL-3.0-only
#pragma once

#include <QObject>
#include <QPointer>
#include <QQuickPaintedItem>
#include <QTimer>
#include <QUrl>
#include <memory>

class QAbstractVideoSurface;
class QMediaPlayer;

namespace mod::filemanager {

struct VideoFrameBuffer;

class VideoPlayback : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool playing READ playing NOTIFY stateChanged)
    Q_PROPERTY(bool loading READ loading NOTIFY stateChanged)
    Q_PROPERTY(bool seekable READ seekable NOTIFY stateChanged)
    Q_PROPERTY(QString error READ error NOTIFY stateChanged)
    Q_PROPERTY(qint64 position READ position NOTIFY positionChanged)
    Q_PROPERTY(qint64 duration READ duration NOTIFY stateChanged)
    Q_PROPERTY(bool hasFrame READ hasFrame NOTIFY frameChanged)

public:
    explicit VideoPlayback(QObject* parent = nullptr);
    ~VideoPlayback() override;
    static void registerQmlType();
    void open(const QUrl& file);
    bool playing() const;
    bool loading() const;
    bool seekable() const;
    QString error() const;
    qint64 position() const;
    qint64 duration() const;
    bool hasFrame() const;
    Q_INVOKABLE void play();
    Q_INVOKABLE void pause();
    Q_INVOKABLE void seek(qint64 position);
    Q_INVOKABLE void close();

signals:
    void stateChanged();
    void positionChanged();
    void frameChanged();
    void audioActiveChanged(bool active);

private:
    friend class VideoCanvas;
    void updateState();
    std::shared_ptr<VideoFrameBuffer> mFrames;
    std::unique_ptr<QAbstractVideoSurface> mSurface;
    std::unique_ptr<QMediaPlayer> mPlayer;
    QTimer mSeekTimer;
    qint64 mPendingSeek = -1;
};

class VideoCanvas : public QQuickPaintedItem {
    Q_OBJECT
    Q_PROPERTY(QObject* playback READ playback WRITE setPlayback NOTIFY playbackChanged)

public:
    explicit VideoCanvas(QQuickItem* parent = nullptr);
    QObject* playback() const { return mPlayback.data(); }
    void setPlayback(QObject* value);
    void paint(QPainter* painter) override;

signals:
    void playbackChanged();

private:
    QPointer<VideoPlayback> mPlayback;
    std::shared_ptr<VideoFrameBuffer> mFrames;
};

}
