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

            visible: NotificationService.notifications.length > 0
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
                    model: ScriptModel {
                        values: NotificationService.notifications
                        objectProp: "seqId"
                    }

                    Rectangle {
                        id: notifCard
                        required property var modelData
                        required property int index

                        Layout.fillWidth: true
                        Layout.preferredHeight: cardContent.implicitHeight + 24
                        radius: 12
                        color: root.theme.bgBase
                        border.color: modelData.urgency === NotificationUrgency.Critical ? root.theme.urgencyCritical :
                                      modelData.urgency === NotificationUrgency.Low     ? root.theme.urgencyLow     : root.theme.bgBorder
                        border.width: 1
                        clip: true

                        Accessible.role: Accessible.StaticText
                        Accessible.name: (modelData.urgency === NotificationUrgency.Critical ? "[Critical] " :
                                         modelData.urgency === NotificationUrgency.Low       ? "[Low] "      : "") +
                                         (modelData.appName || "Notification") + ": " + modelData.summary

                        HoverHandler {
                            id: cardHover
                            onHoveredChanged: notifCard.modelData.hovered = hovered
                        }

                        NumberAnimation on opacity {
                            id: entryAnim
                            from: 0; to: 1
                            duration: 200
                            easing.type: Easing.OutCubic
                            running: false
                        }
                        Component.onCompleted: entryAnim.start()

                        Rectangle {
                            width: 3
                            height: parent.height - 16
                            radius: 2
                            anchors.left: parent.left
                            anchors.leftMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            color: notifCard.modelData.urgency === NotificationUrgency.Critical ? root.theme.urgencyCritical :
                                   notifCard.modelData.urgency === NotificationUrgency.Low      ? root.theme.urgencyLow      : root.theme.urgencyNormal
                        }

                        ColumnLayout {
                            id: cardContent
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 12
                            anchors.topMargin: 12
                            anchors.bottomMargin: 12
                            spacing: 6

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Item {
                                    Layout.preferredWidth: 16
                                    Layout.preferredHeight: 16
                                    Layout.alignment: Qt.AlignVCenter

                                    IconImage {
                                        anchors.centerIn: parent
                                        source: Quickshell.iconPath(notifCard.modelData.appIcon, true)
                                        implicitSize: 16
                                        visible: notifCard.modelData.appIcon !== ""
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        visible: notifCard.modelData.appIcon === ""
                                        text: {
                                            const name = notifCard.modelData.appName.toLowerCase();
                                            if (notifCard.modelData.urgency === NotificationUrgency.Critical) return "󰀦";
                                            if (name.includes("discord"))  return "󰙯";
                                            if (name.includes("firefox"))  return "󰈹";
                                            if (name.includes("chrome"))   return "";
                                            if (name.includes("telegram")) return "";
                                            if (name.includes("spotify"))  return "󰓇";
                                            if (name.includes("terminal") || name.includes("kitty") || name.includes("alacritty")) return "";
                                            return "󰂚";
                                        }
                                        color: notifCard.modelData.urgency === NotificationUrgency.Critical
                                               ? root.theme.urgencyCritical : root.theme.urgencyNormal
                                        font.pixelSize: 14
                                        font.family: "Hack Nerd Font"
                                    }
                                }

                                Text {
                                    text: notifCard.modelData.appName || "Notification"
                                    color: root.theme.textMuted
                                    font.pixelSize: 11
                                    font.family: "Hack Nerd Font"
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                Item { Layout.fillWidth: true }

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
                                        onClicked: notifCard.modelData.dismiss()
                                    }
                                }
                            }

                            Text {
                                text: notifCard.modelData.summary
                                color: root.theme.textPrimary
                                font.pixelSize: 13
                                font.family: "Hack Nerd Font"
                                font.bold: true
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                                visible: text !== ""
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                visible: notifCard.modelData.body !== "" || notifCard.modelData.image !== ""

                                Text {
                                    text: notifCard.modelData.body
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
                                    Layout.preferredWidth: 24
                                    Layout.preferredHeight: 24
                                    radius: 4
                                    color: "transparent"
                                    clip: true
                                    visible: notifCard.modelData.image !== ""

                                    Image {
                                        anchors.fill: parent
                                        source: notifCard.modelData.image
                                        fillMode: Image.PreserveAspectCrop
                                        sourceSize.width: 24
                                        sourceSize.height: 24
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6
                                visible: notifCard.modelData.actions.length > 0

                                Repeater {
                                    model: notifCard.modelData.actions

                                    Rectangle {
                                        id: actionBtn
                                        required property var modelData

                                        Layout.preferredHeight: 26
                                        Layout.preferredWidth: actionText.width + 16
                                        radius: 6
                                        color: actionHover.containsMouse ? root.theme.bgBorder : root.theme.bgSurface

                                        Behavior on color {
                                            ColorAnimation { duration: 100 }
                                        }

                                        Accessible.role: Accessible.Button
                                        Accessible.name: actionBtn.modelData.text || ""

                                        Text {
                                            id: actionText
                                            anchors.centerIn: parent
                                            text: actionBtn.modelData.text || ""
                                            color: root.theme.accentPrimary
                                            font.pixelSize: 11
                                            font.family: "Hack Nerd Font"
                                        }

                                        MouseArea {
                                            id: actionHover
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: notifCard.modelData.invokeAction(actionBtn.modelData.identifier)
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 2
                                radius: 1
                                color: root.theme.bgSurface
                                Layout.topMargin: 2
                                visible: notifCard.modelData.urgency !== NotificationUrgency.Critical

                                Rectangle {
                                    id: progressBar
                                    height: parent.height
                                    width: parent.width
                                    radius: 1
                                    color: notifCard.modelData.urgency === NotificationUrgency.Critical
                                           ? root.theme.urgencyCritical : root.theme.urgencyNormal
                                    opacity: 0.6

                                    SequentialAnimation {
                                        running: notifCard.modelData.urgency !== NotificationUrgency.Critical
                                        PauseAnimation { duration: 50 }
                                        NumberAnimation {
                                            target: progressBar
                                            property: "width"
                                            to: 0
                                            duration: notifCard.modelData.expireTimeout > 0
                                                      ? notifCard.modelData.expireTimeout * 1000
                                                      : 5000
                                        }
                                    }
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            anchors.topMargin: 30
                            z: -1
                            onClicked: notifCard.modelData.dismiss()
                            cursorShape: Qt.PointingHandCursor
                        }
                    }
                }
            }
        }
    }
}
