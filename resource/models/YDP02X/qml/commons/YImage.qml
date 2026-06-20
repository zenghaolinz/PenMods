import QtQuick 2.12

YImageBase {
    property string imageName: ""
    source: ("" === imageName) ? "" : ("image://icons/%1.png").arg(imageName)
}
