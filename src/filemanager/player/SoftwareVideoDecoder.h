// SPDX-License-Identifier: GPL-3.0-only
#pragma once

#include <QString>

namespace mod::filemanager {

// Select software decoders in this process before Qt creates a video pipeline.
bool prepareSoftwareVideo(const QString& pluginPath, QString& error);

}
