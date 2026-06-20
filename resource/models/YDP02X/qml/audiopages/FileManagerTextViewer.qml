import QtQuick 2.12
import com.youdao.pen 1.0

import "../commons"
import "../components"
import "../i18n"

YBackButtonAudioPage {
    id: id_container_index

    property variant stringList: {
        let ret = textReader.content
        if (!textReader.isMarkdown) {
            ret = ret.split('\n')
        } else {
            ret = [ret]
        }
        return ret
    }

    YVerticalTitleBar {
        id: id_title_bar
        onCallBack: backButtonClicked()
    }

    ListView {
        id: id_content
        model: stringList
        anchors.fill: parent
        anchors.leftMargin: 54
        anchors.rightMargin: 10

        delegate: Text {
            text: model.modelData
            font.pixelSize: 16
            font.family: qmlGlobal.fontFamilyZhCn
            textFormat: textReader.isMarkdown ? Text.MarkdownText : Text.PlainText
            wrapMode: Text.WrapAnywhere
            color: YColors.white
            width: 260
        }

        header: id_header_component

        Component {
            id: id_header_component
            Item {
                width: id_content.width
                implicitHeight: 50

                YTextBase {
                    color: YColors.grayText
                    font.pixelSize: 16
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    elide: YTextBase.ElideRight
                    text: textReader.title
                }
            }
        }
    }

}