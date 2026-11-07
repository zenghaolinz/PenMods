import QtQuick 2.12
import "../commons"

YBackButtonPage {
    id: page
    objectName: "FileManagerImageViewer.qml"

    property url fileUrl
    property string title
    property real zoom: 1
    defaultTitleBar.z: 2

    function setZoom(value) {
        const centerX = (viewport.contentX + viewport.width / 2) / viewport.contentWidth
        const centerY = (viewport.contentY + viewport.height / 2) / viewport.contentHeight
        zoom = Math.max(1, Math.min(4, value))
        viewport.contentX = Math.max(0, Math.min(viewport.contentWidth - viewport.width, centerX * viewport.contentWidth - viewport.width / 2))
        viewport.contentY = Math.max(0, Math.min(viewport.contentHeight - viewport.height, centerY * viewport.contentHeight - viewport.height / 2))
    }

    Flickable {
        id: viewport
        anchors.fill: parent; anchors.leftMargin: 54; anchors.bottomMargin: 22
        clip: true; boundsBehavior: Flickable.StopAtBounds
        interactive: page.zoom > 1 && picture.status === Image.Ready
        contentWidth: width * page.zoom; contentHeight: height * page.zoom
        Image {
            id: picture
            objectName: "penmods-imported-image"
            width: viewport.contentWidth; height: viewport.contentHeight
            source: page.fileUrl; asynchronous: true; cache: false; autoTransform: true
            sourceSize.width: 1600; sourceSize.height: 1200
            fillMode: Image.PreserveAspectFit
        }
    }

    YTextBase {
        anchors.centerIn: viewport; width: viewport.width
        horizontalAlignment: Text.AlignHCenter; color: "white"; font.pixelSize: 14
        visible: picture.status === Image.Loading || picture.status === Image.Error
        text: picture.status === Image.Error ? "无法读取图片" : "正在打开图片…"
    }

    Column {
        x: 8; y: 56; spacing: 5; z: 3
        YButtonBase {
            width: 38; height: 32; radius: 6; enabled: picture.status === Image.Ready && page.zoom < 4
            onClicked: page.setZoom(page.zoom * 2)
            YTextMedium { anchors.centerIn: parent; text: "+"; font.pixelSize: 21 }
        }
        YButtonBase {
            width: 38; height: 32; radius: 6; enabled: picture.status === Image.Ready && page.zoom > 1
            onClicked: page.setZoom(page.zoom / 2)
            YTextMedium { anchors.centerIn: parent; text: "−"; font.pixelSize: 21 }
        }
        YTextBase {
            width: 38; horizontalAlignment: Text.AlignHCenter
            text: page.zoom + "×"; color: "#CCD8ED"; font.pixelSize: 12
        }
    }

    YTextBase {
        anchors.left: viewport.left; anchors.right: parent.right; anchors.rightMargin: 8
        anchors.bottom: parent.bottom; height: 22; verticalAlignment: Text.AlignVCenter
        text: page.title; textFormat: Text.PlainText; elide: Text.ElideRight; color: "#CCD8ED"; font.pixelSize: 12
    }
}
