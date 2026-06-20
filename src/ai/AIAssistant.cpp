// SPDX-License-Identifier: GPL-3.0-only
/*
 * Copyright (C) 2022-present, PenUniverse.
 * This file is part of the PenMods open source project.
 */

#include "ai/AIAssistant.h"

#include "common/Event.h"
#include "common/Utils.h"

#include <QNetworkReply>
#include <QNetworkRequest>
#include <QQmlContext>
#include <QUrl>

namespace mod {

AIAssistant::AIAssistant() : Logger("AIAssistant") {

    mCfg = Config::getInstance().read(mClassName);

    // Config seeds every key in its defaults, so direct subscript access is safe
    // and matches the pattern used by every other module (e.g. NetworkSettings).
    mEnabled       = mCfg["enabled"];
    mProviderIndex = mCfg["provider_index"];
    mBaseUrl       = QString::fromStdString(mCfg["base_url"]);
    mApiKey        = QString::fromStdString(mCfg["api_key"]);
    mModel         = QString::fromStdString(mCfg["model"]);
    mTemperature   = mCfg["temperature"];
    mSystemPrompt  = QString::fromStdString(mCfg["system_prompt"]);

    mNam = new QNetworkAccessManager(this);

    // Seed the system message once the prompt is known.
    if (!mSystemPrompt.isEmpty()) {
        mMessages = json::array({{{"role", "system"}, {"content", mSystemPrompt.toStdString()}}});
    }

    connect(&Event::getInstance(), &Event::beforeUiInitialization, [this](QQuickView& view, QQmlContext* context) {
        context->setContextProperty("aiAssistant", this);
    });

    info(
        "AIAssistant ready. provider={} base={} model={}",
        mProviderIndex,
        mBaseUrl.toStdString(),
        mModel.toStdString()
    );
}

// --- configuration getters/setters ---

bool AIAssistant::getEnabled() const { return mEnabled; }
void AIAssistant::setEnabled(bool val) {
    if (mEnabled != val) {
        mEnabled        = val;
        mCfg["enabled"] = val;
        WRITE_CFG;
        emit configChanged();
    }
}

int AIAssistant::getProviderIndex() const { return mProviderIndex; }
void AIAssistant::setProviderIndex(int index) {
    if (index < 0 || index >= (int)(sizeof(kProviders) / sizeof(kProviders[0]))) {
        return;
    }
    if (mProviderIndex != index) {
        mProviderIndex         = index;
        mCfg["provider_index"] = index;
        WRITE_CFG;
        emit providerChanged();
    }
}

QString AIAssistant::getBaseUrl() const { return mBaseUrl; }
void AIAssistant::setBaseUrl(const QString& val) {
    if (mBaseUrl != val) {
        mBaseUrl        = val;
        mCfg["base_url"] = val.toStdString();
        WRITE_CFG;
        emit configChanged();
    }
}

QString AIAssistant::getApiKey() const { return mApiKey; }
void AIAssistant::setApiKey(const QString& val) {
    if (mApiKey != val) {
        mApiKey        = val;
        mCfg["api_key"] = val.toStdString();
        WRITE_CFG;
        emit configChanged();
    }
}

QString AIAssistant::getModel() const { return mModel; }
void AIAssistant::setModel(const QString& val) {
    if (mModel != val) {
        mModel        = val;
        mCfg["model"] = val.toStdString();
        WRITE_CFG;
        emit configChanged();
    }
}

double AIAssistant::getTemperature() const { return mTemperature; }
void AIAssistant::setTemperature(double val) {
    if (mTemperature != val) {
        mTemperature        = val;
        mCfg["temperature"] = val;
        WRITE_CFG;
        emit configChanged();
    }
}

QString AIAssistant::getSystemPrompt() const { return mSystemPrompt; }
void AIAssistant::setSystemPrompt(const QString& val) {
    if (mSystemPrompt != val) {
        mSystemPrompt         = val;
        mCfg["system_prompt"] = val.toStdString();
        WRITE_CFG;
        // Re-seed the system message at index 0.
        if (mMessages.empty() || mMessages[0].value("role", "") != "system") {
            mMessages.insert(mMessages.begin(), {{"role", "system"}, {"content", val.toStdString()}});
        } else {
            mMessages[0]["content"] = val.toStdString();
        }
        emit configChanged();
    }
}

// --- runtime state getters ---

bool    AIAssistant::getRequesting() const { return mRequesting; }
QString AIAssistant::getCurrentReply() const { return mAccumulatedReply; }
QString AIAssistant::getLastError() const { return mLastError; }

// --- presets ---

QStringList AIAssistant::providerNames() const {
    QStringList list;
    for (const auto& p : kProviders) {
        list << QString::fromUtf8(p.name);
    }
    return list;
}

void AIAssistant::selectProvider(int index) {
    if (index < 0 || index >= (int)(sizeof(kProviders) / sizeof(kProviders[0]))) {
        return;
    }
    const auto& p = kProviders[index];
    setProviderIndex(index);
    // "自定义" (last entry) leaves user values untouched.
    if (p.baseUrl[0] != '\0') {
        setBaseUrl(QString::fromUtf8(p.baseUrl));
        setModel(QString::fromUtf8(p.defaultModel));
    }
}

// --- conversation ---

void AIAssistant::clearHistory() {
    if (!mSystemPrompt.isEmpty()) {
        mMessages = json::array({{{"role", "system"}, {"content", mSystemPrompt.toStdString()}}});
    } else {
        mMessages = json::array();
    }
    mAccumulatedReply.clear();
    emit replyChunkChanged(QString());
}

void AIAssistant::send(const QString& userMessage) {
    // Tear down any in-flight request synchronously before starting a new one.
    // stop() (abort) is asynchronous and would race with the new request, so we
    // disconnect signals and drop the old reply right here.
    if (mNetworkReply) {
        disconnect(mNetworkReply, nullptr, this, nullptr);
        mNetworkReply->abort();
        mNetworkReply->deleteLater();
        mNetworkReply = nullptr;
        mSseBuffer.clear();
        _setRequesting(false);
    }

    if (!mEnabled) {
        _setError("AI 助手未启用");
        return;
    }
    if (mApiKey.isEmpty()) {
        _setError("未配置 API Key");
        return;
    }
    if (mBaseUrl.isEmpty()) {
        _setError("未配置 Base URL");
        return;
    }
    if (mModel.isEmpty()) {
        _setError("未配置模型");
        return;
    }

    _resetReplyState();
    _setError(QString());
    _setRequesting(true);

    mMessages.push_back({{"role", "user"}, {"content", userMessage.toStdString()}});

    json body = {
        {"model",       mModel.toStdString()},
        {"messages",    mMessages          },
        {"stream",      true               },
        {"temperature", mTemperature       }
    };

    QNetworkRequest req;
    // Join base URL and path, tolerating a trailing slash on the base.
    QString path = mBaseUrl;
    if (path.endsWith('/')) {
        path.chop(1);
    }
    path += "/chat/completions";
    req.setUrl(QUrl(path));
    req.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    req.setRawHeader("Authorization", ("Bearer " + mApiKey).toUtf8());
    // Some providers (e.g. OpenRouter) recommend an Accept header for SSE.
    req.setRawHeader("Accept", "text/event-stream");

    info("POST {} (provider={}, model={})", path.toStdString(), mProviderIndex, mModel.toStdString());

    mNetworkReply = mNam->post(req, QString::fromStdString(body.dump()).toUtf8());

    connect(mNetworkReply, &QIODevice::readyRead, this, &AIAssistant::_onReadyRead);
    connect(mNetworkReply, &QNetworkReply::finished, this, &AIAssistant::_onReplyFinished);
    // errorOccurred is Qt6; the QOverload form covers Qt5.
#if QT_VERSION >= QT_VERSION_CHECK(6, 0, 0)
    connect(mNetworkReply, &QNetworkReply::errorOccurred, this, &AIAssistant::_onReplyError);
#else
    connect(
        mNetworkReply,
        QOverload<QNetworkReply::NetworkError>::of(&QNetworkReply::error),
        this,
        &AIAssistant::_onReplyError
    );
#endif
}

void AIAssistant::stop() {
    if (mNetworkReply) {
        // abort() triggers errorOccurred(OperationCanceledError) then finished.
        mNetworkReply->abort();
    }
}

// --- internal helpers ---

void AIAssistant::_setRequesting(bool val) {
    if (mRequesting != val) {
        mRequesting = val;
        emit requestingChanged();
    }
}

void AIAssistant::_setError(const QString& msg) {
    if (mLastError != msg) {
        mLastError = msg;
        emit errorChanged(msg);
    }
}

void AIAssistant::_resetReplyState() {
    mAccumulatedReply.clear();
    mSseBuffer.clear();
    emit replyChunkChanged(QString());
}

void AIAssistant::_onReadyRead() {
    if (!mNetworkReply) {
        return;
    }
    mSseBuffer += mNetworkReply->readAll();
    _drainSseBuffer();
}

void AIAssistant::_drainSseBuffer() {
    // An SSE event is terminated by a blank line. Both "\n\n" and "\r\n\r\n"
    // occur in practice; normalize CR to LF first so a single "\n\n" split works.
    mSseBuffer.replace("\r\n", "\n");

    int idx;
    while ((idx = mSseBuffer.indexOf("\n\n")) != -1) {
        QByteArray rawEvent = mSseBuffer.left(idx);
        mSseBuffer          = mSseBuffer.mid(idx + 2);

        // A single event may contain several "data:" lines; concatenate them.
        QString data;
        for (const auto& line : rawEvent.split('\n')) {
            QByteArray trimmed = line;
            while (!trimmed.isEmpty() && trimmed[0] == ' ') {
                trimmed.remove(0, 1);
            }
            if (trimmed.startsWith("data:")) {
                QByteArray payload = trimmed.mid(5);
                while (!payload.isEmpty() && payload[0] == ' ') {
                    payload.remove(0, 1);
                }
                data += QString::fromUtf8(payload);
            }
            // Ignore "event:", "id:", "retry:", and comment (":...") lines.
        }
        if (data.isEmpty()) {
            continue;
        }
        if (data == "[DONE]") {
            // Stream end marker. The final finished() will tidy up state.
            continue;
        }

        try {
            auto        chunk   = json::parse(data.toStdString());
            const auto& choices = chunk.contains("choices") ? chunk["choices"] : json::array();
            if (choices.empty() || !choices[0].contains("delta")) {
                continue;
            }
            const auto& delta = choices[0]["delta"];
            // Standard content increment.
            if (delta.contains("content") && !delta["content"].is_null()) {
                QString piece = QString::fromStdString(delta["content"].get<std::string>());
                mAccumulatedReply += piece;
                emit replyChunkChanged(piece);
            }
            // Reasoning models (e.g. deepseek-reasoner) stream the chain-of-thought
            // separately; surface it too so the user sees live progress.
            if (delta.contains("reasoning_content") && !delta["reasoning_content"].is_null()) {
                QString piece = QString::fromStdString(delta["reasoning_content"].get<std::string>());
                mAccumulatedReply += piece;
                emit replyChunkChanged(piece);
            }
        } catch (const std::exception& e) {
            // A malformed chunk should not abort the whole stream.
            warn("Failed to parse SSE chunk: {}", e.what());
        }
    }
}

void AIAssistant::_onReplyError(QNetworkReply::NetworkError code) {
    // abort() from stop() surfaces as OperationCanceledError; treat as silent.
    if (code == QNetworkReply::OperationCanceledError) {
        return;
    }
    if (!mNetworkReply) {
        return;
    }
    // For HTTP-layer errors (401/403/429/5xx) the body often carries a JSON
    // error message; read it for a friendlier hint.
    auto       httpStatus = mNetworkReply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
    QByteArray body       = mNetworkReply->readAll();
    QString    detail;
    if (!body.isEmpty()) {
        try {
            auto j = json::parse(QString::fromUtf8(body).toStdString());
            if (j.contains("error") && j["error"].contains("message")) {
                detail = QString::fromStdString(j["error"]["message"].get<std::string>());
            }
        } catch (...) {
            detail = QString::fromUtf8(body);
        }
    }
    if (detail.isEmpty()) {
        detail = mNetworkReply->errorString();
    }
    error("Request failed (http={} code={}): {}", httpStatus, (int)code, detail.toStdString());
    _setError(detail.isEmpty() ? "请求失败" : detail);
}

void AIAssistant::_onReplyFinished() {
    if (!mNetworkReply) {
        return;
    }

    // Drain any final bytes the server sent after the last readyRead.
    if (mNetworkReply->bytesAvailable() > 0) {
        mSseBuffer += mNetworkReply->readAll();
        _drainSseBuffer();
    }

    bool aborted = (mNetworkReply->error() == QNetworkReply::OperationCanceledError);
    bool noError = (mNetworkReply->error() == QNetworkReply::NoError);

    // Record the assistant turn so multi-turn context is preserved.
    if (noError && !mAccumulatedReply.isEmpty()) {
        mMessages.push_back({{"role", "assistant"}, {"content", mAccumulatedReply.toStdString()}});
    } else if (!aborted) {
        // A failed request: the user turn that just failed should not poison
        // the context for the next attempt.
        if (!mMessages.empty() && mMessages.back().value("role", "") == "user") {
            mMessages.erase(mMessages.end() - 1);
        }
    }

    mNetworkReply->deleteLater();
    mNetworkReply = nullptr;
    mSseBuffer.clear();

    _setRequesting(false);
    emit requestFinished();
}

} // namespace mod
