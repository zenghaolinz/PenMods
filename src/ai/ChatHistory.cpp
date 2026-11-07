#include "ChatHistory.h"

#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QSaveFile>
#include <QUuid>

namespace mod {
using Json = nlohmann::json;
static QString text(const Json& value) { return QString::fromStdString(value.get<std::string>()); }
static std::string now() { return QDateTime::currentDateTime().toString(Qt::ISODate).toStdString(); }

ChatHistory::ChatHistory(QString path) : mPath(std::move(path)) {}
Json* ChatHistory::current() {
    for (auto& session : mSessions)
        if (session["id"] == mActive.toStdString()) return &session;
    return nullptr;
}
const Json* ChatHistory::current() const { return const_cast<ChatHistory*>(this)->current(); }
QString ChatHistory::title() const { return current() ? text((*current())["title"]) : QString("新会话"); }

bool ChatHistory::load() {
    QFile file(mPath);
    if (!file.exists()) { create(); return save(); }
    if (!file.open(QIODevice::ReadOnly)) { mWritable = false; mError = "无法读取本机对话历史"; return false; }
    try {
        if (file.size() > 8 * 1024 * 1024) throw std::runtime_error("history too large");
        auto data = Json::parse(file.readAll().toStdString());
        if (data.at("version") != 1 || !data.at("sessions").is_array()
            || data["sessions"].size() > 30) throw std::runtime_error("invalid history");
        auto sessions = data["sessions"];
        for (auto& session : sessions) {
            if (!session.at("id").is_string() || !session.at("title").is_string()
                || !session.at("updated_at").is_string() || !session.at("messages").is_array()
                || session["messages"].size() > 200 || session["messages"].size() % 2)
                throw std::runtime_error("invalid session");
            size_t index = 0;
            for (auto& message : session["messages"]) {
                if (message.at("role") != (index++ % 2 ? "assistant" : "user")
                    || !message.at("content").is_string() || !message.at("status").is_string()
                    || !message.at("error").is_string()) throw std::runtime_error("invalid message");
                if (message["status"] == "pending") {
                    message["status"] = "stopped";
                    message["error"] = "上次回答被中断，可重试";
                }
            }
        }
        mSessions = std::move(sessions);
        mActive = text(data.at("active"));
        if (!current()) {
            if (mSessions.empty()) create();
            else mActive = text(mSessions.back()["id"]);
        }
        mError.clear();
        return true;
    } catch (...) {
        file.close();
        // Preserve the unreadable original before allowing a fresh history to be saved.
        if (!QFile::rename(mPath, mPath + ".corrupt-" + QUuid::createUuid().toString(QUuid::WithoutBraces))) {
            mWritable = false;
            mError = "历史文件损坏且无法备份，请检查存储空间";
            return false;
        }
        mSessions = Json::array();
        create();
        mError = "历史文件损坏，原文件已保留备份";
        return false;
    }
}

bool ChatHistory::save() {
    if (!mWritable) return false;
    QDir().mkpath(QFileInfo(mPath).absolutePath());
    QSaveFile file(mPath);
    if (!file.open(QIODevice::WriteOnly)) { mError = "无法保存对话，请检查存储空间"; return false; }
    file.setPermissions(QFileDevice::ReadOwner | QFileDevice::WriteOwner);
    auto encode = [&]() { return Json{{"version", 1}, {"active", mActive.toStdString()}, {"sessions", mSessions}}.dump(); };
    auto bytes = encode();
    while (bytes.size() > 8 * 1024 * 1024) {
        auto oldest = std::find_if(mSessions.begin(), mSessions.end(), [this](const auto& session) {
            return session["id"] != mActive.toStdString();
        });
        if (oldest != mSessions.end()) mSessions.erase(oldest);
        else if (current() && (*current())["messages"].size() > 2) {
            auto& messages = (*current())["messages"];
            messages.erase(messages.begin(), messages.begin() + 2);
        } else { mError = "对话过大，无法保存"; file.cancelWriting(); return false; }
        bytes = encode();
    }
    if (file.write(bytes.data(), bytes.size()) != (qint64)bytes.size() || !file.commit()) {
        mError = "保存对话失败，当前内容暂留内存";
        return false;
    }
    mError.clear();
    return true;
}

static QVariantList variants(const Json& array) {
    return QJsonDocument::fromJson(QByteArray::fromStdString(array.dump())).toVariant().toList();
}
QVariantList ChatHistory::messages() const { return current() ? variants((*current())["messages"]) : QVariantList{}; }
QVariantList ChatHistory::sessions() const {
    Json list = Json::array();
    for (auto it = mSessions.rbegin(); it != mSessions.rend(); ++it)
        list.push_back({{"id", (*it)["id"]}, {"title", (*it)["title"]},
                        {"updated_at", (*it)["updated_at"]}, {"count", (*it)["messages"].size() / 2}});
    return variants(list);
}
QString ChatHistory::create() {
    if (current() && (*current())["messages"].empty()) return mActive;
    mActive = QUuid::createUuid().toString(QUuid::WithoutBraces);
    mSessions.push_back({{"id", mActive.toStdString()}, {"title", "新会话"}, {"updated_at", now()}, {"messages", Json::array()}});
    if (mSessions.size() > 30) mSessions.erase(mSessions.begin());
    return mActive;
}
bool ChatHistory::select(const QString& id) {
    for (const auto& session : mSessions) if (session["id"] == id.toStdString()) { mActive = id; return true; }
    return false;
}
bool ChatHistory::remove(const QString& id) {
    for (auto it = mSessions.begin(); it != mSessions.end(); ++it) {
        if ((*it)["id"] != id.toStdString()) continue;
        mSessions.erase(it);
        if (mActive == id) {
            mActive.clear();
            if (mSessions.empty()) create();
            else mActive = text(mSessions.back()["id"]);
        }
        return true;
    }
    return false;
}
void ChatHistory::touch() {
    for (auto it = mSessions.begin(); it != mSessions.end(); ++it) {
        if ((*it)["id"] != mActive.toStdString()) continue;
        auto session = std::move(*it);
        session["updated_at"] = now();
        mSessions.erase(it);
        mSessions.push_back(std::move(session));
        break;
    }
}
void ChatHistory::rename(const QString& value) {
    if (current() && !value.trimmed().isEmpty()) { (*current())["title"] = value.trimmed().left(40).toStdString(); touch(); }
}
void ChatHistory::clear() { if (current()) { (*current())["messages"] = Json::array(); touch(); } }
void ChatHistory::beginTurn(const QString& value) {
    if (!current()) create();
    auto& session = *current();
    auto& messages = session["messages"];
    if (messages.empty() && session["title"] == "新会话") session["title"] = value.simplified().left(24).toStdString();
    if (messages.size() >= 200) messages.erase(messages.begin(), messages.begin() + 2);
    messages.push_back({{"role", "user"}, {"content", value.left(16000).toStdString()}, {"status", "complete"}, {"error", ""}});
    messages.push_back({{"role", "assistant"}, {"content", ""}, {"status", "pending"}, {"error", ""}});
    touch();
}
void ChatHistory::finishTurn(const QString& reply, const QString& status, const QString& error) {
    if (!current() || (*current())["messages"].empty()) return;
    auto& message = (*current())["messages"].back();
    if (message["status"] != "pending") return;
    message["content"] = reply.left(128000).toStdString();
    message["status"] = status.toStdString();
    message["error"] = error.left(2000).toStdString();
    touch();
}
QString ChatHistory::lastPrompt() const {
    if (!current() || (*current())["messages"].size() < 2) return {};
    const auto& messages = (*current())["messages"];
    return text(messages[messages.size() - 2]["content"]);
}
void ChatHistory::removeLastTurn() {
    if (current() && (*current())["messages"].size() >= 2) {
        auto& messages = (*current())["messages"];
        messages.erase(messages.end() - 2, messages.end());
    }
}
Json ChatHistory::context(const QString& prompt) const {
    Json turns = Json::array();
    if (current()) {
        const auto& messages = (*current())["messages"];
        for (size_t i = 0; i + 1 < messages.size(); i += 2) {
            if (messages[i + 1]["status"] != "complete") continue;
            for (auto index : {i, i + 1}) turns.push_back({{"role", messages[index]["role"]}, {"content", messages[index]["content"]}});
        }
    }
    while (turns.size() > 40) turns.erase(turns.begin(), turns.begin() + 2);
    if (!prompt.isEmpty()) turns.insert(turns.begin(), Json{{"role", "system"}, {"content", prompt.toStdString()}});
    return turns;
}
}
