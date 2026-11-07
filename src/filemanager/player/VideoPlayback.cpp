// SPDX-License-Identifier: GPL-3.0-only
#include "VideoPlayback.h"

#include <QAbstractVideoSurface>
#include <QImage>
#include <QMediaPlayer>
#include <QMutex>
#include <QMutexLocker>
#include <QPainter>
#include <QVideoFrame>
#include <qqml.h>
#include <algorithm>
#include <functional>

namespace mod::filemanager {

struct VideoFrameBuffer {
    QImage get() const {
        QMutexLocker guard(&mutex);
        return image;
    }
    void set(QImage frame) {
        QMutexLocker guard(&mutex);
        image = std::move(frame);
    }
    mutable QMutex mutex;
    QImage image;
};

class FrameSurface : public QAbstractVideoSurface {
public:
    FrameSurface(std::shared_ptr<VideoFrameBuffer> frames, std::function<void()> notify)
        : mFrames(std::move(frames)), mNotify(std::move(notify)) {}

    QList<QVideoFrame::PixelFormat> supportedPixelFormats(QAbstractVideoBuffer::HandleType type) const override {
        if (type != QAbstractVideoBuffer::NoHandle) return {};
        return {QVideoFrame::Format_RGB32, QVideoFrame::Format_ARGB32, QVideoFrame::Format_RGB24, QVideoFrame::Format_RGB565};
    }

    bool present(const QVideoFrame& frame) override {
        QVideoFrame mapped(frame);
        const auto format = QVideoFrame::imageFormatFromPixelFormat(mapped.pixelFormat());
        if (format == QImage::Format_Invalid || !mapped.map(QAbstractVideoBuffer::ReadOnly)) return false;
        const QImage view(mapped.bits(), mapped.width(), mapped.height(), mapped.bytesPerLine(), format);
        const QSize limit(640, 340);
        auto image = view.width() > limit.width() || view.height() > limit.height()
            ? view.scaled(limit, Qt::KeepAspectRatio, Qt::FastTransformation) : view.copy();
        mapped.unmap();
        if (image.isNull()) return false;
        mFrames->set(std::move(image));
        mNotify();
        return true;
    }
private:
    std::shared_ptr<VideoFrameBuffer> mFrames;
    std::function<void()> mNotify;
};

VideoPlayback::VideoPlayback(QObject* parent) : QObject(parent), mFrames(std::make_shared<VideoFrameBuffer>()) {
    mSeekTimer.setSingleShot(true);
    connect(&mSeekTimer, &QTimer::timeout, this, [this] {
        if (mPendingSeek < 0 || !seekable()) return;
        const qint64 target = mPendingSeek;
        const bool resume = playing();
        // Queue the target before the pipeline starts again. Live flushing seeks
        // can be ignored by the firmware while its output sink is changing.
        mPlayer->stop();
        mPlayer->setPosition(target);
        if (resume) mPlayer->play();
        else mPlayer->pause();
    });
}
VideoPlayback::~VideoPlayback() = default;

void VideoPlayback::registerQmlType() {
    static const int typeId = qmlRegisterType<VideoCanvas>("PenMods.Media", 1, 0, "VideoCanvas");
    Q_UNUSED(typeId);
}

void VideoPlayback::open(const QUrl& file) {
    if (!mPlayer) {
        mSurface = std::make_unique<FrameSurface>(mFrames, [this] {
            QMetaObject::invokeMethod(this, &VideoPlayback::frameChanged, Qt::QueuedConnection);
        });
        mPlayer = std::make_unique<QMediaPlayer>();
        mPlayer->setVideoOutput(mSurface.get());
        connect(mPlayer.get(), &QMediaPlayer::positionChanged, this, [this](qint64 position) {
            if (mPendingSeek >= 0 && qAbs(position - mPendingSeek) < 150) mPendingSeek = -1;
            emit positionChanged();
        });
        connect(mPlayer.get(), &QMediaPlayer::stateChanged, this, &VideoPlayback::updateState);
        connect(mPlayer.get(), &QMediaPlayer::mediaStatusChanged, this, &VideoPlayback::updateState);
        connect(mPlayer.get(), &QMediaPlayer::durationChanged, this, &VideoPlayback::updateState);
        connect(mPlayer.get(), &QMediaPlayer::seekableChanged, this, &VideoPlayback::updateState);
        connect(mPlayer.get(), &QMediaPlayer::audioAvailableChanged, this, &VideoPlayback::updateState);
        connect(mPlayer.get(), QOverload<QMediaPlayer::Error>::of(&QMediaPlayer::error), this, &VideoPlayback::updateState);
    }
    close();
    mPlayer->setMedia(QMediaContent(file));
    updateState();
}

void VideoPlayback::updateState() {
    emit stateChanged();
    emit audioActiveChanged(playing() && mPlayer->isAudioAvailable());
}

bool VideoPlayback::playing() const { return mPlayer && mPlayer->state() == QMediaPlayer::PlayingState; }
bool VideoPlayback::loading() const { return mPlayer && mPlayer->mediaStatus() == QMediaPlayer::LoadingMedia; }
bool VideoPlayback::seekable() const { return mPlayer && mPlayer->isSeekable(); }
QString VideoPlayback::error() const {
    if (!mPlayer || (mPlayer->error() == QMediaPlayer::NoError && mPlayer->mediaStatus() != QMediaPlayer::InvalidMedia)) return {};
    const QString detail = mPlayer->errorString();
    return detail.isEmpty() ? QStringLiteral("Invalid media") : detail;
}
qint64 VideoPlayback::position() const { return mPlayer ? mPlayer->position() : 0; }
qint64 VideoPlayback::duration() const { return mPlayer ? mPlayer->duration() : 0; }
bool VideoPlayback::hasFrame() const { return !mFrames->get().isNull(); }

void VideoPlayback::play() {
    if (!mPlayer) return;
    mPlayer->play();
}
void VideoPlayback::pause() { if (mPlayer) mPlayer->pause(); }
void VideoPlayback::seek(qint64 value) {
    if (!seekable() || duration() <= 0) return;
    mPendingSeek = std::clamp<qint64>(value, 0, duration());
    mSeekTimer.start(0);
}
void VideoPlayback::close() {
    mSeekTimer.stop();
    mPendingSeek = -1;
    if (!mPlayer || mPlayer->media().isNull()) return;
    mPlayer->stop();
    mPlayer->setMedia(QMediaContent());
    mFrames->set({});
    emit frameChanged();
    updateState();
}

VideoCanvas::VideoCanvas(QQuickItem* parent) : QQuickPaintedItem(parent) { setOpaquePainting(true); }

void VideoCanvas::setPlayback(QObject* value) {
    auto* playback = qobject_cast<VideoPlayback*>(value);
    if (mPlayback == playback) return;
    if (mPlayback) disconnect(mPlayback, nullptr, this, nullptr);
    mPlayback = playback;
    mFrames = playback ? playback->mFrames : nullptr;
    if (playback) connect(playback, &VideoPlayback::frameChanged, this, [this] { update(); });
    emit playbackChanged();
    update();
}

void VideoCanvas::paint(QPainter* painter) {
    const QRectF area = boundingRect();
    painter->fillRect(area, Qt::black);
    const auto frame = mFrames ? mFrames->get() : QImage();
    if (frame.isNull()) return;
    QSizeF size = frame.size();
    size.scale(area.size(), Qt::KeepAspectRatio);
    QRectF target(QPointF(), size);
    target.moveCenter(area.center());
    painter->drawImage(target, frame);
}

}
