import Quickshell
import Quickshell.Wayland
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

            Layout.fillWidth: true
            Layout.preferredHeight: cardContent.implicitHeight + 24
            radius: 12
            color: root.theme.bgBase
            border.color: modelData.urgency === NotificationUrgency.Critical ? root.theme.urgencyCritical :
                          modelData.urgency === NotificationUrgency.Low ? root.theme.urgencyLow : root.theme.bgBorder
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
              color: modelData.urgency === NotificationUrgency.Critical ? root.theme.urgencyCritical :
                     modelData.urgency === NotificationUrgency.Low ? root.theme.urgencyLow : root.theme.urgencyNormal
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
                Text {
                  text: {
                    if (modelData.urgency === NotificationUrgency.Critical) return "󰀦";
                    if (modelData.appName.toLowerCase().includes("discord")) return "󰙯";
                    if (modelData.appName.toLowerCase().includes("firefox")) return "󰈹";
                    if (modelData.appName.toLowerCase().includes("chrome")) return "";
                    if (modelData.appName.toLowerCase().includes("telegram")) return "";
                    if (modelData.appName.toLowerCase().includes("spotify")) return "󰓇";
                    if (modelData.appName.toLowerCase().includes("terminal") ||
                        modelData.appName.toLowerCase().includes("kitty") ||
                        modelData.appName.toLowerCase().includes("alacritty")) return "";
                    return "󰂚";
                  }
                  color: modelData.urgency === NotificationUrgency.Critical ? root.theme.urgencyCritical : root.theme.urgencyNormal
                  font.pixelSize: 14
                  font.family: "Hack Nerd Font"
                  Layout.alignment: Qt.AlignVCenter
                }

                Text {
                  text: modelData.appName || "Notification"
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
                    onClicked: NotificationService.dismiss(notifCard.modelData)
                  }
                }
              }

              // Summary (title)
              Text {
                text: modelData.summary || ""
                color: root.theme.textPrimary
                font.pixelSize: 13
                font.family: "Hack Nerd Font"
                font.bold: true
                elide: Text.ElideRight
                Layout.fillWidth: true
                visible: text !== ""
              }

              // Body
              Text {
                text: modelData.body || ""
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

              // Action buttons
              RowLayout {
                Layout.fillWidth: true
                spacing: 6
                visible: modelData.actions.length > 0

                Repeater {
                  model: notifCard.modelData.actions

                  Rectangle {
                    id: actionBtn
                    required property NotificationAction modelData

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
                      text: actionBtn.modelData.text
                      color: root.theme.accentPrimary
                      font.pixelSize: 11
                      font.family: "Hack Nerd Font"
                    }

                    MouseArea {
                      id: actionHover
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor
                      onClicked: NotificationService.invokeAction(notifCard.modelData, actionBtn.modelData)
                    }
                  }
                }
              }

              // Progress bar (expire timer)
              Rectangle {
                Layout.fillWidth: true
                height: 2
                radius: 1
                color: root.theme.bgSurface
                Layout.topMargin: 2

                Rectangle {
                  id: progressBar
                  height: parent.height
                  radius: 1
                  color: modelData.urgency === NotificationUrgency.Critical ? root.theme.urgencyCritical : root.theme.urgencyNormal
                  opacity: 0.6

                  NumberAnimation on width {
                    from: progressBar.parent.width
                    to: 0
                    duration: {
                      if (notifCard.modelData.urgency === NotificationUrgency.Critical) return 0;
                      if (notifCard.modelData.expireTimeout > 0) return notifCard.modelData.expireTimeout * 1000;
                      return 5000;
                    }
                    running: notifCard.modelData.urgency !== NotificationUrgency.Critical
                    onFinished: NotificationService.expire(notifCard.modelData)
                  }
                }
              }
            }

            // Click body to dismiss
            MouseArea {
              anchors.fill: parent
              anchors.topMargin: 30
              z: -1
              onClicked: NotificationService.dismiss(notifCard.modelData)
              cursorShape: Qt.PointingHandCursor
            }
          }
        }
      }
    }
  }
}
