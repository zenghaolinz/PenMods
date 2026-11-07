#pragma once
#include <QString>
#include <QVariantList>
#include <functional>

namespace mod::filemanager {
struct TextSearchResult { QVariantList files; QString error; bool truncated = false; };
TextSearchResult findTextFiles(const QString& root, const QString& query, bool contents,
                               const std::function<bool()>& cancelled = [] { return false; });
bool isTextFile(const QString& path);
}
