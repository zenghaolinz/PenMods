import QtQuick 2.12

import "../commons"

YSettingAboutItem {
    id: id_setting_about_clickable_item
    opacity: (opacityChangableWhenPressed && (id_button.pressed || !enabled)) ? 0.6 : 1
    valueRightMargin: 8 + id_button_icon_loader.item.width + 10

    property alias icon: id_setting_about_clickable_item.source
    property string source: ""
    property alias imageName: id_setting_about_clickable_item.source

    property alias iconSourceSize: id_setting_about_clickable_item.sourceSize
    property size sourceSize: Qt.size(24, 24)
    property alias pressed: id_button.pressed
    property bool opacityChangableWhenPressed: true

    property alias iconComponent: id_button_icon_loader.sourceComponent
    property alias iconLoaded: id_button_icon_loader.isLoaded

    signal clicked()

    YLoader {
        id: id_button_icon_loader
        active: true
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: 10
        sourceComponent: YImage {
            sourceSize: id_setting_about_clickable_item.sourceSize
            imageName: id_setting_about_clickable_item.source
        }
    }

    YMouseArea {
        id: id_button
        anchors.fill: parent
        onClicked: {
            id_setting_about_clickable_item.clicked()
        }
        objectName: "YSettingAboutClickableItem.qml_YMouseArea"
    }
}
