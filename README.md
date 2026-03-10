# my quickshell config
a personal Hyprland desktop config built with [Quickshell](https://quickshell.outfoxxed.me/). status bar, app launcher, notification daemon, media controls, OSD, wallpaper manager, and a theme switcher with 206 themes. each piece is its own module and works independently, so feel free to grab only the parts you need.

i hope it's helpful as a starting point or reference. if you have questions or ide

as, don't hesitate to open an issue — happy to chat.

<img width="1920" height="111" alt="image" src="https://github.com/user-attachments/assets/06d824ae-cf21-4c78-919c-1604f1c0a2dc" />
<br/>
<img width="405" height="146" alt="image" src="https://github.com/user-attachments/assets/40c9b11a-abf2-4e9b-bf85-ec44ea67d69d" />
<br/>
<img width="601" height="495" alt="image" src="https://github.com/user-attachments/assets/40c46613-dc24-461a-9075-33ffea221716" />


https://github.com/user-attachments/assets/55c47c05-34b6-402c-aea7-42a369b86828


## what's included

| Module | What it does |
|--------|-------------|
| **Bar** | clock, workspaces, active window title, volume, brightness, network, battery, system tray, now-playing indicator |
| **App Launcher** | rofi drun-style application launcher |
| **Notifications** | dunst-style notification daemon with popups |
| **Media Control** | popup overlay with album art, playback controls, progress bar, and volume slider |
| **OSD** | on-screen display for volume and brightness changes, auto-hides |
| **Theme Switcher** | 206 themes across 6 families, persists across restarts |
| **Wallpaper Manager** | grid picker for wallpapers, preview, supports hyprpaper and swww |

## prerequisites

these are needed regardless of which modules you use:

- [Quickshell](https://quickshell.outfoxxed.me/) + Qt 6
- [Hyprland](https://hyprland.org/)
- a [Nerd Font](https://www.nerdfonts.com/) (i use Hack Nerd Font — swap it in the QML files if you prefer another)

optional, depending on which modules you use:

- `brightnessctl` — for brightness display and control in the bar and OSD
- `nmcli` — for wifi network info in the bar
- `/sys/class/power_supply/` — for battery info (standard on most laptops)
- `hyprpaper` or `swww` — for the wallpaper manager

## installing everything

if you'd like the full setup:

```bash
git clone https://github.com/doannc2212/quickshell-config ~/.config/quickshell
quickshell
```

that's it — quickshell reads from `~/.config/quickshell/` by default.

## installing individual modules

each module is self-contained in its own folder with a `DefaultTheme.qml` fallback, so you can pick and choose. here's how to set up just the parts you want.

### bar

the status bar — clock, workspaces, window title, volume, brightness, network, battery, system tray, and a now-playing indicator.

**extra dependencies:** `brightnessctl`, `nmcli`, `/sys/class/power_supply/`

1. copy `bar/` into your quickshell config directory
2. in your `shell.qml`, add:

```qml
import "bar"

Bar {}
```

the bar will use its built-in Tokyo Night Night colors by default. to wire it up with the theme switcher instead, pass `theme: yourThemeObject`.

you can also toggle the bar via IPC:
```
qs ipc call bar toggle
```

### app launcher

a rofi drun-style launcher overlay. searches by name, description, keywords, and categories. keyboard navigation with arrow keys, enter, and escape.

1. copy `app-launcher/` into your quickshell config directory
2. in your `shell.qml`, add:

```qml
import "app-launcher"

AppLauncher {}
```

3. bind a key in `hyprland.conf`:

```
bind = SUPER, D, exec, qs ipc call launcher toggle
```

### notifications

a built-in notification daemon — replaces dunst/mako. popups appear in the top-right corner with urgency-based styling and auto-expire timers.

**note:** only one notification daemon can own `org.freedesktop.Notifications` on D-Bus at a time. please stop dunst/mako before using this.

1. copy `notifications/` into your quickshell config directory
2. in your `shell.qml`, add:

```qml
import "notifications"

NotificationPopup {}
```

3. optionally bind IPC commands in `hyprland.conf`:

```
bind = SUPER, N, exec, qs ipc call notifications dismiss_all
bind = SUPER SHIFT, N, exec, qs ipc call notifications dnd_toggle
```

features:
- urgency-based accent colors (critical, normal, low)
- app icons for common apps (discord, firefox, spotify, etc.)
- action buttons from the notification
- progress bar showing time until auto-dismiss
- click to dismiss, close button per notification
- max 5 visible notifications at a time
- do not disturb mode

### media control

a popup overlay that shows the active MPRIS player with album art, track info, playback controls, a seekable progress bar, and a volume slider.

1. copy `media/` into your quickshell config directory
2. in your `shell.qml`, add:

```qml
import "media"

MediaControl {}
```

3. bind keys in `hyprland.conf`:

```
bind = SUPER, M, exec, qs ipc call media toggle
bind = , XF86AudioPlay, exec, qs ipc call media play_pause
```

### osd

a vertical pill overlay that appears on the right side of the screen when volume or brightness changes, then auto-hides after 1.5 seconds.

**extra dependencies:** `brightnessctl`

1. copy `osd/` into your quickshell config directory
2. in your `shell.qml`, add:

```qml
import "osd"

OSD {}
```

no IPC needed — it reacts automatically to PipeWire volume changes and backlight changes.

### theme switcher

a theme picker overlay with 206 themes across 6 families. selected theme persists across restarts and syncs with kitty terminal and system dark/light mode.

1. copy `theme-switcher/` into your quickshell config directory
2. in your `shell.qml`, create the switcher and wire its theme into other modules:

```qml
import "theme-switcher"

ThemeSwitcher {
    id: ts
}

// then pass ts.theme into your other modules:
// Bar { theme: ts.theme }
// AppLauncher { theme: ts.theme }
```

3. bind a key in `hyprland.conf`:

```
bind = SUPER, T, exec, qs ipc call theme toggle
```

available theme families:
- **Tokyo Night** — Night, Storm, Moon, Light
- **Catppuccin** — Mocha, Macchiato, Frappe, Latte
- **Zen** — Dark, Light
- **Arc** — Dark, Light
- **Beared** — Arc, Surprising Eggplant, Oceanic, Solarized Dark, Coffee, Monokai Stone, Vivid Black
- **MonkeyType** — 187 community themes

### wallpaper manager

a grid-based wallpaper picker that scans `~/Pictures/Wallpapers` and `~/Pictures`. click to apply, right-click to preview. auto-detects swww or hyprpaper as backend. persists current wallpaper to `wallpaper.conf`.

**extra dependencies:** `hyprpaper` or `swww`

1. copy `wallpaper/` into your quickshell config directory
2. in your `shell.qml`, add:

```qml
import "wallpaper"

WallpaperManager {}
```

3. bind a key in `hyprland.conf`:

```
bind = SUPER, W, exec, qs ipc call wallpaper toggle
```

## tweaking

- **colors** — all colors live in `theme-switcher/Theme.qml`. pick a theme via the switcher, or add your own by appending to the `themes` array.
- **font** — search for `"Hack Nerd Font"` in the QML files and swap it with yours.
- **layout** — rearrange widgets in `bar/Bar.qml`.
- **polling rate** — change the interval in `bar/SystemInfo.qml` (default 2s).
- **extra bar widgets** — CPU, memory, and temperature widgets are already written in `bar/Bar.qml` but commented out. uncomment them if you'd like them back (requires `top`, `free`, and `sensors`).
- **adding a module** — create a folder with an entry QML file + `DefaultTheme.qml`, add `property var theme: DefaultTheme {}`, and wire it in `shell.qml`.

## acknowledgments

this wouldn't exist without the wonderful work behind [Quickshell](https://quickshell.outfoxxed.me/), [Hyprland](https://hyprland.org/), and the theme creators:

- [Tokyo Night](https://github.com/enkia/tokyo-night-vscode-theme) by enkia — 4 themes (Night, Storm, Moon, Light)
- [Catppuccin](https://github.com/catppuccin/catppuccin) by the Catppuccin team — 4 themes (Mocha, Macchiato, Frappe, Latte)
- [Beared Theme](https://marketplace.visualstudio.com/items?itemName=BeardedBear.beardedtheme) by BeardedBear — 7 themes
- [MonkeyType](https://monkeytype.com/) — 187 community themes. colors were derived from MonkeyType's theme palette. all credit goes to the original theme creators and the MonkeyType community contributors.

thank you all.
