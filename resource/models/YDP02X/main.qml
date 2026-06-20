import QtQuick 2.12
import com.youdao.pen 1.0

import "./qml/utils/utils.js" as UTILS
import "./qml/i18n"
import "./qml"
import "./qml/commons"
import "./qml/components"
import "./qml/audioplayer"

YMainWindow {
    id: id_main_menu_root

    function showPage(qrcqml, cachePage, properties) {
        if ((typeof cachePage !== undefined) && cachePage) {
            return id_page_pop_helper.cacheShow(qrcqml, false, properties)
        }
        return id_page_pop_helper.show(qrcqml, false, properties)
    }

    function closeAudioPlayer() {
        if (id_audio_player_loader.item != null && id_audio_player_loader.item.isShowing) {
            id_audio_player_loader.item.close()
        }
    }

    function closeItemsForHomeKeyReleased() {
        if (closeQuickSetting()) {
            return
        }
    }

    YIndexPage {
        id: id_index_page
        onShowAIAssistant: {
            console.log("main.qml===onShowAIAssistant")
            showPage("AIChatPage")
        }
    }

    YStackView {
        id: id_stack_view
        onCurrentPopIdValidChanged: {
            if (!currentPopIdValid) {
                qmlGlobal.currentPageIndex = YEnum.PageIndex.NonePage
            }
        }
    }

    YPopLayer {
        id: id_page_pop_helper
    }

    YScanWordsResultLoader {
        id: id_scan_words_result_loader
        onOcrStart: {
            closeTipDialog()
            closeAudioPlayer()
            closeQuickSetting()
            speechManager.setEnable(false)
        }
        isVerifiyFinished: id_main_menu_root.isVerifiyFinished
    }

    YLoader {
        id: id_audio_player_loader
        width: parent.width
        height: parent.height
    }

    // for fps test
//    YFPSText {
//        width: 180
//        height: 60
//        anchors.left: parent.left
//        anchors.leftMargin: 20
//        anchors.top: parent.top
//        anchors.topMargin: 20
//        YTextMedium {
//            anchors.centerIn: parent
//            text: "FPS: " + parent.fps.toFixed(2)
//            color: YColors.red
//        }
//    }

    Connections {
        target: qmlGlobal
        ignoreUnknownSignals: true
        function onRequestSettingPage(index) {
            showPage("YSettingPage")
            if ((index < YEnum.SettingIndex.SI_COUNT)
                    && (null !== id_page_pop_helper.popItemObject)) {
                id_page_pop_helper.popItemObject.settingItemClicked(index, true)
            }
            id_scan_words_result_loader.hidden()
            closeQuickSetting()
            closeAudioPlayer()
        }
        function onShowLoginPage() {
            console.log("main.qml===onShowLoginPage===called")
            if (!wifiManager.onoff || !wifiManager.link) {
                qmlGlobal.showToast(YTranslateText.networkAbnormalPleaseCheck, YColors.grayNormal)
                return
            }
            showPage("YLoginPage")
        }
        function onShowFollowPage(spellSwitchButtonVisible) {
            const followPage = showPage("YFollowPage")
            if (id_audio_player_loader.item != null && id_audio_player_loader.item.isShowing) {
                followPage.backButtonClicked.connect(id_audio_player_loader.item.raise)
                id_audio_player_loader.item.hidden()
            }
        }

        function onShowSpellPage(propertiesValue) {
            showPage("YSpellPage");
        }

        function onShowSpeechPage() {
            id_scan_words_result_loader.hidden()
            showPage("YSpeechPage", false)
        }

        function onShowDictPage(pageIndex, ocrContent) {
            console.log("main.qml===onShowDictPage===called pageIndex:", pageIndex)
            const dictPageObj = showPage("YDictPage", true)
            if (null !== dictPageObj) {
                dictPageObj.stackQueryResult = []
                switch (pageIndex) {
                case YEnum.PageIndex.History:
                    dictPageObj.title = YTranslateText.history
                    break
                case YEnum.PageIndex.Fav:
                    dictPageObj.title = YTranslateText.favoriteWords
                    dictPageObj.backButtonClicked.connect(function() {
                        qmlGlobal.backToWordCardView()
                    })
                    break
                case YEnum.PageIndex.Reading:
                    dictPageObj.title = YTranslateText.touchreading
                    break
                default:
                    dictPageObj.title = ""
                    break
                }
                dictPageObj.visible = true
                if (ocrContent.length && ocrContent !== "isOcrStart") {
                    dictPageObj.ocrContentString = ocrContent
                    //dictPageObj.isScannig = true
                } else if (ocrContent === "isOcrStart") {
                    console.log('ocrContent === "isOcrStart"')
                    dictPageObj.isButtonIsRePress = true
                    dictPageObj.isScannig = true
                    dictPageObj.visible = false
                }
                resultManager.isReportButtonVisible = false
            }
        }

        function onQueryFromDictPage(mainQuery, srcLang, dstLang) {
            console.log("main.qml===onQueryFromDictPage===called mainQuery: ", mainQuery, ", srcLang:", srcLang, "dstLang:", dstLang)
            if (!resultManager.entryResult(mainQuery, srcLang, dstLang)) {
                qmlGlobal.showToast(YTranslateText.queryFaildPleaseTryAgain, "#2D2E33")
            } else {
                const dictPageObj = showPage("YDictPage", true)
                if (null !== dictPageObj) {
                    dictPageObj.title = YTranslateText.history//临时标记，防止加入历史记录、单词本
                }
            }
        }

        function onShowDictDetailPage(dictType, dictContent, qsTitle) {
            console.log("main.qml===onShowDictDetailPage===called dictType:", dictType, ", qsTitle:", qsTitle, ", dictContent", dictContent)
            let dictDetailPageObj = showPage("YDictDetailPage", true)
            dictDetailPageObj.title = qsTitle
            dictDetailPageObj.dictType = dictType
            dictDetailPageObj.content = dictContent
            switch (dictType) {
            case YEnum.DtChLarge:
                dictDetailPageObj.title = YTranslateText.dtChLarge
                break
            case YEnum.DtChAncientWord:
                dictDetailPageObj.title = YTranslateText.dtChAncientWord
                break
            case YEnum.DtChPoemDict:
                dictDetailPageObj.title = YTranslateText.ancientPoemsReading
                break
            case YEnum.DtSenior:
                dictDetailPageObj.title = YTranslateText.dtSenior
                break
            case YEnum.DtWebster:
                dictDetailPageObj.title = YTranslateText.dtWebster
                break
            case YEnum.DtOxford:
                dictDetailPageObj.title = YTranslateText.dtOxfordNumber
                break
            case YEnum.DtKoCh:
                dictDetailPageObj.title = YTranslateText.dtKoCh
                break
            case YEnum.DtChKo:
                dictDetailPageObj.title = YTranslateText.dtChKo
                break
            default:
                break
            }
        }

        function onShowAudioPlayer() {
            if (id_audio_player_loader.item != null) {
                id_audio_player_loader.item.show()
            }
        }

        function onRequestTouchReadingPage(index) {
            if (index < YEnum.RI_COUNT) {
                id_page_pop_helper.showWithProperties(
                            "YTouchReadingPage", {"currentTabIndex": index})
            } else {
                showPage("YTouchReadingPage")
            }
        }

        function onRequestShowPage(index, cachePage) {
            console.trace()
            switch (index) {
            case YEnum.PageIndex.Dict:
                if (resultManager.mainQuery.length > 0) {
                    qmlGlobal.showDictPage(index)
                } else {
                    id_scan_words_result_loader.showEmpty()
                }
                break
            case YEnum.PageIndex.Speech:
                qmlGlobal.showSpeechPage();
                break
            case YEnum.PageIndex.Reading:
                showPage("YTouchReadingPage")
                break
            case YEnum.PageIndex.TextBook:
                showPage("YTextbookPage")
                break
            case YEnum.PageIndex.Fav:
                showPage("YWordBookPage")
                break
            case YEnum.PageIndex.Audioplayer:
                showPage("YAudioPage", cachePage)
                break
            case YEnum.PageIndex.History:
                const resultItem = showPage("YHistoryPage")
                if (null !== resultItem) {
                    historyManager.loadMore()
                }
                break
            case YEnum.PageIndex.Setting:
                showPage("YSettingPage")
                break
            case YEnum.PageIndex.PowerOff:
                showPage("YPowerOffPage")
                break
            }
        }
    }

    Connections {
        target: systemBase
        ignoreUnknownSignals: true
        function onHomeKeyRelease() {
            console.log("main.qml===onHomeKeyRelease===")

            closeTipDialog()

            if (closeQuickSetting()) {
                return
            }

            qmlGlobal.closePageWhileHomeKeyReleased()
            qmlGlobal.currentPageIndex = YEnum.PageIndex.NonePage

            if (qmlGlobal.inputPageShowing) {
                qmlGlobal.closeInputPageWhileHomeKeyReleased()
                qmlGlobal.inputPageShowing = false
            }

            closeAudioPlayer()

            if (id_scan_words_result_loader.active) {
                qmlGlobal.stopAllAnimationMusic()
                id_scan_words_result_loader.active = false
            }

            id_page_pop_helper.closeAllPopPage()
        }
        function onHomeKeyDoublePress() {
            console.log("main.qml====onHomeKeyDoublePress")
            if (quickSettingOpening) {
                closeQuickSetting()
            } else {
                openQuickSetting()
            }
        }
        function onPowerKeyLongPress() {
            if (id_audio_player_loader.active) {
                id_audio_player_loader.active = false
            }
            soundCenter.forceStop()
            closeQuickSetting()
            qmlGlobal.requestShowPage(YEnum.PageIndex.PowerOff)
        }
        function onStopContinueScan() {
            id_scan_words_result_loader.showIndex = 0
        }

        function onHomeKeyLongPress() {
            console.log("main.qml====onHomeKeyLongPress")
            closeItemsForHomeKeyReleased()
        }
    }

    YTimer {
        id: id_delay_init_timer
        interval: 200
        onTriggered: {
            console.log("@@@ main.qml ==== id_delay_init_timer.triggered")
            delayInitMainWindow()

            id_index_page.delayInitMainTitleBar()

            id_audio_player_loader.source = "qml/audioplayer/YAudioPlayer.qml"
            id_audio_player_loader.active = true
        }
    }

    Component.onCompleted: {
        console.log("@@@ main.qml ==== Component.onCompleted")
        id_delay_init_timer.start()
        systemBase.headSetInitStatus()
    }
}
