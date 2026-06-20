// SPDX-License-Identifier: GPL-3.0-only
/*
 * Copyright (C) 2022-present, PenUniverse.
 * This file is part of the PenMods open source project.
 */

#pragma once

#include "common/Utils.h"
#include "common/service/Logger.h"
#include "common/service/Singleton.h"

#include "mod/Config.h"

#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QStringList>

namespace mod {

// OpenAI-compatible chat completions adapter.
//
// Replaces the legacy New-Bing (Sydney WebSocket) integration with a generic
// adapter that talks to any provider implementing the OpenAI
// `/v1/chat/completions` protocol (DeepSeek, Kimi, Qwen, GLM, Doubao, OpenAI,
// OpenRouter, ...). Bases URLs of common providers are pre-set; users only
// need to fill in their API key.
class AIAssistant : public QObject, public Singleton<AIAssistant>, private Logger {
    Q_OBJECT

    // --- configuration ---
    Q_PROPERTY(bool enabled READ getEnabled WRITE setEnabled NOTIFY configChanged);
    Q_PROPERTY(int providerIndex READ getProviderIndex WRITE setProviderIndex NOTIFY providerChanged);
    Q_PROPERTY(QString baseUrl READ getBaseUrl WRITE setBaseUrl NOTIFY configChanged);
    Q_PROPERTY(QString apiKey READ getApiKey WRITE setApiKey NOTIFY configChanged);
    Q_PROPERTY(QString model READ getModel WRITE setModel NOTIFY configChanged);
    Q_PROPERTY(double temperature READ getTemperature WRITE setTemperature NOTIFY configChanged);
    Q_PROPERTY(QString systemPrompt READ getSystemPrompt WRITE setSystemPrompt NOTIFY configChanged);

    // --- runtime state ---
    Q_PROPERTY(bool requesting READ getRequesting NOTIFY requestingChanged);
    Q_PROPERTY(QString currentReply READ getCurrentReply NOTIFY replyChunkChanged);
    Q_PROPERTY(QString lastError READ getLastError NOTIFY errorChanged);

public:
    [[nodiscard]] bool getEnabled() const;
    void               setEnabled(bool val);

    [[nodiscard]] int getProviderIndex() const;
    void              setProviderIndex(int index);

    [[nodiscard]] QString getBaseUrl() const;
    void                  setBaseUrl(const QString& val);

    [[nodiscard]] QString getApiKey() const;
    void                  setApiKey(const QString& val);

    [[nodiscard]] QString getModel() const;
    void                  setModel(const QString& val);

    [[nodiscard]] double getTemperature() const;
    void                 setTemperature(double val);

    [[nodiscard]] QString getSystemPrompt() const;
    void                  setSystemPrompt(const QString& val);

    [[nodiscard]] bool     getRequesting() const;
    [[nodiscard]] QString  getCurrentReply() const;
    [[nodiscard]] QString  getLastError() const;

    // Send a user message; the reply is streamed back via replyChunkChanged.
    Q_INVOKABLE void send(const QString& userMessage);
    // Abort the in-flight request, if any.
    Q_INVOKABLE void stop();
    // Drop the multi-turn conversation history.
    Q_INVOKABLE void clearHistory();

    // Pre-set providers.
    Q_INVOKABLE QStringList providerNames() const;
    Q_INVOKABLE void         selectProvider(int index);

signals:

    void configChanged();
    void providerChanged();

    void replyChunkChanged(const QString& delta);
    void requestingChanged();
    void requestFinished();
    void errorChanged(const QString& msg);

private:
    friend Singleton<AIAssistant>;
    explicit AIAssistant();

    struct Provider {
        const char* name;
        const char* baseUrl;
        const char* defaultModel;
    };

    static constexpr Provider kProviders[] = {
        {"DeepSeek",   "https://api.deepseek.com",                          "deepseek-chat"        },
        {"Kimi",       "https://api.moonshot.cn/v1",                        "moonshot-v1-8k"       },
        {"通义千问",   "https://dashscope.aliyuncs.com/compatible-mode/v1", "qwen-turbo"           },
        {"智谱GLM",    "https://open.bigmodel.cn/api/paas/v4",              "glm-4-flash"          },
        {"豆包",       "https://ark.cn-beijing.volces.com/api/v3",          "doubao-pro-32k"       },
        {"OpenAI",     "https://api.openai.com/v1",                         "gpt-4o-mini"          },
        {"OpenRouter", "https://openrouter.ai/api/v1",                      "openai/gpt-4o-mini"   },
        {"自定义",     "",                                                ""                     }
    };

    std::string mClassName = "ai";
    json        mCfg;

    bool    mEnabled        = false;
    int     mProviderIndex  = 0;
    QString mBaseUrl;
    QString mApiKey;
    QString mModel;
    double  mTemperature    = 0.7;
    QString mSystemPrompt;

    bool    mRequesting     = false;
    QString mAccumulatedReply; // full text accumulated from the streaming reply
    QString mLastError;

    QNetworkAccessManager* mNam = nullptr;
    QNetworkReply*         mNetworkReply = nullptr;
    QByteArray             mSseBuffer;          // leftover bytes not yet terminated by a blank line

    // Multi-turn context: system + user/assistant turns.
    json mMessages = json::array();

    void _setRequesting(bool val);
    void _setError(const QString& msg);
    void _resetReplyState();
    void _onReadyRead();
    void _onReplyFinished();
    void _onReplyError(QNetworkReply::NetworkError code);
    // Consume complete SSE events from mSseBuffer.
    void _drainSseBuffer();
};

} // namespace mod
