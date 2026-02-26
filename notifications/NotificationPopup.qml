import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts

Scope {
  id: root
  property var theme: DefaultTheme {}

  IpcHandler {
    target: "notifications"

    function dismiss_all(): void {
      NotificationService.dismissAll();
    }

    function dnd_toggle(): void {
      NotificationService.doNotDisturb = !NotificationService.doNotDisturb;
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: notifWindow
      required property var modelData
      screen: modelData

      visible: notifColumn.children.length > 0
      focusable: false
      color: "transparent"

      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
      WlrLayershell.namespace: "quickshell-notifications"

      exclusionMode: ExclusionMode.Ignore

      anchors {
        top: true
        right: true
      }

      implicitWidth: 380
      implicitHeight: notifColumn.implicitHeight + 20

      ColumnLayout {
        id: notifColumn
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 10
        anchors.rightMargin: 10
        width: 360
        spacing: 8

        Repeater {
          model: NotificationService.notifications

          Rectangle {
            id: notifCard
            required property Notification modelData
            required property int index

            // Null-safe computed properties — modelData can be null during delegate destruction
            readonly property int notifUrgency: modelData ? modelData.urgency : NotificationUrgency.Normal
            readonly property string notifAppIcon: modelData ? (modelData.appIcon || "") : ""
            readonly property string notifAppName: modelData ? (modelData.appName || "") : ""
            readonly property string notifSummary: modelData ? (modelData.summary || "") : ""
            readonly property string notifBody: modelData ? (modelData.body || "") : ""
            readonly property string notifImage: modelData ? (modelData.image || "") : ""
            readonly property var notifActions: modelData ? modelData.actions : []
            readonly property int notifExpireTimeout: modelData ? modelData.expireTimeout : 0

            Accessible.role: Accessible.StaticText
            Accessible.name: (notifUrgency === NotificationUrgency.Critical ? "[Critical] " :
                             notifUrgency === NotificationUrgency.Low ? "[Low] " : "") +
                             (notifAppName || "Notification") + ": " + (notifSummary || "")

            Layout.fillWidth: true
            Layout.preferredHeight: cardContent.implicitHeight + 24
            radius: 12
            color: root.theme.bgBase
            border.color: notifUrgency === NotificationUrgency.Critical ? root.theme.urgencyCritical :
                          notifUrgency === NotificationUrgency.Low ? root.theme.urgencyLow : root.theme.bgBorder
            border.width: 1
            opacity: 1
            clip: true

            // Entry animation
            Component.onCompleted: {
              entryAnim.start();
            }

            NumberAnimation on opacity {
              id: entryAnim
              from: 0; to: 1
              duration: 200
              easing.type: Easing.OutCubic
              running: false
            }

            // Urgency accent bar
            Rectangle {
              width: 3
              height: parent.height - 16
              radius: 2
              anchors.left: parent.left
              anchors.leftMargin: 6
              anchors.verticalCenter: parent.verticalCenter
              color: notifCard.notifUrgency === NotificationUrgency.Critical ? root.theme.urgencyCritical :
                     notifCard.notifUrgency === NotificationUrgency.Low ? root.theme.urgencyLow : root.theme.urgencyNormal
            }

            ColumnLayout {
              id: cardContent
              anchors.fill: parent
              anchors.leftMargin: 16
              anchors.rightMargin: 12
              anchors.topMargin: 12
              anchors.bottomMargin: 12
              spacing: 6

              // Header: app name + close button
              RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // App icon
                Item {
                  Layout.preferredWidth: 16
                  Layout.preferredHeight: 16
                  Layout.alignment: Qt.AlignVCenter

                  IconImage {
                    anchors.centerIn: parent
                    source: Quickshell.iconPath(notifCard.notifAppIcon, true)
                    implicitSize: 16
                    visible: notifCard.notifAppIcon !== ""
                  }

                  Text {
                    anchors.centerIn: parent
                    visible: notifCard.notifAppIcon === ""
                    text: {
                      if (notifCard.notifUrgency === NotificationUrgency.Critical) return "󰀦";
                      if (notifCard.notifAppName.toLowerCase().includes("discord")) return "󰙯";
                      if (notifCard.notifAppName.toLowerCase().includes("firefox")) return "󰈹";
                      if (notifCard.notifAppName.toLowerCase().includes("chrome")) return "";
                      if (notifCard.notifAppName.toLowerCase().includes("telegram")) return "";
                      if (notifCard.notifAppName.toLowerCase().includes("spotify")) return "󰓇";
                      if (notifCard.notifAppName.toLowerCase().includes("terminal") ||
                          notifCard.notifAppName.toLowerCase().includes("kitty") ||
                          notifCard.notifAppName.toLowerCase().includes("alacritty")) return "";
                      return "󰂚";
                    }
                    color: notifCard.notifUrgency === NotificationUrgency.Critical ? root.theme.urgencyCritical : root.theme.urgencyNormal
                    font.pixelSize: 14
                    font.family: "Hack Nerd Font"
                  }
                }

                Text {
                  text: notifCard.notifAppName || "Notification"
                  color: root.theme.textMuted
                  font.pixelSize: 11
                  font.family: "Hack Nerd Font"
                  Layout.alignment: Qt.AlignVCenter
                }

                Item { Layout.fillWidth: true }

                // Close button
                Rectangle {
                  width: 20
                  height: 20
                  radius: 10
                  color: closeHover.containsMouse ? root.theme.bgBorder : "transparent"
                  Layout.alignment: Qt.AlignVCenter
                  Accessible.role: Accessible.Button
                  Accessible.name: "Dismiss notification"

                  Text {
                    anchors.centerIn: parent
                    text: "󰅖"
                    color: closeHover.containsMouse ? root.theme.accentRed : root.theme.textMuted
                    font.pixelSize: 12
                    font.family: "Hack Nerd Font"
                  }

                  MouseArea {
                    id: closeHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (notifCard.modelData) NotificationService.dismiss(notifCard.modelData)
                  }
                }
              }

              // Summary (title)
              Text {
                text: notifCard.notifSummary || ""
                color: root.theme.textPrimary
                font.pixelSize: 13
                font.family: "Hack Nerd Font"
                font.bold: true
                elide: Text.ElideRight
                Layout.fillWidth: true
                visible: text !== ""
              }

              // Body + image thumbnail
              RowLayout {
                Layout.fillWidth: true
                spacing: 8
                visible: notifCard.notifBody !== "" || notifCard.notifImage !== ""

                Text {
                  text: notifCard.notifBody || ""
                  color: root.theme.textSecondary
                  font.pixelSize: 12
                  font.family: "Hack Nerd Font"
                  wrapMode: Text.Wrap
                  maximumLineCount: 3
                  elide: Text.ElideRight
                  Layout.fillWidth: true
                  visible: text !== ""
                  textFormat: Text.PlainText
                }

                Rectangle {
                  Layout.preferredWidth: 48
                  Layout.preferredHeight: 48
                  radius: 6
                  color: "transparent"
                  clip: true
                  visible: notifCard.notifImage !== ""

                  Image {
                    anchors.fill: parent
                    source: notifCard.notifImage
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: 48
                    sourceSize.height: 48
                  }
                }
              }

              // Action buttons
              RowLayout {
                Layout.fillWidth: true
                spacing: 6
                visible: notifCard.notifActions.length > 0

                Repeater {
                  model: notifCard.notifActions

                  Rectangle {
                    id: actionBtn
                    required property NotificationAction modelData

                    readonly property string actionLabel: modelData ? (modelData.text || "") : ""

                    Accessible.role: Accessible.Button
                    Accessible.name: actionLabel

                    Layout.preferredHeight: 26
                    Layout.preferredWidth: actionText.width + 16
                    radius: 6
                    color: actionHover.containsMouse ? root.theme.bgBorder : root.theme.bgSurface

                    Behavior on color {
                      ColorAnimation { duration: 100 }
                    }

                    Text {
                      id: actionText
                      anchors.centerIn: parent
                      text: actionBtn.actionLabel
                      color: root.theme.accentPrimary
                      font.pixelSize: 11
                      font.family: "Hack Nerd Font"
                    }

                    MouseArea {
                      id: actionHover
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor
                      onClicked: if (notifCard.modelData && actionBtn.modelData) NotificationService.invokeAction(notifCard.modelData, actionBtn.modelData)
                    }
                  }
                }
              }

              // Auto-close timer (decoupled from animation for reliability)
              Timer {
                id: autoCloseTimer
                interval: {
                  if (notifCard.notifUrgency === NotificationUrgency.Critical) return 0;
                  if (notifCard.notifExpireTimeout > 0) return notifCard.notifExpireTimeout * 1000;
                  return 5000;
                }
                running: notifCard.notifUrgency !== NotificationUrgency.Critical && interval > 0
                repeat: false
                onTriggered: if (notifCard.modelData) NotificationService.expire(notifCard.modelData)
              }

              // Progress bar (visual only)
              Rectangle {
                Layout.fillWidth: true
                height: 2
                radius: 1
                color: root.theme.bgSurface
                Layout.topMargin: 2
                visible: notifCard.notifUrgency !== NotificationUrgency.Critical

                Rectangle {
                  id: progressBar
                  height: parent.height
                  width: parent.width
                  radius: 1
                  color: notifCard.notifUrgency === NotificationUrgency.Critical ? root.theme.urgencyCritical : root.theme.urgencyNormal
                  opacity: 0.6

                  SequentialAnimation {
                    running: notifCard.notifUrgency !== NotificationUrgency.Critical
                    PauseAnimation { duration: 50 }
                    NumberAnimation {
                      target: progressBar
                      property: "width"
                      to: 0
                      duration: autoCloseTimer.interval > 0 ? autoCloseTimer.interval : 5000
                    }
                  }
                }
              }
            }

            // Click body to dismiss
            MouseArea {
              anchors.fill: parent
              anchors.topMargin: 30
              z: -1
              onClicked: if (notifCard.modelData) NotificationService.dismiss(notifCard.modelData)
              cursorShape: Qt.PointingHandCursor
            }
          }
        }
      }
    }
  }
}
