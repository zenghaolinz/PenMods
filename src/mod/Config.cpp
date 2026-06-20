// SPDX-License-Identifier: GPL-3.0-only
/*
 * Copyright (C) 2022-present, PenUniverse.
 * This file is part of the PenMods open source project.
 */

#include "mod/Config.h"

#include "common/Utils.h"

#include "common/util/System.h"

#include "Version.h"

namespace fs = std::filesystem;

namespace mod {

std::string get_config_path() { return (util::getModuleFileInfo().absolutePath() + "config.json").toStdString(); }

Config::Config() : Logger("Config") {

    // clang-format off

    mData = {
        {"version", VERSION_CONFIG},
        {"column_db", {
             {"patch", true}
        }},
        {"dev", {
            {"offline_rm", true}
        }},
        {"net", {
            {"proxy_enabled", false},
            {"proxy_type", 0},
            {"proxy_hostname", "127.0.0.1"},
            {"proxy_port", 1270},
            {"proxy_username", ""},
            {"proxy_password", ""},
        }},
        {"logger", {
            {"no_upload_user_action", true},
            {"no_upload_raw_scan_img", true},
            {"no_upload_httplog", true}
        }},
        {"query", {
            {"lower_scan", false},
            {"type_by_hand", true}
        }},
        {"wordbook", {
            {"phrase_tab", true},
            {"nocase_sensitive", true}
        }},
        {"screen", {
            {"sleep_duration", 30},
            {"intel_sleep", false}
        }},
        {"battery", {
            {"suspend_duration", 600},
            {"performance_mode", 0}
        }},
        {"locker", {
            {"enabled", false},
            {"password", "abcd"},
            {"scene", {
                {"screen_on", false},
                {"restart", true},
                {"reset_page", true},
                {"dev_setting", false}
            }}
        }},
        {"antiembs", {
            {"auto_mute", false},
            {"low_voice", false},
            {"no_auto_pron", false},
            {"fast_hide_music", false},
            {"fast_mute", false}
        }},
        {"serv", {
            {"ssh_autorun", false},
            {"adb_autorun", false},
            {"adb_skip_verification", false}
        }},
        {"fm", {
            {"order", {
                {"basic", 0},
                {"reversed", false}
            }},
            {"hide_paired_lyrics", false}
        }},
        {"ai", {
            {"speech_assistant", false},
            {"enabled", false},
            {"provider_index", 0},
            {"base_url", "https://api.deepseek.com"},
            {"api_key", ""},
            {"model", "deepseek-chat"},
            {"temperature", 0.7},
            {"system_prompt", "你是有道词典笔的AI助手，请简洁准确地回答问题。"},
            {"bing", {
                {"enabled", false},
                {"request_address", ""},
                {"chathub_address", ""}
            }}
        }}
    };

    // clang-format on

    _load();
}

json Config::read(const std::string& name) {
    if (!mData.contains(name)) {
        return {};
    }
    return mData.at(name);
}

bool Config::write(const std::string& name, json content, bool saveImmediately) {
    if (mData.find(name) == mData.end()) {
        return false;
    }
    mData[name] = std::move(content);
    if (saveImmediately) {
        _save();
    }
    return true;
}

bool Config::_update(json& data) {
    if (!data.contains("version")) {
        return false;
    }
    if (data.at("version") == VERSION_CONFIG) {
        return false;
    }
    info("Configuration file is being updated...");

    try {
        auto addMissing = [](json& object, const char* key, json value) {
            if (!object.contains(key)) {
                object[key] = std::move(value);
            }
        };

        // v100 -> v110
        if (data["version"] < 110) {
            data["fm"] = {
                {"order", {{"basic", 0}, {"reversed", false}}}
            };
            data["antiembs"]["fast_mute"] = false;
            data["version"]               = 110;
        }

        // v110 -> v116
        if (data["version"] < 116) {
            data["locker"]["scene"]["dev_setting"] = false;
            data["version"]                        = 116;
        }

        // v116 -> v117
        if (data["version"] < 117) {
            data["fm"]["hide_paird_lyrics"]     = false;
            data["battery"]["performance_mode"] = 0;
            data["version"]                     = 117;
        }

        // v117 -> v118
        if (data["version"] < 118) {
            data["wordbook"].erase("mod_exporter");
            data["version"] = 118;
        }

        // v118 -> v120
        if (data["version"] < 120) {
            if (!data.contains("ai") || !data["ai"].is_object()) data["ai"] = json::object();
            addMissing(
                data["ai"],
                "bing",
                {{"enabled", false}, {"request_address", ""}, {"chathub_address", ""}}
            );
            data["version"] = 120;
        }

        // v120 -> v130
        if (data["version"] < 130) {
            if (!data.contains("ai") || !data["ai"].is_object()) data["ai"] = json::object();
            if (!data.contains("fm") || !data["fm"].is_object()) data["fm"] = json::object();
            addMissing(data["ai"], "speech_assistant", false);
            addMissing(
                data["fm"],
                "hide_paired_lyrics",
                data["fm"].value("hide_paird_lyrics", false)
            );
            data["fm"].erase("hide_paird_lyrics");
            if (data.contains("dev") && data["dev"].is_object())
                data["dev"].erase("wifi_page_show_ip");
            if (!data.contains("column_db") || !data["column_db"].is_object())
                data["column_db"] = json::object();
            data["column_db"].erase("limit");
            addMissing(data["column_db"], "patch", true);
            data["version"]            = 130;
        }

        // v130 -> v200: introduce the OpenAI-compatible AI assistant fields.
        // Bridges the gap left by the v130->v131 TODO so the on-disk version
        // finally catches up to VERSION_CONFIG (200).
        if (data["version"] < 200) {
            if (!data.contains("ai") || !data["ai"].is_object()) data["ai"] = json::object();
            addMissing(data["ai"], "enabled", false);
            addMissing(data["ai"], "provider_index", 0);
            addMissing(data["ai"], "base_url", "https://api.deepseek.com");
            addMissing(data["ai"], "api_key", "");
            addMissing(data["ai"], "model", "deepseek-chat");
            addMissing(data["ai"], "temperature", 0.7);
            addMissing(
                data["ai"],
                "system_prompt",
                "你是有道词典笔的 AI 助手，请简洁准确地回答问题。"
            );
            data["version"] = VERSION_CONFIG;
        }

    } catch (...) {
        return false;
    }

    return true;
}

bool Config::_load() {
    info("Loading configuration...");
    auto path = get_config_path();
    if (!fs::exists(path)) {
        warn("Configuration not found, creating...");
        return _save() ? _load() : false;
    }
    json tmp;
    try {
        tmp = json::parse(readFile(path.c_str()));
    } catch (...) {}
    if (tmp.empty() || !tmp.contains("version")) {
        warn("Configuration error, being repaired...");
        return _save() ? _load() : false;
    }
    if (tmp["version"] != VERSION_CONFIG) {
        if (!_update(tmp)) {
            return false;
        }
        info("Saving configuration...");
        mData = tmp;
        _save();
    }
    info("Successfully loaded configuration.");
    mData = tmp;
    return true;
}

bool Config::_save() {
    std::ofstream ofile;
    ofile.open(get_config_path());
    if (ofile.good()) {
        ofile << mData.dump(4);
        return true;
    }
    return false;
}

} // namespace mod
