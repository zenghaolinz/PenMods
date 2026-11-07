// SPDX-License-Identifier: GPL-3.0-only
/*
 * Copyright (C) 2022-present, PenUniverse.
 * This file is part of the PenMods open source project.
 */

#include "Updater.h"

#include "base/YPointer.h"

#include "common/Event.h"

#include <QQmlContext>

namespace mod {

Updater::Updater() : Logger("Updater") {
    connect(&Event::getInstance(), &Event::uiCompleted, this, &Updater::onUiCompleted);
    connect(&Event::getInstance(), &Event::beforeUiInitialization, [this](QQuickView& view, QQmlContext* context) {
        context->setContextProperty("updater", this);
    });
}

QString Version::toString() const {
    return QString("%1.%2.%3").arg(QString::number(mMajor), QString::number(mMinor), QString::number(mRevision));
}

bool Version::operator==(const Version b) const {
    return mMajor == b.mMajor && mMinor == b.mMinor && mRevision == b.mRevision;
}

bool Version::operator>(const Version b) const {
    if (mMajor != b.mMajor) return mMajor > b.mMajor;
    if (mMinor != b.mMinor) return mMinor > b.mMinor;
    return mRevision > b.mRevision;
}

bool Version::operator<(const Version b) const { return b > *this; }

// The upstream OTA service is retired. Never fetch or execute its packages.
void Updater::check() {
    _setUpdateNote("本适配版使用手动更新，旧在线更新服务已停用。");
    _setOtaStatus(ERROR_NO_CONNECTION);
}

Updater::UpdateInfo& Updater::getInfo() { return mInfo; }

void Updater::download() { _setOtaStatus(DOWNLOAD_FAILED); }
void Updater::install() { _setOtaStatus(INSTALL_FAILED); }

void Updater::onUiCompleted() { _setCurrentVersion(mSelfVersion.toString()); }

void Updater::_setCurrentVersion(QString verstr) {
    mInfo.mCurrentStr = std::move(verstr);
    PEN_CALL(void*, "_ZN14YUpdateManager23onCurrentVersionChangedEv", void*)(YPointer<YUpdateManager>::getInstance());
}

void Updater::_setUpdateNote(QString note) {
    mInfo.mUpdateNote = std::move(note);
    PEN_CALL(void*, "_ZN14YUpdateManager19onUpdateNoteChangedEv", void*)(YPointer<YUpdateManager>::getInstance());
}

void Updater::_setOtaStatus(UpdateStatus stat) {
    mInfo.mOtaStatus = stat;
    PEN_CALL(void*, "_ZN14YUpdateManager18onOtaStatusChangedEv", void*)(YPointer<YUpdateManager>::getInstance());
}

} // namespace mod

PEN_HOOK(QString, _ZN14YUpdateManager14currentVersionEv, uint64 self, void* a2) {
    return mod::Updater::getInstance().getInfo().mCurrentStr;
}

PEN_HOOK(QString, _ZN14YUpdateManager13targetVersionEv, uint64 self, void* a2) {
    return mod::Updater::getInstance().getInfo().mLatestStr;
}

PEN_HOOK(UpdateStatus, _ZN14YUpdateManager9otaStatusEv, uint64) {
    return mod::Updater::getInstance().getInfo().mOtaStatus;
}

PEN_HOOK(QString, _ZN14YUpdateManager10updateNoteEv, uint64 self, void* a2, void* a3) {
    return mod::Updater::getInstance().getInfo().mUpdateNote;
}

// Disabled Functions;

PEN_HOOK(void, _ZN14YUpdateManager7installEv, uint64 self) {}

PEN_HOOK(void, _ZN14YUpdateManager13downloadStartEv, uint64 self) {}

PEN_HOOK(void, _ZN14YUpdateManager13downloadPauseEv, uint64 self) {}

PEN_HOOK(void, _ZN14YUpdateManager14downloadResumeEv, uint64 self) {}

PEN_HOOK(bool, _ZN21YUpdateManagerPrivate25checkOtaOperateThreadFuncEv, uint64 self) { return false; }

PEN_HOOK(bool, _ZN21YUpdateManagerPrivate32checkInstallOtaOperateThreadFuncEv, uint64 self) { return false; }

PEN_HOOK(uint64, _ZN21YUpdateManagerPrivate15checkOtaInstallEv, uint64 self) { return 0; }

PEN_HOOK(void, _ZN21YUpdateManagerPrivate14checkOtaUpdateEv, uint64 self) {}

PEN_HOOK(void, _ZN21YUpdateManagerPrivate19onPowerStatusChangeEiRK7QString, void* self, void* a2, void* a3) {}
