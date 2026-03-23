import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: root

    property var theme

    theme: DefaultTheme {
    }

    property bool panelVisible: false
    property var monitors: []
    property string selectedName: ""
    property string statusText: "Load monitor state from Hyprland to start editing."
    property string applyLog: ""
    property string pendingBatch: ""
    property bool refreshPendingAfterApply: false
    property bool persistConfigEnabled: false
    readonly property string persistTogglePath: Quickshell.env("HOME") + "/.config/quickshell/monitor-manager.conf"
    readonly property string persistHyprPath: Quickshell.env("HOME") + "/.config/hypr/monitors.conf"
    readonly property string persistSourceLine: "source = ~/.config/hypr/monitors.conf"
    readonly property int selectedIndex: {
        for (let i = 0; i < monitors.length; i++) {
            if (monitors[i].name === selectedName)
                return i;

        }
        return -1;
    }
    readonly property var selectedMonitor: selectedIndex >= 0 ? monitors[selectedIndex] : null
    readonly property var activeMonitors: monitors.filter((m) => {
        return !m.disabled;
    })

    function clone(value) {
        return JSON.parse(JSON.stringify(value));
    }

    function roundTo(value, step) {
        return Math.round(value / step) * step;
    }

    function parseNumber(value, fallback) {
        const parsed = Number(value);
        return isNaN(parsed) ? fallback : parsed;
    }

    function parseModeString(mode) {
        const match = /^(\d+)x(\d+)(?:@([\d.]+))?$/.exec((mode || "").trim());
        if (!match)
            return null;

        const width = parseInt(match[1], 10);
        const height = parseInt(match[2], 10);
        const refresh = match[3] ? parseFloat(match[3]) : 0;
        return {
            "width": width,
            "height": height,
            "refresh": refresh,
            "label": modeLabel(width, height, refresh)
        };
    }

    function modeLabel(width, height, refresh) {
        const rate = Number(refresh);
        if (!isNaN(rate) && rate > 0)
            return width + "x" + height + "@" + rate.toFixed(2);

        return width + "x" + height;
    }

    function logicalSize(monitor) {
        const rotated = monitor.transform === 1 || monitor.transform === 3 || monitor.transform === 5 || monitor.transform === 7;
        const rawWidth = rotated ? monitor.height : monitor.width;
        const rawHeight = rotated ? monitor.width : monitor.height;
        const scale = monitor.scale > 0 ? monitor.scale : 1;
        return {
            "width": Math.max(1, rawWidth / scale),
            "height": Math.max(1, rawHeight / scale)
        };
    }

    function normalizeMonitor(raw, index) {
        const modes = [];
        const seen = {
        };
        const addMode = (candidate) => {
            if (!candidate)
                return ;

            const parsed = typeof candidate === "string" ? parseModeString(candidate) : {
                "width": parseInt(candidate.width || 0, 10),
                "height": parseInt(candidate.height || 0, 10),
                "refresh": parseFloat(candidate.refreshRate || candidate.refresh || 0),
                "label": modeLabel(parseInt(candidate.width || 0, 10), parseInt(candidate.height || 0, 10), parseFloat(candidate.refreshRate || candidate.refresh || 0))
            };
            if (!parsed || parsed.width <= 0 || parsed.height <= 0)
                return ;

            const key = parsed.label;
            if (seen[key])
                return ;

            seen[key] = true;
            modes.push(parsed);
        };
        addMode({
            "width": raw.width,
            "height": raw.height,
            "refreshRate": raw.refreshRate
        });
        if (raw.availableModes) {
            for (const candidate of raw.availableModes) addMode(candidate)
        }
        const initialMode = modes.length > 0 ? modes[0] : {
            "width": Math.max(1, parseInt(raw.width || 1920, 10)),
            "height": Math.max(1, parseInt(raw.height || 1080, 10)),
            "refresh": parseFloat(raw.refreshRate || 60),
            "label": modeLabel(Math.max(1, parseInt(raw.width || 1920, 10)), Math.max(1, parseInt(raw.height || 1080, 10)), parseFloat(raw.refreshRate || 60))
        };
        const disabled = raw.disabled === true;
        return {
            "key": (raw.name || "monitor") + "-" + index,
            "id": raw.id !== undefined ? raw.id : index,
            "name": raw.name || ("monitor-" + index),
            "description": raw.description || "",
            "make": raw.make || "",
            "model": raw.model || "",
            "serial": raw.serial || "",
            "focused": raw.focused === true,
            "disabled": disabled,
            "width": initialMode.width,
            "height": initialMode.height,
            "refreshRate": initialMode.refresh,
            "x": parseInt(raw.x || 0, 10),
            "y": parseInt(raw.y || 0, 10),
            "scale": parseFloat(raw.scale || 1),
            "transform": parseInt(raw.transform || 0, 10),
            "vrr": parseInt(raw.vrr || 0, 10),
            "mirror": raw.mirrorOf || "",
            "currentWorkspace": raw.activeWorkspace && raw.activeWorkspace.name ? raw.activeWorkspace.name : "",
            "currentFormat": raw.currentFormat || "",
            "availableModes": modes
        };
    }

    function selectMonitor(name) {
        if (!name)
            return ;

        selectedName = name;
    }

    function loadMonitors(jsonText) {
        try {
            const parsed = JSON.parse(jsonText);
            if (!Array.isArray(parsed))
                throw new Error("Expected an array");

            const next = parsed.map((monitor, index) => {
                return normalizeMonitor(monitor, index);
            }).sort((a, b) => {
                if (a.disabled !== b.disabled)
                    return a.disabled ? 1 : -1;

                if (a.focused !== b.focused)
                    return a.focused ? -1 : 1;

                return a.name.localeCompare(b.name);
            });
            monitors = next;
            if (next.length === 0) {
                selectedName = "";
                statusText = "Hyprland returned no monitors.";
            } else if (!next.some((m) => {
                return m.name === selectedName;
            })) {
                const preferred = next.find((m) => {
                    return m.focused;
                }) || next[0];
                selectedName = preferred.name;
                statusText = "Loaded " + next.length + " monitor" + (next.length !== 1 ? "s." : ".");
            } else {
                statusText = "Refreshed " + next.length + " monitor" + (next.length !== 1 ? "s." : ".");
            }
        } catch (error) {
            statusText = "Failed to parse hyprctl JSON: " + error;
            console.error("MonitorManager parse error:", error, jsonText);
        }
    }

    function refreshMonitors() {
        if (refreshProc.running || applyProc.running)
            return ;

        statusText = "Querying Hyprland monitor state...";
        refreshProc.running = true;
    }

    function updateMonitorByName(name, patch) {
        const next = clone(monitors);
        for (let i = 0; i < next.length; i++) {
            if (next[i].name === name) {
                for (const key in patch) next[i][key] = patch[key]
                monitors = next;
                return ;
            }
        }
    }

    function setMonitorMode(name, label) {
        const monitor = monitors.find((m) => {
            return m.name === name;
        });
        if (!monitor)
            return ;

        const parsed = parseModeString(label);
        if (!parsed)
            return ;

        updateMonitorByName(name, {
            "width": parsed.width,
            "height": parsed.height,
            "refreshRate": parsed.refresh > 0 ? parsed.refresh : monitor.refreshRate
        });
    }

    function anchorMonitor() {
        const selectable = activeMonitors.filter((m) => {
            return m.name !== selectedName;
        });
        if (selectable.length === 0)
            return null;

        return selectable.find((m) => {
            return m.focused;
        }) || selectable[0];
    }

    function placeSelected(direction) {
        if (!selectedMonitor)
            return ;

        const anchor = anchorMonitor();
        if (!anchor)
            return ;

        const selectedSize = logicalSize(selectedMonitor);
        const anchorSize = logicalSize(anchor);
        let nextX = selectedMonitor.x;
        let nextY = selectedMonitor.y;
        if (direction === "left") {
            nextX = roundTo(anchor.x - selectedSize.width, 10);
            nextY = anchor.y;
        } else if (direction === "right") {
            nextX = roundTo(anchor.x + anchorSize.width, 10);
            nextY = anchor.y;
        } else if (direction === "above") {
            nextX = anchor.x;
            nextY = roundTo(anchor.y - selectedSize.height, 10);
        } else if (direction === "below") {
            nextX = anchor.x;
            nextY = roundTo(anchor.y + anchorSize.height, 10);
        }
        updateMonitorByName(selectedMonitor.name, {
            "x": nextX,
            "y": nextY,
            "mirror": direction === "mirror" ? anchor.name : ""
        });
        if (direction === "mirror")
            statusText = selectedMonitor.name + " will mirror " + anchor.name + ".";
        else
            statusText = selectedMonitor.name + " placed " + direction + " " + anchor.name + ".";
    }

    function buildMonitorRule(monitor) {
        if (monitor.disabled)
            return monitor.name + ",disable";

        let rule = monitor.name + "," + modeLabel(monitor.width, monitor.height, monitor.refreshRate) + "," + Math.round(monitor.x) + "x" + Math.round(monitor.y) + "," + Number(monitor.scale).toFixed(2).replace(/\.?0+$/, "");
        if (monitor.transform > 0)
            rule += ",transform," + monitor.transform;

        if (monitor.mirror !== "")
            rule += ",mirror," + monitor.mirror;

        if (monitor.vrr > 0)
            rule += ",vrr," + monitor.vrr;

        return rule;
    }

    function buildBatchCommand() {
        return monitors.map((m) => {
            return "keyword monitor " + buildMonitorRule(m);
        }).join(" ; ");
    }

    function buildPersistConfig() {
        return [
            "# Generated by Quickshell MonitorManager",
            "# ARandR-style draft persisted for Hyprland startup",
            monitors.map((m) => {
                return "monitor = " + buildMonitorRule(m);
            }).join("\n")
        ].join("\n");
    }

    function buildDisabledPersistConfig() {
        return [
            "# Generated by Quickshell MonitorManager",
            "# Monitor persistence disabled"
        ].join("\n");
    }

    function setPersistConfigEnabled(enabled) {
        persistConfigEnabled = enabled;
        persistToggleProc.command = ["sh", "-c", 'mkdir -p "$HOME/.config/quickshell" && printf "persist=%s\\n" "$1" > "$HOME/.config/quickshell/monitor-manager.conf"', "sh", enabled ? "1" : "0"];
        persistToggleProc.running = true;
    }

    function applyChanges() {
        if (applyProc.running || monitors.length === 0)
            return ;

        pendingBatch = buildBatchCommand();
        if (pendingBatch === "")
            return ;

        applyLog = pendingBatch;
        persistProc.command = ["sh", "-c", 'mkdir -p "$HOME/.config/hypr" && printf "%s\\n" "$1" > "$HOME/.config/hypr/monitors.conf" && conf="$HOME/.config/hypr/hyprland.conf" && line="$2" && if [ "$3" = "1" ] && [ -f "$conf" ] && ! grep -Fqx "$line" "$conf"; then printf "\\n# Quickshell monitor persistence\\n%s\\n" "$line" >> "$conf"; fi', "sh", persistConfigEnabled ? buildPersistConfig() : buildDisabledPersistConfig(), persistSourceLine, persistConfigEnabled ? "1" : "0"];
        persistProc.running = true;
        applyProc.command = ["hyprctl", "--batch", pendingBatch];
        statusText = persistConfigEnabled ? "Applying monitor layout and saving boot config..." : "Applying monitor layout...";
        refreshPendingAfterApply = true;
        applyProc.running = true;
    }

    function resetSelectionLayout() {
        if (!selectedMonitor)
            return ;

        updateMonitorByName(selectedMonitor.name, {
            "x": 0,
            "y": 0,
            "scale": 1,
            "transform": 0,
            "mirror": ""
        });
        statusText = "Reset draft settings for " + selectedMonitor.name + ".";
    }

    function moveSelected(dx, dy) {
        if (!selectedMonitor)
            return ;

        updateMonitorByName(selectedMonitor.name, {
            "x": roundTo(selectedMonitor.x + dx, 10),
            "y": roundTo(selectedMonitor.y + dy, 10),
            "mirror": ""
        });
    }

    IpcHandler {
        function toggle() {
            root.panelVisible = !root.panelVisible;
            if (root.panelVisible)
                root.refreshMonitors();

        }

        function refresh() {
            root.refreshMonitors();
        }

        target: "monitors"
    }

    Process {
        id: refreshProc

        command: ["hyprctl", "-j", "monitors", "all"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: root.loadMonitors(text)
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim() !== "")
                    root.statusText = "hyprctl refresh failed: " + text.trim();

            }
        }

    }

    Process {
        id: applyProc

        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                root.statusText = text.trim() !== "" ? "Applied layout: " + text.trim() : "Layout command sent to Hyprland.";
                if (root.refreshPendingAfterApply) {
                    root.refreshPendingAfterApply = false;
                    root.refreshMonitors();
                }
            }
        }

        stderr: StdioCollector {
            onStreamFinished: {
                root.refreshPendingAfterApply = false;
                if (text.trim() !== "")
                    root.statusText = "hyprctl apply failed: " + text.trim();

            }
        }

    }

    Process {
        id: persistProc

        running: false

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.trim() !== "")
                    root.statusText = "Monitor persistence failed: " + text.trim();

            }
        }

    }

    Process {
        id: persistToggleProc

        running: false
    }

    FileView {
        id: persistToggleFile

        path: root.persistTogglePath
        onTextChanged: {
            const raw = persistToggleFile.text().trim();
            root.persistConfigEnabled = /^persist=(1|true|yes|on)$/i.test(raw);
        }
    }

    PanelWindow {
        id: panel

        visible: root.panelVisible
        focusable: true
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "quickshell-monitors"
        exclusionMode: ExclusionMode.Ignore

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.panelVisible = false

            Rectangle {
                anchors.fill: parent
                color: root.theme.bgOverlay
            }

        }

        Rectangle {
            id: shell

            anchors.centerIn: parent
            width: Math.min(parent.width - 40, 1320)
            height: Math.min(parent.height - 40, 820)
            radius: 9
            color: root.theme.bgBase
            border.color: root.theme.bgBorder
            border.width: 1
            Keys.onEscapePressed: root.panelVisible = false

            MouseArea {
                anchors.fill: parent
                onClicked: (event) => {
                    return event.accepted = true;
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 9
                    color: root.theme.bgSurface
                    border.color: root.theme.bgBorder
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 12

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            ColumnLayout {
                                spacing: 4

                                Text {
                                    text: "󰍹  Monitor Layout"
                                    color: root.theme.textPrimary
                                    font.pixelSize: 22
                                    font.family: "Hack Nerd Font"
                                    font.bold: true
                                }

                                Text {
                                    text: "Layout editor for Hyprland outputs."
                                    color: root.theme.textMuted
                                    font.pixelSize: 12
                                    font.family: "Hack Nerd Font"
                                }

                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                width: 118
                                height: 36
                                radius: 8
                                color: refreshMouse.containsMouse ? root.theme.bgHover : root.theme.bgBase
                                border.color: root.theme.bgBorder
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: refreshProc.running ? "Refreshing" : "󰑐  Refresh"
                                    color: root.theme.textPrimary
                                    font.pixelSize: 12
                                    font.family: "Hack Nerd Font"
                                }

                                MouseArea {
                                    id: refreshMouse

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.refreshMonitors()
                                }

                            }

                            Rectangle {
                                width: 118
                                height: 36
                                radius: 8
                                color: applyMouse.containsMouse ? root.theme.accentPrimary : Qt.darker(root.theme.accentPrimary, 1.15)

                                Text {
                                    anchors.centerIn: parent
                                    text: applyProc.running ? "Applying" : "󰄬  Apply"
                                    color: root.theme.bgBase
                                    font.pixelSize: 12
                                    font.family: "Hack Nerd Font"
                                    font.bold: true
                                }

                                MouseArea {
                                    id: applyMouse

                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.applyChanges()
                                }

                            }

                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 36
                            radius: 8
                            color: persistMouse.containsMouse ? root.theme.bgHover : root.theme.bgBase
                            border.color: root.persistConfigEnabled ? root.theme.accentPrimary : root.theme.bgBorder
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 10

                                Rectangle {
                                    width: 38
                                    height: 22
                                    radius: 12
                                    color: root.persistConfigEnabled ? root.theme.accentPrimary : root.theme.bgSurface
                                    border.color: root.persistConfigEnabled ? root.theme.accentPrimary : root.theme.bgBorder
                                    border.width: 1

                                    Rectangle {
                                        width: 16
                                        height: 16
                                        radius: 8
                                        y: 3
                                        x: root.persistConfigEnabled ? 19 : 3
                                        color: root.persistConfigEnabled ? root.theme.bgBase : root.theme.textMuted

                                        Behavior on x {
                                            NumberAnimation {
                                                duration: 120
                                                easing.type: Easing.OutCubic
                                            }

                                        }

                                    }

                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1

                                    Text {
                                        text: "Persist On Boot"
                                        color: root.theme.textPrimary
                                        font.pixelSize: 12
                                        font.family: "Hack Nerd Font"
                                        font.bold: true
                                    }

                                    Text {
                                        text: root.persistConfigEnabled ? "Apply also writes " + root.persistHyprPath.split("/").slice(-2).join("/") : "Layout applies live only until the next Hyprland start"
                                        color: root.theme.textMuted
                                        font.pixelSize: 10
                                        font.family: "Hack Nerd Font"
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                }
                            }

                            MouseArea {
                                id: persistMouse

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.setPersistConfigEnabled(!root.persistConfigEnabled)
                            }

                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 40
                            radius: 8
                            color: root.theme.bgBase
                            border.color: root.theme.bgBorder
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 14
                                anchors.rightMargin: 14
                                spacing: 10

                                Text {
                                    text: "󰜎"
                                    color: root.theme.accentCyan
                                    font.pixelSize: 14
                                    font.family: "Hack Nerd Font"
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: root.statusText
                                    color: root.theme.textSecondary
                                    font.pixelSize: 12
                                    font.family: "Hack Nerd Font"
                                    elide: Text.ElideRight
                                }

                            }

                        }

                        Rectangle {
                            id: canvasCard

                            property real pad: 28
                            property real layoutMinX: {
                                if (root.activeMonitors.length === 0)
                                    return 0;

                                let minValue = root.activeMonitors[0].x;
                                for (const monitor of root.activeMonitors) minValue = Math.min(minValue, monitor.x)
                                return minValue;
                            }
                            property real layoutMinY: {
                                if (root.activeMonitors.length === 0)
                                    return 0;

                                let minValue = root.activeMonitors[0].y;
                                for (const monitor of root.activeMonitors) minValue = Math.min(minValue, monitor.y)
                                return minValue;
                            }
                            property real layoutWidth: {
                                if (root.activeMonitors.length === 0)
                                    return 1;

                                let minValue = layoutMinX;
                                let maxValue = layoutMinX + 1;
                                for (const monitor of root.activeMonitors) {
                                    const size = root.logicalSize(monitor);
                                    maxValue = Math.max(maxValue, monitor.x + size.width);
                                }
                                return Math.max(1, maxValue - minValue);
                            }
                            property real layoutHeight: {
                                if (root.activeMonitors.length === 0)
                                    return 1;

                                let minValue = layoutMinY;
                                let maxValue = layoutMinY + 1;
                                for (const monitor of root.activeMonitors) {
                                    const size = root.logicalSize(monitor);
                                    maxValue = Math.max(maxValue, monitor.y + size.height);
                                }
                                return Math.max(1, maxValue - minValue);
                            }
                            property real layoutScale: Math.min((width - pad * 2) / layoutWidth, (height - pad * 2) / layoutHeight)

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 9
                            color: Qt.darker(root.theme.bgSurface, 1.1)
                            border.color: root.theme.bgBorder
                            border.width: 1

                            Item {
                                anchors.fill: parent
                                anchors.margins: 14

                                Repeater {
                                    model: 20

                                    Rectangle {
                                        width: parent.width
                                        height: 1
                                        y: index * parent.height / 20
                                        color: Qt.rgba(1, 1, 1, 0.035)
                                    }

                                }

                                Repeater {
                                    model: 20

                                    Rectangle {
                                        width: 1
                                        height: parent.height
                                        x: index * parent.width / 20
                                        color: Qt.rgba(1, 1, 1, 0.035)
                                    }

                                }

                            }

                            Text {
                                anchors.centerIn: parent
                                visible: root.activeMonitors.length === 0
                                text: "No active monitors returned by Hyprland"
                                color: root.theme.textMuted
                                font.pixelSize: 14
                                font.family: "Hack Nerd Font"
                            }

                            Repeater {
                                model: root.activeMonitors

                                Rectangle {
                                    id: displayRect

                                    required property var modelData
                                    property var logical: root.logicalSize(modelData)
                                    property real scaleFactor: Math.max(0.06, canvasCard.layoutScale)

                                    x: canvasCard.pad + (modelData.x - canvasCard.layoutMinX) * scaleFactor
                                    y: canvasCard.pad + (modelData.y - canvasCard.layoutMinY) * scaleFactor
                                    width: Math.max(90, logical.width * scaleFactor)
                                    height: Math.max(64, logical.height * scaleFactor)
                                    radius: 8
                                    color: root.selectedName === modelData.name ? root.theme.bgSelected : root.theme.bgBase
                                    border.color: root.selectedName === modelData.name ? root.theme.accentPrimary : (hover.containsMouse ? root.theme.accentCyan : root.theme.bgBorder)
                                    border.width: root.selectedName === modelData.name ? 2 : 1

                                    Column {
                                        anchors.fill: parent
                                        anchors.margins: 14
                                        spacing: 6

                                        Text {
                                            text: displayRect.modelData.focused ? "󰍹  " + displayRect.modelData.name : displayRect.modelData.name
                                            color: root.theme.textPrimary
                                            font.pixelSize: Math.max(12, Math.min(18, displayRect.width / 11))
                                            font.family: "Hack Nerd Font"
                                            font.bold: true
                                        }

                                        Text {
                                            text: root.modeLabel(displayRect.modelData.width, displayRect.modelData.height, displayRect.modelData.refreshRate)
                                            color: root.theme.textSecondary
                                            font.pixelSize: Math.max(10, Math.min(14, displayRect.width / 14))
                                            font.family: "Hack Nerd Font"
                                        }

                                        Text {
                                            text: Math.round(displayRect.modelData.x) + "x" + Math.round(displayRect.modelData.y)
                                            color: root.theme.textMuted
                                            font.pixelSize: Math.max(10, Math.min(13, displayRect.width / 15))
                                            font.family: "Hack Nerd Font"
                                        }

                                    }

                                    Rectangle {
                                        anchors.right: parent.right
                                        anchors.top: parent.top
                                        anchors.margins: 12
                                        width: 34
                                        height: 20
                                        radius: 8
                                        color: displayRect.modelData.mirror !== "" ? root.theme.accentOrange : root.theme.bgSurface

                                        Text {
                                            anchors.centerIn: parent
                                            text: displayRect.modelData.scale.toFixed(2).replace(/\.?0+$/, "") + "x"
                                            color: displayRect.modelData.mirror !== "" ? root.theme.bgBase : root.theme.textSecondary
                                            font.pixelSize: 10
                                            font.family: "Hack Nerd Font"
                                            font.bold: displayRect.modelData.mirror !== ""
                                        }

                                    }

                                    HoverHandler {
                                        id: hover
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.selectMonitor(displayRect.modelData.name)
                                    }

                                    Behavior on x {
                                        NumberAnimation {
                                            duration: 140
                                            easing.type: Easing.OutCubic
                                        }

                                    }

                                    Behavior on y {
                                        NumberAnimation {
                                            duration: 140
                                            easing.type: Easing.OutCubic
                                        }

                                    }

                                    Behavior on width {
                                        NumberAnimation {
                                            duration: 140
                                            easing.type: Easing.OutCubic
                                        }

                                    }

                                    Behavior on height {
                                        NumberAnimation {
                                            duration: 140
                                            easing.type: Easing.OutCubic
                                        }

                                    }

                                }

                            }

                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 120
                            radius: 9
                            color: root.theme.bgBase
                            border.color: root.theme.bgBorder
                            border.width: 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 10

                                Text {
                                    text: "Apply Preview"
                                    color: root.theme.textPrimary
                                    font.pixelSize: 13
                                    font.family: "Hack Nerd Font"
                                    font.bold: true
                                }

                                Text {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    wrapMode: Text.WrapAnywhere
                                    text: root.buildBatchCommand()
                                    color: root.theme.textMuted
                                    font.pixelSize: 11
                                    font.family: "Hack Nerd Font"
                                }

                            }

                        }

                    }

                }

                Rectangle {
                    Layout.preferredWidth: 380
                    Layout.fillHeight: true
                    radius: 9
                    color: root.theme.bgSurface
                    border.color: root.theme.bgBorder
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 12

                        Text {
                            text: "Outputs"
                            color: root.theme.textPrimary
                            font.pixelSize: 16
                            font.family: "Hack Nerd Font"
                            font.bold: true
                        }

                        Flickable {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 220
                            contentWidth: width
                            contentHeight: cards.implicitHeight
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds

                            Column {
                                id: cards

                                width: parent.width
                                spacing: 8

                                Repeater {
                                    model: root.monitors

                                    Rectangle {
                                        required property var modelData

                                        width: cards.width
                                        height: 84
                                        radius: 8
                                        color: root.selectedName === modelData.name ? root.theme.bgSelected : root.theme.bgBase
                                        border.color: root.selectedName === modelData.name ? root.theme.accentPrimary : root.theme.bgBorder
                                        border.width: root.selectedName === modelData.name ? 2 : 1

                                        Column {
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.leftMargin: 14
                                            anchors.rightMargin: 14
                                            spacing: 5

                                            Row {
                                                width: parent.width
                                                spacing: 8

                                                Text {
                                                    text: modelData.disabled ? "󰍹" : "󰍺"
                                                    color: modelData.disabled ? root.theme.textMuted : root.theme.accentGreen
                                                    font.pixelSize: 14
                                                    font.family: "Hack Nerd Font"
                                                }

                                                Text {
                                                    text: modelData.name
                                                    color: root.theme.textPrimary
                                                    font.pixelSize: 14
                                                    font.family: "Hack Nerd Font"
                                                    font.bold: true
                                                }

                                                Text {
                                                    text: modelData.focused ? "focused" : (modelData.mirror !== "" ? "mirror" : (modelData.disabled ? "disabled" : "active"))
                                                    color: modelData.focused ? root.theme.accentCyan : root.theme.textMuted
                                                    font.pixelSize: 11
                                                    font.family: "Hack Nerd Font"
                                                }

                                            }

                                            Text {
                                                width: parent.width
                                                text: modelData.description !== "" ? modelData.description : (modelData.make + " " + modelData.model).trim()
                                                color: root.theme.textSecondary
                                                font.pixelSize: 11
                                                font.family: "Hack Nerd Font"
                                                elide: Text.ElideRight
                                            }

                                            Text {
                                                text: modelData.disabled ? "Disabled" : root.modeLabel(modelData.width, modelData.height, modelData.refreshRate) + "  •  " + Math.round(modelData.x) + "x" + Math.round(modelData.y) + "  •  scale " + modelData.scale.toFixed(2).replace(/\.?0+$/, "")
                                                color: root.theme.textMuted
                                                font.pixelSize: 11
                                                font.family: "Hack Nerd Font"
                                            }

                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.selectMonitor(modelData.name)
                                        }

                                    }

                                }

                            }

                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 9
                            color: root.theme.bgBase
                            border.color: root.theme.bgBorder
                            border.width: 1

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 10

                                Text {
                                    text: root.selectedMonitor ? "Edit " + root.selectedMonitor.name : "Select a monitor"
                                    color: root.theme.textPrimary
                                    font.pixelSize: 14
                                    font.family: "Hack Nerd Font"
                                    font.bold: true
                                }

                                Text {
                                    visible: root.selectedMonitor !== null
                                    text: root.selectedMonitor ? (root.selectedMonitor.description !== "" ? root.selectedMonitor.description : "Hyprland output") : ""
                                    color: root.theme.textMuted
                                    font.pixelSize: 11
                                    font.family: "Hack Nerd Font"
                                    wrapMode: Text.Wrap
                                    Layout.fillWidth: true
                                }

                                GridLayout {
                                    Layout.fillWidth: true
                                    columns: 2
                                    columnSpacing: 8
                                    rowSpacing: 8
                                    visible: root.selectedMonitor !== null

                                    Text {
                                        text: "Enabled"
                                        color: root.theme.textSecondary
                                        font.pixelSize: 11
                                        font.family: "Hack Nerd Font"
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 34
                                        radius: 8
                                        color: enableMouse.containsMouse ? root.theme.bgHover : root.theme.bgSurface
                                        border.color: root.theme.bgBorder
                                        border.width: 1

                                        Text {
                                            anchors.centerIn: parent
                                            text: root.selectedMonitor && !root.selectedMonitor.disabled ? "On" : "Off"
                                            color: root.selectedMonitor && !root.selectedMonitor.disabled ? root.theme.accentGreen : root.theme.textMuted
                                            font.pixelSize: 12
                                            font.family: "Hack Nerd Font"
                                            font.bold: true
                                        }

                                        MouseArea {
                                            id: enableMouse

                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (!root.selectedMonitor)
                                                    return ;

                                                root.updateMonitorByName(root.selectedMonitor.name, {
                                                    "disabled": !root.selectedMonitor.disabled,
                                                    "mirror": ""
                                                });
                                            }
                                        }

                                    }

                                    Text {
                                        text: "Mode"
                                        color: root.theme.textSecondary
                                        font.pixelSize: 11
                                        font.family: "Hack Nerd Font"
                                    }

                                    ComboBox {
                                        Layout.fillWidth: true
                                        enabled: root.selectedMonitor && !root.selectedMonitor.disabled
                                        model: root.selectedMonitor ? root.selectedMonitor.availableModes.map((m) => {
                                            return m.label;
                                        }) : []
                                        currentIndex: {
                                            if (!root.selectedMonitor)
                                                return -1;

                                            const label = root.modeLabel(root.selectedMonitor.width, root.selectedMonitor.height, root.selectedMonitor.refreshRate);
                                            return model.indexOf(label);
                                        }
                                        onActivated: (index) => {
                                            if (!root.selectedMonitor || index < 0)
                                                return ;

                                            root.setMonitorMode(root.selectedMonitor.name, currentText);
                                        }
                                    }

                                    Text {
                                        text: "Scale"
                                        color: root.theme.textSecondary
                                        font.pixelSize: 11
                                        font.family: "Hack Nerd Font"
                                    }

                                    SpinBox {
                                        Layout.fillWidth: true
                                        enabled: root.selectedMonitor && !root.selectedMonitor.disabled
                                        from: 100
                                        to: 300
                                        stepSize: 25
                                        editable: true
                                        value: root.selectedMonitor ? Math.round(root.selectedMonitor.scale * 100) : 100
                                        textFromValue: (value) => {
                                            return (value / 100).toFixed(2).replace(/\.?0+$/, "");
                                        }
                                        valueFromText: (text) => {
                                            return Math.round(root.parseNumber(text, 1) * 100);
                                        }
                                        onValueModified: {
                                            if (!root.selectedMonitor)
                                                return ;

                                            root.updateMonitorByName(root.selectedMonitor.name, {
                                                "scale": value / 100,
                                                "mirror": ""
                                            });
                                        }
                                    }

                                    Text {
                                        text: "Rotation"
                                        color: root.theme.textSecondary
                                        font.pixelSize: 11
                                        font.family: "Hack Nerd Font"
                                    }

                                    ComboBox {
                                        Layout.fillWidth: true
                                        enabled: root.selectedMonitor && !root.selectedMonitor.disabled
                                        model: ["0 • Normal", "1 • 90°", "2 • 180°", "3 • 270°", "4 • Flipped", "5 • Flipped 90°", "6 • Flipped 180°", "7 • Flipped 270°"]
                                        currentIndex: root.selectedMonitor ? Math.max(0, root.selectedMonitor.transform) : 0
                                        onActivated: (index) => {
                                            if (!root.selectedMonitor)
                                                return ;

                                            root.updateMonitorByName(root.selectedMonitor.name, {
                                                "transform": index,
                                                "mirror": ""
                                            });
                                        }
                                    }

                                    Text {
                                        text: "Position X"
                                        color: root.theme.textSecondary
                                        font.pixelSize: 11
                                        font.family: "Hack Nerd Font"
                                    }

                                    SpinBox {
                                        Layout.fillWidth: true
                                        enabled: root.selectedMonitor && !root.selectedMonitor.disabled
                                        from: -20000
                                        to: 20000
                                        stepSize: 10
                                        editable: true
                                        value: root.selectedMonitor ? root.selectedMonitor.x : 0
                                        onValueModified: {
                                            if (!root.selectedMonitor)
                                                return ;

                                            root.updateMonitorByName(root.selectedMonitor.name, {
                                                "x": value,
                                                "mirror": ""
                                            });
                                        }
                                    }

                                    Text {
                                        text: "Position Y"
                                        color: root.theme.textSecondary
                                        font.pixelSize: 11
                                        font.family: "Hack Nerd Font"
                                    }

                                    SpinBox {
                                        Layout.fillWidth: true
                                        enabled: root.selectedMonitor && !root.selectedMonitor.disabled
                                        from: -20000
                                        to: 20000
                                        stepSize: 10
                                        editable: true
                                        value: root.selectedMonitor ? root.selectedMonitor.y : 0
                                        onValueModified: {
                                            if (!root.selectedMonitor)
                                                return ;

                                            root.updateMonitorByName(root.selectedMonitor.name, {
                                                "y": value,
                                                "mirror": ""
                                            });
                                        }
                                    }

                                    Text {
                                        text: "Mirror"
                                        color: root.theme.textSecondary
                                        font.pixelSize: 11
                                        font.family: "Hack Nerd Font"
                                    }

                                    ComboBox {
                                        Layout.fillWidth: true
                                        enabled: root.selectedMonitor && !root.selectedMonitor.disabled
                                        model: {
                                            const options = ["Disabled"];
                                            if (!root.selectedMonitor)
                                                return options;

                                            for (const monitor of root.activeMonitors) {
                                                if (monitor.name !== root.selectedMonitor.name)
                                                    options.push(monitor.name);

                                            }
                                            return options;
                                        }
                                        currentIndex: {
                                            if (!root.selectedMonitor)
                                                return 0;

                                            if (root.selectedMonitor.mirror === "")
                                                return 0;

                                            return model.indexOf(root.selectedMonitor.mirror);
                                        }
                                        onActivated: (index) => {
                                            if (!root.selectedMonitor)
                                                return ;

                                            root.updateMonitorByName(root.selectedMonitor.name, {
                                                "mirror": index <= 0 ? "" : currentText
                                            });
                                        }
                                    }

                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 1
                                    color: root.theme.bgBorder
                                    visible: root.selectedMonitor !== null
                                }

                                Text {
                                    visible: root.selectedMonitor !== null
                                    text: "Quick Placement"
                                    color: root.theme.textSecondary
                                    font.pixelSize: 11
                                    font.family: "Hack Nerd Font"
                                    font.bold: true
                                }

                                GridLayout {
                                    Layout.fillWidth: true
                                    columns: 2
                                    columnSpacing: 8
                                    rowSpacing: 8
                                    visible: root.selectedMonitor !== null

                                    Repeater {
                                        model: [{
                                            "label": "Left Of",
                                            "action": "left"
                                        }, {
                                            "label": "Right Of",
                                            "action": "right"
                                        }, {
                                            "label": "Above",
                                            "action": "above"
                                        }, {
                                            "label": "Below",
                                            "action": "below"
                                        }]

                                        Rectangle {
                                            required property var modelData

                                            Layout.fillWidth: true
                                            height: 34
                                            radius: 8
                                            color: quickMouse.containsMouse ? root.theme.bgHover : root.theme.bgSurface
                                            border.color: root.theme.bgBorder
                                            border.width: 1

                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData.label
                                                color: root.theme.textPrimary
                                                font.pixelSize: 11
                                                font.family: "Hack Nerd Font"
                                            }

                                            MouseArea {
                                                id: quickMouse

                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.placeSelected(modelData.action)
                                            }

                                        }

                                    }

                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8
                                    visible: root.selectedMonitor !== null

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 34
                                        radius: 8
                                        color: mirrorAction.containsMouse ? root.theme.bgHover : root.theme.bgSurface
                                        border.color: root.theme.bgBorder
                                        border.width: 1

                                        Text {
                                            anchors.centerIn: parent
                                            text: "Mirror Anchor"
                                            color: root.theme.textPrimary
                                            font.pixelSize: 11
                                            font.family: "Hack Nerd Font"
                                        }

                                        MouseArea {
                                            id: mirrorAction

                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.placeSelected("mirror")
                                        }

                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 34
                                        radius: 8
                                        color: resetMouse.containsMouse ? root.theme.bgHover : root.theme.bgSurface
                                        border.color: root.theme.bgBorder
                                        border.width: 1

                                        Text {
                                            anchors.centerIn: parent
                                            text: "Reset Draft"
                                            color: root.theme.textPrimary
                                            font.pixelSize: 11
                                            font.family: "Hack Nerd Font"
                                        }

                                        MouseArea {
                                            id: resetMouse

                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.resetSelectionLayout()
                                        }

                                    }

                                }

                                Item {
                                    Layout.fillHeight: true
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: root.selectedMonitor ? "Focused workspace: " + (root.selectedMonitor.currentWorkspace || "none") : ""
                                    color: root.theme.textMuted
                                    font.pixelSize: 11
                                    font.family: "Hack Nerd Font"
                                    visible: root.selectedMonitor !== null
                                }

                            }

                        }

                    }

                }

            }

        }

    }

}
