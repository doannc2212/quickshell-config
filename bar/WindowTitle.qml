import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

Text {
  property var theme

  text: Hyprland.activeToplevel ? Hyprland.activeToplevel.title : ""
  color: theme.textPrimary
  font.pixelSize: 13
  font.family: "Hack Nerd Font"
  elide: Text.ElideRight
  width: Math.min(implicitWidth, 400)
  clip: true
}
