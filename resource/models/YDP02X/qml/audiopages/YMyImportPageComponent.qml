import QtQuick 2.12
import com.youdao.pen 1.0

import "../commons"
import "../components"
import "../i18n"

YBackButtonAudioPage {
    id: id_container_index

    property string selectedFileName: ""
    property string keyboardAction: "rename"
    property bool textSearchOpen: false

    YVerticalTitleBar {
        id: id_title_bar
        onCallBack: {
            if (textSearchOpen) {
                textSearchOpen = false
            } else if (visible && fileManager.canCdUp()) {
                fileManager.changeDir("..")
            } else {
                backButtonClicked()
            }
        }
    }


    YBaseListView {
        id: id_import_page_column_view
        anchors.fill: parent
        anchors.leftMargin: 54
        anchors.rightMargin: 10
        spacing: 8

        model: fileManager
        onMovingChanged: {
            if (!moving && atYEnd && fileManager.hasMore) {
                fileManager.loadMore()
            }
        }

        header: id_header_component

        Component {
            id: id_header_component
            Item {
                width: id_import_page_column_view.width
                implicitHeight: 50

                YTextBase {
                    color: YColors.grayText
                    font.pixelSize: 16
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    elide: YTextBase.ElideLeft
                    text: fileManager.currentTitle
                    textFormat: Text.StyledText
                }
            }
        }

        delegate: Item {
            width: id_import_page_column_view.width
            implicitHeight: 50
            YMyImportPageComponentViewItem {
                implicitHeight: parent.implicitHeight
                title: model.fileName
                value: model.isDir ? "" : model.sizeStr

                onClicked: {
                    if (model.isDir) {
                        fileManager.changeDir(model.fileName)
                        return
                    }
                    switch (model.extName) {
                    case "mp3":
                        fileManager.playFromView(model.fileName)
                        break
                    case "md": case "txt": case "lrc": case "json":
                    case "xml": case "yml": case "yaml":
                        textReader.open(model.fileName)
                        id_pop_container.show("FileManagerTextViewer")
                        break
                    case "png": case "jpg": case "jpeg": {
                        const image = fileManager.imageUrl(model.fileName)
                        if (image.toString().length)
                            id_pop_container.show("ImageViewer", {fileUrl: image, title: model.fileName})
                        break
                    }
                    case "avi": case "mp4": case "mov": case "flv":
                    case "mkv": case "webm": {
                        if (videoPlayer.open(model.fileName)) {
                            if (mediaPlayerManager.playState === YEnum.PLAYING)
                                mediaPlayerManager.onClickedPause()
                            id_pop_container.show("VideoPlayer", {title: model.fileName})
                        }
                        break
                    }
                    default:
                        qmlGlobal.showToast("暂不支持该格式", YColors.yellow)
                    }
                }

                onLongPressed: {
                    selectedFileName = model.fileName
                    id_file_actions.show()
                }
            }
        }

        footer: (count > 0 && fileManager.hasMore)
                ? id_listview_loading_footer : id_listview_loaded_footer

        Component {
            id: id_listview_loading_footer

            YListViewLoadMoreFooter {}
        }

        Component {
            id: id_listview_loaded_footer

            YSpacing {
                width: id_import_page_column_view.width
                implicitHeight: 18
            }
        }

        onBusyingChanged: {
            if (!busying) {
                id_import_page_column_view.positionViewAtBeginning()
            }
        }
    }

    YText {
        id: id_import_page_column_view_empty_tip
        anchors.centerIn: parent
        text: "空文件夹"
        color: YColors.white
        font.pixelSize: 20
        visible: id_import_page_column_view.count === 0
    }

    YIconButton {
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 10
        width: 30; height: 30; radius: 6
        source: "commons/more"
        enabled: id_import_page_column_view.count > 0
        onValidClicked: id_pop_container.show("FileManagerDrawerLayer")
    }

    YTwoButtonDialog {
        id: id_file_actions
        anchors.fill: parent
        tipItem.text: "管理文件：" + selectedFileName
        buttonItemConfirm.text: "重命名"
        buttonItemCancel.text: "删除"
        onClickedConfirm: { close(); requestRenameKeyboard() }
        onClickedCancel: { fileManager.remove(selectedFileName); close() }
    }

    YPagePopHelper {
        id: id_keyboard_helper
        z: 40
        property bool keyboardOpen: false
        isShowing: keyboardOpen
        function inputPageCreated(keyboardPage) {
            keyboardPage.backButtonClicked.connect(function() {
                keyboardOpen = false
                qmlGlobal.inputPageShowing = false
                keyboardPage.todoDestroy()
            })
            keyboardPage.inputFinished.connect(function(content) {
                if (keyboardAction === "search") {
                    textSearchPanel.query = content.trim().slice(0, 128)
                    textSearchPanel.run()
                } else fileManager.rename(selectedFileName, content)
            })
            keyboardPage.placeHolderText = keyboardAction === "search" ? "文件名/正文关键词（最多128字）" : "请输入新文件名"
            keyboardPage.enterText(keyboardAction === "search" ? textSearchPanel.query : selectedFileName)
            keyboardOpen = true
            keyboardPage.show()
            qmlGlobal.inputPageShowing = true
        }
    }

    function requestRenameKeyboard() { requestKeyboard("rename") }
    function requestKeyboard(action) {
        if (id_keyboard_helper.keyboardOpen) return
        keyboardAction = action
        const component = Qt.createComponent("qrc:/qml/YInputPage.qml", Component.PreferSynchronous)
        if (component.status !== Component.Ready) {
            console.warn("我的导入键盘：", component.errorString())
            return
        }
        const keyboard = component.createObject(id_keyboard_helper.containerItem)
        if (keyboard) id_keyboard_helper.inputPageCreated(keyboard)
    }

    Item {
        id: id_pop_container
        z: 30
        anchors.fill: parent
        signal closeSameItem(string popStackId)
        function show(page, properties) {
            closeSameItem(page)
            const component = Qt.createComponent(("./%1.qml").arg(page))
            if (component.status !== Component.Ready) {
                console.warn("我的导入：", component.errorString())
                if (page === "VideoPlayer") videoPlayer.playback.close()
                return
            }
            const incubator = component.incubateObject(id_pop_container, properties || {})
            function initialize(item) {
                Object.defineProperty(item, "popStackId", {value: page})
                item.backButtonClicked.connect(function() { closeSameItem(page); item.destroy(1) })
                id_pop_container.closeSameItem.connect(function(stackId) {
                    if (stackId === page) item.destroy(1)
                })
                systemBase.homeKeyRelease.connect(function() { item.destroy(1) })
                item.show()
            }
            if (incubator.status === Component.Ready) initialize(incubator.object)
            else incubator.onStatusChanged = function(status) {
                if (status === Component.Ready) initialize(incubator.object)
            }
        }
    }

    YButtonBase {
        x: 7; anchors.bottom: parent.bottom; anchors.bottomMargin: 52
        width: 40; height: 30; radius: 6; color: "#335A7A"
        onClicked: { textSearchOpen = true; requestKeyboard("search") }
        YTextMedium { anchors.centerIn: parent; text: "找文本"; font.pixelSize: 10 }
    }
    TextFileSearchPanel {
        id: textSearchPanel
        anchors.fill: parent; anchors.leftMargin: 54
        z: 10; visible: textSearchOpen
        onCloseRequested: textSearchOpen = false
        onRequestQuery: requestKeyboard("search")
        onOpenResult: {
            if (fileManager.openTextResult(path)) {
                if (textSearchPanel.searchContents) textReader.search(textSearchPanel.query)
                id_pop_container.show("FileManagerTextViewer")
            }
        }
    }

    Component.onCompleted: fileManager.changeDir("")
}
