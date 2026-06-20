import QtQuick 2.12

import "../commons"
import "../components"

YSettingAboutClickableItem {
    id: id_my_import_page_component_view_item

    readonly property bool isDir: model.isDir
    signal longPressed()

    valueRightMargin: 10
    imageName: isDir ? "settings/info_more_arrow" : ""

    titlePixelSize: 16
    valuePixelSize: 14

    YMouseArea {
        anchors.fill: parent
        onClicked: id_my_import_page_component_view_item.clicked()
        onPressAndHold: id_my_import_page_component_view_item.longPressed()
    }
}
