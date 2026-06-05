import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
  id: panel

  // Not required — intentionally null when no monitor is selected
  property var monitor:     null
  property var allMonitors: []
  required property var theme

  signal modeSelected(string mode)
  signal scaleSelected(real scale)      // not scaleChanged — conflicts with Item.scale built-in
  signal transformChanged(int transform)
  signal enableToggled(bool enabled)    // not enabledChanged — conflicts with Item.enabled built-in
  signal mirrorChanged(string mirrorOf)

  property bool modePickerOpen:   false
  property bool mirrorPickerOpen: false

  // Close open pickers when the selected monitor changes
  onMonitorChanged: {
    modePickerOpen   = false;
    mirrorPickerOpen = false;
    modeDropdown.close();
    mirrorDropdown.close();
  }

  // ── Mode dropdown overlay ────────────────────────────────────────────────
  Popup {
    id: modeDropdown
    parent: modePill
    x: 0
    y: modePill.height + 4
    width: modePill.width
    padding: 1  // background border is drawn inward, so contentItem overlaps it without this
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

    onOpened: panel.modePickerOpen   = true
    onClosed: panel.modePickerOpen   = false

    background: Rectangle {
      radius: 8
      color: panel.theme.bgSurface
      border.color: panel.theme.accentPrimary
      border.width: 1
    }

    contentItem: ListView {
      id: modeList
      implicitHeight: Math.min(contentHeight + 2, 180)
      model: panel.monitor?.availableModes ?? []
      boundsBehavior: Flickable.StopAtBounds
      clip: true

      delegate: Rectangle {
        required property string modelData
        width: modeList.width
        height: 28
        radius: 4
        color: modelData === (panel.monitor?.selectedMode ?? "") ? panel.theme.accentPrimary : "transparent"

        Row {
          anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
          spacing: 0

          Text {
            text: modelData.split("@")[0]
            color: modelData === (panel.monitor?.selectedMode ?? "") ? panel.theme.bgBase : panel.theme.textPrimary
            font { pixelSize: 11; family: "Hack Nerd Font" }
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - rateText.width
          }
          Text {
            id: rateText
            text: "@" + (modelData.split("@")[1] ?? "")
            color: modelData === (panel.monitor?.selectedMode ?? "") ? panel.theme.bgBase : panel.theme.textMuted
            font { pixelSize: 11; family: "Hack Nerd Font" }
            anchors.verticalCenter: parent.verticalCenter
          }
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            panel.modeSelected(modelData);
            modeDropdown.close();
          }
        }
      }
    }
  }

  // ── Mirror dropdown overlay ──────────────────────────────────────────────
  Popup {
    id: mirrorDropdown
    parent: mirrorPill
    x: 0
    y: mirrorPill.height + 4
    width: mirrorPill.width
    padding: 1  // background border is drawn inward, so contentItem overlaps it without this
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

    onOpened: panel.mirrorPickerOpen = true
    onClosed: panel.mirrorPickerOpen = false

    background: Rectangle {
      radius: 8
      color: panel.theme.bgSurface
      border.color: panel.theme.accentPrimary
      border.width: 1
    }

    contentItem: ListView {
      id: mirrorList
      implicitHeight: Math.min(contentHeight + 2, 150)
      model: {
        if (panel.monitor === null) return [];
        const opts = [""];
        for (const m of panel.allMonitors) {
          if (m.name !== panel.monitor.name) opts.push(m.name);
        }
        return opts;
      }
      boundsBehavior: Flickable.StopAtBounds
      clip: true

      delegate: Rectangle {
        required property string modelData
        width: mirrorList.width
        height: 28
        radius: 4
        color: modelData === (panel.monitor?.mirrorOf ?? "") ? panel.theme.accentPrimary : "transparent"

        Text {
          anchors { fill: parent; leftMargin: 10 }
          text: modelData === "" ? "None" : modelData
          color: modelData === (panel.monitor?.mirrorOf ?? "")
                 ? panel.theme.bgBase
                 : (modelData === "" ? panel.theme.textMuted : panel.theme.textPrimary)
          font { pixelSize: 11; family: "Hack Nerd Font" }
          verticalAlignment: Text.AlignVCenter
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            panel.mirrorChanged(modelData);
            mirrorDropdown.close();
          }
        }
      }
    }
  }

  // All children use optional chaining (monitor?.X) so bindings are safe when monitor is null
  ScrollView {
    anchors.fill: parent
    clip: true
    contentWidth: availableWidth
    // ScrollView is visible but content guards itself against null monitor
    visible: panel.monitor !== null

    ColumnLayout {
      width: panel.width
      spacing: 12

      // Monitor identity
      Text {
        Layout.fillWidth: true
        text: panel.monitor?.name ?? ""
        color: panel.theme.textPrimary
        font { pixelSize: 14; bold: true; family: "Hack Nerd Font" }
      }
      Text {
        Layout.fillWidth: true
        text: panel.monitor?.description ?? ""
        color: panel.theme.textMuted
        font { pixelSize: 11; family: "Hack Nerd Font" }
        elide: Text.ElideRight
      }

      // Divider
      Divider { color: panel.theme.bgBorder }

      // Resolution section
      Text {
        text: "Resolution"
        color: panel.theme.textSecondary
        font { pixelSize: 11; family: "Hack Nerd Font" }
      }

      // Collapsed mode pill
      Rectangle {
        id: modePill
        Layout.fillWidth: true
        height: 32
        radius: 8
        color: panel.theme.bgSurface
        border.color: panel.modePickerOpen ? panel.theme.accentPrimary : panel.theme.bgBorder
        border.width: 1

        Row {
          anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
          spacing: 0

          Text {
            text: (panel.monitor?.selectedMode ?? "").replace("Hz", "")
            color: panel.theme.textPrimary
            font { pixelSize: 12; family: "Hack Nerd Font" }
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 20
            elide: Text.ElideRight
          }
          Text {
            text: panel.modePickerOpen ? "▴" : "▾"
            color: panel.theme.textMuted
            font { pixelSize: 16; family: "Hack Nerd Font" }
            anchors.verticalCenter: parent.verticalCenter
          }
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            if (panel.modePickerOpen) {
              modeDropdown.close();
            } else {
              mirrorDropdown.close();
              modeDropdown.open();
            }
          }
        }
      }

      // Divider
      Divider { color: panel.theme.bgBorder }

      // Scale section
      Text {
        text: "Scale"
        color: panel.theme.textSecondary
        font { pixelSize: 11; family: "Hack Nerd Font" }
      }

      Flow {
        Layout.fillWidth: true
        spacing: 4

        Repeater {
          model: [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 2.5, 3.0]
          Rectangle {
            required property real modelData
            width: 38; height: 26; radius: 6
            color: Math.abs((panel.monitor?.scale ?? -1) - modelData) < 0.01 ? panel.theme.accentPrimary : panel.theme.bgSurface
            border.color: panel.theme.bgBorder
            border.width: 1

            Text {
              anchors.centerIn: parent
              text: modelData + "×"
              color: Math.abs((panel.monitor?.scale ?? -1) - modelData) < 0.01 ? panel.theme.bgBase : panel.theme.textPrimary
              font { pixelSize: 10; family: "Hack Nerd Font" }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: panel.scaleSelected(modelData)
            }
          }
        }
      }

      // Divider
      Divider { color: panel.theme.bgBorder }

      // Rotation section
      Text {
        text: "Rotation"
        color: panel.theme.textSecondary
        font { pixelSize: 11; family: "Hack Nerd Font" }
      }

      Row {
        spacing: 4

        Repeater {
          model: [
            { t: 0, label: "0°",   icon: "󰍹" },
            { t: 1, label: "90°",  icon: "󰑧" },
            { t: 2, label: "180°", icon: "󱃨" },
            { t: 3, label: "270°", icon: "󰑥" },
          ]

          Rectangle {
            required property var modelData
            width: 52; height: 26; radius: 6
            color: (panel.monitor?.transform ?? -1) === modelData.t ? panel.theme.accentPrimary : panel.theme.bgSurface
            border.color: panel.theme.bgBorder
            border.width: 1

            Row {
              anchors.centerIn: parent
              spacing: 4
              Text {
                text: modelData.icon
                anchors.verticalCenter: parent.verticalCenter
                color: (panel.monitor?.transform ?? -1) === modelData.t ? panel.theme.bgBase : panel.theme.textMuted
                font { pixelSize: 13; family: "Hack Nerd Font" }
              }
              Text {
                text: modelData.label
                anchors.verticalCenter: parent.verticalCenter
                color: (panel.monitor?.transform ?? -1) === modelData.t ? panel.theme.bgBase : panel.theme.textPrimary
                font { pixelSize: 10; family: "Hack Nerd Font" }
              }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: panel.transformChanged(modelData.t)
            }
          }
        }
      }

      // Divider
      Divider { color: panel.theme.bgBorder }

      // Mirror section
      Text {
        text: "Mirror of"
        color: panel.theme.textSecondary
        font { pixelSize: 11; family: "Hack Nerd Font" }
      }

      // Mirror collapsed pill
      Rectangle {
        id: mirrorPill
        Layout.fillWidth: true
        height: 32
        radius: 8
        color: panel.theme.bgSurface
        border.color: panel.mirrorPickerOpen ? panel.theme.accentPrimary : panel.theme.bgBorder
        border.width: 1

        Row {
          anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
          spacing: 0

          Text {
            text: (panel.monitor?.mirrorOf ?? "") === "" ? "None" : (panel.monitor?.mirrorOf ?? "")
            color: (panel.monitor?.mirrorOf ?? "") === "" ? panel.theme.textMuted : panel.theme.textPrimary
            font { pixelSize: 12; family: "Hack Nerd Font" }
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 20
            elide: Text.ElideRight
          }
          Text {
            text: panel.mirrorPickerOpen ? "▴" : "▾"
            color: panel.theme.textMuted
            font { pixelSize: 16; family: "Hack Nerd Font" }
            anchors.verticalCenter: parent.verticalCenter
          }
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            if (panel.mirrorPickerOpen) {
              mirrorDropdown.close();
            } else {
              modeDropdown.close();
              mirrorDropdown.open();
            }
          }
        }
      }

      // Divider
      Divider { color: panel.theme.bgBorder }

      // Enable / Disable toggle
      Rectangle {
        Layout.fillWidth: true
        height: 32
        radius: 8
        color: (panel.monitor?.disabled ?? true) ? panel.theme.bgSurface : panel.theme.accentGreen
        border.color: panel.theme.bgBorder
        border.width: 1

        Row {
          anchors.centerIn: parent
          spacing: 8
          Text {
            text: (panel.monitor?.disabled ?? true) ? "" : ""
            anchors.verticalCenter: parent.verticalCenter
            color: (panel.monitor?.disabled ?? true) ? panel.theme.textMuted : panel.theme.bgBase
            font { pixelSize: 14; family: "Hack Nerd Font" }
          }
          Text {
            text: (panel.monitor?.disabled ?? true) ? "Disabled" : "Enabled"
            anchors.verticalCenter: parent.verticalCenter
            color: (panel.monitor?.disabled ?? true) ? panel.theme.textMuted : panel.theme.bgBase
            font { pixelSize: 12; bold: true; family: "Hack Nerd Font" }
          }
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            if (panel.monitor !== null) panel.enableToggled(panel.monitor.disabled);
          }
        }
      }

      // Bottom spacer
      Item { height: 8 }
    }
  }
}
