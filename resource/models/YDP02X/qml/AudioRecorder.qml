import QtQuick 2.12
import com.youdao.pen 1.0

import "./commons"
import "./components"
import "./i18n"
import "./settingpages"

YBackButtonPage {
    id: id_audio_recorder
    objectName: "YPage===AudioRecorder.qml"

    Flickable {
        id: id_item_container
        anchors.fill: parent
        anchors.leftMargin: 54
        anchors.rightMargin: 10
        contentHeight: id_title_container.height + id_column_main.height

        YSettingItemTitle {
            id: id_title_container
            title: "录音机"
        }

        Column {
            id: id_column_main
            anchors.top: id_title_container.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            spacing: 8

            YSettingAboutClickableItem {
                id: id_state
                opacityChangableWhenPressed: false
                sourceSize: Qt.size(24,24)
                onClicked: {
                    switch (audioRecorder.state) {
                    case MEnum.RC_Active:
                        stop()
                        break
                    case MEnum.RC_Suspended:
                        break
                    case MEnum.RC_Idle:
                    case MEnum.RC_Stopped:
                    case MEnum.RC_Interrupted:
                    case MEnum.RC_Waiting:
                        start()
                        break
                    }
                }
            }

            YSettingAboutClickableItem {
                title: audioRecorder.state == MEnum.RC_Active || audioRecorder.state == MEnum.RC_Waiting ? "修改文件名" : "文件名"
                enabled: audioRecorder.state == MEnum.RC_Active
                value: audioRecorder.fileName
                imageName: "settings/info_more_arrow"
                onClicked: requestKeyboard()
            }

            YSpacingForColumn {
                implicitHeight: 4
            }

            function update() {
                switch (audioRecorder.state) {
                case MEnum.RC_Active:
                    id_state.title = '正在录音'
                    id_state.value = '00:00:00'
                    id_state.source = ''
                    break
                case MEnum.RC_Suspended:
                    id_state.title = '暂停'
                    id_state.source = 'audioplayer/play'
                    break
                case MEnum.RC_Idle:
                case MEnum.RC_Stopped:
                case MEnum.RC_Interrupted:
                case MEnum.RC_Waiting:
                    id_state.title = '就绪'
                    id_state.value = ''
                    id_state.source = 'audioplayer/mic'
                    break
                }
            }

        }

    }

    property bool locked: false

    function start() {
        if (locked) { return }
        locked = true
        audioRecorder.start()
        locked = false
    }

    function stop() {
        if (locked) { return }
        locked = true
        switch (audioRecorder.stop()) {
        case MEnum.RC_OpenError:
            qmlGlobal.showToast("打开输入设备时出现错误", YColors.yellow)
            break
        case MEnum.RC_IOError:
            qmlGlobal.showToast("从输入设备读取数据时出现错误", YColors.yellow)
            break
        // case MEnum.RC_UnderrunError:
        //    showToast("输入流采样率异常", YColors.yellow)
        //    break
        case MEnum.RC_FatalError:
            qmlGlobal.showToast("输入设备引发无法恢复的错误", YColors.yellow)
            break
        case MEnum.RC_NoError:
        case MEnum.RC_UnderrunError: // temp...
        default:
            qmlGlobal.showToast("录音保存成功")
            break
        }
        locked = false
    }

    function ts2str(ts) {
        let s = ts % 60
        ts -= s
        let m = (ts / 60) % 60
        ts -= m * 60
        let h = ts / 3600
        if (s < 10) { s = "0" + String(s) }
        if (m < 10) { m = "0" + String(m) }
        if (h < 10) { h = "0" + String(h) }
        return `${h}:${m}:${s}`
    }

    Connections {
        target: audioRecorder
        ignoreUnknownSignals: true
        property int currentSeconds: 0
        function onStateChanged() {
            id_column_main.update()
            switch (audioRecorder.state) {
            case MEnum.RC_Active:
                break
            case MEnum.RC_Suspended:
                break
            case MEnum.RC_Stopped:
            case MEnum.RC_Interrupted:
                stop()
                break
            case MEnum.RC_Idle:
                break
            }
        }
        function onNotify() {
            currentSeconds += 1
            id_state.value = ts2str(currentSeconds)
        }
    }

    Item {
        anchors.fill: parent
        anchors.topMargin: 80
        anchors.leftMargin: 0

        Column {
            id: id_column_sidebar
            anchors.left: parent.left
            anchors.topMargin: 12
            spacing: 8
            visible: !qmlGlobal.inputPageShowing

            YIconButton {
                id: id_start_record
                width: 30
                height: 30
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.bottom: parent.bottom
                radius: 6
                enabled: audioRecorder.state != MEnum.RC_Active || audioRecorder.state == MEnum.RC_Waiting
                source: "audioplayer/mic"
                sourceSize: Qt.size(20, 20)
                property bool recording: false
                onValidClicked: {
                    start()
                }
            }

            YIconButton {
                id: id_play_record
                width: 30
                height: 30
                anchors.top: id_start_record.bottom
                anchors.topMargin: 10
                anchors.left: parent.left
                anchors.leftMargin: 10
                radius: 6
                enabled: audioRecorder.state != MEnum.RC_Active && audioRecorder.state != MEnum.RC_Waiting
                source: "audioplayer/pause"
                sourceSize: Qt.size(24, 24)
                onValidClicked: {
                }
            }

            YIconButton {
                id: id_stop_record
                width: 30
                height: 30
                anchors.top: id_play_record.bottom
                anchors.topMargin: 10
                anchors.left: parent.left
                anchors.leftMargin: 10
                radius: 6
                enabled: audioRecorder.state == MEnum.RC_Active && audioRecorder.state != MEnum.RC_Waiting
                source: "textbook/select-check"
                sourceSize: Qt.size(20, 20)
                onValidClicked: {
                    stop()
                }
            }

        }
    }

    YPagePopHelper {
        id: id_page_pop_helper
        isShowing: qmlGlobal.inputPageShowing
        objectName: "from_AudioRecorder.qml"

        function inputPageCreated(keyboardPage) {
            keyboardPage.backButtonClicked.connect(function(){
                qmlGlobal.inputPageShowing = false
                keyboardPage.todoDestroy()
                keyboardPage = null
            })
            keyboardPage.inputFinished.connect(function(content){
                let ret = audioRecorder.setFileName(content)
                switch(ret) {
                case 0:
                    qmlGlobal.showToast('文件名已修改')
                    break
                case 1:
                    qmlGlobal.showToast('文件名不能包含特殊字符', YColors.yellow)
                    break
                }
            })
            keyboardPage.enterText(audioRecorder.fileName)
            keyboardPage.show()
            qmlGlobal.inputPageShowing = true
        }
    }

    function requestKeyboard() {
        let component = qmlCreateComponent("YInputPage")
        if (Component.Ready === component.status) {
            var incubator = component.incubateObject(id_page_pop_helper.containerItem);
            if (incubator.status !== Component.Ready) {
                incubator.onStatusChanged = function(status) {
                    if (status === Component.Ready) {
                        id_page_pop_helper.inputPageCreated(incubator.object)
                    }
                }
            } else {
                id_page_pop_helper.inputPageCreated(incubator.object)
            }
        }
    }

    Connections {
        target: systemBase
        ignoreUnknownSignals: true
        onOcrStart: {
            backButtonClicked()
        }
    }

    Component.onCompleted: {
        id_column_main.update()
    }

    onBackButtonClicked: {
        stop()
    }

    onVisibleChanged: {
        if (visible) {
            qmlGlobal.currentPageIndex = MEnum.PG_AudioRecorder
        }
    }
}
