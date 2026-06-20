import QtQuick 2.12
import com.youdao.pen 1.0

import "./commons"
import "./components"
import "./i18n"

// this is not a YPage

YBackground {
    id: id_container_index
    anchors.fill: parent

    signal showAIAssistant()

    function openAIAssistant() {
        console.log("YIndexPage.qml===openAIAssistant")
        showAIAssistant()
    }

    function delayInitMainTitleBar(){
        id_main_titlebar_loader.source = "components/YMainTitleBar.qml"
        id_main_titlebar_loader.active = true
    }

    YLoader {
        id: id_main_titlebar_loader
        width: parent.width
        height: 50

        function openAIAssistant() {
            id_container_index.openAIAssistant()
        }
    }

    function mainMenuClicked(index) {
        console.log("YIndexPage.qml===mainMenuClicked===index: ", index)
        let component = null
        switch (index) {
        case YEnum.PageIndex.Dict:
            logManager.sendHttpLog("action=home_search_click")
            qmlGlobal.requestShowPage(YEnum.PageIndex.Dict)
            break
        case YEnum.PageIndex.Speech:
            logManager.sendHttpLog("action=home_voiceassist_click")
            qmlGlobal.requestShowPage(YEnum.PageIndex.Speech)
            break
        case YEnum.PageIndex.Reading:
//            if (settingManager.showReadingBookGuide) {
//                readingBookManager.playGuideVideo()
//            } else {
                logManager.sendHttpLog("action=home_book_touch_reading_click")
                qmlGlobal.requestShowPage(YEnum.PageIndex.Reading)
//            }
            break
        case YEnum.PageIndex.TextBook:
            logManager.sendHttpLog("action=home_textbook_click")
            qmlGlobal.requestShowPage(YEnum.PageIndex.TextBook)
            break
        case YEnum.PageIndex.Fav:
            logManager.sendHttpLog("action=home_wordbook_click")
            qmlGlobal.requestShowPage(YEnum.PageIndex.Fav)
            break
        case YEnum.PageIndex.Audioplayer:
            logManager.sendHttpLog("action=home_listening_clik")
            qmlGlobal.requestShowPage(YEnum.PageIndex.Audioplayer)
            break
        case YEnum.PageIndex.History:
            logManager.sendHttpLog("action=home_history_click")
            qmlGlobal.requestShowPage(YEnum.PageIndex.History)
            break
        case YEnum.PageIndex.Setting:
            logManager.sendHttpLog("action=home_settings_click")
            qmlGlobal.requestShowPage(YEnum.PageIndex.Setting)
            break
        case YEnum.PageIndex.PowerOff:
            id_page_pop_helper.show("YPowerOffPage")
            qmlGlobal.requestShowPage(YEnum.PageIndex.PowerOff)
            break
        }
    }

    YHorizontalListView {
        id: id_main_menu_list_view
        anchors.fill: parent
        anchors.topMargin: 56
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        anchors.bottomMargin: 12
        spacing: 8
        model: mainMenuModel
        clip: false
        delegate: YHorizontalListViewDelegate {
            id: id_item_delegate
            width: 112
            height: 102

            YImage {
                anchors.fill: parent
                sourceSize: Qt.size(112, 102)
                opacity: id_main_menu_icon_button.pressed ? 0.6 : 1
                imageName: ("%1-bg").arg(iconFg)
                antialiasing: true
            }

            YImage {
                anchors.top: parent.top
                anchors.topMargin: 14
                anchors.left: parent.left
                anchors.leftMargin: 14
                width: 40
                height: 40
                sourceSize: Qt.size(40, 40)
                imageName: iconFg
            }

            YText {
                height: 24
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 12
                anchors.left: parent.left
                anchors.leftMargin: 14
                font.pixelSize: 18
                font.weight: Font.DemiBold
                text: {
                    switch (pageIndex) {
                    case YEnum.PageIndex.Dict:
                        return YTranslateText.dict
                    case YEnum.PageIndex.Speech:
                        return YTranslateText.speech
                    case YEnum.PageIndex.Reading:
                        return YTranslateText.touchreading
                    case YEnum.PageIndex.TextBook:
                        return YTranslateText.textbookSynchronous
                    case YEnum.PageIndex.Fav:
                        return YTranslateText.favoriteWords
                    case YEnum.PageIndex.Audioplayer:
                        return YTranslateText.listeningExercise
                    case YEnum.PageIndex.History:
                        return YTranslateText.history
                    case YEnum.PageIndex.Setting:
                        return YTranslateText.settings
                    default:
                        return ""
                    }
                }
            }

            YMouseArea {
                id: id_main_menu_icon_button
                anchors.fill: parent
                objectName: "main.qml_mainMenuListView_pageIndex" + pageIndex
                onClicked: {
                    mainMenuClicked(pageIndex)
                }
            }
        }
    }

    ListModel {
        id: mainMenuModel
        Component.onCompleted: {
            append({iconFg: "home-dict", pageIndex: YEnum.PageIndex.Dict})
            if (qmlGlobal.checkFeature(YEnum.FEATURE_ASSISTANT)) {
                append({iconFg: "home-speech", pageIndex: YEnum.PageIndex.Speech})
            }
            if (qmlGlobal.checkFeature(YEnum.FEATURE_TEXTBOOK)) {
                append({iconFg: "home-textbook", pageIndex: YEnum.PageIndex.TextBook})
            }
            append({iconFg: "home-fav", pageIndex: YEnum.PageIndex.Fav})
            if (qmlGlobal.checkFeature(YEnum.FEATURE_AUDIO)) {
                append({iconFg: "home-audioplayer", pageIndex: YEnum.PageIndex.Audioplayer})
            }
            append({iconFg: "home-history", pageIndex: YEnum.PageIndex.History})
            append({iconFg: "home-setting", pageIndex: YEnum.PageIndex.Setting})
        }
    }
}
