import QtQuick

Row {
  property var theme

  readonly property color batteryColor: {
    if (SystemInfo.batteryLevelRaw > 20) return theme.batteryGood;
    if (SystemInfo.batteryLevelRaw > 10) return theme.batteryWarning;
    return theme.batteryCritical;
  }

  spacing: 4

  // CPU
  Rectangle {
    height: 24
    width: cpuContent.width + 12
    radius: 12
    color: theme.bgSurface

    Row {
      id: cpuContent
      anchors.centerIn: parent
      spacing: 6

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "󰻠"
        color: theme.accentOrange
        font.pixelSize: 14
        font.family: "Hack Nerd Font"
      }
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: SystemInfo.cpuUsage
        color: theme.textPrimary
        font.pixelSize: 11
        font.family: "Hack Nerd Font"
      }
    }
  }

  // Memory
  Rectangle {
    height: 24
    width: memContent.width + 12
    radius: 12
    color: theme.bgSurface

    Row {
      id: memContent
      anchors.centerIn: parent
      spacing: 6

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "󰍛"
        color: theme.accentCyan
        font.pixelSize: 14
        font.family: "Hack Nerd Font"
      }
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: SystemInfo.memoryUsage
        color: theme.textPrimary
        font.pixelSize: 11
        font.family: "Hack Nerd Font"
      }
    }
  }

  // Network
  Rectangle {
    height: 24
    width: netContent.width + 12
    radius: 12
    color: theme.bgSurface

    Row {
      id: netContent
      anchors.centerIn: parent
      spacing: 6

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "󰛳"
        color: theme.accentGreen
        font.pixelSize: 14
        font.family: "Hack Nerd Font"
      }
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: SystemInfo.networkInfo
        color: theme.textPrimary
        font.pixelSize: 11
        font.family: "Hack Nerd Font"
      }
    }
  }

  // Battery
  Rectangle {
    height: 24
    width: battContent.width + 12
    radius: 12
    color: theme.bgSurface

    Row {
      id: battContent
      anchors.centerIn: parent
      spacing: 6

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: SystemInfo.batteryIcon
        color: batteryColor
        font.pixelSize: 14
        font.family: "Hack Nerd Font"
      }
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: SystemInfo.batteryLevel
        color: theme.textPrimary
        font.pixelSize: 11
        font.family: "Hack Nerd Font"
      }
    }
  }

  // Temperature
  Rectangle {
    height: 24
    width: tempContent.width + 12
    radius: 12
    color: theme.bgSurface

    Row {
      id: tempContent
      anchors.centerIn: parent
      spacing: 6

      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "󰔏"
        color: theme.accentRed
        font.pixelSize: 14
        font.family: "Hack Nerd Font"
      }
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: SystemInfo.temperature
        color: theme.textPrimary
        font.pixelSize: 11
        font.family: "Hack Nerd Font"
      }
    }
  }
}
