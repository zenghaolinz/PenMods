import QtQuick 2.12

import "../../commons"
import "../../i18n"

Item {
    anchors.left: parent.left
    anchors.right: parent.right
    height: 50

    readonly property bool acceptabled: id_input_core.length
    property alias text: id_input_core.text
    property alias placeHolderText: id_placeholder_text.text

    signal backed()
    signal accepted()

    function delChar() {
        id_input_core.remove(Math.max(0, id_input_core.cursorPosition - 1),
                             id_input_core.cursorPosition)
        if (!id_input_core.activeFocus) {
            id_input_core.forceActiveFocus()
        }
    }

    function enterSpacing() {
        id_input_core.insert(id_input_core.cursorPosition, " ")
        if (!id_input_core.activeFocus) {
            id_input_core.forceActiveFocus()
        }
    }

    function enterChar(text) {
        id_input_core.insert(id_input_core.cursorPosition, text)
        if (!id_input_core.activeFocus) {
            id_input_core.forceActiveFocus()
        }
    }

    function clear() {
        id_input_core.clear()
    }

    YIconButton {
        id: id_back_button_bg
        implicitWidth: 30
        implicitHeight: 30
        radius: height/2
        icon: "ic_back"
        sourceSize: Qt.size(24, 24)
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter

        YBackButtonBase {
            anchors.fill: parent
            anchors.margins: -10
            onTriggered: {
                backed()
            }
        }
    }

    Rectangle {
        id: id_input_core_background
        anchors.left: id_back_button_bg.right
        anchors.leftMargin: 22
        anchors.right: id_accepted_button_background.left
        anchors.rightMargin: 22
        anchors.verticalCenter: parent.verticalCenter
        implicitHeight: 34
//        radius: height/2
        color: YColors.black

        TextInput {
            id: id_input_core
            anchors.fill: parent
            verticalAlignment: TextInput.AlignVCenter
            font.family: qmlGlobal.fontFamily
            font.pixelSize: 18
            color: YColors.white
            clip: true
            cursorDelegate: id_cursor_delegate

            YTextBase {
                id: id_placeholder_text
                anchors.fill: parent
                verticalAlignment: YText.AlignVCenter
                opacity: !id_input_core.length && !id_input_core.inputMethodComposing ? 1 : 0
                color: YColors.grayText
                font: id_input_core.font
                wrapMode: YText.Wrap
                text: YTranslateText.inputTip
                Behavior on opacity { NumberAnimation { duration: 120 } }
            }
        }
    }

    YIconButton {
        id: id_accepted_button_background
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: 40
        implicitHeight: 30
        radius: height/2
        color: YColors.grayNormal
        enabled: acceptabled
        sourceSize: Qt.size(24, 24)
        imageName: "input/ic_selected"
        mouseAreaMargins: -10
        onClicked: {
            accepted()
        }
    }

    Component {
        id: id_cursor_delegate
        Rectangle {
            id: id_cursor_context
            width: 2
            height: 20
            opacity: 0
            color: YColors.red
            SequentialAnimation {
                running: !id_input_core.readOnly && id_input_core.activeFocus
                loops: SequentialAnimation.Infinite
                ScriptAction { script: id_cursor_context.opacity = 1 }
                PauseAnimation { duration: 600 }
                ScriptAction { script: id_cursor_context.opacity = 0 }
                PauseAnimation { duration: 600 }
            }
        }
    }
}
