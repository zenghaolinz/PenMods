import QtQuick 2.12
import com.youdao.pen 1.0
import "./commons"
import "./commons/input"

YPage {
    id: id_input_page
    visible: true
    objectName: "YPage===YSettingPage.qml"

    readonly property int bootomMargin: 11
    property alias placeHolderText: id_input_text_title_area.placeHolderText

    signal inputFinished(string text)

    YInputTextTitleArea {
        id: id_input_text_title_area
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        onBacked: {
            backButtonClicked()
        }
        onAccepted: {
            inputFinished(id_input_text_title_area.text)
            backButtonClicked()
        }
    }

    Flickable {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        anchors.topMargin: id_input_text_title_area.height
        contentWidth: width
        contentHeight: {
            switch (qmlGlobal.currentInputStatus) {
            case YEnum.InputStatus.Lower:
                return id_input_text_function_group.height
                        + id_input_text_lower_chars.height + bootomMargin
            case YEnum.InputStatus.Upper:
                return id_input_text_function_group.height
                        + id_input_text_upper_chars.height + bootomMargin
            case YEnum.InputStatus.Number:
                return id_input_text_function_group.height
                        + id_input_text_number_chars.height + bootomMargin
            case YEnum.InputStatus.Symbol:
                return id_input_text_function_group.height
                        + id_input_text_symbol_chars.height + bootomMargin
            }
            return id_input_text_function_group.height
                    + id_input_text_lower_chars.height + bootomMargin
        }
        clip: true

        YInputTextFunctionGroup {
            id: id_input_text_function_group
            anchors.left: parent.left
            anchors.right: parent.right
            onDelChar: {
                id_input_text_title_area.delChar()
            }
            onEnterSpace: {
                id_input_text_title_area.enterSpacing()
            }
            onRequestClear: {
                id_input_text_title_area.clear()
            }
        }

        YInputTextLowerChars {
            id: id_input_text_lower_chars
            visible: YEnum.InputStatus.Lower === qmlGlobal.currentInputStatus
            anchors.top: id_input_text_function_group.bottom
            anchors.topMargin: 5
        }

        YInputTextUpperChars {
            id: id_input_text_upper_chars
            visible: YEnum.InputStatus.Upper === qmlGlobal.currentInputStatus
            anchors.top: id_input_text_function_group.bottom
            anchors.topMargin: 5
        }

        YInputTextNumberChars {
            id: id_input_text_number_chars
            visible: YEnum.InputStatus.Number === qmlGlobal.currentInputStatus
            anchors.top: id_input_text_function_group.bottom
            anchors.topMargin: 5
        }

        YInputTextSymbolChars {
            id: id_input_text_symbol_chars
            visible: YEnum.InputStatus.Symbol === qmlGlobal.currentInputStatus
            anchors.top: id_input_text_function_group.bottom
            anchors.topMargin: 5
            onEnterSpace: {
                id_input_text_title_area.enterSpacing()
            }
        }

        Rectangle {
            id: id_highlight_item
            width: visible ? 66 : 0
            height: visible ? 66 : 0
            radius: 12
            visible: id_highlight_item_content.text.length > 0
            color: "#36373D"
            YTextMedium {
                id: id_highlight_item_content
                font.pixelSize: 18
                anchors.centerIn: parent
                text: ""
            }
        }
    }


    Connections {
        target: keyBoard
        ignoreUnknownSignals: true
        enabled: id_input_page.visible
        function onScanFinished(result) {
            if (result.length > 0) {
                id_input_text_title_area.enterChar(result)
            }
        }
    }

    Connections {
        target: qmlGlobal
        ignoreUnknownSignals: true
        enabled: id_input_page.visible
        onCloseInputPageWhileHomeKeyReleased: {
            id_input_page.backButtonClicked()
        }
    }
}
