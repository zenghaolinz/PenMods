import QtQuick 2.12
import com.youdao.pen 1.0
import "./commons"
import "./components"

YBackButtonPage {
    id: id_ai_chat
    objectName: "YPage===AIChatPage.qml"
    property string keyboardMode: "message"
    property bool historyOpen: false
    property string deleteId: ""
    ListModel { id: id_messages }

    Row {
        id: toolbar
        anchors.left: parent.left
        anchors.leftMargin: 58
        anchors.top: parent.top
        anchors.topMargin: 4
        spacing: 6
        YButtonBase {
            width: id_ai_chat.width - 168
            height: 28
            radius: 6
            color: YColors.grayNormal
            onClicked: requestKeyboard("rename")
            YTextBase { anchors.fill: parent; anchors.margins: 5; text: aiAssistant.conversationTitle; elide: Text.ElideRight; textFormat: Text.PlainText; font.pixelSize: 13 }
        }
        YButtonBase {
            width: 50; height: 28; radius: 6; color: YColors.grayNormal
            onClicked: { deleteId = ""; historyOpen = true }
            YTextMedium { anchors.centerIn: parent; text: "历史"; font.pixelSize: 13 }
        }
        YButtonBase {
            width: 38; height: 28; radius: 6; color: "#3578B8"
            onClicked: aiAssistant.newConversation()
            YTextMedium { anchors.centerIn: parent; text: "新建"; font.pixelSize: 13 }
        }
    }

    ListView {
        id: id_message_list
        anchors.fill: parent
        anchors.leftMargin: 54
        anchors.rightMargin: 10
        anchors.topMargin: 38
        anchors.bottomMargin: aiAssistant.lastError.length > 0 ? 68 : 48
        clip: true
        spacing: 8
        model: id_messages
        delegate: Rectangle {
            width: id_message_list.width
            height: messageColumn.height + 16
            radius: 8
            color: model.role === "user" ? "#335A7A" : YColors.grayNormal
            Column {
                id: messageColumn
                x: 8; y: 8; width: parent.width - 16; spacing: 4
                YTextBase {
                    width: parent.width
                    text: model.content.length > 0 ? model.content : (model.status === "pending" ? "正在回答…" : "未收到回答")
                    textFormat: Text.PlainText
                    wrapMode: Text.Wrap
                    color: YColors.white
                    font.pixelSize: 15
                }
                YTextBase {
                    width: parent.width
                    visible: model.role === "assistant" && model.status !== "complete" && model.status !== "pending"
                    text: model.error.length > 0 ? model.error : (model.status === "stopped" ? "已停止，可点击重试" : "回答失败，可点击重试")
                    textFormat: Text.PlainText
                    wrapMode: Text.Wrap
                    font.pixelSize: 12
                    color: "#FFBD80"
                }
            }
        }
        YTextBase {
            anchors.centerIn: parent
            width: parent.width
            visible: id_messages.count === 0
            text: "输入问题，或直接扫描文字\n对话自动保存在本机\n点击上方标题可改名"
            textFormat: Text.PlainText
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            font.pixelSize: 13
            color: YColors.grayText
        }
    }
    YTextBase {
        anchors.left: parent.left; anchors.leftMargin: 58
        anchors.right: parent.right; anchors.rightMargin: 10
        anchors.bottom: id_input_button.top; anchors.bottomMargin: 3
        text: aiAssistant.lastError
        textFormat: Text.PlainText
        color: YColors.red; font.pixelSize: 12; elide: Text.ElideRight
        visible: text.length > 0
    }
    YButtonBase {
        id: id_input_button
        anchors.left: parent.left; anchors.leftMargin: 58
        anchors.right: retryButton.left; anchors.rightMargin: 8
        anchors.bottom: parent.bottom; anchors.bottomMargin: 8
        implicitHeight: 34; radius: 8; color: "#3578B8"
        onClicked: { if (aiAssistant.requesting) aiAssistant.stop(); else requestKeyboard("message") }
        YTextMedium { anchors.centerIn: parent; text: aiAssistant.requesting ? "停止回答" : "输入问题" }
    }
    YButtonBase {
        id: retryButton
        anchors.right: parent.right; anchors.rightMargin: 10
        anchors.bottom: parent.bottom; anchors.bottomMargin: 8
        implicitWidth: 60; implicitHeight: 34; radius: 8; color: YColors.grayNormal
        enabled: !aiAssistant.requesting && id_messages.count > 0
        opacity: enabled ? 1 : 0.45
        onClicked: aiAssistant.retryLast()
        YTextMedium { anchors.centerIn: parent; text: "重试" }
    }

    Rectangle {
        anchors.fill: parent
        anchors.leftMargin: 54
        color: "#20252F"
        visible: historyOpen
        z: 10
        MouseArea { anchors.fill: parent }
        YTextBase { x: 6; y: 7; text: "本机历史（30个 / 8MB）"; font.pixelSize: 13; color: YColors.white }
        YButtonBase {
            anchors.right: parent.right; anchors.rightMargin: 8; y: 3
            width: 42; height: 27; radius: 5; color: YColors.grayNormal
            onClicked: { historyOpen = false; deleteId = "" }
            YTextMedium { anchors.centerIn: parent; text: "返回"; font.pixelSize: 13 }
        }
        ListView {
            anchors.fill: parent; anchors.topMargin: 35; anchors.bottomMargin: 38
            anchors.leftMargin: 6; anchors.rightMargin: 8
            clip: true; spacing: 5
            model: aiAssistant.conversations
            delegate: Rectangle {
                width: ListView.view.width; height: 48; radius: 6
                color: modelData.id === aiAssistant.activeConversationId ? "#335A7A" : YColors.grayNormal
                MouseArea {
                    anchors.fill: parent; anchors.rightMargin: 40
                    onClicked: { aiAssistant.selectConversation(modelData.id); historyOpen = false; deleteId = "" }
                }
                YTextBase { x: 7; y: 5; width: parent.width - 48; text: modelData.title; textFormat: Text.PlainText; elide: Text.ElideRight; font.pixelSize: 14; color: YColors.white }
                YTextBase { x: 7; y: 26; text: modelData.updated_at.replace("T", " ").slice(0,16) + " · " + modelData.count + "轮"; font.pixelSize: 11; color: YColors.grayText }
                YButtonBase {
                    anchors.right: parent.right; anchors.rightMargin: 4; anchors.verticalCenter: parent.verticalCenter
                    width: 34; height: 34; radius: 5; color: "#6B3A40"
                    onClicked: deleteId = modelData.id
                    YTextMedium { anchors.centerIn: parent; text: "删除"; font.pixelSize: 11 }
                }
            }
        }
        YTextBase { x: 8; anchors.bottom: parent.bottom; anchors.bottomMargin: 10; visible: deleteId.length === 0; text: "保留每个会话最近100轮；联网仅发送当前会话"; font.pixelSize: 10; color: YColors.grayText }
        Row {
            x: 6; anchors.bottom: parent.bottom; anchors.bottomMargin: 4; spacing: 8
            visible: deleteId.length > 0
            YButtonBase {
                width: 140; height: 30; radius: 5; color: "#9C414A"
                onClicked: { aiAssistant.deleteConversation(deleteId); deleteId = "" }
                YTextMedium { anchors.centerIn: parent; text: "确认删除此会话"; font.pixelSize: 12 }
            }
            YButtonBase {
                width: 70; height: 30; radius: 5; color: YColors.grayNormal
                onClicked: deleteId = ""
                YTextMedium { anchors.centerIn: parent; text: "取消"; font.pixelSize: 12 }
            }
        }
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
                if (id_ai_chat.keyboardMode === "rename")
                    aiAssistant.renameConversation(content)
                else
                    submitMessage(content)
            })
            keyboardPage.placeHolderText = id_ai_chat.keyboardMode === "rename" ? "输入会话名称" : "请输入问题…"
            keyboardPage.show()
            qmlGlobal.inputPageShowing = true
        }
    }

    function requestKeyboard(mode) {
        keyboardMode = mode || "message"
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


    function reloadMessages() {
        id_messages.clear()
        const saved = aiAssistant.messages
        for (let i = 0; i < saved.length; ++i)
            id_messages.append(saved[i])
        id_message_list.positionViewAtEnd()
    }
    function submitMessage(content) {
        const text = content.trim()
        if (text.length === 0) return
        if (aiAssistant.requesting) {
            qmlGlobal.showToast("请等待当前回答完成", YColors.grayNormal)
            return
        }
        aiAssistant.send(text)
    }
    Connections {
        target: aiAssistant
        function onHistoryChanged() { reloadMessages() }
        function onReplyChunkChanged(delta) {
            if (id_messages.count > 0 && id_messages.get(id_messages.count - 1).role === "assistant"
                    && id_messages.get(id_messages.count - 1).status === "pending") {
                const follow = id_message_list.atYEnd
                id_messages.setProperty(id_messages.count - 1, "content", aiAssistant.currentReply)
                if (follow) id_message_list.positionViewAtEnd()
            }
        }
    }
    Connections {
        target: systemBase
        ignoreUnknownSignals: true
        function onOcrStop(scanType) {
            if (id_ai_chat.visible && !historyOpen && !qmlGlobal.inputPageShowing && systemBase.ocrCompletedResult.length > 0)
                submitMessage(systemBase.ocrCompletedResult)
        }
    }
    Component.onCompleted: reloadMessages()
    onVisibleChanged: {
        if (visible) qmlGlobal.currentPageIndex = PageIndex.AIAssistant
    }
}
