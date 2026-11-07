// SPDX-License-Identifier: GPL-3.0-only
/*
 * Copyright (C) 2022-present, PenUniverse.
 * This file is part of the PenMods open source project.
 */

#include "filemanager/player/VideoPlayer.h"
#include "filemanager/player/SoftwareVideoDecoder.h"

#include "filemanager/FileManager.h"

#include "common/Event.h"
#include "common/Utils.h"
#include "common/util/System.h"

#include <QQmlContext>

namespace mod::filemanager {

VideoPlayer::VideoPlayer() {
    connect(&mPlayback, &VideoPlayback::audioActiveChanged, this, &VideoPlayer::setAudioActive);
    connect(&Event::getInstance(), &Event::beforeUiInitialization, [this](QQuickView& view, QQmlContext* context) {
        context->setContextProperty("videoPlayer", this);
    });
} // namespace mod::filemanager

bool VideoPlayer::open(const QString& fileName) {
    const auto file = FileManager::getInstance().viewerFile(fileName);
    if (!file.exists()) {
        showToast("找不到视频文件", "#E9900C");
        return false;
    }
    if (!mDecoderReady) {
        QString error;
        const auto plugin = util::getModuleFileInfo().absoluteDir().filePath("media/libgstlibav.so");
        if (!prepareSoftwareVideo(plugin, error)) {
            showToast(error.toStdString(), "#E9900C");
            return false;
        }
        mDecoderReady = true;
    }
    VideoPlayback::registerQmlType();
    mPlayback.open(QUrl::fromLocalFile(file.absoluteFilePath()));
    return true;
}

void VideoPlayer::setAudioActive(bool active) {
    if (mAudioActive == active) return;
    mAudioActive = active;
    PEN_CALL(void*, "ydubus_sender_send_event", int, const char*)(
        0, active ? R"({"action":"Open"})" : R"({"action":"Close"})");
}
} // namespace mod::filemanager
