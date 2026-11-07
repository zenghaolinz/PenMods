#include <QGuiApplication>
#include <QQmlEngine>
#include <QQmlComponent>
#include <QQmlContext>
#include <QQmlPropertyMap>
#include <QQuickItem>
#include <QDebug>
#include <QQmlExpression>
#include <QAbstractItemModel>
#include <QTemporaryDir>
#include <QFile>
#include "filemanager/reader/ReadingDocument.h"
#include "filemanager/player/VideoPlayback.h"
#include <cstdio>
#include <functional>
#include "../resource/models/YDP02X/qrc_qml.h"
extern bool qRegisterResourceData(int, const unsigned char*, const unsigned char*, const unsigned char*);

int main(int argc, char** argv) {
    qputenv("QT_QPA_PLATFORM", "offscreen");
    qputenv("QT_QUICK_BACKEND", "software");
    QGuiApplication app(argc, argv);
    qmlRegisterType<QObject>("com.youdao.pen", 1, 0, "TestPlaceholder");
    mod::filemanager::VideoPlayback::registerQmlType();
    qRegisterResourceData(3, qt_resource_struct, qt_resource_name, qt_resource_data);
    QQmlEngine engine;
    engine.addImportPath("/usr/qml");
    QQmlPropertyMap global, ai, column, developer, network, system, pageIndex, reader, media, music, enums, fileManager, videoPlayer, videoPlayback;
    QTemporaryDir readingTemp;
    const auto textPath = readingTemp.filePath("book.txt");
    { QFile file(textPath); file.open(QIODevice::WriteOnly); file.write(QString("第一段阅读文本\n搜索与书签测试\n末尾内容").toUtf8()); }
    mod::filemanager::ReadingDocument readingDocument(readingTemp.filePath("state.json"));
    if (!readingDocument.open(textPath)) return 11;
    mod::filemanager::ReadingBlockModel readingModel(readingDocument);
    global.insert("fontFamily", "sans-serif"); global.insert("inputPageShowing", false);
    global.insert("fontFamilyZhCn", "sans-serif");
    global.insert("checkFeature", QVariant::fromValue(engine.evaluate("(function(){return true;})")));
    enums.insert("PageIndex", QVariantMap{{"Dict",0},{"Speech",1},{"Reading",2},{"TextBook",3},{"Fav",4},{"Audioplayer",5},{"History",6},{"Setting",7},{"PowerOff",8}});
    enums.insert("PLAYING", 1); enums.insert("FEATURE_ASSISTANT",1); enums.insert("FEATURE_AUDIO",2); enums.insert("FEATURE_TEXTBOOK",3);
    auto calls = engine.newObject(); engine.globalObject().setProperty("testCalls", calls);
    auto method = [&](QQmlPropertyMap& target, const QString& name, const QString& body) {
        target.insert(name, QVariant::fromValue(engine.evaluate("(function(value){" + body + "})")));
    };
    reader.insert("blocks", QVariant::fromValue<QObject*>(&readingModel));
    reader.insert("savedPosition", 0); reader.insert("lastError", ""); reader.insert("title", "阅读测试.txt");
    reader.insert("searchQuery", ""); reader.insert("matchCount", 0); reader.insert("matchIndex", -1); reader.insert("matchBlock", -1);
    reader.insert("bookmarks", QVariantList{QVariantMap{{"block",1},{"label","2 · 搜索与书签测试"}}});
    method(reader,"savePosition","testCalls.savedPosition=value;");
    method(reader,"search","testCalls.query=value;"); method(reader,"moveMatch","return 1;");
    method(reader,"toggleBookmark","testCalls.bookmark=value;"); method(reader,"removeBookmark","testCalls.removed=value;");
    media.insert("title", "试听.mp3"); media.insert("currentPos",20000); media.insert("duration",100000); media.insert("playState",1); media.insert("playbackRate",1.0);
    method(media,"closeRepeat","testCalls.repeatClosed=true;");
    method(media,"onFastForward","testCalls.forward=value;"); method(media,"onFastBackward","testCalls.backward=value;");
    method(media,"onClickedPlay","testCalls.play=true;"); method(media,"onClickedPause","testCalls.pause=true;");
    method(media,"onClickedPrev","testCalls.prev=true;"); method(media,"onClickedNext","testCalls.next=true;");
    music.insert("playlist", QVariantList{QVariantMap{{"title","试听.mp3"},{"index",0}}, QVariantMap{{"title","第二首.mp3"},{"index",1}}});
    music.insert("currentIndex",0); music.insert("localPlayback",true);
    method(music,"selectTrack","testCalls.track=value;");
    fileManager.insert("textSearchResults", QVariantList{QVariantMap{{"fileName","book.txt"},{"path",textPath},{"relativePath","folder/book.txt"},{"snippet","匹配文本"}}});
    fileManager.insert("textSearching",false); fileManager.insert("textSearchError","");
    method(fileManager,"searchTextFiles","testCalls.fileQuery=value;");
    method(fileManager,"cancelTextSearch","testCalls.searchCancelled=true;");
    videoPlayer.insert("playback", QVariant::fromValue<QObject*>(&videoPlayback));
    videoPlayback.insert("playing", false); videoPlayback.insert("seekable", false);
    videoPlayback.insert("loading", false); videoPlayback.insert("error", "");
    videoPlayback.insert("position", 0); videoPlayback.insert("duration", 0);
    method(videoPlayback,"play", ""); method(videoPlayback,"pause", ""); method(videoPlayback,"close", "");
    ai.insert("messages", QVariantList{
        QVariantMap{{"role", "user"}, {"content", "解释一下 apple，给我一个例句"}, {"status", "complete"}, {"error", ""}},
        QVariantMap{{"role", "assistant"}, {"content", "apple：苹果。例句：I eat an apple every day."}, {"status", "complete"}, {"error", ""}}});
    ai.insert("conversations", QVariantList{
        QVariantMap{{"id", "test"}, {"title", "英语单词复习"}, {"updated_at", "2026-11-06T20:00:00"}, {"count", 1}},
        QVariantMap{{"id", "other"}, {"title", "阅读理解"}, {"updated_at", "2026-11-05T18:00:00"}, {"count", 3}}});
    ai.insert("activeConversationId", "test"); ai.insert("conversationTitle", "测试会话");
    ai.insert("requesting", false); ai.insert("lastError", "");
    column.insert("limit", 80); developer.insert("wifiPageShowIp", true); developer.insert("offlineRM", false);
    network.insert("localIpAddress", "192.0.2.10");
    system.insert("ocrCompletedResult", ""); pageIndex.insert("AIAssistant", 103);
    for (const auto& pair : QList<QPair<QString, QObject*>>{{"qmlGlobal", &global}, {"aiAssistant", &ai},
            {"columnDb", &column}, {"developerSettings", &developer}, {"networkSettings", &network},
            {"systemBase", &system}, {"PageIndex", &pageIndex}, {"textReader", &reader},
            {"mediaPlayerManager", &media}, {"musicPlayer", &music}, {"YEnum", &enums}, {"fileManager", &fileManager}, {"videoPlayer", &videoPlayer}})
        engine.rootContext()->setContextProperty(pair.first, pair.second);
    for (const auto& path : {"qml/AIChatPage.qml", "qml/settingpages/ColumnDbPage.qml", "qml/settingpages/DeveloperSettingPage.qml",
            "qml/audioplayer/LocalAudioControls.qml", "qml/audiopages/FileManagerTextViewer.qml", "qml/audiopages/TextFileSearchPanel.qml",
            "qml/audiopages/ImageViewer.qml", "qml/audiopages/VideoPlayer.qml", "qml/YIndexPage.qml"}) {
        QQmlComponent component(&engine, QUrl(QString("qrc:/") + path));
        if (component.isError()) { qWarning() << component.errors(); return 1; }
        QObject* object = component.create();
        if (!object) { qWarning() << component.errors(); return 2; }
        object->setProperty("width", 320); object->setProperty("height", 170);
        object->setProperty("visible", true);
        if (QString(path).contains("AIChat")) object->setProperty("historyOpen", true);
        QCoreApplication::processEvents();
        auto evaluate = [&](const QString& expression) {
            QQmlExpression script(engine.rootContext(), object, expression);
            auto result = script.evaluate();
            if (script.hasError()) qWarning() << script.error();
            return result;
        };
        if (QString(path).contains("FileManagerTextViewer")) {
            const auto* view = object->findChild<QObject*>("reading-blocks-view");
            if (!view || view->property("count").toInt() != readingDocument.blockCount()) return 12;
            std::puts("PASS: reader binds the real lazy text model");
        }
        if (QString(path).contains("ImageViewer")) {
            evaluate("setZoom(8)");
            if (object->property("zoom").toInt() != 4) return 13;
            evaluate("setZoom(0)");
            if (object->property("zoom").toInt() != 1) return 14;
            std::puts("PASS: image viewer clamps zoom to 1–4x");
        }
        if (QString(path).contains("LocalAudioControls")) {
            evaluate("seekTo(50000)");
            if (calls.property("forward").toInt() != 30000) return 4;
            evaluate("seekTo(-1000)");
            if (calls.property("backward").toInt() != 20000) return 5;
            evaluate("seekTo(200000)");
            if (calls.property("forward").toInt() != 80000 || !calls.property("repeatClosed").toBool()) return 6;
            evaluate("hold(-1)");
            if (calls.property("backward").toInt() != 5000 || object->property("heldDirection").toInt() != -1) return 7;
            object->setProperty("visible",false);
            if (object->property("heldDirection").toInt() != 0) return 8;
            std::puts("PASS: seek clamping, forward/backward, long-hold start and close cancellation");
        }
        if (QString(path).contains("YIndexPage")) {
            auto* menu = object->findChild<QAbstractItemModel*>("penmods-home-menu");
            if (!menu || menu->rowCount() < 8) return 9;
            bool firstAi = false;
            const auto roles = menu->roleNames();
            for (auto it = roles.begin(); it != roles.end(); ++it) {
                if (it.value() == "pageIndex") firstAi = menu->data(menu->index(0,0),it.key()).toInt() == -100;
            }
            if (!firstAi) return 10;
            std::puts("PASS: large AI card precedes all seven official home cards");
        }
        if (QString(path).contains("ColumnDb")) {
            // Repeater delegates belong to the visual item tree.
            std::function<QObject*(QQuickItem*)> find = [&](QQuickItem* item) -> QObject* {
                if (item->objectName() == "load-count-30") return item;
                for (auto* child : item->childItems()) if (auto* result = find(child)) return result;
                return nullptr;
            };
            auto* button = find(qobject_cast<QQuickItem*>(object));
            if (!button || !QMetaObject::invokeMethod(button, "clicked") || column.value("limit").toInt() != 30) return 3;
        }
        std::printf("PASS: create %s\n", path);
        delete object;
    }
    std::puts("PASS: list load-count button updates its bound setting");
    return 0;
}
