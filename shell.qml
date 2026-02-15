//@ pragma UseQApplication
//@ pragma Env QT_QPA_PLATFORMTHEME=gtk3
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QSG_RENDER_LOOP=threaded
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000

import Quickshell
import "bar"
import "app-launcher"
import "notifications"
import "theme-switcher"

Scope {
  ThemeSwitcher { id: ts }
  Bar { theme: ts.theme }
  AppLauncher { theme: ts.theme }
  NotificationPopup { theme: ts.theme }
}
