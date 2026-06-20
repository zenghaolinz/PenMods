import QtQuick 2.12
import com.youdao.pen 1.0

import "../commons"
import "../components"

YSettingItemPage {
    id: id_ai_setting
    objectName: "YPage===AISettingPage.qml"
    property string editTarget: ""
    readonly property var providerNames: ["DeepSeek", "Kimi", "通义千问", "智谱 GLM",
                                          "豆包", "OpenAI", "OpenRouter", "自定义"]

    Flickable {
        anchors.fill: parent
        anchors.leftMargin: 54
        anchors.rightMargin: 10
        contentHeight: id_title.height + id_column.height

        YSettingItemTitle { id: id_title; title: "AI 助手设置" }

        Column {
            id: id_column
            anchors.top: id_title.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 8

            YSettingSwitchItem {
                title: "启用 AI 助手"
                switchOn: aiAssistant.enabled
                interval: 0
                onTimerTriggered: aiAssistant.enabled = switchOn
            }
            YSettingAboutClickableItem {
                title: "服务商"
                value: providerNames[aiAssistant.providerIndex]
                imageName: "settings/info_more_arrow"
                onClicked: aiAssistant.selectProvider((aiAssistant.providerIndex + 1) % providerNames.length)
            }
            YSettingAboutClickableItem {
                title: "API Key"
                value: aiAssistant.apiKey.length > 0 ? "已配置" : "未配置"
                imageName: "settings/info_more_arrow"
                onClicked: requestKeyboard("apiKey", "请输入 API Key")
            }
            YSettingAboutClickableItem {
                title: "Base URL"
                value: aiAssistant.baseUrl
                imageName: "settings/info_more_arrow"
                onClicked: requestKeyboard("baseUrl", "请输入 Base URL")
            }
            YSettingAboutClickableItem {
                title: "模型"
                value: aiAssistant.model
                imageName: "settings/info_more_arrow"
                onClicked: requestKeyboard("model", "请输入模型名称")
            }
            YSettingAboutClickableItem {
                title: "系统提示词"
                value: "点击修改"
                imageName: "settings/info_more_arrow"
                onClicked: requestKeyboard("systemPrompt", "请输入系统提示词")
            }
            YSpacingForColumn { implicitHeight: 4 }
        }
    }

    YPagePopHelper {
        id: id_keyboard_helper
        isShowing: qmlGlobal.inputPageShowing

        function inputPageCreated(keyboardPage, placeholder) {
            keyboardPage.backButtonClicked.connect(function() {
                qmlGlobal.inputPageShowing = false
                keyboardPage.todoDestroy()
            })
            keyboardPage.inputFinished.connect(function(content) {
                if (editTarget === "apiKey") aiAssistant.apiKey = content
                else if (editTarget === "baseUrl") aiAssistant.baseUrl = content
                else if (editTarget === "model") aiAssistant.model = content
                else if (editTarget === "systemPrompt") aiAssistant.systemPrompt = content
            })
            keyboardPage.placeHolderText = placeholder
            keyboardPage.show()
            qmlGlobal.inputPageShowing = true
        }
    }

    function requestKeyboard(target, placeholder) {
        editTarget = target
        let component = qmlCreateComponent("YInputPage")
        if (component.status !== Component.Ready)
            return
        let incubator = component.incubateObject(id_keyboard_helper.containerItem)
        if (incubator.status === Component.Ready) {
            id_keyboard_helper.inputPageCreated(incubator.object, placeholder)
        } else {
            incubator.onStatusChanged = function(status) {
                if (status === Component.Ready)
                    id_keyboard_helper.inputPageCreated(incubator.object, placeholder)
            }
        }
    }
}
