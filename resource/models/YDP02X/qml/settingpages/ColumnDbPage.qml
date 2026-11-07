import QtQuick 2.12
import "../commons"
import "../components"

YSettingItemPage {
    objectName: "YPage===ColumnDbPage.qml"
    Flickable {
        anchors.fill: parent
        anchors.leftMargin: 54
        anchors.rightMargin: 10
        contentHeight: content.height
        clip: true
        Column {
            id: content
            width: parent.width
            spacing: 8
            YSettingItemTitle { title: "列表加载数量：" + columnDb.limit }
            Row {
                spacing: 8
                Repeater {
                    model: [10, 30, 50, 80, 100]
                    delegate: YButtonBase {
                        objectName: "load-count-" + modelData
                        width: 40
                        height: 34
                        radius: 6
                        color: columnDb.limit === modelData ? "#3578B8" : YColors.grayNormal
                        onClicked: columnDb.limit = modelData
                        YTextMedium { anchors.centerIn: parent; text: modelData }
                    }
                }
            }
            YTextBase {
                width: parent.width
                text: "高级设置：调整单词本、教材等列表每次读取的条目数。\n10 为原版数量，80 为增强默认值。数量越大，每次加载的数据越多，也会占用更多内存。"
                wrapMode: Text.Wrap
                font.pixelSize: 14
                color: YColors.grayText
            }
        }
    }
}
