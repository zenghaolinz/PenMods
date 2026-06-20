import QtQuick 2.12
import com.youdao.pen 1.0

import "./commons"
import "./components"
import "./i18n"

YPage {
    id: id_setting_page
    objectName: "YPage===YSettingPage.qml"

    property int currentShowIndex: -1

    function showSettingPage(settingPage) {
        id_pop_container.show(settingPage)
    }

    Item {
        id: id_setting_views
        anchors.fill: parent

        GridView {
            id: id_setting_gridview
            anchors.fill: parent
            anchors.leftMargin: 54
            anchors.rightMargin: 10
            clip: true
            cellWidth: 256
            cellHeight: 58
            model: id_setting_model
            cacheBuffer: 1000
            readonly property bool isMoveToUp: (verticalVelocity > 0)

            delegate: YMouseArea {
                id: id_item_delegate

                width: id_setting_gridview.cellWidth
                height: id_setting_gridview.cellHeight
                objectName: "YSettingPage.qml_delegate_index" + index
                Rectangle {
                    width: parent.width
                    height: parent.height - 8
                    color: YColors.grayNormal
                    opacity: parent.pressed ? 0.6 : 1
                    radius: 12

                    YImage {
                        id: id_icon
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        imageName: settingIcon
                        sourceSize: Qt.size(24, 24)
                    }

                    YTextMedium {
                        id: id_label
                        anchors.left: id_icon.right
                        anchors.leftMargin: 10
                        anchors.right: parent.right
                        anchors.rightMargin: 20
                        anchors.verticalCenter: parent.verticalCenter
                        text: {
                            switch (settingIndex) {
                            case YEnum.SettingIndex.Network:
                                return YTranslateText.network
                            case YEnum.SettingIndex.Bluetooth:
                                return YTranslateText.bluetooth
                            case YEnum.SettingIndex.Volume:
                                return YTranslateText.volume
                            case YEnum.SettingIndex.Brightness:
                                return YTranslateText.brightness
                            case YEnum.SettingIndex.Translate:
                                return YTranslateText.translate
                            case YEnum.SettingIndex.Dict:
                                return YTranslateText.dictionary
                            case YEnum.SettingIndex.Pronunc:
                                return YTranslateText.pronunc
                            case YEnum.SettingIndex.Handedness:
                                return YTranslateText.handedness
                            case YEnum.SettingIndex.Language:
                                return YTranslateText.deviceLanguage
                            case YEnum.SettingIndex.MultiLines:
                                return YTranslateText.multi
                            case YEnum.SettingIndex.Update:
                                return YTranslateText.update
                            case YEnum.SettingIndex.About:
                                return YTranslateText.about
                            case 201:
                                return "电池信息"
                            case 202:
                                return "列式数据库"
                            case 203:
                                return "日志管理"
                            case 204:
                                return "开发者选项"
                            case 205:
                                return "扫描查询"
                            case 206:
                                return "安全与锁定"
                            case 207:
                                return "笔头 LED"
                            case 208:
                                return "AI 助手"
                            case 209:
                                return "关于 PenMods"
                            default:
                                return ""
                            }
                        }
                        elide: YText.ElideRight
                    }
                }

                onClicked: {
                    settingItemClicked(settingIndex)
                }
            }

            header: YSpacing {
                width: id_setting_gridview.width
                implicitHeight: 12
            }

            footer: YSpacing {
                width: id_setting_gridview.width
                implicitHeight: 12
            }
        }
    }

    YVerticalTitleBar {
        id: id_title_bar
        onCallBack: {
            backButtonClicked()
        }

        YButtonBase {
            id: id_portrait_icon_bg
            implicitWidth: 30
            implicitHeight: 30
            mouseAreaMargins: -10
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.bottom: parent.bottom
            opacity: id_back_button.pressed || !enabled ? 0.6 : 1
            color: YColors.grayNormal
            radius: height/2

            onClicked: {
                if (loginManager.isLogin)
                    logManager.sendHttpLog("action=settings_account_click")
                else
                    logManager.sendHttpLog("action=settings_login_click")
                qmlGlobal.showLoginPage()
            }

            YUserPortrait {
                id: id_portrait_icon
                width: 30
                height: 30
                anchors.centerIn: parent
                sourceSize: Qt.size(30, 30)
                defaultIconSource: "image://icons/portrait.png"
                borderColor: YColors.black
            }
        }
    }

    onBackButtonClicked: {
        id_pop_container.popItemObject = null
    }

    Item {
        id: id_pop_container
        anchors.fill: parent

        property var popItemObject: null

        signal closeSameItem(string popStackId)

        function updateStackInfo() {
            if (id_pop_container.children.length > 1) {
                const lastChild = id_pop_container.children[id_pop_container.children.length - 2]
                popItemObject = lastChild
            } else {
                popItemObject = null
            }
        }

        function show(settingPage) {
            closeSameItem(settingPage)
            function newComponentInit(incubatorObject) {
                Object.defineProperty(incubatorObject, 'popStackId', {
                                          enumerable: false, configurable: false,
                                          writable: false, value: settingPage
                                      })
                popItemObject = incubatorObject
                qmlGlobal.requestShowPage.connect(function(index, cachePage) {
                    if (YEnum.PageIndex.Setting !== index) {
                        updateStackInfo()
                        incubatorObject.destroy(1)
                    }
                })
                incubatorObject.backButtonClicked.connect(function() {
                    closeSameItem(incubatorObject.popStackId)
                    updateStackInfo()
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

                if ("settingpages/YSettingUpdate" === settingPage
                        && wifiManager.internetConnect
                        && null !== id_pop_container.popItemObject) {
                    id_pop_container.popItemObject.checkUpdate()
                }
            }

            const newComponent = Qt.createComponent(("./%1.qml").arg(settingPage))
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

    function settingItemClicked(index, popThisPage = false) {
        console.log("YSettingPage.qml===settingItemClicked===index: ", index)
        currentShowIndex = index
        let component = null
        switch (index) {
        case YEnum.SettingIndex.Network:
            logManager.sendHttpLog("action=settings_network_click")
            showSettingPage("settingpages/YSettingWifi")
            break;
        case YEnum.SettingIndex.Bluetooth:
            logManager.sendHttpLog("action=settings_bluetooth_click")
            showSettingPage("settingpages/YSettingBluetooth")
            break;
        case YEnum.SettingIndex.Volume:
            logManager.sendHttpLog("action=settings_sound_click")
            settingManager.updateVolumeAndLcd()
            showSettingPage("settingpages/YSettingVolume")
            break;
        case YEnum.SettingIndex.Brightness:
            logManager.sendHttpLog("action=settings_brightness_click")
            settingManager.updateVolumeAndLcd()
            showSettingPage("settingpages/YSettingBrightness")
            break;
        case YEnum.SettingIndex.Translate:
            logManager.sendHttpLog("action=settings_translate_click")
            showSettingPage("settingpages/YSettingTranslate")
            break;
        case YEnum.SettingIndex.Dict:
            logManager.sendHttpLog("action=settings_dict_click")
            showSettingPage("settingpages/YSettingDict")
            break;
        case YEnum.SettingIndex.Pronunc:
            logManager.sendHttpLog("action=settings_pronounce_click")
            showSettingPage("settingpages/YSettingPronunc")
            break;
        case YEnum.SettingIndex.Handedness:
            logManager.sendHttpLog("action=settings_direction_click")
            showSettingPage("settingpages/YSettingHandedness")
            break;
        case YEnum.SettingIndex.Language:
            logManager.sendHttpLog("action=settings_language_click")
            showSettingPage("settingpages/YSettingLanguage")
            break;
        case YEnum.SettingIndex.MultiLines:
            logManager.sendHttpLog("action=settings_multiline_click")
            showSettingPage("settingpages/YSettingMultiLines")
            break;
        case YEnum.SettingIndex.Update:
            logManager.sendHttpLog("action=settings_update_click")
            showSettingPage("settingpages/YSettingUpdate")
            break;
        case YEnum.SettingIndex.About:
            logManager.sendHttpLog("action=settings_about_click")
            showSettingPage("settingpages/YSettingAbout")
            break;
        case 201:
            showSettingPage("settingpages/BatteryInfoPage")
            break;
        case 202:
            showSettingPage("settingpages/ColumnDbPage")
            break;
        case 203:
            showSettingPage("settingpages/LoggerSettingPage")
            break;
        case 204:
            showSettingPage("settingpages/DeveloperSettingPage")
            break;
        case 205:
            showSettingPage("settingpages/QuerySettingPage")
            break;
        case 206:
            showSettingPage("settingpages/LockSettingPage")
            break;
        case 207:
            showSettingPage("settingpages/Torch")
            break;
        case 208:
            showSettingPage("settingpages/AISettingPage")
            break;
        case 209:
            showSettingPage("settingpages/AboutPenMods")
            break;
        }
    }

    ListModel {
        id: id_setting_model

        Component.onCompleted: {
            append({settingIndex: YEnum.SettingIndex.Network,       settingIcon: "settings/ic_network"})
            append({settingIndex: YEnum.SettingIndex.Bluetooth,     settingIcon: "settings/ic_bluetooth"})
            append({settingIndex: YEnum.SettingIndex.Volume,        settingIcon: "settings/ic_sounds"})
            append({settingIndex: YEnum.SettingIndex.Brightness,    settingIcon: "settings/ic_brightness"})
            if (qmlGlobal.checkFeature(YEnum.FEATURE_VERSION_PRO)) {
                append({settingIndex: YEnum.SettingIndex.Translate, settingIcon: "settings/ic_translate"})
            }
            append({settingIndex: YEnum.SettingIndex.Dict,          settingIcon: "settings/ic_dict"})
            append({settingIndex: YEnum.SettingIndex.Pronunc,       settingIcon: "settings/ic_pronunc"})
            append({settingIndex: YEnum.SettingIndex.Handedness,    settingIcon: "settings/ic_handedness"})
            if (!qmlGlobal.checkFeature(YEnum.FEATURE_SERIAL_D2)) {
                append({settingIndex: YEnum.SettingIndex.Language,      settingIcon: "settings/ic_language"})
            }
            append({settingIndex: YEnum.SettingIndex.MultiLines,    settingIcon: "settings/ic_multi"})
            append({settingIndex: 206, settingIcon: "settings/ic_handedness"})
            append({settingIndex: 205, settingIcon: "settings/ic_translate"})
            append({settingIndex: 208, settingIcon: "settings/ic_dict"})
            append({settingIndex: 201, settingIcon: "settings/ic_brightness"})
            append({settingIndex: 207, settingIcon: "settings/ic_brightness"})
            append({settingIndex: 202, settingIcon: "settings/ic_dict"})
            append({settingIndex: 203, settingIcon: "settings/ic_about"})
            append({settingIndex: 204, settingIcon: "settings/ic_update"})
            append({settingIndex: 209, settingIcon: "settings/ic_about"})
            append({settingIndex: YEnum.SettingIndex.Update,        settingIcon: "settings/ic_update"})
            append({settingIndex: YEnum.SettingIndex.About,         settingIcon: "settings/ic_about"})
        }
    }

    Component.onDestruction: {
        console.log("YSettingPage.qml===Component.onDestruction===called")
    }

    onVisibleChanged: {
        if (visible) {
            qmlGlobal.currentPageIndex = YEnum.PageIndex.Setting
        }
    }
}
