import QtQuick 2.12
import com.youdao.pen 1.0

import "../commons"
import "../components"
import "../i18n"

Item {
    id: id_bing_tip_message_card
    height: id_text_area.contentHeight + 5
    opacity: 0

    YImage {
        id: id_tip_icon
        sourceSize: Qt.size(22, 22)
        resource: {
            switch (model.type) {
            case MEnum.BI_BotTip:
                return "new-bing-bot-tip"
            case MEnum.BI_BotError:
                return "new-bing-bot-error"
            default:
                return undefined
            }
        }
    }

    Text {
        id: id_text_area
        anchors.top: id_tip_icon.top
        anchors.topMargin: 2
        anchors.left: id_tip_icon.right
        anchors.leftMargin: 6
        font.pixelSize: 14
        font.family: qmlGlobal.fontFamilyZhCn
        color: "white"
        wrapMode: Text.WrapAnywhere
        textFormat: Text.PlainText
        text: model.content
        width: 260 - 25
    }

    Behavior on opacity {
        NumberAnimation { duration: 300 }
    }

    Component.onCompleted: {
        opacity = 1
    }

}
