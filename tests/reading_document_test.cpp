#include "filemanager/reader/ReadingDocument.h"
#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QTemporaryDir>
#include <QTextCodec>
#include <cstdio>
#include <stdexcept>

static int checks = 0;
static void require(bool value, const char* message) { ++checks; if (!value) throw std::runtime_error(message); }
static void write(const QString& path, const QByteArray& bytes) { QFile file(path); if (!file.open(QIODevice::WriteOnly) || file.write(bytes) != bytes.size()) throw std::runtime_error("fixture write"); }
int main(int argc, char** argv) {
    QCoreApplication app(argc, argv);
    try {
        QTemporaryDir temp;
        require(temp.isValid(), "temporary storage");
        const auto source = temp.filePath("book.txt"), state = temp.filePath("state.json");
        const auto content = QString("标题\n") + QString(239, 'a') + "NEEDLE" + QString(200, 'b') + "\napple Apple\n末尾";
        write(source, content.toUtf8());
        mod::filemanager::ReadingDocument document(state);
        require(document.open(source), "UTF-8 open");
        require(document.text() == content && document.blockCount() >= 5, "unicode and long-line segmentation");
        document.search("needle");
        require(document.matchCount() == 1 && document.matchBlock() == 1, "search across visual block boundary");
        document.search("apple");
        require(document.matchCount() == 2, "case-insensitive search");
        require(document.moveMatch(1) >= 0 && document.matchIndex() == 1, "next result");
        document.moveMatch(1);
        require(document.matchIndex() == 0, "result wrapping");
        document.moveMatch(-1);
        require(document.matchIndex() == 1, "previous result wrapping");
        document.search("missing"); require(document.matchBlock() == -1 && document.moveMatch(1) == -1, "missing query");
        require(document.savePosition(2) && document.toggleBookmark(2), "save position and bookmark");
        mod::filemanager::ReadingDocument restored(state);
        require(restored.open(source) && restored.position() == 2, "restore position after restart");
        require(restored.bookmarks().size() == 1 && restored.bookmarks()[0].toMap()["block"].toInt() == 2, "restore bookmark");
        QFile original(source); original.open(QIODevice::ReadOnly);
        require(original.readAll() == content.toUtf8(), "source text remains unchanged"); original.close();
        const auto other = temp.filePath("other.txt"); write(other, "other");
        require(restored.open(other) && restored.bookmarks().empty() && restored.position() == 0, "file state isolation");
        require(restored.open(source) && restored.removeBookmark(2) && restored.bookmarks().empty(), "remove bookmark");
        require(!restored.removeBookmark(2), "removing absent bookmark is safe");
        restored.toggleBookmark(1); restored.savePosition(1);
        write(source, "changed document");
        require(restored.open(source) && restored.position() == 0 && restored.bookmarks().empty(), "content changes reset stale offsets");
        auto* gb = QTextCodec::codecForName("GB18030"); require(gb != nullptr, "Chinese codec available");
        const auto legacy = temp.filePath("gb.txt"); write(legacy, gb->fromUnicode("中文阅读测试"));
        require(restored.open(legacy) && restored.text() == "中文阅读测试", "GB18030 fallback");
        const auto utf16 = temp.filePath("utf16.txt");
        write(utf16, QByteArray::fromHex("fffe") + QTextCodec::codecForName("UTF-16LE")->fromUnicode("双字节文本"));
        require(restored.open(utf16) && restored.text() == "双字节文本", "UTF-16 BOM decoding");
        require(!restored.open(temp.filePath("absent.txt")) && restored.blockCount() == 0 && !restored.error().isEmpty(), "failed open clears stale content");
        const auto large = temp.filePath("large.txt"); QFile oversized(large); oversized.open(QIODevice::WriteOnly); oversized.resize(128LL * 1024 * 1024 + 1); oversized.close();
        require(!restored.open(large), "file size limit");
        const auto bigBook = temp.filePath("big-book.txt");
        { QFile file(bigBook); file.open(QIODevice::WriteOnly); const QByteArray chunk(65536, 'a'); for (int i = 0; i < 80; ++i) file.write(chunk); file.write("TAIL_TOKEN"); }
        require(restored.open(bigBook), "read a text larger than four MB");
        require(restored.blockCount() > 20000 && restored.text().size() == 65536, "large file uses a bounded preview and lazy blocks");
        restored.search("TAIL_TOKEN");
        require(restored.matchCount() == 1 && restored.matchBlock() == restored.blockCount() - 1, "search reaches the end of a large file");
        mod::filemanager::ReadingBlockModel model(restored);
        require(model.rowCount() == restored.blockCount() && model.data(model.index(model.rowCount()-1,0),Qt::UserRole+1).toString().contains("TAIL_TOKEN"), "lazy QML model returns tail text");
        require(restored.savePosition(restored.blockCount()-1) && restored.toggleBookmark(restored.blockCount()-1), "large file position and bookmark");
        mod::filemanager::ReadingDocument bigRestored(state);
        require(bigRestored.open(bigBook) && bigRestored.position() == bigRestored.blockCount()-1 && bigRestored.bookmarks().size() == 1, "restore a large-file bookmark");
        const auto newline = temp.filePath("newline.txt"); write(newline, QByteArray(65535, 'a') + "\r\nb");
        require(restored.open(newline), "decode CRLF at a stream boundary");
        restored.search("a\nb"); require(restored.matchCount() == 1, "search over normalized stream boundaries");
        const auto middleBom = temp.filePath("middle-bom.txt");
        const auto withBom = QString(32768, 'a') + QChar(0xfeff) + "needle";
        write(middleBom, withBom.toUtf8());
        require(restored.open(middleBom) && restored.text() == withBom, "preserve interior Unicode markers in cached pages");
        const auto repeats = temp.filePath("repeats.txt"); write(repeats, QString("q ").repeated(600).toUtf8());
        restored.open(repeats); restored.search("q"); require(restored.matchCount() == 500, "bounded search results");
        const auto many = temp.filePath("many.txt"); write(many, QString("line\n").repeated(60).toUtf8()); restored.open(many);
        for (int i = 0; i < 50; ++i) require(restored.toggleBookmark(i), "create bookmark");
        require(!restored.toggleBookmark(50) && restored.bookmarks().size() == 50, "bookmark limit");
        const auto corrupt = temp.filePath("broken-state.json"); write(corrupt, "broken-original");
        mod::filemanager::ReadingDocument repaired(corrupt); repaired.open(other);
        require(QDir(temp.path()).entryList({"broken-state.json.corrupt-*"}).size() == 1 && repaired.savePosition(0), "preserve corrupt metadata before recovery");
        std::printf("PASS: %d native reading/search/bookmark checks\n", checks);
        return 0;
    } catch (const std::exception& error) { std::printf("FAIL after %d checks: %s\n", checks, error.what()); return 1; }
}
