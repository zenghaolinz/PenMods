import QtQuick 2.12
import com.youdao.pen 1.0

import "./commons"
import "./components"

YBackButtonPage {
    id: id_ai_chat
    objectName: "YPage===AIChatPage.qml"

    ListModel { id: id_messages }

    ListView {
        id: id_message_list
        anchors.fill: parent
        anchors.leftMargin: 54
        anchors.rightMargin: 10
        anchors.topMargin: 8
        anchors.bottomMargin: 48
        clip: true
        spacing: 8
        model: id_messages

        delegate: Rectangle {
            width: id_message_list.width
            height: id_message.height + 18
            radius: 10
            color: model.role === "user" ? "#335A7A" : YColors.grayNormal

            YTextBase {
                id: id_message
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 9
                text: model.content
                wrapMode: Text.Wrap
                color: YColors.white
                font.pixelSize: 15
            }
        }

        onCountChanged: positionViewAtEnd()
    }

    YTextBase {
        anchors.left: parent.left
        anchors.leftMargin: 58
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.bottom: id_input_button.top
        anchors.bottomMargin: 3
        text: aiAssistant.lastError
        color: YColors.red
        font.pixelSize: 12
        elide: Text.ElideRight
        visible: text.length > 0
    }

    YButtonBase {
        id: id_input_button
        anchors.left: parent.left
        anchors.leftMargin: 58
        anchors.right: id_clear_button.left
        anchors.rightMargin: 8
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 8
        implicitHeight: 34
        radius: 8
        color: aiAssistant.requesting ? YColors.grayNormal : "#3578B8"
        enabled: !aiAssistant.requesting
        onClicked: requestKeyboard()

        YTextMedium {
            anchors.centerIn: parent
            text: aiAssistant.requesting ? "正在回答…" : "输入问题"
        }
    }

    YButtonBase {
        id: id_clear_button
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 8
        implicitWidth: 72
        implicitHeight: 34
        radius: 8
        color: YColors.grayNormal
        onClicked: {
            aiAssistant.clearHistory()
            id_messages.clear()
        }

        YTextMedium { anchors.centerIn: parent; text: "清空" }
    }

    YPagePopHelper {
        id: id_keyboard_helper
        isShowing: qmlGlobal.inputPageShowing
        objectName: "from_AIChatPage.qml"

        function inputPageCreated(keyboardPage) {
            keyboardPage.backButtonClicked.connect(function() {
                qmlGlobal.inputPageShowing = false
                keyboardPage.todoDestroy()
            })
            keyboardPage.inputFinished.connect(function(content) {
                if (content.trim().length === 0)
                    return
                id_messages.append({"role": "user", "content": content})
                id_messages.append({"role": "assistant", "content": ""})
                aiAssistant.send(content)
            })
            keyboardPage.placeHolderText = "请输入问题…"
            keyboardPage.show()
            qmlGlobal.inputPageShowing = true
        }
    }

    function requestKeyboard() {
        let component = qmlCreateComponent("YInputPage")
        if (component.status !== Component.Ready)
            return
        let incubator = component.incubateObject(id_keyboard_helper.containerItem)
        if (incubator.status === Component.Ready) {
            id_keyboard_helper.inputPageCreated(incubator.object)
        } else {
            incubator.onStatusChanged = function(status) {
                if (status === Component.Ready)
                    id_keyboard_helper.inputPageCreated(incubator.object)
            }
        }
    }

    Connections {
        target: aiAssistant
        function onReplyChunkChanged(delta) {
            if (id_messages.count > 0
                    && id_messages.get(id_messages.count - 1).role === "assistant") {
                id_messages.setProperty(id_messages.count - 1, "content",
                                        aiAssistant.currentReply)
                id_message_list.positionViewAtEnd()
            }
        }
    }

}
