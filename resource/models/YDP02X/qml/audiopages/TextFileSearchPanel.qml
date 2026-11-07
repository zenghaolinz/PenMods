import QtQuick 2.12
import "../commons"

Rectangle {
    id: panel
    color: "#151B27"
    property string query: ""
    property bool searchContents: false
    signal closeRequested()
    signal requestQuery()
    signal openResult(string path)
    function run() { fileManager.searchTextFiles(query, searchContents) }
    onVisibleChanged: { if (visible) run(); else fileManager.cancelTextSearch() }
    Component.onDestruction: fileManager.cancelTextSearch()
    MouseArea { anchors.fill: parent }
    Row {
        x: 6; y: 4; spacing: 6
        YButtonBase {
            width: 58; height: 30; radius: 6; color: !searchContents ? "#3578B8" : YColors.grayNormal
            onClicked: { searchContents = false; run() }
            YTextMedium { anchors.centerIn: parent; text: "文件名"; font.pixelSize: 12 }
        }
        YButtonBase {
            width: 48; height: 30; radius: 6; color: searchContents ? "#3578B8" : YColors.grayNormal
            onClicked: { searchContents = true; if (!query.length) requestQuery(); else run() }
            YTextMedium { anchors.centerIn: parent; text: "内容"; font.pixelSize: 12 }
        }
        YButtonBase {
            width: 48; height: 30; radius: 6
            onClicked: requestQuery()
            YTextMedium { anchors.centerIn: parent; text: "输入"; font.pixelSize: 12 }
        }
        YButtonBase {
            width: 48; height: 30; radius: 6
            onClicked: closeRequested()
            YTextMedium { anchors.centerIn: parent; text: "返回"; font.pixelSize: 12 }
        }
    }
    YTextBase {
        x: 8; y: 40; width: parent.width - 16; font.pixelSize: 11; color: "#B9C8DD"
        text: fileManager.textSearching ? "正在搜索导入目录及子文件夹…" : (query.length ? query : "所有文本") + " · " + fileManager.textSearchResults.length + " 个文件"
        textFormat: Text.PlainText; elide: Text.ElideRight
    }
    ListView {
        anchors.fill: parent; anchors.topMargin: 62; anchors.leftMargin: 6; anchors.rightMargin: 8
        anchors.bottomMargin: fileManager.textSearchError.length ? 23 : 6
        clip: true; spacing: 6; model: fileManager.textSearchResults
        delegate: YButtonBase {
            width: ListView.view.width; height: searchContents ? 70 : 50; radius: 6
            onClicked: openResult(modelData.path)
            YTextBase { x: 7; y: 5; width: parent.width - 14; text: modelData.fileName; textFormat: Text.PlainText; elide: Text.ElideRight; color: "white"; font.pixelSize: 14 }
            YTextBase { x: 7; y: 27; width: parent.width - 14; text: modelData.relativePath; textFormat: Text.PlainText; elide: Text.ElideLeft; color: "#9AAAC4"; font.pixelSize: 10 }
            YTextBase { x: 7; y: 46; width: parent.width - 14; visible: searchContents; text: modelData.snippet; textFormat: Text.PlainText; elide: Text.ElideRight; color: "#CCD8ED"; font.pixelSize: 11 }
        }
        YTextBase {
            anchors.centerIn: parent; width: parent.width
            visible: !fileManager.textSearching && !fileManager.textSearchResults.length
            text: query.length ? "没有找到匹配文本" : "按文件名或正文关键词查找文本"
            wrapMode: Text.Wrap; horizontalAlignment: Text.AlignHCenter; color: YColors.grayText; font.pixelSize: 13
        }
    }
    YTextBase {
        x: 8; width: parent.width - 16; anchors.bottom: parent.bottom; anchors.bottomMargin: 5
        visible: fileManager.textSearchError.length > 0
        text: fileManager.textSearchError; textFormat: Text.PlainText; elide: Text.ElideRight; color: "#FFBD80"; font.pixelSize: 11
    }
}
