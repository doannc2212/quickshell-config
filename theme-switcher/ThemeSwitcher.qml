import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

Scope {
    id: root
    property var theme: Theme

    IpcHandler {
        target: "theme"

        function toggle(): void {
            themePanel.visible = !themePanel.visible;
            if (themePanel.visible) {
                selectedIndex = root.theme.currentIndex;
                themeList.positionViewAtIndex(selectedIndex, ListView.Center);
                themeList.forceActiveFocus();
            }
        }
    }

    property int selectedIndex: 0

    PanelWindow {
        id: themePanel
        visible: false
        focusable: true
        color: "transparent"

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "quickshell-theme"

        exclusionMode: ExclusionMode.Ignore

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        // Dark overlay backdrop
        MouseArea {
            anchors.fill: parent
            onClicked: themePanel.visible = false

            Rectangle {
                anchors.fill: parent
                color: root.theme.bgOverlay
            }
        }

        // Centered theme switcher box
        Rectangle {
            id: themeBox
            anchors.centerIn: parent
            width: 620
            height: 520
            radius: 16
            color: root.theme.bgBase
            border.color: root.theme.bgBorder
            border.width: 1

            Behavior on color { ColorAnimation { duration: 150 } }
            Behavior on border.color { ColorAnimation { duration: 150 } }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                // Header
                Text {
                    text: "  Theme Switcher"
                    color: root.theme.accentPrimary
                    font.pixelSize: 14
                    font.family: "Hack Nerd Font"
                    font.bold: true

                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                // Theme count
                Text {
                    text: root.theme.count + " themes — " + root.theme.currentFamily + " " + root.theme.currentName
                    color: root.theme.textMuted
                    font.pixelSize: 11
                    font.family: "Hack Nerd Font"

                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                // Theme list
                ListView {
                    id: themeList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: root.theme.themes
                    clip: true
                    spacing: 2
                    boundsBehavior: Flickable.StopAtBounds
                    focus: true
                    currentIndex: root.selectedIndex
                    highlightMoveDuration: 150
                    highlightMoveVelocity: -1

                    highlight: Rectangle {
                        radius: 8
                        color: root.theme.bgSelected

                        Behavior on color { ColorAnimation { duration: 150 } }

                        Rectangle {
                            width: 3
                            height: 24
                            radius: 2
                            color: root.theme.accentPrimary
                            anchors.left: parent.left
                            anchors.leftMargin: 2
                            anchors.verticalCenter: parent.verticalCenter

                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }

                    section.property: "family"
                    section.delegate: Item {
                        required property string section
                        width: themeList.width
                        height: 28

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: section.toUpperCase()
                            color: root.theme.textMuted
                            font.pixelSize: 10
                            font.family: "Hack Nerd Font"
                            font.bold: true
                            font.letterSpacing: 1.5

                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }

                    delegate: Rectangle {
                        id: delegateRoot
                        required property var modelData
                        required property int index

                        width: themeList.width
                        height: 44
                        radius: 8
                        color: hoverArea.containsMouse && root.selectedIndex !== index ? root.theme.bgHover : "transparent"

                        Behavior on color { ColorAnimation { duration: 100 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            spacing: 10

                            // Theme name
                            Text {
                                text: delegateRoot.modelData.name
                                color: root.selectedIndex === delegateRoot.index ? root.theme.textPrimary : root.theme.textSecondary
                                font.pixelSize: 13
                                font.family: "Hack Nerd Font"
                                font.bold: root.selectedIndex === delegateRoot.index
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter

                                Behavior on color { ColorAnimation { duration: 150 } }
                            }

                            // Color swatches
                            Row {
                                spacing: 6
                                Layout.alignment: Qt.AlignVCenter

                                Repeater {
                                    model: [
                                        delegateRoot.modelData.bgBase,
                                        delegateRoot.modelData.accentPrimary,
                                        delegateRoot.modelData.accentGreen,
                                        delegateRoot.modelData.accentOrange,
                                        delegateRoot.modelData.accentRed
                                    ]

                                    Rectangle {
                                        required property var modelData
                                        width: 14
                                        height: 14
                                        radius: 7
                                        color: modelData
                                        border.color: root.theme.bgBorder
                                        border.width: 1
                                    }
                                }
                            }

                            // Checkmark for active theme
                            Text {
                                text: root.theme.currentIndex === delegateRoot.index ? "" : ""
                                color: root.theme.accentGreen
                                font.pixelSize: 14
                                font.family: "Hack Nerd Font"
                                visible: root.theme.currentIndex === delegateRoot.index
                                Layout.alignment: Qt.AlignVCenter

                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                        }

                        MouseArea {
                            id: hoverArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.theme.setTheme(delegateRoot.index);
                                themePanel.visible = false;
                            }
                            onEntered: root.selectedIndex = delegateRoot.index
                        }
                    }

                    Keys.onEscapePressed: themePanel.visible = false

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Down) {
                            event.accepted = true;
                            root.selectedIndex = Math.min(root.selectedIndex + 1, themeList.count - 1);
                            themeList.positionViewAtIndex(root.selectedIndex, ListView.Contain);
                        } else if (event.key === Qt.Key_Up) {
                            event.accepted = true;
                            root.selectedIndex = Math.max(root.selectedIndex - 1, 0);
                            themeList.positionViewAtIndex(root.selectedIndex, ListView.Contain);
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            event.accepted = true;
                            root.theme.setTheme(root.selectedIndex);
                            themePanel.visible = false;
                        }
                    }
                }

                // Footer hints
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16

                    Row {
                        spacing: 4
                        Rectangle {
                            width: hintNav.width + 8; height: 18; radius: 4; color: root.theme.bgSurface
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Text { id: hintNav; anchors.centerIn: parent; text: "↑↓"; color: root.theme.textMuted; font.pixelSize: 10; font.family: "Hack Nerd Font" }
                        }
                        Text { text: "navigate"; color: root.theme.textMuted; font.pixelSize: 10; font.family: "Hack Nerd Font"; anchors.verticalCenter: parent.verticalCenter }
                    }

                    Row {
                        spacing: 4
                        Rectangle {
                            width: hintEnter.width + 8; height: 18; radius: 4; color: root.theme.bgSurface
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Text { id: hintEnter; anchors.centerIn: parent; text: "⏎"; color: root.theme.textMuted; font.pixelSize: 10; font.family: "Hack Nerd Font" }
                        }
                        Text { text: "select"; color: root.theme.textMuted; font.pixelSize: 10; font.family: "Hack Nerd Font"; anchors.verticalCenter: parent.verticalCenter }
                    }

                    Row {
                        spacing: 4
                        Rectangle {
                            width: hintEsc.width + 8; height: 18; radius: 4; color: root.theme.bgSurface
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Text { id: hintEsc; anchors.centerIn: parent; text: "esc"; color: root.theme.textMuted; font.pixelSize: 10; font.family: "Hack Nerd Font" }
                        }
                        Text { text: "close"; color: root.theme.textMuted; font.pixelSize: 10; font.family: "Hack Nerd Font"; anchors.verticalCenter: parent.verticalCenter }
                    }

                    Item { Layout.fillWidth: true }
                }
            }
        }
    }
}
