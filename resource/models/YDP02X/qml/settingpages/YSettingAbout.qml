import QtQuick 2.12
import com.youdao.pen 1.0

import "../commons"
import "../components"
import "../i18n"

YSettingItemPage {
    id: id_setting_item
    objectName: "YPage===YSettingAbout.qml"
    property int clickCount: 0

    Flickable {
        id: id_setting_item_view
        anchors.fill: parent
        anchors.leftMargin: 54
        anchors.rightMargin: 10
        contentHeight: id_title_container.height + id_column.height

        YSettingItemTitle {
            id: id_title_container
            title: YTranslateText.about

            YMouseArea {
                anchors.fill: parent

                onClicked: {
                    if (clickCount <= 0) {
                        id_click_count_timer.start()

                        console.log("ccccccccccccccccc",settingManager.sysDevName + "ii " +settingManager.sysRegionInfo)
                    }

                    clickCount++
                    if (clickCount >= 5) {
                        console.log("YSettingAbout.qml===uploadUserActionLog, cnt ", clickCount)
                        clickCount = 0
                        logManager.uploadUserActionLog()
                        id_click_count_timer.stop()
                    }
                }
                objectName: "YSettingAbout.qml_YMouseArea"
            }

            YTimer {
                id: id_click_count_timer
                interval: 2000
                objectName: "YSettingAbout.qml_id_click_count_timer"
                onTriggered: {
                    if (clickCount > 1) {
                        clickCount--
                    }

                    if (clickCount == 0) {
                        stop()
                    }
                }
            }
        }

        Column {
            id: id_column
            anchors.top: id_title_container.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 8

            YSettingAboutItem {
                title: YTranslateText.model
                value: settingManager.sysDevName //+ " " +settingManager.sysRegionInfo;
            }

            YSettingAboutItem {
                title: YTranslateText.version
                value: settingManager.sysVersion
            }

            YSettingAboutClickableItem {
                title: YTranslateText.memoryStorage
                value: settingManager.memoryStorage + "GB"
                imageName: "settings/info_more_arrow"
                onClicked: {
                    settingManager.updateSystemInfo()
                    id_pop_container.show("YSettingStorageInfo")
                }
            }

            YSettingAboutItem {
                title: YTranslateText.sysSn
                titleItem.anchors.right: undefined
                titleItem.anchors.rightMargin: undefined
                value: settingManager.sysSn
            }

            YSettingAboutItem {
                title: YTranslateText.macAddress
                titleItem.anchors.right: undefined
                titleItem.anchors.rightMargin: undefined
                value: settingManager.sysMac
            }

            YSettingAboutItem {
                visible: !qmlGlobal.checkFeature(YEnum.FEATURE_SKU_KO)
                         && !qmlGlobal.checkFeature(YEnum.FEATURE_SKU_EN)
                title: YTranslateText.serviceHotline
                value: qmlGlobal.checkFeature(YEnum.FEATURE_SKU_TW)
                       ? "0800-000150" : "400-800-4163"
            }

            YSettingAboutClickableItem {
                title: YTranslateText.certification
                value: ""
                imageName: "settings/info_more_arrow"
                onClicked: {
                    id_pop_container.show("YSettingCertification")
                }
            }
            //开源软件使用许可
            YSettingAboutClickableItem {
                title: YTranslateText.opensourcelicense
                value: ""
                imageName: "settings/info_more_arrow"
                onClicked: {
                    id_pop_container.show("YSettingOpenLicense")
                }
            }


            YSettingAboutClickableItem {
                title: YTranslateText.resetChoice
                value: ""
                imageName: "settings/info_more_arrow"
                onClicked: {
                    id_pop_container.show("YSettingReset")
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

        function show(aboutPage) {
            closeSameItem(aboutPage)
            function newComponentInit(incubatorObject) {
                Object.defineProperty(incubatorObject, 'popStackId', {
                                          enumerable: false, configurable: false,
                                          writable: false, value: aboutPage
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

            const newComponent = Qt.createComponent(("./%1.qml").arg(aboutPage))
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
