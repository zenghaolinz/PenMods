import QtQuick 2.12
import com.youdao.pen 1.0

import "../commons"
import "../components"
import "../i18n"

BingUserMessageCard {
    id: id_bot_message_card
    height: messageItem.contentHeight + 50

    Rectangle {
        id: id_div_line_2
        width: parent.width
        height: 1
        color: "gray"
        opacity: 0.3
        anchors.top: messageItem.bottom
        anchors.topMargin: 10
    }

    Rectangle {
        id: id_limit_indicator
        width: 12
        height: 12
        radius: height / 2
        color: {
            let r = model.userMessages / model.maxUserMessages
            if (r < 0.5) {
                return "#2C8247"
            } else if (r < 1) {
                return "#EE8F00"
            } else {
                return "#C80000"
            }
        }
        anchors.top: id_div_line_2.bottom
        anchors.topMargin: 8
        anchors.right: parent.right
        anchors.rightMargin: 10

        Text {
            id: id_usage_counter
            text: ("%1 / %2").arg(model.userMessages).arg(model.maxUserMessages)
            anchors.right: parent.left
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            font.pixelSize: 12
            font.family: qmlGlobal.fontFamily
            textFormat: Text.PlainText
            color: "white"
        }

    }

}