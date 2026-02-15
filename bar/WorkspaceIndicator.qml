import QtQuick
import Quickshell.Hyprland

Row {
  property var theme

  spacing: 4

  Repeater {
    model: Hyprland.workspaces

    Rectangle {
      required property var modelData
      width: modelData.focused ? 32 : 24
      height: 24
      radius: 12
      color: modelData.focused ? theme.accentPrimary : theme.bgSurface

      Text {
        anchors.centerIn: parent
        text: modelData.id
        color: modelData.focused ? theme.bgBase : theme.textPrimary
        font.pixelSize: 11
        font.family: "Hack Nerd Font"
        font.bold: modelData.focused
      }

      MouseArea {
        anchors.fill: parent
        onClicked: modelData.activate()
      }

      Behavior on width {
        NumberAnimation { duration: 150 }
      }
    }
  }
}
