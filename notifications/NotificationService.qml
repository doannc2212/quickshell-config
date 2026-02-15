pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
  id: root

  property list<Notification> notifications: []
  property bool doNotDisturb: false
  readonly property int count: notifications.length

  NotificationServer {
    id: server
    actionsSupported: true
    bodySupported: true
    bodyMarkupSupported: true
    imageSupported: true
    keepOnReload: false

    onNotification: notification => {
      notification.tracked = true;

      if (root.doNotDisturb) return;

      root.notifications = [notification, ...root.notifications];

      // Cap visible notifications at 5
      if (root.notifications.length > 5) {
        const old = root.notifications[root.notifications.length - 1];
        old.expire();
        root.notifications = root.notifications.slice(0, 5);
      }
    }
  }

  function dismiss(notification) {
    if (!notification) return;
    root.notifications = root.notifications.filter(n => n !== notification);
    notification.dismiss();
  }

  function expire(notification) {
    if (!notification) return;
    root.notifications = root.notifications.filter(n => n !== notification);
    notification.expire();
  }

  function invokeAction(notification, action) {
    if (!notification || !action) return;
    root.notifications = root.notifications.filter(n => n !== notification);
    action.invoke();
  }

  function dismissAll() {
    const toRemove = [...root.notifications];
    root.notifications = [];
    for (const n of toRemove) n.dismiss();
  }
}
