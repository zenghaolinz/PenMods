import QtQuick 2.12
import com.youdao.pen 1.0
import "../commons"

Rectangle {
    id: controls
    color: "#151B27"
    signal closeRequested()
    signal advancedRequested()
    property bool choosing: false
    property bool scrubbing: false
    property real preview: 0
    property int heldDirection: 0
    property bool resumeAfterSeek: false
    readonly property var rates: [0.8, 1, 1.2, 1.5]
    function time(ms) {
        const seconds = Math.max(0, Math.floor(ms / 1000))
        return Math.floor(seconds / 60) + ":" + (seconds % 60 < 10 ? "0" : "") + seconds % 60
    }
    function seekTo(value) {
        if (mediaPlayerManager.duration <= 0 || !isFinite(value)) return
        const playing = mediaPlayerManager.playState === YEnum.PLAYING
        const target = Math.max(0, Math.min(mediaPlayerManager.duration, Math.round(value)))
        const delta = target - mediaPlayerManager.currentPos
        mediaPlayerManager.closeRepeat()
        if (delta > 0) mediaPlayerManager.onFastForward(delta)
        else if (delta < 0) mediaPlayerManager.onFastBackward(-delta)
        if (delta !== 0 && playing) { resumeAfterSeek = true; resumeTimer.restart() }
    }
    function hold(direction) { heldDirection = direction; seekTo(mediaPlayerManager.currentPos + direction * 5000); holdTimer.start() }
    Timer { id: holdTimer; interval: 350; repeat: true; onTriggered: controls.seekTo(mediaPlayerManager.currentPos + heldDirection * 3000) }
    Timer { id: resumeTimer; interval: 120; onTriggered: { if (resumeAfterSeek && controls.visible) mediaPlayerManager.onClickedPlay(); resumeAfterSeek = false } }
    onVisibleChanged: { holdTimer.stop(); resumeTimer.stop(); resumeAfterSeek = false; heldDirection = 0; scrubbing = false; choosing = false }
    YVerticalTitleBar { onCallBack: { holdTimer.stop(); closeRequested() } }
    Item {
        anchors.fill: parent; anchors.leftMargin: 58; anchors.rightMargin: 10
        YTextBase {
            x: 0; y: 6; width: parent.width - 52
            text: mediaPlayerManager.title; textFormat: Text.PlainText; elide: Text.ElideRight
            color: "white"; font.pixelSize: 14
        }
        YButtonBase {
            anchors.right: parent.right; y: 2; width: 46; height: 30; radius: 6; color: "#344263"
            onClicked: choosing = true
            YTextMedium { anchors.centerIn: parent; text: "选曲"; font.pixelSize: 13 }
        }
        Row {
            y: 39; anchors.horizontalCenter: parent.horizontalCenter; spacing: 10
            YButtonBase {
                width: 70; height: 42; radius: 9; color: "#29364B"
                YTextMedium { anchors.centerIn: parent; text: "上一首"; font.pixelSize: 13 }
                MouseArea {
                    objectName: "local-audio-back"
                    anchors.fill: parent; pressAndHoldInterval: 400
                    property bool held: false
                    onPressed: held = false
                    onPressAndHold: { held = true; controls.hold(-1) }
                    onReleased: { holdTimer.stop(); heldDirection = 0 }
                    onClicked: if (!held) mediaPlayerManager.onClickedPrev(false)
                    onCanceled: { holdTimer.stop(); heldDirection = 0 }
                }
            }
            YButtonBase {
                width: 70; height: 42; radius: 9; color: "#3578B8"
                onClicked: {
                    resumeTimer.stop(); resumeAfterSeek = false
                    if (mediaPlayerManager.playState === YEnum.PLAYING) mediaPlayerManager.onClickedPause()
                    else mediaPlayerManager.onClickedPlay()
                }
                YTextMedium { anchors.centerIn: parent; text: mediaPlayerManager.playState === YEnum.PLAYING ? "暂停" : "播放"; font.pixelSize: 14 }
            }
            YButtonBase {
                width: 70; height: 42; radius: 9; color: "#29364B"
                YTextMedium { anchors.centerIn: parent; text: "下一首"; font.pixelSize: 13 }
                MouseArea {
                    objectName: "local-audio-forward"
                    anchors.fill: parent; pressAndHoldInterval: 400
                    property bool held: false
                    onPressed: held = false
                    onPressAndHold: { held = true; controls.hold(1) }
                    onReleased: { holdTimer.stop(); heldDirection = 0 }
                    onClicked: if (!held) mediaPlayerManager.onClickedNext(false)
                    onCanceled: { holdTimer.stop(); heldDirection = 0 }
                }
            }
        }
        Item {
            id: seekBar
            x: 8; y: 85; width: parent.width - 16; height: 30
            readonly property real ratio: mediaPlayerManager.duration > 0 ? Math.max(0, Math.min(1, (scrubbing ? preview : mediaPlayerManager.currentPos) / mediaPlayerManager.duration)) : 0
            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 6; radius: 3; color: "#485267" }
            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width * seekBar.ratio; height: 6; radius: 3; color: "#60B5FF" }
            Rectangle { x: (parent.width - width) * seekBar.ratio; anchors.verticalCenter: parent.verticalCenter; width: 16; height: 16; radius: 8; color: "white" }
            MouseArea {
                anchors.fill: parent; anchors.margins: -5; enabled: mediaPlayerManager.duration > 0
                function update(x) { preview = Math.max(0, Math.min(1, (x - 5) / seekBar.width)) * mediaPlayerManager.duration }
                onPressed: { scrubbing = true; update(mouse.x) }
                onPositionChanged: if (pressed) update(mouse.x)
                onReleased: { controls.seekTo(preview); scrubbing = false }
                onCanceled: scrubbing = false
            }
        }
        YTextBase { y: 115; text: time(scrubbing ? preview : mediaPlayerManager.currentPos) + " / " + time(mediaPlayerManager.duration); font.pixelSize: 12; color: "#CCD8ED" }
        YButtonBase {
            anchors.right: parent.right; anchors.rightMargin: 72; y: 113; width: 50; height: 24; radius: 5; color: "#29364B"
            onClicked: advancedRequested()
            YTextBase { anchors.centerIn: parent; text: "更多"; font.pixelSize: 12; color: "white" }
        }
        YButtonBase {
            anchors.right: parent.right; y: 113; width: 65; height: 24; radius: 5; color: "#29364B"
            onClicked: {
                let next = 0
                for (let i = 0; i < rates.length; ++i) if (Math.abs(rates[i] - mediaPlayerManager.playbackRate) < 0.01) next = (i + 1) % rates.length
                mediaPlayerManager.playbackRate = rates[next]
            }
            YTextBase { anchors.centerIn: parent; text: mediaPlayerManager.playbackRate + "×"; font.pixelSize: 12; color: "white" }
        }
        YTextBase { y: 144; text: "拖动进度 · 长按上一首/下一首连续快退/快进"; font.pixelSize: 10; color: "#9AAAC4" }
    }
    Rectangle {
        anchors.fill: parent; anchors.leftMargin: 54; color: "#151B27"; visible: choosing
        MouseArea { anchors.fill: parent }
        YTextBase { x: 8; y: 8; text: "当前文件夹 · " + musicPlayer.playlist.length + " 首"; color: "white"; font.pixelSize: 14 }
        YButtonBase {
            anchors.right: parent.right; anchors.rightMargin: 8; y: 3; width: 44; height: 28; radius: 5
            onClicked: choosing = false
            YTextMedium { anchors.centerIn: parent; text: "返回"; font.pixelSize: 12 }
        }
        ListView {
            anchors.fill: parent; anchors.topMargin: 36; anchors.leftMargin: 6; anchors.rightMargin: 8
            clip: true; spacing: 5; model: musicPlayer.playlist
            delegate: YButtonBase {
                width: ListView.view.width; height: 42; radius: 6
                color: modelData.index === musicPlayer.currentIndex ? "#335A7A" : "#29364B"
                onClicked: { musicPlayer.selectTrack(modelData.index); choosing = false }
                YTextBase { anchors.fill: parent; anchors.margins: 8; text: modelData.title; textFormat: Text.PlainText; elide: Text.ElideRight; font.pixelSize: 14; color: "white" }
            }
        }
    }
}
