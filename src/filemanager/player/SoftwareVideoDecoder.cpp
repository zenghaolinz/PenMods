// SPDX-License-Identifier: GPL-3.0-only
#include "SoftwareVideoDecoder.h"

#include <QFile>
#include <QLibrary>

namespace mod::filemanager {

bool prepareSoftwareVideo(const QString& pluginPath, QString& error) {
    error.clear();
    if (!QFile::exists(pluginPath)) {
        error = "找不到视频软件解码插件";
        return false;
    }

    static QLibrary gst("libgstreamer-1.0.so.0");
    gst.setLoadHints(QLibrary::PreventUnloadHint);
    using Init = int (*)(int*, char***, void**);
    using Load = void* (*)(const char*, void**);
    using Find = void* (*)(const char*);
    using SetRank = void (*)(void*, unsigned);
    using Unref = void (*)(void*);
    const auto init = reinterpret_cast<Init>(gst.resolve("gst_init_check"));
    const auto load = reinterpret_cast<Load>(gst.resolve("gst_plugin_load_file"));
    const auto find = reinterpret_cast<Find>(gst.resolve("gst_element_factory_find"));
    const auto setRank = reinterpret_cast<SetRank>(gst.resolve("gst_plugin_feature_set_rank"));
    const auto unref = reinterpret_cast<Unref>(gst.resolve("gst_object_unref"));
    if (!init || !load || !find || !setRank || !unref || !init(nullptr, nullptr, nullptr)) {
        error = "无法初始化视频播放服务";
        return false;
    }
    auto* plugin = load(QFile::encodeName(pluginPath).constData(), nullptr);
    if (!plugin) {
        error = "视频软件解码插件加载失败";
        return false;
    }
    unref(plugin);

    auto* h264 = find("avdec_h264");
    if (!h264) {
        error = "视频软件解码插件缺少 H.264 支持";
        return false;
    }
    setRank(h264, 512);
    unref(h264);
    // These firmware factories are present even when the VPU is unavailable.
    for (const char* name : {"mppvideodec", "mppjpegdec"}) {
        if (auto* factory = find(name)) {
            setRank(factory, 0);
            unref(factory);
        }
    }
    return true;
}

}
