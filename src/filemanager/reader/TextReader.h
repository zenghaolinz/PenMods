// SPDX-License-Identifier: GPL-3.0-only
/*
 * Copyright (C) 2022-present, PenUniverse.
 * This file is part of the PenMods open source project.
 */

#pragma once
#include "ReadingDocument.h"

namespace mod::filemanager {

class TextReader : public QObject, public Singleton<TextReader> {
    Q_OBJECT

    Q_PROPERTY(bool isMarkdown READ getIsMarkdown NOTIFY documentChanged);
    Q_PROPERTY(QString content READ getContent NOTIFY documentChanged);
    Q_PROPERTY(QString title READ getTitle NOTIFY documentChanged)
    Q_PROPERTY(QAbstractItemModel* blocks READ blocks CONSTANT)
    Q_PROPERTY(int savedPosition READ savedPosition NOTIFY documentChanged)
    Q_PROPERTY(QString lastError READ lastError NOTIFY stateChanged)
    Q_PROPERTY(QVariantList bookmarks READ bookmarks NOTIFY stateChanged)
    Q_PROPERTY(int matchCount READ matchCount NOTIFY searchChanged)
    Q_PROPERTY(int matchIndex READ matchIndex NOTIFY searchChanged)
    Q_PROPERTY(int matchBlock READ matchBlock NOTIFY searchChanged)
    Q_PROPERTY(QString searchQuery READ searchQuery NOTIFY searchChanged)

public:
    Q_INVOKABLE void open(QString dir);

    bool getIsMarkdown();

    QString getContent();

    QString getTitle();
    QAbstractItemModel* blocks() { return &mBlockModel; }
    int savedPosition() const { return mDocument.position(); }
    QString lastError() const { return mDocument.error(); }
    QVariantList bookmarks() const { return mDocument.bookmarks(); }
    int matchCount() const { return mDocument.matchCount(); }
    int matchIndex() const { return mDocument.matchIndex(); }
    int matchBlock() const { return mDocument.matchBlock(); }
    QString searchQuery() const { return mDocument.query(); }
    Q_INVOKABLE void search(const QString& value);
    Q_INVOKABLE int moveMatch(int direction);
    Q_INVOKABLE void savePosition(int block);
    Q_INVOKABLE void toggleBookmark(int block);
    Q_INVOKABLE void removeBookmark(int block);
signals:
    void documentChanged();
    void searchChanged();
    void stateChanged();

private:
    friend Singleton<TextReader>;
    explicit TextReader();

    QString mOpeningFileName;
    QString mContent;
    ReadingDocument mDocument;
    ReadingBlockModel mBlockModel;
}; // namespace mod::filemanager
} // namespace mod::filemanager
