#include "filemanager/TextFileSearch.h"
#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QTemporaryDir>
#include <QTextCodec>
#include <cstdio>
#include <stdexcept>
static int checks = 0;
static void require(bool value, const char* message) { ++checks; if (!value) throw std::runtime_error(message); }
static void write(const QString& path, const QByteArray& bytes) { QDir().mkpath(QFileInfo(path).absolutePath()); QFile file(path); if (!file.open(QIODevice::WriteOnly) || file.write(bytes) != bytes.size()) throw std::runtime_error("fixture write"); }
int main(int argc, char** argv) {
    QCoreApplication app(argc,argv);
    try {
        QTemporaryDir temp, outside;
        require(temp.isValid() && outside.isValid(), "temporary directories");
        write(temp.filePath("小说/海边.txt"), QString("海边看星星").toUtf8());
        write(temp.filePath("nested/story.TXT"), "APPLE and orange");
        write(temp.filePath("nested/legacy.md"), QTextCodec::codecForName("GB18030")->fromUnicode("中文星星"));
        write(temp.filePath("record.mp3"), "星星");
        auto result = mod::filemanager::findTextFiles(temp.path(),"STORY",false);
        require(result.files.size() == 1 && result.files[0].toMap()["relativePath"] == "nested/story.TXT", "recursive case-insensitive file names");
        result = mod::filemanager::findTextFiles(temp.path(),"apple",true);
        require(result.files.size() == 1 && result.files[0].toMap()["snippet"].toString().contains("APPLE"), "cross-file content match with snippet");
        result = mod::filemanager::findTextFiles(temp.path(),"星星",true);
        require(result.files.size() == 2, "UTF-8 and GB18030 contents, audio excluded");
        require(mod::filemanager::findTextFiles(temp.path(),"",false).files.size() == 3, "browse all text files");
        require(!mod::filemanager::findTextFiles(temp.path(),"",true).error.isEmpty(), "empty content query rejected");
        require(mod::filemanager::findTextFiles(temp.path(),"absent",false).files.empty(), "missing name");
        write(outside.filePath("external.txt"), "outside marker");
        require(QFile::link(outside.filePath("external.txt"),temp.filePath("linked.txt")), "create symlink fixture");
        require(mod::filemanager::findTextFiles(temp.path(),"outside marker",true).files.empty(), "do not follow external file symlinks");
        write(temp.filePath("boundary.txt"), QByteArray(65533,'a') + "needle");
        require(mod::filemanager::findTextFiles(temp.path(),"needle",true).files.size() == 1, "content keyword across decode chunks");
        require(mod::filemanager::findTextFiles(temp.path(),"needle",true,[]{ return true; }).files.empty(), "cancel scanning");
        require(!mod::filemanager::findTextFiles(temp.filePath("missing"),"q",false).error.isEmpty(), "missing root reported");
        for (int i = 0; i < 205; ++i) write(temp.filePath("many/entry-"+QString::number(i)+".txt"),"entry");
        result = mod::filemanager::findTextFiles(temp.path(),"entry-",false);
        require(result.files.size() == 200 && result.truncated, "bound result count");
        std::printf("PASS: %d native text-file search checks\n",checks); return 0;
    } catch (const std::exception& error) { std::printf("FAIL after %d checks: %s\n",checks,error.what()); return 1; }
}
