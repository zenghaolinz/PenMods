import QtQuick 2.12
import com.youdao.pen 1.0

import "../commons"
import "../components"
import "../i18n"

YPage {
    id: id_setting_item
    objectName: "YPage===ColumnDbPage.qml"

    Flickable {
        id: id_setting_item_view
        anchors.fill: parent
        anchors.leftMargin: 54
        anchors.rightMargin: 10
        contentHeight: id_title_item.height + id_slider_rect.height + 62
        interactive: !id_slider_moving_timer.running

        YSettingItemTitle {
            id: id_title_item
            title: "单次查询数量限制: " + columnDb.limit
        }

        YSettingItemBackground {
            id: id_slider_rect
            implicitHeight: 60
            anchors.top: id_title_item.bottom

            YSlider {
                id: id_slider
                implicitWidth: 140
                anchors.centerIn: parent
                minValue: 10
                value: columnDb.limit
                onValueChanged: {
                    columnDb.limit = value
                }
            }

            YTimer {
                id: id_slider_moving_timer
                interval: 300
                objectName: "ColumnDbPage.qml_id_slider_moving_timer"
            }

            YClickabledImage {
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: id_slider.left
                anchors.rightMargin: 16
                resource: "db-limit-dec"
                onClicked: {
                    id_slider.decrementTenValue()
                }
            }

            YClickabledImage {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: id_slider.right
                anchors.leftMargin: 16
                resource: "db-limit-inc"
                onClicked: {
                    id_slider.incrementTenValue()
                }
            }
        }

    }

    YVerticalTitleBar {
        id: id_title_bar
        onCallBack: {
            backButtonClicked()
        }
    }
}
