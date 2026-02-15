import Quickshell
import QtQuick
import QtQuick.Layouts

Scope {
  id: root
  property var theme: DefaultTheme {}

  Variants {
    model: Quickshell.screens

    PanelWindow {
      required property var modelData
      screen: modelData

      anchors {
        top: true
        left: true
        right: true
      }

      implicitHeight: 32
      color: root.theme.bgBase

      RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 8

        TimeWidget { theme: root.theme }
        WorkspaceIndicator { theme: root.theme }

        Item {
          Layout.fillWidth: true
        }

        SystemInfoWidget { theme: root.theme }
        SystemTrayWidget { theme: root.theme }
      }

      // Center window title independently
      WindowTitle {
        theme: root.theme
        anchors.centerIn: parent
      }
    }
  }
}
