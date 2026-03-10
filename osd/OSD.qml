import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts

Scope {
  id: root
  property var theme: DefaultTheme {}

  property bool showVolume: false
  property bool showBrightness: false
  property real volumeValue: 0
  property bool volumeMuted: false
  property real brightnessValue: 0
  property real maxBrightness: 1
  property bool _brightnessReady: false

  // PipeWire tracking
  PwObjectTracker {
    objects: [Pipewire.defaultAudioSink]
  }

  Connections {
    target: Pipewire.defaultAudioSink?.audio ?? null

    function onVolumeChanged() {
      root.volumeValue = Pipewire.defaultAudioSink.audio.volume;
      root.showVolume = true;
      volumeHideTimer.restart();
    }

    function onMutedChanged() {
      root.volumeMuted = Pipewire.defaultAudioSink.audio.muted;
      root.showVolume = true;
      volumeHideTimer.restart();
    }
  }

  Timer {
    id: volumeHideTimer
    interval: 1500
    onTriggered: root.showVolume = false
  }

  // Brightness monitoring
  FileView {
    id: brightnessFile
    path: ""
    watchChanges: true
    onFileChanged: brightnessReadProc.running = true
  }

  Process {
    id: brightnessReadProc
    command: ["brightnessctl", "get"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        const val = parseInt(text.trim());
        if (!isNaN(val) && root.maxBrightness > 0) {
          root.brightnessValue = val / root.maxBrightness;
          if (root._brightnessReady) {
            root.showBrightness = true;
            brightnessHideTimer.restart();
          }
          root._brightnessReady = true;
        }
      }
    }
  }

  Process {
    id: backlightDiscovery
    command: ["sh", "-c", "p=$(ls -d /sys/class/backlight/*/brightness 2>/dev/null | head -1); [ -n \"$p\" ] && echo \"$p\" && cat \"${p%brightness}max_brightness\""]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        const lines = text.trim().split("\n");
        if (lines.length >= 2) {
          const max = parseInt(lines[1]);
          if (!isNaN(max) && max > 0) root.maxBrightness = max;
          brightnessFile.path = lines[0];
          brightnessReadProc.running = true;
        }
      }
    }
  }

  Timer {
    id: brightnessHideTimer
    interval: 1500
    onTriggered: root.showBrightness = false
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      required property var modelData
      screen: modelData

      visible: root.showVolume || root.showBrightness
      focusable: false
      color: "transparent"

      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
      WlrLayershell.namespace: "quickshell-osd"

      exclusionMode: ExclusionMode.Ignore
      mask: Region {}

      anchors {
        right: true
        top: true
        bottom: true
      }

      implicitWidth: 70

      Column {
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 12

        // Volume pill — vertical
        Rectangle {
          id: volumePill
          width: 36
          height: 200
          radius: 25
          color: root.theme.bgBase
          border.color: root.theme.bgBorder
          border.width: 1
          opacity: root.showVolume ? 1 : 0

          Behavior on opacity { NumberAnimation { duration: 150 } }

          Accessible.role: Accessible.ProgressBar
          Accessible.name: root.volumeMuted ? "Volume: muted" : "Volume: " + Math.round(root.volumeValue * 100) + "%"

          ColumnLayout {
            anchors.fill: parent
            anchors.topMargin: 12
            anchors.bottomMargin: 12
            anchors.leftMargin: 0
            anchors.rightMargin: 0
            spacing: 8

            Text {
              text: root.volumeMuted ? "Mute" : Math.round(root.volumeValue * 100) + "%"
              color: root.theme.textSecondary
              font.pixelSize: 10
              font.family: "Hack Nerd Font"
              Layout.alignment: Qt.AlignHCenter
            }

            Rectangle {
              Layout.fillHeight: true
              Layout.alignment: Qt.AlignHCenter
              width: 8
              radius: 4
              color: root.theme.bgSurface
              border.color: root.theme.bgBorder
              border.width: 1
              clip: true

              Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 2
                height: Math.max(0, (parent.height - 4) * Math.max(0, Math.min(1, root.volumeMuted ? 0 : root.volumeValue)))
                radius: 3
                color: root.volumeMuted ? root.theme.textMuted : root.theme.accentPrimary

                Behavior on height { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
              }
            }

            Text {
              text: {
                if (root.volumeMuted || root.volumeValue <= 0) return "󰖁";
                if (root.volumeValue < 0.33) return "󰕿";
                if (root.volumeValue < 0.66) return "󰖀";
                return "󰕾";
              }
              color: root.volumeMuted ? root.theme.textMuted : root.theme.accentPrimary
              font.pixelSize: 15
              font.family: "Hack Nerd Font"
              Layout.alignment: Qt.AlignHCenter
            }
          }
        }

        // Brightness pill — vertical
        Rectangle {
          id: brightnessPill
          width: 36
          height: 200
          radius: 25
          color: root.theme.bgBase
          border.color: root.theme.bgBorder
          border.width: 1
          opacity: root.showBrightness ? 1 : 0

          Behavior on opacity { NumberAnimation { duration: 150 } }

          Accessible.role: Accessible.ProgressBar
          Accessible.name: "Brightness: " + Math.round(root.brightnessValue * 100) + "%"

          ColumnLayout {
            anchors.fill: parent
            anchors.topMargin: 12
            anchors.bottomMargin: 12
            anchors.leftMargin: 0
            anchors.rightMargin: 0
            spacing: 8

            Text {
              text: Math.round(root.brightnessValue * 100) + "%"
              color: root.theme.textSecondary
              font.pixelSize: 10
              font.family: "Hack Nerd Font"
              Layout.alignment: Qt.AlignHCenter
            }

            Rectangle {
              Layout.fillHeight: true
              Layout.alignment: Qt.AlignHCenter
              width: 8
              radius: 4
              color: root.theme.bgSurface
              border.color: root.theme.bgBorder
              border.width: 1
              clip: true

              Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 2
                height: Math.max(0, (parent.height - 4) * Math.max(0, Math.min(1, root.brightnessValue)))
                radius: 3
                color: root.theme.accentOrange

                Behavior on height { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
              }
            }

            Text {
              text: "󰃠"
              color: root.theme.accentOrange
              font.pixelSize: 15
              font.family: "Hack Nerd Font"
              Layout.alignment: Qt.AlignHCenter
            }
          }
        }
      }
    }
  }
}
