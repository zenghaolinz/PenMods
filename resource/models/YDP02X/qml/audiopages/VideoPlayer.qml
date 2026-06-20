import QtQuick 2.12
import QtMultimedia 5.14
import com.youdao.pen 1.0

import "../commons"
import "../components"
import "../i18n"

YBackButtonAudioPage {
    id: id_video_player

    YVerticalTitleBar {
        id: id_title_bar
        visible: id_video.playbackState != MediaPlayer.PlayingState
        onCallBack: backButtonClicked()
    }

    Video {
        id: id_video
        width: YEnum.Screen.Width
        height: YEnum.Screen.Height
        autoPlay: true
        source: videoPlayer.path

        MouseArea {
            anchors.fill: parent
            onClicked: {
                id_video.playbackState == MediaPlayer.PlayingState ? id_video.pause() : id_video.play()
            }
        }

        onPaused: {
            videoPlayer.onStatusChanged('paused')
        }

        onPlaying: {
            videoPlayer.onStatusChanged('playing')
        }

        onStopped: {
            videoPlayer.onStatusChanged('stopped')
        }

        YProgressBar {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 2
            color: YColors.black
            progressColor: YColors.blueText
            progressGradient: Gradient {
                GradientStop { position: 0.0; color: YColors.blueText }
                GradientStop { position: 1.0; color: YColors.blueText }
            }
            progress: id_video.bufferProgress
        }

        /*
        function mmssString(ms) {
            let seconds = parseInt(ms / 1000);
            let minutes = parseInt(seconds / 60);
            seconds = seconds % 60;
            return ("%1%2:%3%4").arg(minutes > 9 ? "" : "0").arg(minutes).arg(seconds > 9 ? "" : "0").arg(seconds);
        }

        Item {
            id: id_player_progress_timeinfo_item
            implicitWidth: 200
            implicitHeight: 54
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 10
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.horizontalCenterOffset: ((id_video.bufferProgress - 50) * 0.01 * parent.width).bound(-284, +284)
            visible: false

            YBlurMaskRectangle {
                id: id_blur_mask_rectangle
                anchors.fill: parent
                sourceItem: id_audio_player_container
                sourceRect: Qt.rect(parent.x, parent.y, width, height)
                blurRadius: 48

                Rectangle {
                    anchors.fill: parent
                    color: YColors.white
                    opacity: 0.14
                    radius: height/2
                }
            }

            YTextMedium {
                anchors.centerIn: parent
                font.pixelSize: 16
                textFormat: Text.RichText
                text: ('<span style="font-family: %1; color:%2">%3</span> / %4')
                    .arg(qmlGlobal.fontFamilyEnUs).arg(YColors.blueText)
                    .arg(mmssString(id_video.position))
                    .arg(mmssString(id_video.duration))
            }
        }*/

    }

    onBackButtonClicked: {
        videoPlayer.onStatusChanged('stopped')
        console.warn("VideoPlayer backbuttonclicked!!!!")
    }

    onVisibleChanged: {
        console.warn("VideoPlayer onVisibleChanged")
        if (visible) {
            console.warn("VideoPlayer onVisibleChanged->MEnum.PG_VideoPlayer")
            qmlGlobal.currentPageIndex = MEnum.PG_VideoPlayer
        }
    }

}