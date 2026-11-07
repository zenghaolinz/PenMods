// SPDX-License-Identifier: GPL-3.0-only
/*
 * Copyright (C) 2022-present, PenUniverse.
 * This file is part of the PenMods open source project.
 */

#pragma once

#include "VideoPlayback.h"

namespace mod::filemanager {

class VideoPlayer : public QObject, public Singleton<VideoPlayer> {
    Q_OBJECT
    Q_PROPERTY(QObject* playback READ playback CONSTANT)

public:
    Q_INVOKABLE bool open(const QString& fileName);
    QObject* playback() { return &mPlayback; }

private:
    friend Singleton<VideoPlayer>;
    explicit VideoPlayer();
    void setAudioActive(bool active);

    VideoPlayback mPlayback;
    bool mDecoderReady = false;
    bool mAudioActive = false;
}; // namespace mod::filemanager
} // namespace mod::filemanager
