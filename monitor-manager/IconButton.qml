import QtQuick

// Generic clickable button (icon glyph, text label, or both) with hover highlight.
// Root is Rectangle so callers can set border.color / border.width directly.
Rectangle {
    id: root

    required property var   theme

    property string icon:       ""
    property string label:      ""
    property color  iconColor:  root.theme.textSecondary
    property int    iconSize:   14
    property bool   bold:       false
    property bool   circular:   false           // true → radius = height / 2
    property color  baseColor:  "transparent"
    property color  hoverColor: root.theme.bgHover
    property bool   _enabled:   true
    property int    hPadding:   8

    signal clicked()

    implicitWidth:  iconLabel.implicitWidth + hPadding * 2
    implicitHeight: 28
    radius:         circular ? height / 2 : 8
    color:          (area.containsMouse && _enabled) ? hoverColor : baseColor

    Text {
        id: iconLabel
        anchors.centerIn: parent
        text: root.icon !== "" && root.label !== ""
              ? root.icon + "  " + root.label
              : root.icon !== "" ? root.icon : root.label
        color: root.iconColor
        font  { pixelSize: root.iconSize; bold: root.bold; family: "Hack Nerd Font" }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: root._enabled
        cursorShape:  root._enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        enabled:      root._enabled
        onClicked:    root.clicked()
    }
}
