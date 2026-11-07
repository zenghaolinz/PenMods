import QtQuick 2.12
import "../commons"
import "../components"

YBackButtonPage {
    id: reader
    objectName: "FileManagerTextViewer.qml"
    property int fontPixels: 18
    property bool bookmarksOpen: false
    function currentBlock() {
        const index = content.indexAt(2, content.contentY + 4)
        return index >= 0 ? index : Math.max(0, content.currentIndex)
    }
    function jump(block) {
        if (block < 0 || content.count === 0) return
        content.currentIndex = Math.min(content.count - 1, block)
        content.positionViewAtIndex(content.currentIndex, ListView.Beginning)
    }
    function nextMatch(direction) { jump(textReader.moveMatch(direction)) }
    function changeFont(delta) {
        const block = currentBlock()
        fontPixels = Math.max(14, Math.min(26, fontPixels + delta))
        Qt.callLater(function() { reader.jump(block) })
    }
    Timer { id: saveTimer; interval: 700; onTriggered: textReader.savePosition(currentBlock()) }
    Row {
        x: 58; y: 4; spacing: 6
        YButtonBase {
            width: 48; height: 30; radius: 6; color: "#335A7A"
            onClicked: requestSearchKeyboard()
            YTextMedium { anchors.centerIn: parent; text: textReader.searchQuery.length ? "重搜" : "搜索"; font.pixelSize: 13 }
        }
        YButtonBase {
            visible: !textReader.searchQuery.length
            width: 48; height: 30; radius: 6
            onClicked: bookmarksOpen = true
            YTextMedium { anchors.centerIn: parent; text: "书签"; font.pixelSize: 13 }
        }
        YButtonBase {
            width: 36; height: 30; radius: 6
            onClicked: { if (textReader.searchQuery.length) nextMatch(-1); else changeFont(-2) }
            YTextMedium { anchors.centerIn: parent; text: textReader.searchQuery.length ? "上一" : "A−"; font.pixelSize: 12 }
        }
        YButtonBase {
            width: 36; height: 30; radius: 6
            onClicked: { if (textReader.searchQuery.length) nextMatch(1); else changeFont(2) }
            YTextMedium { anchors.centerIn: parent; text: textReader.searchQuery.length ? "下一" : "A+"; font.pixelSize: 12 }
        }
        YTextBase {
            visible: textReader.searchQuery.length > 0
            width: 42; height: 30; verticalAlignment: Text.AlignVCenter
            text: (textReader.matchIndex + 1) + "/" + textReader.matchCount
            color: "white"; font.pixelSize: 12
        }
        YButtonBase {
            visible: textReader.searchQuery.length > 0
            width: 32; height: 30; radius: 6
            onClicked: textReader.search("")
            YTextMedium { anchors.centerIn: parent; text: "×" }
        }
    }
    ListView {
        id: content
        objectName: "reading-blocks-view"
        anchors.fill: parent; anchors.leftMargin: 58; anchors.rightMargin: 10
        anchors.topMargin: 40; anchors.bottomMargin: 26
        clip: true; model: textReader.blocks
        onContentYChanged: if (visible && count > 0) saveTimer.restart()
        delegate: Rectangle {
            width: content.width; height: blockText.implicitHeight + 6
            color: textReader.searchQuery.length && index === textReader.matchBlock ? "#324C6F" : "transparent"
            Text {
                id: blockText
                width: parent.width; y: 3
                text: modelData.length ? modelData : " "
                textFormat: Text.PlainText; wrapMode: Text.Wrap
                font.family: qmlGlobal.fontFamilyZhCn; font.pixelSize: fontPixels; color: "white"
            }
        }
    }
    YTextBase {
        x: 58; width: parent.width - 68; anchors.bottom: parent.bottom; anchors.bottomMargin: 6
        text: textReader.lastError.length ? textReader.lastError : (content.count ? Math.round((currentBlock() + 1) * 100 / content.count) + "% · " : "") + textReader.title
        textFormat: Text.PlainText; elide: Text.ElideRight; font.pixelSize: 11
        color: textReader.lastError.length ? "#FFAB91" : YColors.grayText
    }
    Rectangle {
        anchors.fill: parent; anchors.leftMargin: 54; color: "#151B27"; visible: bookmarksOpen
        MouseArea { anchors.fill: parent }
        YTextBase { x: 6; y: 10; text: "书签 " + textReader.bookmarks.length + "/50"; color: "white"; font.pixelSize: 13 }
        YButtonBase {
            x: 100; y: 4; width: 90; height: 30; radius: 5; color: "#335A7A"
            onClicked: textReader.toggleBookmark(currentBlock())
            YTextMedium { anchors.centerIn: parent; text: "标记/取消"; font.pixelSize: 12 }
        }
        YButtonBase {
            anchors.right: parent.right; anchors.rightMargin: 8; y: 4; width: 48; height: 30; radius: 5
            onClicked: bookmarksOpen = false
            YTextMedium { anchors.centerIn: parent; text: "返回"; font.pixelSize: 12 }
        }
        ListView {
            anchors.fill: parent; anchors.topMargin: 40; anchors.leftMargin: 6; anchors.rightMargin: 8
            clip: true; spacing: 6; model: textReader.bookmarks
            delegate: YButtonBase {
                width: ListView.view.width; height: 42; radius: 6
                onClicked: { reader.jump(modelData.block); bookmarksOpen = false }
                YTextBase { x: 7; y: 10; width: parent.width - 45; text: modelData.label; textFormat: Text.PlainText; elide: Text.ElideRight; color: "white"; font.pixelSize: 13 }
                YButtonBase {
                    anchors.right: parent.right; anchors.rightMargin: 3; anchors.verticalCenter: parent.verticalCenter
                    width: 34; height: 34; radius: 5; color: "#653A40"
                    onClicked: textReader.removeBookmark(modelData.block)
                    YTextMedium { anchors.centerIn: parent; text: "×" }
                }
            }
            YTextBase { anchors.centerIn: parent; visible: !textReader.bookmarks.length; text: "在阅读位置点击“标记/取消”添加书签"; width: parent.width; wrapMode: Text.Wrap; font.pixelSize: 13; color: YColors.grayText }
        }
    }
    YPagePopHelper {
        id: keyboardHelper
        property bool keyboardOpen: false
        isShowing: keyboardOpen
        function initialize(page) {
            page.backButtonClicked.connect(function() { keyboardOpen = false; qmlGlobal.inputPageShowing = false; page.todoDestroy() })
            page.inputFinished.connect(function(value) { textReader.search(value); reader.jump(textReader.matchBlock) })
            page.placeHolderText = "搜索本文（最多128字）"
            page.enterText(textReader.searchQuery)
            keyboardOpen = true
            page.show(); qmlGlobal.inputPageShowing = true
        }
    }
    function requestSearchKeyboard() {
        if (keyboardHelper.keyboardOpen) return
        const component = Qt.createComponent("qrc:/qml/YInputPage.qml", Component.PreferSynchronous)
        if (component.status !== Component.Ready) return
        const page = component.createObject(keyboardHelper.containerItem)
        if (page) keyboardHelper.initialize(page)
    }
    Component.onCompleted: Qt.callLater(function() {
        reader.jump(textReader.searchQuery.length && textReader.matchBlock >= 0 ? textReader.matchBlock : textReader.savedPosition)
    })
    Component.onDestruction: { saveTimer.stop(); textReader.savePosition(currentBlock()) }
}
