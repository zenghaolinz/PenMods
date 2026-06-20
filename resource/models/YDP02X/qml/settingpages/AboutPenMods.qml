import QtQuick 2.12
import com.youdao.pen 1.0

import "../commons"
import "../components"
import "../i18n"

YSettingItemPage {
    id: id_setting_item
    objectName: "YPage===AboutPenMods.qml"

    Flickable {
        id: id_setting_item_view
        anchors.fill: parent
        anchors.leftMargin: 54
        anchors.rightMargin: 10
        contentHeight: id_title_container.height + id_column.height

        YSettingItemTitle {
            id: id_title_container
            title: "关于 PenMods"
        }

        Column {
            id: id_column
            anchors.top: id_title_container.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 8

            YSettingAboutItem {
                title: "版本"
                value: mod.version
            }

            DescribedClickableTextBox {
                opacityChangableWhenPressed: false
                describeItem.width: 200
                title: "构建日期"
                describe: mod.buildDate
            }

            YSettingAboutItem {
                title: "已缓存符号计数"
                value: mod.cachedSymCount
            }

            YSettingAboutItem {
                title: "GitHub"
                value: "PenUniverse"
            }

            YSettingAboutItem {
                title: "QQ交流群"
                value: "641664873"
            }

            DescribedClickableTextBox {
                opacityChangableWhenPressed: false
                describeItem.width: 200
                title: "特别鸣谢"
                describe: "Dobby (Hook Framework)\nQt Project\nNetease Youdao\nRedbeanW (Developer)\nAll Sponsors..."
            }

            YSettingAboutClickableItem {
                title: "捐助项目发展"
                imageName: "settings/info_more_arrow"
                onClicked: {
                    id_pop_container.show("AFDianQrCode")
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
