import QtQuick 2.12
import com.youdao.pen 1.0

import "../commons"
import "../components"
import "../i18n"

Rectangle {
    id: id_user_message_card
    width: 260
    height: id_message_text.contentHeight + 20
    radius: 20
    color: YColors.grayNormal
    readonly property alias messageItem: id_message_text

    Text {
        id: id_message_text
        font.family: qmlGlobal.fontFamilyZhCn
        font.pixelSize: 15
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 10
        width: parent.width - 16
        wrapMode: Text.WrapAnywhere
        textFormat: Text.PlainText
        text: modelData
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        color: YColors.grayText
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            bot.ask(modelData)
        }
    }

}