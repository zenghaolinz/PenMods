import QtQuick 2.12
import com.youdao.pen 1.0

import "../../commons"

YMouseArea {
    id: id_input_text_item
    width: 56
    height: 56
    objectName: "YInputTextItem.qml_YMouseArea"

    property string text: ""

    onPressed: {
        id_text_item.text = text
        const pos = id_input_text_item.mapToItem(containerItem.parent, 0, 0)
        const posX = pos.x + id_input_text_item.width / 2
        const posY = pos.y + id_input_text_item.height / 2
        charPressed(id_text_item.text, posX, posY)
    }
    onPressAndHold: {
        switch (qmlGlobal.currentInputStatus) {
        case YEnum.InputStatus.Lower:
            id_text_item.text = text.toUpperCase()
            break
        case YEnum.InputStatus.Upper:
            id_text_item.text = text.toLowerCase()
            break
        case YEnum.InputStatus.Number:
        case YEnum.InputStatus.Symbol:
        default:
            id_text_item.text = text
            break
        }
    }
    onReleased: {
        charRelessed()
        charTriggered(id_text_item.text)
        id_text_item.text = text
    }
    onCanceled: {
        charRelessed()
        id_text_item.text = text
    }

    Rectangle {
        id: id_normal_area
        anchors.fill: parent
        radius: 12
        color: YColors.grayNormal
    }

    YTextMedium {
        id: id_text_item
        font.pixelSize: 20
        anchors.centerIn: parent
        text: id_input_text_item.text
    }

}
