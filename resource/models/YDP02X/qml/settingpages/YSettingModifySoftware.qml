import QtQuick 2.12
import com.youdao.pen 1.0
import "../components"
//import BaseQml 1.0
import "../i18n"
import "../commons"

YSettingItemPage  {
    id: id_setting_item
    objectName: "YPage===YSettingOpenLicense.qml"

    property string tips:  "本设备软件系统使用了开源软件代码，您可以修改此部分开源软件代码，但不合适的修改可能会造成本设备无法正常工作，包括但不限于功能不完整、不能正常开机、软件不稳定等。请您在修改之前知晓并同意放弃以下权益:"
    property string noticestr: "<b> 1、同意放弃质保<br>  2、同意放弃售后支持 </b> <br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp"
    property string netstep:  "同意协议，进入<u>下一步</u>"
    property var popcurrentShowPage: null

    YSettingItemTitle {
        id: id_title_bar
//        onCallBack: {
//            backButtonClicked();
//        }
    }
    Flickable {
        anchors.fill: parent
        anchors.leftMargin: 54
        anchors.rightMargin: 16
        contentHeight: id_update_content_col.height
        boundsBehavior: Flickable.StopAtBounds
        Column {
            id: id_update_content_col

            YSettingItemTitle {
                id: id_title_container
                title: YTranslateText.modifysoftware
            }
            YText {
                color: YColors.grayText
                font.pixelSize: 14
                font.family: qmlGlobal.fontFamilyZhCn
                width: 267
                wrapMode: YTextBase.Wrap
                text: tips
                lineHeightMode: Text.FixedHeight
                lineHeight: 18
                verticalAlignment: YText.AlignVCenter
            }
            YText {
                color: YColors.grayText
                font.pixelSize: 14
                font.family: qmlGlobal.fontFamilyZhCn
                width: 267
                wrapMode: YTextBase.Wrap
                textFormat: Text.RichText
                text: noticestr
                lineHeightMode: Text.FixedHeight
                lineHeight: 18
                verticalAlignment: YText.AlignVCenter
            }
            YText {
                color: YColors.red
                font.pixelSize: 14
                font.family: qmlGlobal.fontFamilyZhCn
                width: 267
                wrapMode: YTextBase.Wrap
                textFormat: Text.RichText
                text:  netstep //同意协议 下一步
                lineHeightMode: Text.FixedHeight
                lineHeight: 18
                verticalAlignment: YText.AlignVCenter
                MouseArea
                {
                   anchors.fill: parent
                   onClicked:
                   {

                     id_pop_container.show("YSettingSetupInformation")
                   }
                }
            }

        }

    }


//    YPopLayer {
//        id: id_pop_layer
//        function showPage(qrcqml, properties) {
//            show(qrcqml, false, false, properties)
//            popcurrentShowPage = popItemObject
////            popcurrentShowPage.backButtonClicked.connect(function(){
////                popcurrentShowPage = null

////            })
//        }
//    }

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
