#pragma once
#include <QJsonObject>
#include <QStringList>
#include <QVariantList>
#include <QVector>
#include <QCache>
#include <QAbstractListModel>
#include <QTemporaryFile>
#include <memory>

namespace mod::filemanager {
class ReadingDocument {
public:
    explicit ReadingDocument(QString statePath);
    bool open(const QString& path);
    QString error() const { return mError; }
    QString text() const;
    int blockCount() const { return mOffsets.size(); }
    QString block(int index) const;
    int position() const;
    bool savePosition(int block);
    void search(QString query);
    QString query() const { return mQuery; }
    int matchCount() const { return mMatches.size(); }
    int matchIndex() const { return mMatchIndex; }
    int matchBlock() const;
    int moveMatch(int direction);
    QVariantList bookmarks() const;
    bool toggleBookmark(int block);
    bool removeBookmark(int block);
private:
    int blockAt(int offset) const;
    bool save();
    QString readText(int offset, int length) const;
    QString mStatePath, mKey, mQuery, mError;
    QVector<int> mOffsets, mLengths, mMatches;
    std::unique_ptr<QTemporaryFile> mDecoded;
    mutable QCache<int, QString> mBlockCache{128};
    int mCharacters = 0;
    int mMatchIndex = -1;
    QJsonObject mState;
    bool mWritable = true;
};

class ReadingBlockModel : public QAbstractListModel {
public:
    explicit ReadingBlockModel(ReadingDocument& document, QObject* parent = nullptr) : QAbstractListModel(parent), mDocument(document) {}
    int rowCount(const QModelIndex& parent = QModelIndex()) const override { return parent.isValid() ? 0 : mDocument.blockCount(); }
    QVariant data(const QModelIndex& index, int role) const override {
        if (!index.isValid() || index.model() != this || index.row() < 0 || index.row() >= mDocument.blockCount()
            || (role != Qt::UserRole + 1 && role != Qt::DisplayRole)) return {};
        return mDocument.block(index.row());
    }
    QHash<int, QByteArray> roleNames() const override { return {{Qt::UserRole + 1, "modelData"}}; }
    void beginLoad() { beginResetModel(); }
    void endLoad() { endResetModel(); }
private:
    ReadingDocument& mDocument;
};
}
