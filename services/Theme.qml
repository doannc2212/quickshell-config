pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property int currentIndex: 0
    readonly property var current: themes[currentIndex]
    readonly property int count: themes.length
    readonly property string currentName: current.name
    readonly property string currentFamily: current.family
    readonly property bool isDark: !isLightColor(current.bgBase)

    function isLightColor(hex) {
        hex = hex.toString().replace("#", "");
        var r = parseInt(hex.substr(0, 2), 16);
        var g = parseInt(hex.substr(2, 2), 16);
        var b = parseInt(hex.substr(4, 2), 16);
        return (0.299 * r + 0.587 * g + 0.114 * b) / 255 > 0.5;
    }

    function applySystemColorScheme(dark) {
        colorSchemeProc.command = ["gsettings", "set",
            "org.gnome.desktop.interface", "color-scheme",
            dark ? "prefer-dark" : "prefer-light"];
        colorSchemeProc.running = true;
    }

    // Reactive color properties — same API as before
    readonly property color bgBase:       current.bgBase
    readonly property color bgSurface:    current.bgSurface
    readonly property color bgHover:      current.bgHover
    readonly property color bgSelected:   current.bgSelected
    readonly property color bgBorder:     current.bgBorder
    readonly property color bgOverlay:    "#88000000"

    readonly property color textPrimary:   current.textPrimary
    readonly property color textSecondary: current.textSecondary
    readonly property color textMuted:     current.textMuted

    readonly property color accentPrimary: current.accentPrimary
    readonly property color accentCyan:    current.accentCyan
    readonly property color accentGreen:   current.accentGreen
    readonly property color accentOrange:  current.accentOrange
    readonly property color accentRed:     current.accentRed

    // Semantic aliases
    readonly property color urgencyLow:      textMuted
    readonly property color urgencyNormal:   accentPrimary
    readonly property color urgencyCritical: accentRed
    readonly property color batteryGood:     accentGreen
    readonly property color batteryWarning:  accentOrange
    readonly property color batteryCritical: accentRed

    function setTheme(index) {
        if (index >= 0 && index < themes.length) {
            currentIndex = index;
            saveProc.command = ["sh", "-c",
                "echo " + index + " > $HOME/.config/quickshell/theme.conf"];
            saveProc.running = true;
            applyKittyTheme(themes[index]);
            applySystemColorScheme(!isLightColor(themes[index].bgBase));
        }
    }

    function applyKittyTheme(t) {
        var colorsConf = [
            "foreground " + t.textPrimary,
            "background " + t.bgBase,
            "cursor " + t.accentPrimary,
            "cursor_text_color " + t.bgBase,
            "selection_foreground " + t.textPrimary,
            "selection_background " + t.bgSelected,
            "active_tab_foreground " + t.textPrimary,
            "active_tab_background " + t.bgSurface,
            "inactive_tab_foreground " + t.textMuted,
            "inactive_tab_background " + t.bgBase,
            "color0 " + t.bgSurface,
            "color1 " + t.accentRed,
            "color2 " + t.accentGreen,
            "color3 " + t.accentOrange,
            "color4 " + t.accentPrimary,
            "color5 " + t.accentPrimary,
            "color6 " + t.accentCyan,
            "color7 " + t.textSecondary,
            "color8 " + t.textMuted,
            "color9 " + t.accentRed,
            "color10 " + t.accentGreen,
            "color11 " + t.accentOrange,
            "color12 " + t.accentPrimary,
            "color13 " + t.accentPrimary,
            "color14 " + t.accentCyan,
            "color15 " + t.textPrimary
        ].join("\n");
        var colorsArgs = [
            "foreground=" + t.textPrimary,
            "background=" + t.bgBase,
            "cursor=" + t.accentPrimary,
            "cursor_text_color=" + t.bgBase,
            "selection_foreground=" + t.textPrimary,
            "selection_background=" + t.bgSelected,
            "active_tab_foreground=" + t.textPrimary,
            "active_tab_background=" + t.bgSurface,
            "inactive_tab_foreground=" + t.textMuted,
            "inactive_tab_background=" + t.bgBase,
            "color0=" + t.bgSurface,
            "color1=" + t.accentRed,
            "color2=" + t.accentGreen,
            "color3=" + t.accentOrange,
            "color4=" + t.accentPrimary,
            "color5=" + t.accentPrimary,
            "color6=" + t.accentCyan,
            "color7=" + t.textSecondary,
            "color8=" + t.textMuted,
            "color9=" + t.accentRed,
            "color10=" + t.accentGreen,
            "color11=" + t.accentOrange,
            "color12=" + t.accentPrimary,
            "color13=" + t.accentPrimary,
            "color14=" + t.accentCyan,
            "color15=" + t.textPrimary
        ].join(" ");
        kittyProc.command = ["sh", "-c",
            "printf '%s\\n' '" + colorsConf + "' > $HOME/.config/kitty/theme-colors.conf; " +
            "for sock in /tmp/kitty-*; do " +
            "[ -S \"$sock\" ] && kitty @ --to \"unix:$sock\" set-colors --all --configured " + colorsArgs + "; " +
            "done"
        ];
        kittyProc.running = true;
    }

    Process { id: saveProc; running: false }
    Process { id: kittyProc; running: false }
    Process { id: colorSchemeProc; running: false }

    Process {
        id: loadProc
        command: ["sh", "-c", "cat $HOME/.config/quickshell/theme.conf 2>/dev/null"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const idx = parseInt(text.trim());
                if (!isNaN(idx) && idx >= 0 && idx < root.themes.length) {
                    root.currentIndex = idx;
                    root.applyKittyTheme(root.themes[idx]);
                    root.applySystemColorScheme(!root.isLightColor(root.themes[idx].bgBase));
                }
            }
        }
    }

    readonly property var themes: [
        // ── Tokyo Night ──────────────────────────────
        {
            name: "Night", family: "Tokyo Night",
            bgBase: "#1a1b26", bgSurface: "#24283b", bgHover: "#1e2235",
            bgSelected: "#283457", bgBorder: "#32364a",
            textPrimary: "#c0caf5", textSecondary: "#a9b1d6", textMuted: "#565f89",
            accentPrimary: "#7aa2f7", accentCyan: "#7dcfff",
            accentGreen: "#9ece6a", accentOrange: "#ff9e64", accentRed: "#f7768e"
        },
        {
            name: "Storm", family: "Tokyo Night",
            bgBase: "#24283b", bgSurface: "#292e42", bgHover: "#272c3f",
            bgSelected: "#2e3c64", bgBorder: "#3b4261",
            textPrimary: "#c0caf5", textSecondary: "#a9b1d6", textMuted: "#565f89",
            accentPrimary: "#7aa2f7", accentCyan: "#7dcfff",
            accentGreen: "#9ece6a", accentOrange: "#ff9e64", accentRed: "#f7768e"
        },
        {
            name: "Moon", family: "Tokyo Night",
            bgBase: "#222436", bgSurface: "#2f334d", bgHover: "#2a2e48",
            bgSelected: "#2d3f76", bgBorder: "#3b4261",
            textPrimary: "#c8d3f5", textSecondary: "#828bb8", textMuted: "#636da6",
            accentPrimary: "#82aaff", accentCyan: "#86e1fc",
            accentGreen: "#c3e88d", accentOrange: "#ff966c", accentRed: "#ff757f"
        },
        {
            name: "Light", family: "Tokyo Night",
            bgBase: "#e1e2e7", bgSurface: "#d0d5e3", bgHover: "#c4c8da",
            bgSelected: "#b6bfe2", bgBorder: "#b4b5b9",
            textPrimary: "#3760bf", textSecondary: "#6172b0", textMuted: "#848cb5",
            accentPrimary: "#2e7de9", accentCyan: "#007197",
            accentGreen: "#587539", accentOrange: "#b15c00", accentRed: "#f52a65"
        },

        // ── Catppuccin ───────────────────────────────
        {
            name: "Mocha", family: "Catppuccin",
            bgBase: "#1e1e2e", bgSurface: "#313244", bgHover: "#272839",
            bgSelected: "#45475a", bgBorder: "#585b70",
            textPrimary: "#cdd6f4", textSecondary: "#bac2de", textMuted: "#a6adc8",
            accentPrimary: "#89b4fa", accentCyan: "#74c7ec",
            accentGreen: "#a6e3a1", accentOrange: "#fab387", accentRed: "#f38ba8"
        },
        {
            name: "Macchiato", family: "Catppuccin",
            bgBase: "#24273a", bgSurface: "#363a4f", bgHover: "#2d3145",
            bgSelected: "#494d64", bgBorder: "#5b6078",
            textPrimary: "#cad3f5", textSecondary: "#b8c0e0", textMuted: "#a5adcb",
            accentPrimary: "#8aadf4", accentCyan: "#7dc4e4",
            accentGreen: "#a6da95", accentOrange: "#f5a97f", accentRed: "#ed8796"
        },
        {
            name: "Frappe", family: "Catppuccin",
            bgBase: "#303446", bgSurface: "#414559", bgHover: "#383c50",
            bgSelected: "#51576d", bgBorder: "#626880",
            textPrimary: "#c6d0f5", textSecondary: "#b5bfe2", textMuted: "#a5adce",
            accentPrimary: "#8caaee", accentCyan: "#85c1dc",
            accentGreen: "#a6d189", accentOrange: "#ef9f76", accentRed: "#e78284"
        },
        {
            name: "Latte", family: "Catppuccin",
            bgBase: "#eff1f5", bgSurface: "#ccd0da", bgHover: "#dce0e8",
            bgSelected: "#bcc0cc", bgBorder: "#acb0be",
            textPrimary: "#4c4f69", textSecondary: "#5c5f77", textMuted: "#6c6f85",
            accentPrimary: "#1e66f5", accentCyan: "#209fb5",
            accentGreen: "#40a02b", accentOrange: "#fe640b", accentRed: "#d20f39"
        },

        // ── Beared ───────────────────────────────────
        {
            name: "Arc", family: "Beared",
            bgBase: "#1c2433", bgSurface: "#181f2c", bgHover: "#242f42",
            bgSelected: "#283449", bgBorder: "#11161f",
            textPrimary: "#d0d7e4", textSecondary: "#afbbd2", textMuted: "#4a5e84",
            accentPrimary: "#69C3FF", accentCyan: "#22ECDB",
            accentGreen: "#3CEC85", accentOrange: "#FF955C", accentRed: "#E35535"
        },
        {
            name: "Surprising Eggplant", family: "Beared",
            bgBase: "#1d1426", bgSurface: "#17101f", bgHover: "#331c31",
            bgSelected: "#3e2036", bgBorder: "#0e0912",
            textPrimary: "#d0c1de", textSecondary: "#b6a0cc", textMuted: "#5d4179",
            accentPrimary: "#00B3BD", accentCyan: "#d24e4e",
            accentGreen: "#a9dc76", accentOrange: "#FF955C", accentRed: "#C13838"
        },
        {
            name: "Oceanic", family: "Beared",
            bgBase: "#1a2b34", bgSurface: "#16252d", bgHover: "#233b47",
            bgSelected: "#284350", bgBorder: "#101a20",
            textPrimary: "#cddde6", textSecondary: "#acc6d4", textMuted: "#467188",
            accentPrimary: "#5fb2df", accentCyan: "#59c6c8",
            accentGreen: "#97c892", accentOrange: "#DC8255", accentRed: "#B4552D"
        },
        {
            name: "Solarized Dark", family: "Beared",
            bgBase: "#132c34", bgSurface: "#10252c", bgHover: "#193a45",
            bgSelected: "#1c424d", bgBorder: "#0b191e",
            textPrimary: "#c3e0e9", textSecondary: "#9eccdb", textMuted: "#367b90",
            accentPrimary: "#4db0f7", accentCyan: "#26bbae",
            accentGreen: "#a5b82e", accentOrange: "#e8913b", accentRed: "#f45645"
        },
        {
            name: "Coffee", family: "Beared",
            bgBase: "#292423", bgSurface: "#231f1e", bgHover: "#3e3331",
            bgSelected: "#493b37", bgBorder: "#181615",
            textPrimary: "#ceb5b0", textSecondary: "#beaba7", textMuted: "#564642",
            accentPrimary: "#6EDDD6", accentCyan: "#3ceaa8",
            accentGreen: "#9DCC57", accentOrange: "#ffa777", accentRed: "#f24343"
        },
        {
            name: "Monokai Stone", family: "Beared",
            bgBase: "#2A2D33", bgSurface: "#25282d", bgHover: "#353840",
            bgSelected: "#3a3d46", bgBorder: "#1c1e22",
            textPrimary: "#dee0e4", textSecondary: "#c3c6cc", textMuted: "#656b78",
            accentPrimary: "#78dce8", accentCyan: "#78e8c6",
            accentGreen: "#a9dc76", accentOrange: "#fc9867", accentRed: "#fc6a67"
        },
        {
            name: "Vivid Black", family: "Beared",
            bgBase: "#141417", bgSurface: "#0f0f11", bgHover: "#1f1f23",
            bgSelected: "#242429", bgBorder: "#060607",
            textPrimary: "#c5c5cb", textSecondary: "#aaaab3", textMuted: "#50505a",
            accentPrimary: "#28A9FF", accentCyan: "#14E5D4",
            accentGreen: "#42DD76", accentOrange: "#FF7135", accentRed: "#D62C2C"
        }
    ]
}
