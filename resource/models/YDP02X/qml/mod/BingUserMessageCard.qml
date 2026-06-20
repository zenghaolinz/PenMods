import QtQuick 2.12
import com.youdao.pen 1.0

import "../commons"
import "../components"
import "../i18n"

Rectangle {
    id: id_user_message_card
    width: 260
    height: id_message_text.contentHeight + 20
    radius: 12
    color: YColors.grayNormal
    opacity: 0
    readonly property alias messageItem: id_message_text 

    Text {
        id: id_message_text
        font.family: qmlGlobal.fontFamilyZhCn
        font.pixelSize: 16
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 10
        width: parent.width - 16
        wrapMode: Text.WrapAnywhere
        textFormat: Text.MarkdownText
        text: model.content
        color: "white"
    }

    Behavior on opacity {
        NumberAnimation { duration: 300 }
    }

    Component.onCompleted: {
        opacity = 1
    }

}