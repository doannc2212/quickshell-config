import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

Scope {
    id: root
    property var theme: Theme
    property string font: "Hack Nerd Font"

    IpcHandler {
        target: "theme"

        function toggle(): void {
            themePanel.visible = !themePanel.visible;
            if (themePanel.visible) {
                searchInput.text = "";
                searchText = "";
                selectedIndex = 0;
                for (var i = 0; i < filteredThemes.length; i++) {
                    if (filteredThemes[i].originalIndex === root.theme.currentIndex) {
                        selectedIndex = i;
                        break;
                    }
                }
                themeList.positionViewAtIndex(selectedIndex, ListView.Center);
                searchInput.forceActiveFocus();
            } else {
                root.theme.previewIndex = -1;
            }
        }
    }

    property int selectedIndex: 0
    property string searchText: ""

    onSelectedIndexChanged: {
        if (themePanel.visible && filteredThemes.length > 0 && selectedIndex >= 0 && selectedIndex < filteredThemes.length) {
            root.theme.previewIndex = filteredThemes[selectedIndex].originalIndex;
        }
    }

    property var filteredThemes: {
        var query = searchText.toLowerCase();
        var result = [];
        for (var i = 0; i < root.theme.themes.length; i++) {
            var t = root.theme.themes[i];
            if (query === "" || t.name.toLowerCase().indexOf(query) >= 0 || t.family.toLowerCase().indexOf(query) >= 0) {
                result.push({ data: t, originalIndex: i, family: t.family });
            }
        }
        return result;
    }

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
            onClicked: {
                root.theme.previewIndex = -1;
                themePanel.visible = false;
            }

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
                    font.family: root.font
                    font.bold: true

                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                // Theme count
                Text {
                    text: root.searchText !== ""
                        ? root.filteredThemes.length + " of " + root.theme.count + " themes"
                        : root.theme.count + " themes — " + root.theme.currentFamily + " " + root.theme.currentName
                    color: root.theme.textMuted
                    font.pixelSize: 11
                    font.family: root.font

                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                // Search field
                Rectangle {
                    Layout.fillWidth: true
                    height: 36
                    radius: 8
                    color: root.theme.bgSurface
                    border.color: searchInput.activeFocus ? root.theme.accentPrimary : root.theme.bgBorder
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8

                        Text {
                            text: ""
                            color: root.theme.textMuted
                            font.pixelSize: 13
                            font.family: root.font
                            Layout.alignment: Qt.AlignVCenter

                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            implicitHeight: searchInput.implicitHeight

                            TextInput {
                                id: searchInput
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                color: root.theme.textPrimary
                                font.pixelSize: 13
                                font.family: root.font
                                clip: true
                                selectByMouse: true

                                onTextChanged: {
                                    root.searchText = text;
                                    root.selectedIndex = 0;
                                }

                                Keys.onEscapePressed: {
                                    root.theme.previewIndex = -1;
                                    themePanel.visible = false;
                                }

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
                                        if (root.filteredThemes.length > 0) {
                                            root.theme.previewIndex = -1;
                                            root.theme.setTheme(root.filteredThemes[root.selectedIndex].originalIndex);
                                            themePanel.visible = false;
                                        }
                                    }
                                }
                            }

                            Text {
                                text: "Search themes..."
                                color: root.theme.textMuted
                                font.pixelSize: 13
                                font.family: root.font
                                anchors.verticalCenter: parent.verticalCenter
                                visible: searchInput.text === ""

                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                        }

                        Text {
                            text: ""
                            color: root.theme.textMuted
                            font.pixelSize: 11
                            font.family: root.font
                            visible: searchInput.text !== ""
                            Layout.alignment: Qt.AlignVCenter

                            Behavior on color { ColorAnimation { duration: 150 } }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    searchInput.text = "";
                                    searchInput.forceActiveFocus();
                                }
                            }
                        }
                    }
                }

                // Theme list
                ListView {
                    id: themeList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: root.filteredThemes
                    clip: true
                    spacing: 2
                    boundsBehavior: Flickable.StopAtBounds
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
                            font.family: root.font
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
                                text: delegateRoot.modelData.data.name
                                color: root.selectedIndex === delegateRoot.index ? root.theme.textPrimary : root.theme.textSecondary
                                font.pixelSize: 13
                                font.family: root.font
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
                                        delegateRoot.modelData.data.bgBase,
                                        delegateRoot.modelData.data.accentPrimary,
                                        delegateRoot.modelData.data.accentGreen,
                                        delegateRoot.modelData.data.accentOrange,
                                        delegateRoot.modelData.data.accentRed
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
                                text: ""
                                color: root.theme.accentGreen
                                font.pixelSize: 14
                                font.family: root.font
                                visible: root.theme.currentIndex === delegateRoot.modelData.originalIndex
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
                                root.theme.previewIndex = -1;
                                root.theme.setTheme(delegateRoot.modelData.originalIndex);
                                themePanel.visible = false;
                            }
                            onEntered: root.selectedIndex = delegateRoot.index
                        }
                    }

                    // No results message
                    Text {
                        anchors.centerIn: parent
                        text: "No themes found"
                        color: root.theme.textMuted
                        font.pixelSize: 13
                        font.family: root.font
                        visible: themeList.count === 0 && root.searchText !== ""

                        Behavior on color { ColorAnimation { duration: 150 } }
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
                            Text { id: hintNav; anchors.centerIn: parent; text: "↑↓"; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.font }
                        }
                        Text { text: "navigate"; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.font; anchors.verticalCenter: parent.verticalCenter }
                    }

                    Row {
                        spacing: 4
                        Rectangle {
                            width: hintEnter.width + 8; height: 18; radius: 4; color: root.theme.bgSurface
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Text { id: hintEnter; anchors.centerIn: parent; text: "⏎"; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.font }
                        }
                        Text { text: "select"; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.font; anchors.verticalCenter: parent.verticalCenter }
                    }

                    Row {
                        spacing: 4
                        Rectangle {
                            width: hintEsc.width + 8; height: 18; radius: 4; color: root.theme.bgSurface
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Text { id: hintEsc; anchors.centerIn: parent; text: "esc"; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.font }
                        }
                        Text { text: "close"; color: root.theme.textMuted; font.pixelSize: 10; font.family: root.font; anchors.verticalCenter: parent.verticalCenter }
                    }

                    Item { Layout.fillWidth: true }
                }
            }
        }
    }
}
