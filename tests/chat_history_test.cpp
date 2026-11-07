#include "ai/ChatHistory.h"
#include "common/util/Network.h"
#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QTemporaryDir>
#include <cstdio>
#include <stdexcept>

static int checks = 0;
static void require(bool value, const char* message) {
    ++checks;
    if (!value) throw std::runtime_error(message);
}
int main(int argc, char** argv) {
    QCoreApplication app(argc, argv);
    try {
        QTemporaryDir directory;
        require(directory.isValid(), "temporary directory");
        const auto path = directory.filePath("ai-history.json");
        mod::ChatHistory history(path);
        require(history.load(), "create history");
        require(history.sessions().size() == 1, "initial session");
        const auto first = history.activeId();
        history.beginTurn("解释 apple");
        history.finishTurn("苹果", "complete");
        require(history.save(), "atomic save");
        require(!QFile::permissions(path).testFlag(QFileDevice::ReadOther), "private file permissions");
        mod::ChatHistory restored(path);
        require(restored.load(), "reload history");
        require(restored.activeId() == first && restored.messages().size() == 2, "restore active messages");
        require(restored.context("teacher").size() == 3, "system plus completed exchange");
        require(restored.lastPrompt() == "解释 apple", "unicode round trip");
        const auto second = restored.create();
        require(first != second, "independent session ID");
        require(restored.context("").empty(), "session context isolation");
        restored.beginTurn("cancel this");
        restored.finishTurn("partial", "stopped");
        require(restored.context("").empty(), "exclude cancelled answer from API context");
        require(restored.messages().back().toMap()["content"] == "partial", "preserve stopped partial reply");
        restored.removeLastTurn();
        require(restored.messages().empty(), "retry replaces last pair");
        restored.beginTurn("pending at power off");
        require(restored.save(), "persist pending turn before request");
        mod::ChatHistory interrupted(path);
        require(interrupted.load(), "reload interrupted stream");
        require(interrupted.messages().back().toMap()["status"] == "stopped", "mark interrupted stream stopped");
        require(interrupted.context("").empty(), "interrupted context excluded");
        require(interrupted.select(first), "switch session");
        require(interrupted.lastPrompt() == "解释 apple", "switch restores correct messages");
        require(!interrupted.select("unknown") && interrupted.activeId() == first, "invalid switch leaves active unchanged");
        interrupted.rename("  单词复习  ");
        require(interrupted.title() == "单词复习", "rename trimmed");
        require(interrupted.sessions().front().toMap()["id"] == first, "recently edited session appears first");
        for (int i = 0; i < 120; ++i) {
            interrupted.beginTurn(QString::number(i));
            interrupted.finishTurn("answer", "complete");
        }
        require(interrupted.messages().size() == 200, "100 exchange retention");
        require(interrupted.context("system").size() == 41, "last 20 exchanges sent to API");
        require(interrupted.context("")[0]["content"] == "100", "context evicts oldest completed exchanges");
        require(interrupted.remove(second) && interrupted.activeId() == first, "delete other session preserves active");
        require(interrupted.remove(first) && interrupted.sessions().size() == 1, "delete last session creates empty session");
        for (int i = 0; i < 35; ++i) {
            interrupted.beginTurn("question"); interrupted.finishTurn("answer", "complete"); interrupted.create();
        }
        require(interrupted.sessions().size() == 30, "30 session retention");
        require(interrupted.save(), "save retained sessions");
        const auto broken = directory.filePath("broken.json");
        QFile corrupt(broken); corrupt.open(QIODevice::WriteOnly); corrupt.write("broken-original"); corrupt.close();
        mod::ChatHistory damaged(broken);
        require(!damaged.load(), "detect corrupted history");
        const auto backups = QDir(directory.path()).entryList({"broken.json.corrupt-*"});
        require(backups.size() == 1, "preserve corrupt original");
        QFile saved(directory.filePath(backups[0])); saved.open(QIODevice::ReadOnly);
        require(saved.readAll() == "broken-original", "backup bytes unchanged");
        require(damaged.save(), "fresh history can be saved after backup");
        const auto blocker = directory.filePath("blocker");
        QFile blocked(blocker); blocked.open(QIODevice::WriteOnly); blocked.write("keep"); blocked.close();
        mod::ChatHistory unwritable(blocker + "/history.json");
        require(!unwritable.load() && !unwritable.error().isEmpty(), "report write failure");
        const auto cappedPath = directory.filePath("capped.json");
        mod::ChatHistory capped(cappedPath);
        require(capped.load(), "create capped history");
        for (int i = 0; i < 70; ++i) { capped.beginTurn("q"); capped.finishTurn(QString(128000, QChar('a')), "complete"); }
        require(capped.save() && QFileInfo(cappedPath).size() <= 8 * 1024 * 1024, "history stays within total storage cap");
        require(capped.messages().size() < 140 && capped.context("").size() == 40, "cap keeps recent context");
        const auto ip = mod::util::localIpv4Address();
        if (argc > 1) require(ip == QString::fromUtf8(argv[1]), "device Wi-Fi address");
        std::printf("PASS: %d native history/network checks; local IP=%s\n", checks, ip.toUtf8().constData());
        return 0;
    } catch (const std::exception& error) {
        std::printf("FAIL after %d checks: %s\n", checks, error.what());
        return 1;
    }
}
