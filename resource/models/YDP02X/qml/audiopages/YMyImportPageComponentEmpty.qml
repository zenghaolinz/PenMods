import QtQuick 2.12
import com.youdao.pen 1.0

import "../commons"
import "../components"
import "../i18n"

YBackground {
    id: id_container_index
    anchors.fill: parent
    anchors.leftMargin: 54
    anchors.rightMargin: 10
    anchors.topMargin: 12

    YText {
        id: id_title_bar
        anchors.top: parent.top
        width: parent.width
        font.family: qmlGlobal.fontFamilyZhCn
        font.pixelSize: {
            switch (qmlGlobal.language) {
            case YEnum.EN_US:
                return 16
            }
            return 18
        }
        wrapMode: YText.Wrap
        text: YTranslateText.myImportAudiosTip
    }

    Rectangle {
        id: id_qr_code_bg
        implicitWidth: 90
        implicitHeight: 90
        radius: 8
        anchors.left: parent.left
        anchors.top: id_title_bar.bottom
        anchors.topMargin: 10

        YImage {
            id: id_qr_code_icon
            anchors.centerIn: parent
            sourceSize: Qt.size(84, 84)
            imageName: "audioplayer/audioplayer_import_qr"
        }
    }

    Column {
        anchors.left: id_qr_code_bg.right
        anchors.leftMargin: 8
        anchors.top: id_qr_code_bg.top
        anchors.right: parent.right
        spacing: 2

        YTextBase {
            id: id_tip_1
            width: parent.width
            font.family: qmlGlobal.fontFamilyZhCn
            wrapMode: YTextBase.Wrap
            color: YColors.grayText
            font.pixelSize: 15
            text: YTranslateText.myImportAudiosFormat
        }

        YTextBase {
            id: id_tip_2
            width: parent.width
            font.family: qmlGlobal.fontFamilyZhCn
            wrapMode: YTextBase.Wrap
            color: YColors.grayText
            font.pixelSize: 15
            text: YTranslateText.myImportAudiosQrCodeTip
        }

    }
}
