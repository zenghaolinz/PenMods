#include "TextFileSearch.h"
#include <QDir>
#include <QDirIterator>
#include <QFile>
#include <QFileInfo>
#include <QTextCodec>
#include <QVariantMap>
#include <algorithm>

namespace mod::filemanager {
bool isTextFile(const QString& path) {
    const auto suffix = QFileInfo(path).suffix().toLower();
    return QStringList{"txt", "md", "lrc", "json", "xml", "yml", "yaml"}.contains(suffix);
}
static bool contains(QFile& file, QTextCodec* codec, const QString& query, const std::function<bool()>& cancelled,
                     QString& snippet, bool& invalid) {
    file.seek(0); QTextCodec::ConverterState state; QString carry;
    while (!file.atEnd() && !cancelled()) {
        const auto bytes = file.read(64 * 1024);
        if (bytes.isEmpty()) break;
        const auto part = codec->toUnicode(bytes.constData(), bytes.size(), &state);
        if (state.invalidChars) { invalid = true; return false; }
        const auto window = carry + part;
        const auto found = window.indexOf(query, 0, Qt::CaseInsensitive);
        if (found >= 0) {
            snippet = window.mid(std::max(0, found - 20), query.size() + 60).simplified(); return true;
        }
        carry = window.right(std::max(0, query.size() - 1));
    }
    invalid = state.invalidChars || state.remainingChars; return false;
}
TextSearchResult findTextFiles(const QString& root, const QString& value, bool contents,
                               const std::function<bool()>& cancelled) {
    TextSearchResult result;
    const QDir directory(root);
    if (!directory.exists()) { result.error = "导入目录不存在"; return result; }
    const auto query = value.trimmed().left(128);
    if (contents && query.isEmpty()) { result.error = "请输入正文关键词"; return result; }
    QDirIterator iterator(root, QDir::Files | QDir::NoSymLinks | QDir::NoDotAndDotDot, QDirIterator::Subdirectories);
    int visited = 0, skipped = 0;
    while (iterator.hasNext() && !cancelled()) {
        iterator.next();
        if (++visited > 100000) { result.error = "文件过多，仅扫描前 100000 个文件"; break; }
        const auto info = iterator.fileInfo();
        if (!isTextFile(info.fileName())) continue;
        QString snippet;
        bool match = !contents && info.fileName().contains(query, Qt::CaseInsensitive);
        if (contents) {
            if (info.size() > 128LL * 1024 * 1024) { ++skipped; continue; }
            QFile file(info.absoluteFilePath());
            if (!file.open(QIODevice::ReadOnly)) { ++skipped; continue; }
            auto* utf8 = QTextCodec::codecForName("UTF-8");
            auto* codec = QTextCodec::codecForUtfText(file.peek(4096), utf8);
            bool invalid = false;
            match = contains(file, codec, query, cancelled, snippet, invalid);
            if (!match && invalid && codec == utf8 && !cancelled()) {
                if (auto* legacy = QTextCodec::codecForName("GB18030")) {
                    invalid = false; match = contains(file, legacy, query, cancelled, snippet, invalid);
                }
            }
        }
        if (!match || cancelled()) continue;
        result.files.push_back(QVariantMap{{"fileName",info.fileName()}, {"path",info.canonicalFilePath()},
            {"relativePath",directory.relativeFilePath(info.absoluteFilePath())}, {"snippet",snippet}});
        if (result.files.size() == 200) { result.truncated = true; break; }
    }
    if (result.error.isEmpty() && skipped) result.error = QString("跳过 %1 个过大或不可读取的文本").arg(skipped);
    return result;
}
}
