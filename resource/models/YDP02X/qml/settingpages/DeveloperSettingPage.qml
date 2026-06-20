import QtQuick 2.12
import com.youdao.pen 1.0

import "../commons"
import "../components"
import "../i18n"

YSettingItemPage {
    id: id_setting_item
    objectName: "YPage===WordbookSettingPage.qml"

    Flickable {
        id: id_setting_item_view
        anchors.fill: parent
        anchors.leftMargin: 54
        anchors.rightMargin: 10
        contentHeight: id_title_container.height + id_column.height

        YSettingItemTitle {
            id: id_title_container
            title: "开发者选项"
        }

        Column {
            id: id_column
            anchors.top: id_title_container.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 8

            YSettingAboutClickableItem {
                title: "ADB 服务"
                imageName: "settings/info_more_arrow"
                onClicked: {
                    id_pop_container.show("ADBManagePage")
                }
            }

            YSettingAboutClickableItem {
                title: "SSH 服务"
                imageName: "settings/info_more_arrow"
                onClicked: {
                    id_pop_container.show("SSHManagePage")
                }
            }

            DescribedSwitchItem {
                title: "显示IP地址"
                description: "开启后，在WI-FI设置页面 \"已连接\" 旁将显示词典笔的内网IP地址。"
                switchOn: developerSettings.wifiPageShowIp
                interval: 0
                onTimerTriggered: {
                    developerSettings.wifiPageShowIp = switchOn
                }
            }

            DescribedSwitchItem {
                title: "离线资源管理器"
                description: "开启后，后台会定时检查离线资源（如词典）是否有更新。"
                switchOn: developerSettings.offlineRM
                interval: 0
                onTimerTriggered: {
                    developerSettings.offlineRM = switchOn
                }
            }

            YSpacingForColumn {
                implicitHeight: 4
            }
        }

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
