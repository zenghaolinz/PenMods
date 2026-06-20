import QtQuick 2.12
import com.youdao.pen 1.0

import "./commons"
import "./components"
import "./i18n"
import "./settingpages"
import "./mod"

YBackButtonPage {
    id: id_new_bing
    objectName: "YPage===NewBing.qml"

    Flickable {
        id: id_item_container
        anchors.fill: parent
        anchors.leftMargin: 54
        anchors.rightMargin: 10
        contentHeight: id_conversation_style_switcher.height + id_msg_listview.height + id_suggestor.height + 20

        BingConversationStyleSwitcher {
            id: id_conversation_style_switcher
        }

        function jumpToBottom() {
            id_delay_jump_timer.start()
        }

        function jumpToTop() {
            id_item_container.contentY = 0
        }

        Timer {
            id: id_delay_jump_timer
            interval: 2
            onTriggered: {

                id_item_container.contentY = Math.max(id_item_container.contentHeight - id_item_container.height - (id_suggestor.visible ? id_suggestor.height : 0), 0)
            }
        }

        ListView {
            id: id_msg_listview

            anchors.top: id_conversation_style_switcher.bottom
            anchors.topMargin: count > 0 ? 10 : 0
            model: bot

            spacing: 10
            height: contentHeight

            Component.onCompleted: {
                model.dataChanged.connect(id_item_container.jumpToBottom)
                model.rowsInserted.connect(id_item_container.jumpToBottom)
            }

            delegate: Loader {
                sourceComponent: {
                    switch (model.type) {
                    case MEnum.BI_BotMsg:
                        return id_bot_msg_card
                    case MEnum.BI_UserMsg:
                        return id_user_msg_card
                    case MEnum.BI_BotTip:
                    case MEnum.BI_BotError:
                        return id_bot_tiny_card
                    default:
                        return id_empty_card
                    }
                }

                Component {
                    id: id_bot_msg_card
                    BingBotMessageCard {}
                }

                Component {
                    id: id_bot_tiny_card
                    BingTinyMessageCard {}
                }

                Component {
                    id: id_user_msg_card
                    BingUserMessageCard {}
                }

                Component {
                    id: id_empty_card
                    Item {}
                }

            }

        }

        Item {
            id: id_suggestor
            visible: id_suggestion_list.count > 0
            height: visible ? (id_suggest_tip.height + id_suggestion_list.height + 18) : 0
            anchors.top: id_msg_listview.bottom
            anchors.topMargin: 10
            anchors.left: parent.left

            YTextBase {
                id: id_suggest_tip
                color: YColors.grayText
                visible: id_suggestion_list.count > 0
                font.pixelSize: 14
                text: "参考候选..."
            }

            ListView {
                id: id_suggestion_list

                anchors.top: id_suggest_tip.bottom
                anchors.topMargin: 8
                model: bot.suggestions

                spacing: 8
                height: contentHeight

                delegate: Component {
                    id: id_suggestion_block
                    BingSuggestionCard {}
                }

            }

        }

    }

    YIconButton {
        id: id_setting
        width: 30
        height: 30
        anchors.bottom: id_type_msg.top
        anchors.bottomMargin: 10
        anchors.left: parent.left
        anchors.leftMargin: 10
        radius: 6
        source: "commons/more"
        onValidClicked: {
            id_pop_container.show("mod/BingSettingPage")
        }
    }

    YIconButton {
        id: id_type_msg
        width: 30
        height: 30
        anchors.bottom: id_new_topic.top
        anchors.bottomMargin: 10
        anchors.left: parent.left
        anchors.leftMargin: 10
        radius: 6
        realSource: res.get("new-bing-type-msg")
        sourceSize: Qt.size(20, 20)
        onClicked: {
            requestKeyboard()
        }
    }

    YIconButton {
        id: id_new_topic
        width: 30
        height: 30
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 10
        anchors.left: parent.left
        anchors.leftMargin: 10
        enabled: !bot.isStartOfSession
        radius: 6
        source: "ic_delete"
        onClicked: {
            id_item_container.jumpToTop()
            bot.reset()
        }
    }

    YPagePopHelper {
        id: id_page_pop_helper
        isShowing: qmlGlobal.inputPageShowing
        objectName: "from_NewBing.qml"

        function inputPageCreated(keyboardPage) {
            keyboardPage.backButtonClicked.connect(function(){
                qmlGlobal.inputPageShowing = false
                keyboardPage.todoDestroy()
                keyboardPage = null
            })
            keyboardPage.inputFinished.connect(function(content){
                bot.ask(content)
            })
            keyboardPage.show()
            qmlGlobal.inputPageShowing = true
        }
    }

    function requestKeyboard() {
        let component = qmlCreateComponent("YInputPage")
        if (Component.Ready === component.status) {
            var incubator = component.incubateObject(id_page_pop_helper.containerItem);
            if (incubator.status !== Component.Ready) {
                incubator.onStatusChanged = function(status) {
                    if (status === Component.Ready) {
                        id_page_pop_helper.inputPageCreated(incubator.object)
                    }
                }
            } else {
                id_page_pop_helper.inputPageCreated(incubator.object)
            }
        }
    }

    YOneButtonDialog {
        id: id_disengaged_dialog
        anchors.fill: parent
        tipItem.text: "也许该换个新话题了，让我们重新开始吧。"
        buttonItem.text: "好的"
        showClose: false
        onClicked: {
            bot.reset()
            close()
        }
        Connections {
            target: bot
            function onDisengaged() {
                id_disengaged_dialog.show()
            }
        }
    }

    onVisibleChanged: {
        if (visible) {
            qmlGlobal.currentPageIndex = MEnum.PG_NewBing
        } else {
            bot.reset()
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
