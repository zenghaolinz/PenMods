import QtQuick 2.12
import com.youdao.pen 1.0

import "../commons"
import "../components"
import "../i18n"

Item {
    width: parent.width
    height: id_chose_conversation_style_tip.height + id_style_creative.height + id_div_line.height + 28

    Image {
        id: id_new_bing_logo
        anchors.top: parent.top
        anchors.topMargin: 16
        anchors.left: parent.left
        anchors.leftMargin: 2
        width: 30
        height: 44
        sourceSize: Qt.size(30, 44)
        source: res.get("new-bing-logo")
    }

    YText {
        id: id_chose_conversation_style_tip
        color: YColors.grayText
        font.family: qmlGlobal.fontFamilyZhCn
        font.pixelSize: 16
        anchors.top: parent.top
        anchors.topMargin: 12
        anchors.left: id_new_bing_logo.right
        anchors.leftMargin: 68
        text: "选择对话偏好"
    }

    Grid {
        id: id_grid
        anchors.top: id_chose_conversation_style_tip.bottom
        anchors.topMargin: 6
        anchors.left: id_new_bing_logo.right
        anchors.leftMargin: 12
        columns: 3
        columnSpacing: 6

        YButton {
            id: id_style_creative
            implicitHeight: 27
            implicitWidth: 67
            radius: 8
            color: bot.conversationStyle === MEnum.BI_Creative ? "#8B257E" : "#2D2E33"
            mouseAreaMargins: -4
            pixelSize: 14
            text: "创造性"
            enabled: bot.conversationStyle === MEnum.BI_Creative || bot.isStartOfSession
            onClicked: {
                bot.conversationStyle = MEnum.BI_Creative
            }
        }

        YButton {
            id: id_style_balanced
            implicitHeight: 27
            implicitWidth: 67
            radius: 8
            color: bot.conversationStyle === MEnum.BI_Balanced ? "#2870EA" : "#2D2E33"
            mouseAreaMargins: -4
            pixelSize: 14
            text: "中庸"
            enabled: bot.conversationStyle === MEnum.BI_Balanced || bot.isStartOfSession
            onClicked: {
                bot.conversationStyle = MEnum.BI_Balanced
            }
        }

        YButton {
            id: id_style_precise
            implicitHeight: 27
            implicitWidth: 67
            radius: 8
            color: bot.conversationStyle === MEnum.BI_Precise ? "#005366" : "#2D2E33"
            mouseAreaMargins: -4
            pixelSize: 14
            text: "准确性"
            enabled: bot.conversationStyle === MEnum.BI_Precise || bot.isStartOfSession
            onClicked: {
                bot.conversationStyle = MEnum.BI_Precise
            }
        }
    }

    YVerticalDividingLine {
        id: id_div_line
        anchors.top: id_grid.bottom
        anchors.topMargin: 10
        width: parent.width
    }

}