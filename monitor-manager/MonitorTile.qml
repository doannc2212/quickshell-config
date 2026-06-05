import QtQuick

Item {
  id: root

  required property var  monitor
  required property int  index
  required property bool selected
  required property var  theme

  // Use distinct param names (idx, not index) to avoid shadowing the required property
  // Drag boundary (canvas coordinates). Set by MonitorCanvas so tiles can't escape the canvas.
  property real dragMinX: 0
  property real dragMinY: 0
  property real dragMaxX: 100000
  property real dragMaxY: 100000

  signal clicked(int idx)
  signal dragStarted()
  signal dragEnded(int idx, real canvasX, real canvasY)

  Rectangle {
    anchors.fill: parent
    radius: 6
    color: root.selected
      ? Qt.rgba(root.theme.accentPrimary.r, root.theme.accentPrimary.g, root.theme.accentPrimary.b, 0.15)
      : root.theme.bgBase
    border.color: root.selected ? root.theme.accentPrimary : root.theme.bgBorder
    border.width: root.selected ? 2 : 1
    opacity: root.monitor.disabled ? 0.45 : 1.0

    // Name — top-left
    Text {
      anchors { top: parent.top; left: parent.left; margins: 8 }
      text: root.monitor.name
      color: root.selected ? root.theme.accentPrimary : root.theme.textPrimary
      font {
        pixelSize: Math.max(9, Math.min(13, root.width / 10))
        bold: true
        family: "Hack Nerd Font"
      }
      elide: Text.ElideRight
      width: parent.width - 16
    }

    // Mode — center for enabled, center-bottom for disabled (hidden when tile is tiny)
    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.verticalCenter:   root.monitor.disabled ? undefined    : parent.verticalCenter
      anchors.bottom:           root.monitor.disabled ? parent.bottom : undefined
      anchors.bottomMargin:     root.monitor.disabled ? 6            : 0
      text: root.monitor.disabled ? "disabled" : root.monitor.selectedMode.replace("Hz", "")
      color: root.theme.textSecondary
      font {
        pixelSize: Math.max(8, Math.min(11, root.width / 14))
        family: "Hack Nerd Font"
      }
      horizontalAlignment: Text.AlignHCenter
      visible: root.width > 60
    }

    // Rotation badge — bottom-right
    Text {
      anchors { bottom: parent.bottom; right: parent.right; margins: 6 }
      text: (["", "90°", "180°", "270°", "", "90°", "180°", "270°"])[root.monitor.transform] ?? ""
      color: root.theme.accentOrange
      font { pixelSize: 9; family: "Hack Nerd Font" }
      visible: root.monitor.transform !== 0
    }
  }

  MouseArea {
    id: dragArea
    anchors.fill: parent
    drag.target: (root.monitor.disabled || root.monitor.mirrorOf !== "") ? null : root
    drag.axis: Drag.XAndYAxis
    drag.minimumX: root.dragMinX
    drag.minimumY: root.dragMinY
    drag.maximumX: root.dragMaxX
    drag.maximumY: root.dragMaxY
    cursorShape: (root.monitor.disabled || root.monitor.mirrorOf !== "")
                 ? Qt.ForbiddenCursor : Qt.SizeAllCursor

    onClicked: root.clicked(root.index)

    onPressed: {
      if (drag.target !== null) root.dragStarted();
    }
    onReleased: {
      if (drag.active) root.dragEnded(root.index, root.x, root.y);
    }
  }
}
