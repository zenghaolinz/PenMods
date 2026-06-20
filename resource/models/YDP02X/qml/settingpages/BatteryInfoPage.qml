import QtQuick 2.12
import com.youdao.pen 1.0

import "../commons"
import "../components"
import "../i18n"

YSettingItemPage {
    id: id_setting_item
    objectName: "YPage===BatteryInfoPage.qml"

    Flickable {
        id: id_setting_item_view
        anchors.fill: parent
        anchors.leftMargin: 54
        anchors.rightMargin: 10
        contentHeight: id_title_container.height + id_column.height

        YSettingItemTitle {
            id: id_title_container
            title: "电池信息"
        }

        Column {
            id: id_column
            anchors.top: id_title_container.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 8

            YSettingAboutItem {
                title: "状态"
                value: batteryInfo.status
            }

            YSettingAboutItem {
                title: "当前电压"
                value: batteryInfo.voltage
            }

            YSettingAboutItem {
                title: "电池温度"
                value: batteryInfo.temperature
            }

            YSettingAboutItem {
                title: "电池健康"
                value: batteryInfo.health
            }

            YSettingAboutClickableItem {
                title: "自动休眠"
                imageName: "settings/info_more_arrow"
                value: batteryInfo.autoSuspendDuration
                onClicked: {
                    id_pop_container.show("AutoSuspendSetting")
                }
            }

            DescribedClickableTextBox {
                title: "实时电流"
                value: batteryInfo.current
                describe: batteryInfo.prediction
                opacityChangableWhenPressed: false
            }

            YSpacingForColumn {
                implicitHeight: 4
            }

        }

    }

    Timer {
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: batteryInfo.update()
    }

    Item {
        id: id_pop_container
        anchors.fill: parent

        signal closeSameItem(string popStackId)

        function show(page) {
            closeSameItem(page)
            function newComponentInit(incubatorObject) {
                Object.defineProperty(incubatorObject, 'popStackId', {
                                          enumerable: false, configurable: false,
                                          writable: false, value: page
                                      })
                qmlGlobal.requestShowPage.connect(function(index, cachePage) {
                    if (YEnum.PageIndex.Setting !== index) {
                        incubatorObject.destroy(1)
                    }
                })
                incubatorObject.backButtonClicked.connect(function() {
                    closeSameItem(incubatorObject.popStackId)
                    incubatorObject.destroy(1)
                })
                id_pop_container.closeSameItem.connect(function(popStackId) {
                    if (popStackId === incubatorObject.popStackId) {
                        incubatorObject.destroy(1)
                    }
                })
                systemBase.homeKeyRelease.connect(function() {
                    incubatorObject.destroy(1)
                })
                systemBase.homeKeyLongPress.connect(function() {
                    incubatorObject.destroy(1)
                })
                incubatorObject.show()
            }

            const newComponent = Qt.createComponent(("./%1.qml").arg(page))
            const incubator = newComponent.incubateObject(id_pop_container)
            if (incubator.status !== Component.Ready) {
                incubator.onStatusChanged = function(status) {
                    if (status === Component.Ready) {
                        newComponentInit(incubator.object)
                    }
                }
            } else {
                newComponentInit(incubator.object)
            }
        }
    }
}
