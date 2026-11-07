// SPDX-License-Identifier: GPL-3.0-only
/*
 * Copyright (C) 2022-present, PenUniverse.
 * This file is part of the PenMods open source project.
 */

#include "ai/AIAssistant.h"

#include "common/Event.h"
#include "common/Utils.h"
#include "common/util/System.h"
#include <QDir>

#include <QNetworkReply>
#include <QNetworkRequest>
#include <QQmlContext>
#include <QUrl>

namespace mod {

AIAssistant::AIAssistant() : Logger("AIAssistant"),
    mHistory(util::getModuleFileInfo().absoluteDir().filePath("ai-history.json")) {

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

    // Migrate only the retired DeepSeek default. Preserve every custom model
    // selected by the user and models belonging to other providers.
    if (mProviderIndex == 0 && (mModel == "deepseek-chat" || mModel == "v4-flash")) {
        mModel        = "deepseek-v4-flash";
        mCfg["model"] = "deepseek-v4-flash";
        WRITE_CFG;
    }

    if (!mHistory.load()) _setError(mHistory.error());
    mRequestTimer.setSingleShot(true);
    mRequestTimer.setInterval(60000);
    connect(&mRequestTimer, &QTimer::timeout, this, [this]() {
        _setError("请求超时，请检查网络后重试");
        stop();
    });

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
            mMessages.insert(mMessages.begin(), json{{"role", "system"}, {"content", val.toStdString()}});
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
    stop();
    mHistory.clear();
    if (!mSystemPrompt.isEmpty()) {
        mMessages = json::array({{{"role", "system"}, {"content", mSystemPrompt.toStdString()}}});
    } else {
        mMessages = json::array();
    }
    mAccumulatedReply.clear();
    _setError(QString());
    _publishHistory();
    emit replyChunkChanged(QString());
}

void AIAssistant::_publishHistory() {
    if (!mHistory.save()) _setError(mHistory.error());
    emit historyChanged();
}
QVariantList AIAssistant::messages() const {
    auto list = mHistory.messages();
    if (mRequesting && !list.empty()) {
        auto last = list.back().toMap();
        if (last["status"] == "pending") {
            last["content"] = mAccumulatedReply;
            list.back() = last;
        }
    }
    return list;
}
void AIAssistant::newConversation() {
    stop(); mHistory.create(); _setError({}); _resetReplyState(); _publishHistory();
}
void AIAssistant::selectConversation(const QString& id) {
    stop();
    if (mHistory.select(id)) { _setError({}); _resetReplyState(); _publishHistory(); }
}
void AIAssistant::deleteConversation(const QString& id) {
    if (id == mHistory.activeId()) stop();
    if (mHistory.remove(id)) _publishHistory();
}
void AIAssistant::renameConversation(const QString& title) { mHistory.rename(title); _publishHistory(); }
void AIAssistant::retryLast() { const auto prompt = mHistory.lastPrompt(); if (!prompt.isEmpty()) _send(prompt, true); }
void AIAssistant::send(const QString& userMessage) { _send(userMessage, false); }
void AIAssistant::_send(const QString& userMessage, bool retry) {
    if (userMessage.trimmed().isEmpty()) {
        return;
    }
    if (userMessage.size() > 16000) { _setError("问题过长，请限制在 16000 字以内"); return; }
    // Tear down any in-flight request synchronously before starting a new one.
    // stop() detaches the reply before aborting, preventing late signals from
    // changing the new request or leaving an unfinished user turn in history.
    stop();

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
    QUrl endpoint(mBaseUrl.trimmed());
    if (!endpoint.isValid() || endpoint.host().isEmpty()
        || (endpoint.scheme() != "https" && endpoint.scheme() != "http")
        || !endpoint.userInfo().isEmpty() || endpoint.hasQuery() || endpoint.hasFragment()) {
        _setError("Base URL 无效，请填写完整的 HTTP 或 HTTPS 接口地址");
        return;
    }

    _resetReplyState();
    _setError(QString());
    _setRequesting(true);

    if (retry) mHistory.removeLastTurn();
    mMessages = mHistory.context(mSystemPrompt);
    mHistory.beginTurn(userMessage.trimmed());
    _publishHistory();
    mMessages.push_back({{"role", "user"}, {"content", userMessage.trimmed().toStdString()}});

    json body = {
        {"model",       mModel.toStdString()},
        {"messages",    mMessages          },
        {"stream",      true               },
        {"temperature", mTemperature       }
    };

    QNetworkRequest req;
    // Join base URL and path, tolerating a trailing slash on the base.
    QString path = endpoint.toString();
    while (path.endsWith('/')) {
        path.chop(1);
    }
    if (!path.endsWith("/chat/completions")) {
        path += "/chat/completions";
    }
    req.setUrl(QUrl(path));
    req.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    req.setRawHeader("Authorization", ("Bearer " + mApiKey).toUtf8());
    // Some providers (e.g. OpenRouter) recommend an Accept header for SSE.
    req.setRawHeader("Accept", "text/event-stream");

    info("POST {} (provider={}, model={})", path.toStdString(), mProviderIndex, mModel.toStdString());

    // The plugin can be loaded before QCoreApplication exists. Network manager
    // initialization belongs to the first user request, after the event loop starts.
    if (!mNam) mNam = new QNetworkAccessManager(this);
    mNetworkReply = mNam->post(req, QString::fromStdString(body.dump()).toUtf8());
    mRequestTimer.start();

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
        auto* reply = mNetworkReply;
        mNetworkReply = nullptr;
        disconnect(reply, nullptr, this, nullptr);
        reply->abort();
        reply->deleteLater();
        mRequestTimer.stop();
        mSseBuffer.clear();
        mHistory.finishTurn(mAccumulatedReply, mLastError.isEmpty() ? "stopped" : "error", mLastError);
        _publishHistory();
        if (!mMessages.empty() && mMessages.back().value("role", "") == "user") {
            mMessages.erase(mMessages.end() - 1);
        }
        _setRequesting(false);
        emit requestFinished();
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
    mRequestTimer.start();
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
            // Reasoning is intentionally consumed but never shown or stored in
            // conversation history. Only the model's final content reaches QML.
            if (delta.contains("reasoning_content") && !delta["reasoning_content"].is_null()) {
                // Keep this branch explicit for OpenAI-compatible providers
                // that send reasoning and final content in separate fields.
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

    mRequestTimer.stop();
    // Drain any final bytes the server sent after the last readyRead.
    if (mNetworkReply->bytesAvailable() > 0) {
        mSseBuffer += mNetworkReply->readAll();
        _drainSseBuffer();
    }

    bool noError = (mNetworkReply->error() == QNetworkReply::NoError);

    // Record the assistant turn so multi-turn context is preserved.
    if (noError && !mAccumulatedReply.isEmpty()) {
        mMessages.push_back({{"role", "assistant"}, {"content", mAccumulatedReply.toStdString()}});
    } else {
        if (noError && mLastError.isEmpty()) {
            _setError("服务未返回回答，请检查模型或接口配置");
        }
        // A failed request: the user turn that just failed should not poison
        // the context for the next attempt.
        if (!mMessages.empty() && mMessages.back().value("role", "") == "user") {
            mMessages.erase(mMessages.end() - 1);
        }
    }

    mNetworkReply->deleteLater();
    mNetworkReply = nullptr;
    mSseBuffer.clear();
    mHistory.finishTurn(mAccumulatedReply, noError && !mAccumulatedReply.isEmpty() && mLastError.isEmpty()
                        ? "complete" : "error", mLastError);
    _publishHistory();

    _setRequesting(false);
    emit requestFinished();
}

} // namespace mod
