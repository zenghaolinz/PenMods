#pragma once

#include <QString>
#include <QVariantList>
#include <nlohmann/json.hpp>

namespace mod {

// Device-local history. Credentials and provider configuration never enter this file.
class ChatHistory {
public:
    explicit ChatHistory(QString path);
    bool load();
    bool save();
    QString error() const { return mError; }
    QString activeId() const { return mActive; }
    QString title() const;
    QVariantList sessions() const;
    QVariantList messages() const;
    QString create();
    bool select(const QString& id);
    bool remove(const QString& id);
    void rename(const QString& title);
    void clear();
    void beginTurn(const QString& text);
    void finishTurn(const QString& reply, const QString& status, const QString& error = {});
    QString lastPrompt() const;
    void removeLastTurn();
    nlohmann::json context(const QString& systemPrompt) const;

private:
    nlohmann::json* current();
    const nlohmann::json* current() const;
    void touch();
    QString mPath, mActive, mError;
    bool mWritable = true;
    nlohmann::json mSessions = nlohmann::json::array();
};
}
