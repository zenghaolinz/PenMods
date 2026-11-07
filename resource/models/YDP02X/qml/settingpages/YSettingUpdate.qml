import QtQuick 2.12

import "../commons"
import "../components"

YSettingItemPage {
    objectName: "YPage===YSettingUpdate.qml"

    Flickable {
        anchors.fill: parent
        anchors.leftMargin: 54
        anchors.rightMargin: 10
        contentHeight: id_column.height
        clip: true

        Column {
            id: id_column
            width: parent.width
            spacing: 8

            YSettingItemTitle { title: "版本与更新" }

            YSettingAboutItem {
                title: "当前版本"
                value: mod.version
            }

            DescribedClickableTextBox {
                width: parent.width
                opacityChangableWhenPressed: false
                describeItem.width: 200
                title: "手动更新"
                describe: "本适配版已停用旧在线更新服务。\n请使用与 YDP02X 2.1.2 固件匹配的安装包更新。"
            }
        }
    }
}
