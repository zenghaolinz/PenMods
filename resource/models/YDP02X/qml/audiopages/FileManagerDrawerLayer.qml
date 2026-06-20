import QtQuick 2.12
import com.youdao.pen 1.0

import "../commons"
import "../components"
import "../i18n"
import "../settingpages"

YBackButtonPage {
    id: id_setting_item
    objectName: "YPage===FileManagerDrawerPage.qml"

    Flickable {
        id: id_flickable
        anchors.fill: parent
        anchors.leftMargin: 54
        anchors.rightMargin: 10
        contentHeight: id_title_container.height + id_column.height

        YSettingItemTitle {
            id: id_title_container
            title: "选择排序方式"
        }

        Column {
            id: id_column
            anchors.top: id_title_container.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 9

            Grid {
                id: id_grid
                anchors.left: parent.left
                anchors.right: parent.right
                columns: 2
                rowSpacing: 8
                columnSpacing: 6

                Repeater {
                    id: rep
                    model: id_filter_model
                    YButton {
                        id: id_button
                        implicitWidth: 125
                        mouseAreaMargins: -4
                        color: orderType == fileManager.order ? YColors.red : "#2D2E33"
                        text: {
                            switch (orderType) {
                            case 0x00:
                                return "文件名"
                            case 0x01:
                                return "修改日期"
                            case 0x02:
                                return "大小"
                            case 0x80:
                                return "类型"
                            }
                        }
                        onClicked: {
                            fileManager.order = orderType
                            fileManager.reload()
                            close()
                        }
                    }
                }
            }

            YText {
                text: "其他设置"
                color: YColors.grayText
                font.pixelSize: 16
                anchors.left: parent.left
                
            }

            YSettingSwitchItem {
                title: '反转排列顺序'
                switchOn: fileManager.orderReversed
                onTimerTriggered: {
                    fileManager.orderReversed = switchOn
                }
            }

            DescribedSwitchItem {
                title: "隐藏已知歌词文件"
                description: "开启后，将隐藏已匹配乐曲的歌词文件 (lrc格式) 。"
                switchOn: fileManager.hidePairedLyrics
                interval: 0
                onTimerTriggered: {
                    fileManager.hidePairedLyrics = switchOn
                }
            }

            YSpacingForColumn {
                implicitHeight: 4
            }

        }

    }

    ListModel {
        id: id_filter_model
        Component.onCompleted: {
            append({orderType: 0x00})
            append({orderType: 0x01})
            append({orderType: 0x02})
            append({orderType: 0x80})
            // id_delay_timer.start()
        }
    }

    onBackButtonClicked: fileManager.reload()

}
