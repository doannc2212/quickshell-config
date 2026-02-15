# my quickshell config

this is my personal Hyprland desktop config built with [Quickshell](https://quickshell.outfoxxed.me/) — a status bar, app launcher, and notification daemon with a built-in theme switcher. modular architecture where each piece works independently.

feel free to look around, borrow ideas, or use it as a starting point for your own. no pressure — it's just how i like my desktop.

## what's in it

- clock & date
- hyprland workspace indicator
- active window title
- system info (cpu, memory, network, battery, temperature)
- system tray
- app launcher (rofi drun-style)
- notification popups (dunst-style)
- theme switcher (15 themes across 3 families)

<img width="1920" height="111" alt="image" src="https://github.com/user-attachments/assets/06d824ae-cf21-4c78-919c-1604f1c0a2dc" />
<br/>
<img width="405" height="146" alt="image" src="https://github.com/user-attachments/assets/40c9b11a-abf2-4e9b-bf85-ec44ea67d69d" />
<br/>
<img width="601" height="495" alt="image" src="https://github.com/user-attachments/assets/40c46613-dc24-461a-9075-33ffea221716" />

## structure

```
shell.qml                           # assembler — wires modules together
bar/
  Bar.qml                           # status bar layout (one per screen)
  DefaultTheme.qml                  # standalone fallback colors
  TimeWidget.qml                    # clock & date
  WorkspaceIndicator.qml            # hyprland workspaces
  WindowTitle.qml                   # active window
  SystemInfoWidget.qml              # cpu/mem/net/bat/temp
  SystemTrayWidget.qml              # system tray icons
  Time.qml                          # singleton — clock data
  SystemInfo.qml                    # singleton — cpu/mem/net/bat/temp
app-launcher/
  AppLauncher.qml                   # rofi drun-style overlay
  DefaultTheme.qml
notifications/
  NotificationPopup.qml             # dunst-style popups
  NotificationService.qml           # notification daemon (singleton)
  DefaultTheme.qml
theme-switcher/
  ThemeSwitcher.qml                 # theme picker overlay
  Theme.qml                         # 15 themes + persistence + kitty sync
  DefaultTheme.qml
docs/                               # PlantUML architecture diagrams
```

each module is self-contained — no module imports another. `shell.qml` wires the shared theme from `theme-switcher/` into all modules via property injection. remove any module and the rest still work.

## dependencies

- [Quickshell](https://quickshell.outfoxxed.me/) + Qt 6
- Hyprland
- a Nerd Font (i use Hack Nerd Font)
- `top`, `free`, `nmcli`, `sensors` for system info

## running

```bash
quickshell
```

it reads from `~/.config/quickshell/` by default.

## app launcher

a rofi drun-style launcher built into the shell. toggle it via IPC:

```bash
qs ipc call launcher toggle
```

bind it in `hyprland.conf`:

```
bind = SUPER, D, exec, qs ipc call launcher toggle
```

features:
- searches by app name, description, keywords, and categories
- keyboard navigation (arrow keys, enter, escape)
- click backdrop to dismiss

## notifications

a built-in notification daemon — replaces dunst/mako. popups appear in the top-right corner with urgency-based styling and auto-expire timers.

IPC commands:

```bash
qs ipc call notifications dismiss_all   # dismiss all popups
qs ipc call notifications dnd_toggle    # toggle do not disturb
```

features:
- urgency-based accent colors (critical, normal, low)
- app icons for common apps (discord, firefox, spotify, etc.)
- action buttons from the notification
- progress bar showing time until auto-dismiss
- click to dismiss, close button per notification
- max 5 visible notifications at a time
- do not disturb mode

**note:** only one notification daemon can run on D-Bus at a time — stop dunst/mako before using this.

## theme switcher

a built-in theme picker with 15 themes across 3 families. toggle it via IPC:

```bash
qs ipc call theme toggle
```

bind it in `hyprland.conf`:

```
bind = SUPER, T, exec, qs ipc call theme toggle
```

available themes:
- **Tokyo Night** — Night, Storm, Moon, Light
- **Catppuccin** — Mocha, Macchiato, Frappe, Latte
- **Beared** — Arc, Surprising Eggplant, Oceanic, Solarized Dark, Coffee, Monokai Stone, Vivid Black

features:
- color swatches preview for each theme
- keyboard navigation (arrow keys, enter, escape)
- click backdrop to dismiss
- selected theme persists across restarts (saved to `~/.config/quickshell/theme.conf`)
- all components update instantly with smooth color transitions
- syncs with kitty terminal and system dark/light mode

## tweaking

- **colors** — all colors are in `theme-switcher/Theme.qml`. pick a theme via the switcher, or add your own by appending to the `themes` array.
- **font** — search for `"Hack Nerd Font"` and swap it with yours.
- **layout** — rearrange widgets in `bar/Bar.qml`.
- **polling rate** — change the interval in `bar/SystemInfo.qml` (default 2s).
- **adding a module** — create a folder with an entry QML file + `DefaultTheme.qml`, add `property var theme: DefaultTheme {}`, wire it in `shell.qml`.

## docs

architecture diagrams live in `docs/` as PlantUML files:

| Diagram | What it shows |
|---------|---------------|
| `architecture-overview.puml` | full system: modules, dependencies, theme wiring |
| `theme-flow.puml` | how theme propagates from singleton through all modules |
| `folder-structure.puml` | directory tree with role annotations |
| `module-contracts.puml` | class diagram of DefaultTheme, Theme, entry points, widgets |
| `ipc-commands.puml` | sequence diagram of all IPC commands |
| `data-flow.puml` | how data flows from system/D-Bus/Hyprland into widgets |
| `plug-unplug.puml` | activity diagram showing module independence |

render with `plantuml docs/*.puml` or paste into [plantuml.com](https://www.plantuml.com/plantuml/uml/).
