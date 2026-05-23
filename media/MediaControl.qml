import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Layouts

Scope {
  id: root
  property var theme: DefaultTheme {}
  property string font: "Hack Nerd Font"

  property var activePlayer: {
    const players = Mpris.players.values;
    if (!players || players.length === 0) return null;
    for (const p of players) {
      if (p.playbackState === MprisPlaybackState.Playing) return p;
    }
    return players[0];
  }

  property bool popupVisible: false

  IpcHandler {
    target: "media"

    function toggle(): void {
      root.popupVisible = !root.popupVisible;
    }

    function play_pause(): void {
      if (root.activePlayer) root.activePlayer.togglePlaying();
    }
  }

  // Position update timer
  Timer {
    id: posTimer
    interval: 1000
    running: root.popupVisible && root.activePlayer !== null && root.activePlayer.isPlaying
    repeat: true
    onTriggered: posTimer.running = running // force rebind to refresh position
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: mediaWindow
      required property var modelData
      screen: modelData

      visible: root.popupVisible
      focusable: true
      color: "transparent"

      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
      WlrLayershell.namespace: "quickshell-media"

      exclusionMode: ExclusionMode.Ignore

      anchors {
        top: true
        bottom: true
        left: true
        right: true
      }

      // Backdrop
      MouseArea {
        anchors.fill: parent
        onClicked: root.popupVisible = false

        Rectangle {
          anchors.fill: parent
          color: root.theme.bgOverlay
        }
      }

      // Media panel
      Rectangle {
        anchors.centerIn: parent
        width: 420
        height: contentCol.implicitHeight + 48
        radius: 16
        color: root.theme.bgBase
        border.color: root.theme.bgBorder
        border.width: 1

        MouseArea {
          anchors.fill: parent
          onClicked: event => event.accepted = true
        }

        Keys.onEscapePressed: root.popupVisible = false
        Keys.onSpacePressed: {
          if (root.activePlayer) root.activePlayer.togglePlaying();
        }

        ColumnLayout {
          id: contentCol
          anchors.fill: parent
          anchors.margins: 24
          spacing: 16

          // No player state
          Text {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            text: "  No media playing"
            color: root.theme.textMuted
            font.pixelSize: 14
            font.family: root.font
            horizontalAlignment: Text.AlignHCenter
            visible: root.activePlayer === null
          }

          // Album art + track info
          RowLayout {
            Layout.fillWidth: true
            spacing: 16
            visible: root.activePlayer !== null

            // Album art
            Rectangle {
              Layout.preferredWidth: 120
              Layout.preferredHeight: 120
              radius: 12
              color: root.theme.bgSurface
              clip: true

              Image {
                anchors.fill: parent
                source: root.activePlayer ? root.activePlayer.trackArtUrl : ""
                fillMode: Image.PreserveAspectCrop
                sourceSize.width: 120
                sourceSize.height: 120
                visible: status === Image.Ready

                Accessible.role: Accessible.StaticText
                Accessible.name: "Album artwork"
              }

              // Fallback icon
              Text {
                anchors.centerIn: parent
                text: "󰎆"
                color: root.theme.textMuted
                font.pixelSize: 40
                font.family: root.font
                visible: !root.activePlayer || root.activePlayer.trackArtUrl === ""
              }
            }

            // Track info
            ColumnLayout {
              Layout.fillWidth: true
              spacing: 4

              Text {
                text: root.activePlayer ? root.activePlayer.trackTitle : ""
                color: root.theme.textPrimary
                font.pixelSize: 15
                font.family: root.font
                font.bold: true
                elide: Text.ElideRight
                Layout.fillWidth: true

                Accessible.role: Accessible.StaticText
                Accessible.name: "Track: " + text
              }

              Text {
                text: root.activePlayer ? root.activePlayer.trackArtist : ""
                color: root.theme.textSecondary
                font.pixelSize: 13
                font.family: root.font
                elide: Text.ElideRight
                Layout.fillWidth: true
                visible: text !== ""

                Accessible.role: Accessible.StaticText
                Accessible.name: "Artist: " + text
              }

              Text {
                text: root.activePlayer ? root.activePlayer.trackAlbum : ""
                color: root.theme.textMuted
                font.pixelSize: 12
                font.family: root.font
                elide: Text.ElideRight
                Layout.fillWidth: true
                visible: text !== ""

                Accessible.role: Accessible.StaticText
                Accessible.name: "Album: " + text
              }

              Item { Layout.fillHeight: true }

              // Player identity
              Text {
                text: {
                  if (!root.activePlayer) return "";
                  const name = root.activePlayer.identity || "";
                  return name !== "" ? "  " + name : "";
                }
                color: root.theme.textMuted
                font.pixelSize: 11
                font.family: root.font
                visible: text !== ""
              }
            }
          }

          // Progress bar
          ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            visible: root.activePlayer !== null && root.activePlayer.length > 0

            // Clickable progress bar
            Rectangle {
              Layout.fillWidth: true
              height: 6
              radius: 3
              color: root.theme.bgSurface

              Accessible.role: Accessible.ProgressBar
              Accessible.name: "Playback progress"

              Rectangle {
                width: root.activePlayer && root.activePlayer.length > 0
                  ? parent.width * (root.activePlayer.position / root.activePlayer.length)
                  : 0
                height: parent.height
                radius: 3
                color: root.theme.accentPrimary

                Behavior on width {
                  NumberAnimation { duration: 200 }
                }
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: mouse => {
                  if (root.activePlayer && root.activePlayer.length > 0) {
                    const ratio = mouse.x / width;
                    root.activePlayer.position = ratio * root.activePlayer.length;
                  }
                }
              }
            }

            // Time labels
            RowLayout {
              Layout.fillWidth: true

              Text {
                text: formatTime(root.activePlayer ? root.activePlayer.position : 0)
                color: root.theme.textMuted
                font.pixelSize: 10
                font.family: root.font
              }

              Item { Layout.fillWidth: true }

              Text {
                text: formatTime(root.activePlayer ? root.activePlayer.length : 0)
                color: root.theme.textMuted
                font.pixelSize: 10
                font.family: root.font
              }
            }
          }

          // Controls
          RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 20
            visible: root.activePlayer !== null

            // Previous
            Rectangle {
              width: 40
              height: 40
              radius: 20
              color: prevHover.containsMouse ? root.theme.bgHover : "transparent"

              Accessible.role: Accessible.Button
              Accessible.name: "Previous track"

              Text {
                anchors.centerIn: parent
                text: "󰒮"
                color: root.theme.textPrimary
                font.pixelSize: 20
                font.family: root.font
              }

              MouseArea {
                id: prevHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: { if (root.activePlayer) root.activePlayer.previous(); }
              }
            }

            // Play/Pause
            Rectangle {
              width: 48
              height: 48
              radius: 24
              color: root.theme.accentPrimary

              Accessible.role: Accessible.Button
              Accessible.name: root.activePlayer && root.activePlayer.isPlaying ? "Pause" : "Play"

              Text {
                anchors.centerIn: parent
                text: root.activePlayer && root.activePlayer.isPlaying ? "󰏤" : "󰐊"
                color: root.theme.bgBase
                font.pixelSize: 24
                font.family: root.font
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: { if (root.activePlayer) root.activePlayer.togglePlaying(); }
              }
            }

            // Next
            Rectangle {
              width: 40
              height: 40
              radius: 20
              color: nextHover.containsMouse ? root.theme.bgHover : "transparent"

              Accessible.role: Accessible.Button
              Accessible.name: "Next track"

              Text {
                anchors.centerIn: parent
                text: "󰒭"
                color: root.theme.textPrimary
                font.pixelSize: 20
                font.family: root.font
              }

              MouseArea {
                id: nextHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: { if (root.activePlayer) root.activePlayer.next(); }
              }
            }
          }

          // Volume slider
          RowLayout {
            Layout.fillWidth: true
            spacing: 10
            visible: root.activePlayer !== null

            Text {
              text: root.activePlayer && root.activePlayer.volume <= 0 ? "󰖁" :
                    root.activePlayer && root.activePlayer.volume < 0.5 ? "󰖀" : "󰕾"
              color: root.theme.textMuted
              font.pixelSize: 16
              font.family: root.font
            }

            Rectangle {
              Layout.fillWidth: true
              height: 4
              radius: 2
              color: root.theme.bgSurface

              Accessible.role: Accessible.ProgressBar
              Accessible.name: "Volume: " + Math.round((root.activePlayer ? root.activePlayer.volume : 0) * 100) + "%"

              Rectangle {
                width: root.activePlayer ? parent.width * Math.min(root.activePlayer.volume, 1.0) : 0
                height: parent.height
                radius: 2
                color: root.theme.accentCyan
              }

              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: mouse => {
                  if (root.activePlayer) {
                    root.activePlayer.volume = Math.max(0, Math.min(1.0, mouse.x / width));
                  }
                }
              }
            }

            Text {
              text: Math.round((root.activePlayer ? root.activePlayer.volume : 0) * 100) + "%"
              color: root.theme.textMuted
              font.pixelSize: 10
              font.family: root.font
            }
          }
        }
      }
    }
  }

  function formatTime(seconds) {
    if (!seconds || seconds < 0) return "0:00";
    const m = Math.floor(seconds / 60);
    const s = Math.floor(seconds % 60);
    return m + ":" + (s < 10 ? "0" : "") + s;
  }
}
