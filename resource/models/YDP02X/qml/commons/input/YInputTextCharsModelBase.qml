import QtQuick 2.12

import "../../commons"

Flow {
    id: id_input_text_chars_model_base_view
    width: 300
    spacing: 5

    readonly property alias containerItem: id_input_text_chars_model_base_view

    function charTriggered(text) {
        id_input_text_title_area.enterChar(text)
    }

    function charPressed(text, posX, posY) {
        id_highlight_item_content.text = text
        id_highlight_item.x = posX - id_highlight_item.width / 2
        id_highlight_item.y = posY - id_highlight_item.height / 2
    }

    function charRelessed() {
        id_highlight_item_content.text = ""
    }

}
