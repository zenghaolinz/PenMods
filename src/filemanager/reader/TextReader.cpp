// SPDX-License-Identifier: GPL-3.0-only
/*
 * Copyright (C) 2022-present, PenUniverse.
 * This file is part of the PenMods open source project.
 */

#include "filemanager/reader/TextReader.h"
#include "filemanager/FileManager.h"

#include "common/Event.h"
#include "common/util/System.h"

#include <QFile>
#include <QQmlContext>

namespace mod::filemanager {

TextReader::TextReader() : mDocument(util::getModuleFileInfo().absoluteDir().filePath("reading-state.json")), mBlockModel(mDocument, this) {
    connect(&Event::getInstance(), &Event::beforeUiInitialization, [this](QQuickView& view, QQmlContext* context) {
        context->setContextProperty("textReader", this);
    });
} // namespace mod::filemanager

void TextReader::open(QString dir) {
    mOpeningFileName = QFileInfo(dir).fileName();
    mBlockModel.beginLoad();
    mDocument.open(QFileInfo(dir).isAbsolute() ? dir : FileManager::getInstance().getCurrentPath().filePath(dir));
    mBlockModel.endLoad();
    emit documentChanged(); emit searchChanged(); emit stateChanged();
}
void TextReader::search(const QString& value) { mDocument.search(value); emit searchChanged(); emit stateChanged(); }
int TextReader::moveMatch(int direction) { auto block = mDocument.moveMatch(direction); emit searchChanged(); return block; }
void TextReader::savePosition(int block) { mDocument.savePosition(block); emit stateChanged(); }
void TextReader::toggleBookmark(int block) { mDocument.toggleBookmark(block); emit stateChanged(); }
void TextReader::removeBookmark(int block) { mDocument.removeBookmark(block); emit stateChanged(); }

bool TextReader::getIsMarkdown() { return mOpeningFileName.endsWith(".md", Qt::CaseInsensitive); }

QString TextReader::getContent() {
    return mDocument.text();
}

QString TextReader::getTitle() { return mOpeningFileName; }
} // namespace mod::filemanager
