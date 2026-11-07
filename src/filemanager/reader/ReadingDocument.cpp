#include "ReadingDocument.h"
#include <QCryptographicHash>
#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QSaveFile>
#include <QTextCodec>
#include <QUuid>
#include <algorithm>
#include <cstring>

namespace mod::filemanager {
ReadingDocument::ReadingDocument(QString path) : mStatePath(std::move(path)) {
    QFile file(mStatePath);
    if (!file.exists()) return;
    if (!file.open(QIODevice::ReadOnly)) { mWritable = false; return; }
    const auto parsed = QJsonDocument::fromJson(file.read(2 * 1024 * 1024 + 1));
    if (file.size() <= 2 * 1024 * 1024 && parsed.isObject() && parsed.object()["version"].toInt() == 1) {
        mState = parsed.object()["documents"].toObject();
    } else {
        file.close();
        mWritable = QFile::rename(mStatePath, mStatePath + ".corrupt-" + QUuid::createUuid().toString(QUuid::WithoutBraces));
    }
}
bool ReadingDocument::open(const QString& path) {
    mBlockCache.clear(); mDecoded.reset(); mOffsets.clear(); mLengths.clear(); mMatches.clear();
    mMatchIndex = -1; mCharacters = 0; mQuery.clear(); mError.clear(); mKey.clear();
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly)) { mError = "无法打开文本文件"; return false; }
    if (file.size() > 128LL * 1024 * 1024) { mError = "目前支持最大 128 MB 的文本文件"; return false; }
    const auto initialSize = file.size();
    const auto initialModified = QFileInfo(path).lastModified();
    auto* utf8 = QTextCodec::codecForName("UTF-8");
    auto* codec = QTextCodec::codecForUtfText(file.peek(4096), utf8);
    QTextCodec::ConverterState probe;
    QCryptographicHash hash(QCryptographicHash::Sha256);
    while (!file.atEnd()) {
        const auto chunk = file.read(64 * 1024);
        if (chunk.isEmpty() && file.error() != QFile::NoError) { mError = "读取文本失败"; return false; }
        hash.addData(chunk);
        if (codec == utf8) codec->toUnicode(chunk.constData(), chunk.size(), &probe);
    }
    if (codec == utf8 && (probe.invalidChars || probe.remainingChars)) {
        if (auto* legacy = QTextCodec::codecForName("GB18030")) codec = legacy;
    }
    const QString cacheDir = QFileInfo(mStatePath).absoluteDir().filePath("reader-cache");
    if (!QDir().mkpath(cacheDir)) { mError = "无法建立阅读缓存目录"; return false; }
    mDecoded = std::make_unique<QTemporaryFile>(QDir(cacheDir).filePath("text-XXXXXX.tmp"));
    if (!mDecoded->open()) { mError = "无法建立阅读缓存，请检查存储空间"; mDecoded.reset(); return false; }
    mDecoded->setPermissions(QFileDevice::ReadOwner | QFileDevice::WriteOwner);
    file.seek(0);
    QTextCodec::ConverterState decode;
    bool first = true, pendingCr = false, lineHasBlocks = false;
    int start = 0, length = 0;
    auto record = [&]() {
        if (mOffsets.size() >= 2000000) return false;
        mOffsets.push_back(start); mLengths.push_back(length);
        start = mCharacters; length = 0; lineHasBlocks = true; return true;
    };
    auto write = [&](const QString& part) {
        if (mDecoded->write(reinterpret_cast<const char*>(part.utf16()), part.size() * 2LL) != part.size() * 2LL) return false;
        for (const auto character : part) {
            if (character == '\n') {
                if ((length > 0 || !lineHasBlocks) && !record()) return false;
                ++mCharacters; start = mCharacters; length = 0; lineHasBlocks = false;
            } else {
                ++mCharacters; ++length;
                if (length >= 240 && !character.isHighSurrogate() && !record()) return false;
            }
        }
        return true;
    };
    bool okay = true;
    while (!file.atEnd() && okay) {
        const auto bytes = file.read(64 * 1024);
        if (bytes.isEmpty() && file.error() != QFile::NoError) { okay = false; break; }
        auto decoded = codec->toUnicode(bytes.constData(), bytes.size(), &decode);
        if (first && !decoded.isEmpty()) { if (decoded[0] == QChar(0xfeff)) decoded.remove(0,1); first = false; }
        QString normalized; normalized.reserve(decoded.size() + 1);
        for (const auto character : decoded) {
            if (pendingCr) { normalized += '\n'; pendingCr = false; if (character == '\n') continue; }
            if (character == '\r') pendingCr = true;
            else normalized += character;
        }
        okay = write(normalized);
    }
    if (pendingCr && okay) okay = write(QString("\n"));
    if (okay && (length > 0 || !lineHasBlocks)) okay = record();
    if (!okay || !mDecoded->flush()) {
        mError = mOffsets.size() >= 2000000 ? "文本段落过多，请拆分后阅读" : "读取或写入缓存失败，请检查存储空间";
        mDecoded.reset(); mOffsets.clear(); mLengths.clear(); return false;
    }
    if (QFileInfo(path).size() != initialSize || QFileInfo(path).lastModified() != initialModified) {
        mError = "文本正在被修改，请重新打开"; mDecoded.reset(); mOffsets.clear(); mLengths.clear(); return false;
    }
    mKey = QString::fromLatin1(QCryptographicHash::hash(QFileInfo(path).canonicalFilePath().toUtf8(), QCryptographicHash::Sha256).toHex());
    const auto fingerprint = QString::fromLatin1(hash.result().toHex());
    auto document = mState[mKey].toObject();
    if (document["fingerprint"].toString() != fingerprint)
        document = QJsonObject{{"fingerprint", fingerprint}, {"position", 0}, {"bookmarks", QJsonArray{}}};
    document["updated"] = QDateTime::currentMSecsSinceEpoch(); mState[mKey] = document;
    return true;
}
QString ReadingDocument::readText(int offset, int length) const {
    if (!mDecoded || !mDecoded->seek(qint64(offset) * 2)) return {};
    const auto bytes = mDecoded->read(qint64(length) * 2);
    QString value;
    value.resize(bytes.size() / 2);
    std::memcpy(value.data(), bytes.constData(), bytes.size());
    return value;
}
QString ReadingDocument::text() const { return readText(0, std::min(mCharacters, 65536)); }
QString ReadingDocument::block(int index) const {
    if (index < 0 || index >= blockCount()) return {};
    if (auto* cached = mBlockCache.object(index)) return *cached;
    auto value = readText(mOffsets[index], mLengths[index]);
    mBlockCache.insert(index, new QString(value)); return value;
}
int ReadingDocument::blockAt(int offset) const {
    if (mOffsets.isEmpty()) return 0;
    return std::max(0, int(std::upper_bound(mOffsets.begin(), mOffsets.end(), offset) - mOffsets.begin()) - 1);
}
int ReadingDocument::position() const { return mKey.isEmpty() ? 0 : blockAt(mState[mKey].toObject()["position"].toInt()); }
bool ReadingDocument::savePosition(int block) {
    if (mKey.isEmpty() || block < 0 || block >= blockCount()) return false;
    auto document = mState[mKey].toObject(); document["position"] = mOffsets[block];
    document["updated"] = QDateTime::currentMSecsSinceEpoch(); mState[mKey] = document;
    return save();
}
bool ReadingDocument::save() {
    if (!mWritable) { mError = "阅读记录不可写，原文件已保留"; return false; }
    while (mState.size() > 100) {
        QString oldest; double time = 1e30;
        for (auto it = mState.begin(); it != mState.end(); ++it) {
            if (it.key() != mKey && it.value().toObject()["updated"].toDouble() < time) { oldest = it.key(); time = it.value().toObject()["updated"].toDouble(); }
        }
        if (oldest.isEmpty()) break;
        mState.remove(oldest);
    }
    QDir().mkpath(QFileInfo(mStatePath).absolutePath());
    QSaveFile file(mStatePath);
    if (!file.open(QIODevice::WriteOnly)) { mError = "阅读记录保存失败，请检查存储空间"; return false; }
    file.setPermissions(QFileDevice::ReadOwner | QFileDevice::WriteOwner);
    const auto data = QJsonDocument(QJsonObject{{"version", 1}, {"documents", mState}}).toJson(QJsonDocument::Compact);
    if (file.write(data) != data.size() || !file.commit()) { mError = "阅读记录保存失败"; return false; }
    mError.clear(); return true;
}
void ReadingDocument::search(QString value) {
    mQuery = value.left(128); mMatches.clear(); mMatchIndex = -1;
    if (mQuery.isEmpty() || !mDecoded) return;
    QString carry; int nextAllowed = 0;
    for (int offset = 0; offset < mCharacters && mMatches.size() < 500; offset += 32768) {
        const auto part = readText(offset, std::min(32768, mCharacters - offset));
        const auto window = carry + part;
        const int base = offset - carry.size();
        int from = std::max(0, nextAllowed - base);
        while (mMatches.size() < 500) {
            int found = window.indexOf(mQuery, from, Qt::CaseInsensitive);
            if (found < 0) break;
            mMatches.push_back(base + found); nextAllowed = base + found + mQuery.size(); from = found + mQuery.size();
        }
        carry = window.right(std::max(0, mQuery.size() - 1));
    }
    if (!mMatches.isEmpty()) mMatchIndex = 0;
}
int ReadingDocument::matchBlock() const { return mMatchIndex < 0 ? -1 : blockAt(mMatches[mMatchIndex]); }
int ReadingDocument::moveMatch(int direction) {
    if (mMatches.isEmpty()) return -1;
    mMatchIndex = (mMatchIndex + direction + mMatches.size()) % mMatches.size(); return matchBlock();
}
QVariantList ReadingDocument::bookmarks() const {
    QVariantList list;
    for (const auto& value : mState[mKey].toObject()["bookmarks"].toArray()) {
        const int block = blockAt(value.toInt());
        list.push_back(QVariantMap{{"block", block}, {"label", QString::number(block + 1) + " · " + this->block(block).simplified().left(32)}});
    }
    return list;
}
bool ReadingDocument::toggleBookmark(int block) {
    if (mKey.isEmpty() || block < 0 || block >= blockCount()) return false;
    auto document = mState[mKey].toObject(); auto items = document["bookmarks"].toArray();
    const int offset = mOffsets[block]; bool removed = false;
    for (int i = 0; i < items.size(); ++i) if (items[i].toInt() == offset) { items.removeAt(i); removed = true; break; }
    if (!removed) { if (items.size() >= 50) { mError = "每篇最多保存 50 个书签"; return false; } items.push_back(offset); }
    document["bookmarks"] = items; mState[mKey] = document; return save();
}
bool ReadingDocument::removeBookmark(int block) {
    for (const auto& mark : bookmarks()) if (mark.toMap()["block"].toInt() == block) return toggleBookmark(block);
    return false;
}
}
