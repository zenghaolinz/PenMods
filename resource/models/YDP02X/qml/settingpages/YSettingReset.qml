import QtQuick 2.12

import "../commons"
import "../components"
import "../i18n"

YSettingItemPage {
    id: id_setting_item
    objectName: "YPage===YSettingReset.qml"

    Column {
        anchors.left: parent.left
        anchors.leftMargin: 54
        anchors.right: parent.right
        anchors.rightMargin: 10
        spacing: 0

        YSettingItemTitle {
            id: id_title_container
            title: YTranslateText.resetChoice
        }

        YButtonBase {
            implicitHeight: 50
            anchors.left: parent.left
            anchors.right: parent.right
            radius: 12
            YTextMedium {
                text: YTranslateText.resetSettings
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 10
            }
            onClicked: {
                id_reset_settings.show()
            }
        }

        YSpacingForColumn {
            implicitHeight: 8
        }

        YButtonBase {
            implicitHeight: 50
            anchors.left: parent.left
            anchors.right: parent.right
            radius: 12
            YTextMedium {
                text: YTranslateText.resetFactory
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 10
            }
            onClicked: {
                id_reset_factory.show()
            }
        }

        YSpacingForColumn {
            implicitHeight: 12
        }
    }

    YSettingResetSettingsReset {
        id: id_reset_settings
    }

    YSettingResetFactoryReset {
        id: id_reset_factory
    }
}
