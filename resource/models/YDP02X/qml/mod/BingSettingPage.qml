import QtQuick 2.12
import com.youdao.pen 1.0

import "../commons"
import "../components"
import "../i18n"
import "../settingpages"

YBackButtonPage {
    id: id_bing_setting_page
    property int currentKeyboardState: 1 // 1 = sig, 2 = chat hub.

    Flickable {
        id: id_setting_item_view
        anchors.fill: parent
        anchors.leftMargin: 54
        anchors.rightMargin: 10
        contentHeight: id_title_container.height + id_column.height

        YSettingItemTitle {
            id: id_title_container
            title: "Bing ChatBot"
        }

        Column {
            id: id_column
            anchors.top: id_title_container.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 8
            
            YSettingSwitchItem {
                implicitHeight: 54
                title: "主标题栏快捷入口"
                interval: 0
                switchOn: bot.enabled
                onTimerTriggered: {
                    bot.enabled = switchOn
                }
            }

            DescribedClickableTextBox {
                title: "Signature 申请地址"
                describeItem.width: 240
                describeItem.wrapMode: Text.WrapAnywhere
                opacityChangableWhenPressed: false
                describe: bot.requestAddress
                onClicked: {
                    currentKeyboardState = 1
                    requestKeyboard()
                }
            }

            DescribedClickableTextBox {
                title: "Bing ChatHub 地址"
                describeItem.width: 240
                describeItem.wrapMode: Text.WrapAnywhere
                opacityChangableWhenPressed: false
                describe: bot.chathubAddress
                onClicked: {
                    currentKeyboardState = 2
                    requestKeyboard()
                }
            }

            DescribedClickableTextBox {
                title: "关于 Cookies"
                describeItem.width: 240
                describeItem.wrapMode: Text.WrapAnywhere
                opacityChangableWhenPressed: false
                describe: "请确保您的微软账号有 New Bing 的访问权限。\n在 bing.com/chat 使用 Cookie Editor 导出全部 Cookies 为 Json 格式，然后将文件放在 Music/bing-cookies.json 即可。\n点击从文件系统重载 Cookies 信息。"
                onClicked: {
                    bot.initializeCookies()
                    qmlGlobal.showToast("已重载 Cookies", YColors.grayNormal)
                }
            }

            YSettingAboutItem {
                title: "服务版本"
                value: bot.serviceVersion
            }

            YSpacingForColumn {
                implicitHeight: 4
            }

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
                if (currentKeyboardState == 1) {
                    bot.requestAddress = content
                } else if (currentKeyboardState == 2) {
                    bot.chathubAddress = content
                }
            })
            keyboardPage.show()
            if (currentKeyboardState == 1) {
                keyboardPage.enterText(bot.requestAddress)
            } else if (currentKeyboardState == 2) {
                keyboardPage.enterText(bot.chathubAddress)
            }
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

}
