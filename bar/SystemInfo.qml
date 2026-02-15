pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
  id: root

  property string cpuUsage: "0%"
  property string memoryUsage: "0%"
  property string networkInfo: "7F-Internal"
  property int batteryLevelRaw: 0
  property string batteryLevel: "0%"
  property string batteryIcon: "󰂎"
  property string temperature: "0°C"

  // CPU Usage
  Process {
    id: cpuProc
    command: ["sh", "-c", "top -bn1 | grep 'Cpu(s)' | sed 's/.*, *\\([0-9.]*\\)%* id.*/\\1/' | awk '{print 100 - $1\"%\"}'"]
    running: true

    stdout: StdioCollector {
      onStreamFinished: {
        root.cpuUsage = text.trim()
      }
    }
  }

  // Memory Usage
  Process {
    id: memProc
    command: ["sh", "-c", "free | grep Mem | awk '{printf \"%.1f%%\", ($3/$2) * 100.0}'"]
    running: true

    stdout: StdioCollector {
      onStreamFinished: {
        root.memoryUsage = text.trim()
      }
    }
  }

  // Network Info
  Process {
    id: netProc
    command: ["sh", "-c", "nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2"]
    running: true

    stdout: StdioCollector {
      onStreamFinished: {
        const ssid = text.trim()
        root.networkInfo = ssid || "7F-Internal"
      }
    }
  }

  // Battery
  Process {
    id: batteryProc
    command: ["sh", "-c", "cat /sys/class/power_supply/BAT*/capacity 2>/dev/null || echo '99'"]
    running: true

    stdout: StdioCollector {
      onStreamFinished: {
        const level = parseInt(text.trim())
        root.batteryLevelRaw = level
        root.batteryLevel = level + "%"

        // Set icon based on level
        if (level >= 90) root.batteryIcon = "󰁹"
        else if (level >= 80) root.batteryIcon = "󰂂"
        else if (level >= 70) root.batteryIcon = "󰂁"
        else if (level >= 60) root.batteryIcon = "󰂀"
        else if (level >= 50) root.batteryIcon = "󰁿"
        else if (level >= 40) root.batteryIcon = "󰁾"
        else if (level >= 30) root.batteryIcon = "󰁽"
        else if (level >= 20) root.batteryIcon = "󰁼"
        else if (level >= 10) root.batteryIcon = "󰁻"
        else root.batteryIcon = "󰁺"
      }
    }
  }

  // Temperature
  Process {
    id: tempProc
    command: ["sh", "-c", "sensors 2>/dev/null | grep -i 'Package id 0' | awk '{print $4}' | sed 's/+//;s/°C/°C/' || echo '61°C'"]
    running: true

    stdout: StdioCollector {
      onStreamFinished: {
        root.temperature = text.trim() || "61°C"
      }
    }
  }

  // Update timer
  Timer {
    interval: 2000
    running: true
    repeat: true
    onTriggered: {
      cpuProc.running = true
      memProc.running = true
      netProc.running = true
      batteryProc.running = true
      tempProc.running = true
    }
  }
}
