import QtQuick 2.12
import com.youdao.pen 1.0
import "qrc:/qml/commons"

Item {
    id: id_functions_group_root
    implicitWidth: 300
    implicitHeight: 56

    readonly property int spacing: 5
    signal delChar()
    signal enterSpace()
    signal requestClear()

    YInputTextFunctionButton {
        id: id_lower_chars_button
        checkedIndicatorScale: YEnum.InputStatus.Lower === qmlGlobal.currentInputStatus
        onClicked: {
            qmlGlobal.currentInputStatus = YEnum.InputStatus.Lower
        }
        YImage {
            anchors.centerIn: parent
            sourceSize: Qt.size(40, 40)
            imageName: "input/char_lower"
        }
    }
    YInputTextFunctionButton {
        id: id_upper_chars_button
        anchors.left: id_lower_chars_button.right
        anchors.leftMargin: spacing
        checkedIndicatorScale: YEnum.InputStatus.Upper === qmlGlobal.currentInputStatus
        onClicked: {
            qmlGlobal.currentInputStatus = YEnum.InputStatus.Upper
        }
        YImage {
            anchors.centerIn: parent
            sourceSize: Qt.size(40, 40)
            imageName: "input/char_upper"
        }
    }
    YInputTextFunctionButton {
        id: id_number_chars_button
        anchors.left: id_upper_chars_button.right
        anchors.leftMargin: spacing
        checkedIndicatorScale: YEnum.InputStatus.Number === qmlGlobal.currentInputStatus
        onClicked: {
            qmlGlobal.currentInputStatus = YEnum.InputStatus.Number
        }
        YImage {
            anchors.centerIn: parent
            sourceSize: Qt.size(40, 40)
            imageName: "input/char_digital"
        }
    }
    YInputTextFunctionButton {
        id: id_symbol_chars_button
        anchors.left: id_number_chars_button.right
        anchors.leftMargin: spacing
        checkedIndicatorScale: YEnum.InputStatus.Symbol === qmlGlobal.currentInputStatus
        onClicked: {
            qmlGlobal.currentInputStatus = YEnum.InputStatus.Symbol
        }
        YImage {
            anchors.centerIn: parent
            sourceSize: Qt.size(40, 40)
            imageName: "input/char_punctuation"
        }
    }
    YInputTextFunctionButton {
        id: id_del_char_button
        anchors.left: id_symbol_chars_button.right
        anchors.leftMargin: spacing
        onClicked: {
            delChar()
        }
        onPressAndHold: {
            requestClear()
        }
        YImage {
            anchors.centerIn: parent
            sourceSize: Qt.size(40, 40)
            imageName: "input/ic_delete"
        }
    }
//    YInputTextFunctionButton {
//        id: id_space_char_button
//        anchors.left: id_del_char_button.left
//        anchors.top: id_symbol_chars_button.top
//        onClicked: {
//            enterSpace()
//        }
//        YImage {
//            anchors.centerIn: parent
//            sourceSize: Qt.size(40, 40)
//            imageName: "input/ic_space"
//        }
//    }

    Component.onCompleted: {
        console.log("ZDS=====qmlGlobal.currentInputStatus: ", qmlGlobal.currentInputStatus)
    }
}
