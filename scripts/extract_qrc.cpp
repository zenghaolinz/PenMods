#include "../resource/models/YDP02X/qrc_qml.h"

#include <QCoreApplication>
#include <QDir>
#include <QDirIterator>
#include <QFile>
#include <QFileInfo>

bool qRegisterResourceData(int, const unsigned char*, const unsigned char*, const unsigned char*);

int main(int argc, char** argv) {
    QCoreApplication app(argc, argv);
    if (argc != 2 || !qRegisterResourceData(3, qt_resource_struct, qt_resource_name, qt_resource_data)) {
        return 1;
    }

    const QString outputRoot = QString::fromLocal8Bit(argv[1]);
    QDirIterator it(":/", QDirIterator::Subdirectories);
    while (it.hasNext()) {
        const QString resourcePath = it.next();
        const QString relativePath = resourcePath.mid(2);
        if (relativePath.isEmpty()) {
            continue;
        }

        const QString outputPath = QDir(outputRoot).filePath(relativePath);
        if (it.fileInfo().isDir()) {
            if (!QDir().mkpath(outputPath)) {
                return 2;
            }
            continue;
        }

        if (!QDir().mkpath(QFileInfo(outputPath).path())) {
            return 3;
        }
        QFile::remove(outputPath);
        if (!QFile(resourcePath).copy(outputPath)) {
            return 4;
        }
    }
    return 0;
}
