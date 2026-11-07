import QtQuick 2.12
import PenMods.Media 1.0
import "../commons"

YBackButtonPage {
    id: page
    objectName: "FileManagerVideoPlayer.qml"

    property string title
    readonly property var playback: videoPlayer ? videoPlayer.playback : null
    property bool controlsVisible: true
    property bool scrubbing: false
    property real previewPosition: 0
    property real pendingPosition: -1
    readonly property real position: playback ? playback.position : 0
    readonly property real duration: playback ? playback.duration : 0
    readonly property bool seekable: playback && playback.seekable
    readonly property real shownPosition: scrubbing ? previewPosition : pendingPosition >= 0 ? pendingPosition : position
    readonly property bool playing: playback && playback.playing
    readonly property bool failed: playback && playback.error.length > 0

    defaultTitleBar.z: 3
    defaultTitleBar.visible: controlsVisible || !playing

    function showControls() {
        controlsVisible = true
        if (playing) hideControls.restart()
    }

    function seek(position) {
        if (seekable && duration > 0) {
            pendingPosition = Math.round(Math.max(0, Math.min(duration, position)))
            playback.seek(pendingPosition)
            if (playing) seekFeedback.restart()
        }
        showControls()
    }

    function togglePlayback() {
        if (playing) playback.pause()
        else if (playback && !failed) playback.play()
        showControls()
    }

    function timestamp(ms) {
        const seconds = Math.max(0, Math.floor(ms / 1000))
        return Math.floor(seconds / 60) + ":" + (seconds % 60 < 10 ? "0" : "") + seconds % 60
    }

    Timer {
        id: hideControls
        interval: 4000
        onTriggered: if (page.playing && !page.scrubbing) page.controlsVisible = false
    }
    Timer {
        id: seekFeedback
        interval: 1000
        onTriggered: if (page.playing) page.pendingPosition = -1
    }
    VideoCanvas {
        objectName: "penmods-video-playback"
        anchors.fill: parent
        playback: page.playback
        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (page.playing && page.controlsVisible) {
                    hideControls.stop()
                    page.controlsVisible = false
                } else page.showControls()
            }
        }
    }

    onPlayingChanged: {
        showControls()
        if (playing && pendingPosition >= 0) seekFeedback.restart()
    }
    Connections {
        target: page.playback
        function onPositionChanged() {
            if (page.pendingPosition >= 0 && Math.abs(page.position - page.pendingPosition) < 250)
                page.pendingPosition = -1
        }
    }
    onFailedChanged: if (failed) {
        showControls()
        console.warn("VideoPlayer:", playback.error)
    }
    onVisibleChanged: if (playback) {
        if (visible) playback.play()
        else playback.close()
    }
    Component.onDestruction: if (playback) playback.close()

    Rectangle {
        anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
        height: 29; color: "#CA121820"; visible: page.controlsVisible || !page.playing
        YTextBase {
            anchors.fill: parent; anchors.leftMargin: 54; anchors.rightMargin: 8
            verticalAlignment: Text.AlignVCenter
            text: page.title; textFormat: Text.PlainText; elide: Text.ElideRight; color: "white"; font.pixelSize: 13
        }
    }

    YTextBase {
        anchors.centerIn: parent; width: parent.width - 110
        horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap
        visible: page.failed || (playback && playback.loading)
        text: page.failed ? "无法播放此视频\n可尝试小尺寸的 H.264 MP4" : "正在打开视频…"
        color: "white"; font.pixelSize: 14
    }

    Rectangle {
        id: toolbar
        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
        height: 61; color: "#E5121820"; visible: !page.failed && (page.controlsVisible || !page.playing)

        Item {
            id: progress
            anchors.left: parent.left; anchors.right: parent.right
            anchors.leftMargin: 54; anchors.rightMargin: 10
            height: 27
            readonly property real ratio: page.duration > 0
                ? Math.max(0, Math.min(1, page.shownPosition / page.duration)) : 0
            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width; height: 5; radius: 2; color: "#485267" }
            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: parent.width * progress.ratio; height: 5; radius: 2; color: "#60B5FF" }
            Rectangle {
                x: (parent.width - width) * progress.ratio; anchors.verticalCenter: parent.verticalCenter
                width: 14; height: 14; radius: 7; color: "white"
            }
            MouseArea {
                anchors.fill: parent; enabled: page.seekable && page.duration > 0
                function updatePreview() {
                    page.previewPosition = Math.max(0, Math.min(1, mouseX / width)) * page.duration
                }
                onPressed: { hideControls.stop(); page.scrubbing = true; updatePreview() }
                onPositionChanged: if (pressed) updatePreview()
                onReleased: { updatePreview(); page.scrubbing = false; page.seek(page.previewPosition) }
                onCanceled: { page.scrubbing = false; page.showControls() }
            }
        }

        Row {
            x: 54; y: 28; spacing: 5
            YButtonBase {
                width: 46; height: 28; radius: 6; enabled: page.seekable
                onClicked: page.seek(page.shownPosition - 5000)
                YTextMedium { anchors.centerIn: parent; text: "−5 秒"; font.pixelSize: 12 }
            }
            YButtonBase {
                width: 54; height: 28; radius: 6; color: "#3578B8"; enabled: page.duration > 0
                onClicked: page.togglePlayback()
                YTextMedium { anchors.centerIn: parent; text: page.playing ? "暂停" : "播放"; font.pixelSize: 13 }
            }
            YButtonBase {
                width: 46; height: 28; radius: 6; enabled: page.seekable
                onClicked: page.seek(page.shownPosition + 5000)
                YTextMedium { anchors.centerIn: parent; text: "+5 秒"; font.pixelSize: 12 }
            }
            YTextBase {
                width: Math.max(0, toolbar.width - 222); height: 28
                verticalAlignment: Text.AlignVCenter; horizontalAlignment: Text.AlignRight
                text: page.timestamp(page.shownPosition) + " / " + page.timestamp(page.duration)
                font.pixelSize: 11; color: "#CFD8E8"; elide: Text.ElideLeft
            }
        }
    }
}
