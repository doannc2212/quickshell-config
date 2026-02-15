import QtQuick

QtObject {
  readonly property color bgBase: "#1a1b26"
  readonly property color bgSurface: "#24283b"
  readonly property color bgOverlay: "#88000000"
  readonly property color bgHover: "#1e2235"
  readonly property color bgSelected: "#283457"
  readonly property color bgBorder: "#32364a"

  readonly property color textPrimary: "#c0caf5"
  readonly property color textSecondary: "#a9b1d6"
  readonly property color textMuted: "#565f89"

  readonly property color accentPrimary: "#7aa2f7"
  readonly property color accentCyan: "#7dcfff"
  readonly property color accentGreen: "#9ece6a"
  readonly property color accentOrange: "#ff9e64"
  readonly property color accentRed: "#f7768e"

  readonly property color urgencyLow: textMuted
  readonly property color urgencyNormal: accentPrimary
  readonly property color urgencyCritical: accentRed
  readonly property color batteryGood: accentGreen
  readonly property color batteryWarning: accentOrange
  readonly property color batteryCritical: accentRed

  readonly property var themes: []
  readonly property int currentIndex: 0
  readonly property string currentName: "Night"
  readonly property string currentFamily: "Tokyo Night"
  readonly property int count: 0
  function setTheme(index) {}
}
