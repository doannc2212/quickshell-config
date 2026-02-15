import QtQuick

Rectangle {
  property var theme

  height: 24
  width: timeDate.width + 16
  radius: 12
  color: theme.bgSurface

  Row {
    id: timeDate
    anchors.centerIn: parent
    spacing: 8

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: ""
      color: theme.accentPrimary
      font.pixelSize: 14
      font.family: "Hack Nerd Font"
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: Time.timeString
      color: theme.textPrimary
      font.pixelSize: 12
      font.family: "Hack Nerd Font"
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: Time.dateString
      color: theme.textSecondary
      font.pixelSize: 12
      font.family: "Hack Nerd Font"
    }
  }
}
