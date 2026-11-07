#pragma once
#include <QNetworkInterface>
#include <QString>

namespace mod::util {
inline QString localIpv4Address() {
    QString fallback;
    for (const auto& interface : QNetworkInterface::allInterfaces()) {
        const auto flags = interface.flags();
        if (!(flags & QNetworkInterface::IsUp) || (flags & QNetworkInterface::IsLoopBack)) continue;
        for (const auto& entry : interface.addressEntries()) {
            const auto ip = entry.ip();
            if (ip.protocol() != QAbstractSocket::IPv4Protocol || ip.isLoopback() || ip.isNull()) continue;
            if (interface.name().startsWith("wlan") || interface.name().startsWith("wl")) return ip.toString();
            if (fallback.isEmpty()) fallback = ip.toString();
        }
    }
    return fallback.isEmpty() ? QString("未连接") : fallback;
}
}
