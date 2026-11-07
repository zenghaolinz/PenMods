// SPDX-License-Identifier: GPL-3.0-only
/*
 * Copyright (C) 2022-present, PenUniverse.
 * This file is part of the PenMods open source project.
 */

#pragma once

#include "mod/Config.h"

namespace mod {

class DeveloperSettings : public QObject, public Singleton<DeveloperSettings> {
    Q_OBJECT

    Q_PROPERTY(bool offlineRM READ getOfflineRM WRITE setOfflineRM NOTIFY offlineRMChanged);
    Q_PROPERTY(bool wifiPageShowIp READ getWifiPageShowIp WRITE setWifiPageShowIp NOTIFY wifiPageShowIpChanged);

public:
    [[nodiscard]] bool getOfflineRM() const;
    void               setOfflineRM(bool);
    bool getWifiPageShowIp() const { return mWifiPageShowIp; }
    void setWifiPageShowIp(bool value);

signals:

    void offlineRMChanged();
    void wifiPageShowIpChanged();

private:
    friend Singleton<DeveloperSettings>;
    explicit DeveloperSettings();

    std::string mClassName = "dev";
    json        mCfg;

    bool mOfflineRM;
    bool mWifiPageShowIp = false;
};

} // namespace mod
