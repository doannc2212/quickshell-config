pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
  id: root

  property list<Notification> notifications: []
  property bool doNotDisturb: false
  readonly property int count: notifications.length

  // Expiry timers managed here so model resets don't reset countdowns
  property var _timers: []

  Component {
    id: timerComponent
    Timer {
      property var notif: null
      repeat: false
    }
  }

  function _scheduleExpiry(notification) {
    if (notification.urgency === NotificationUrgency.Critical) return;
    const timeout = notification.expireTimeout > 0 ? notification.expireTimeout * 1000 : 5000;
    const t = timerComponent.createObject(root, { interval: timeout, notif: notification });
    t.triggered.connect(function() { root.expire(t.notif); });
    t.start();
    root._timers = [...root._timers, { notification: notification, timer: t }];
  }

  function _cancelExpiry(notification) {
    const entry = root._timers.find(e => e.notification === notification);
    if (entry) {
      entry.timer.stop();
      entry.timer.destroy();
      root._timers = root._timers.filter(e => e.notification !== notification);
    }
  }

  NotificationServer {
    id: server
    actionsSupported: true
    bodySupported: true
    bodyMarkupSupported: true
    imageSupported: true
    keepOnReload: false

    onNotification: notification => {
      if (root.doNotDisturb) return;

      // Skip empty notifications (no app name, summary, body, or image)
      if (!notification.appName && !notification.summary && !notification.body && !notification.image) return;

      notification.tracked = true;

      // Cancel existing timer for this notification (handles replaces_id updates)
      root._cancelExpiry(notification);

      // Deduplicate: remove existing entry before prepending
      root.notifications = [notification, ...root.notifications.filter(n => n !== notification)];

      root._scheduleExpiry(notification);

      // Cap visible notifications at 5
      if (root.notifications.length > 5) {
        root.expire(root.notifications[root.notifications.length - 1]);
      }
    }
  }

  function _safeCall(fn) {
    try { fn(); } catch(e) {}
  }

  function dismiss(notification) {
    if (!notification) return;
    root._cancelExpiry(notification);
    root.notifications = root.notifications.filter(n => n !== notification);
    _safeCall(() => notification.dismiss());
  }

  function expire(notification) {
    if (!notification) return;
    root._cancelExpiry(notification);
    root.notifications = root.notifications.filter(n => n !== notification);
    _safeCall(() => notification.dismiss());
  }

  function invokeAction(notification, action) {
    if (!notification || !action) return;
    root._cancelExpiry(notification);
    root.notifications = root.notifications.filter(n => n !== notification);
    _safeCall(() => action.invoke());
  }

  function dismissAll() {
    const toRemove = [...root.notifications];
    root.notifications = [];
    for (const entry of root._timers) {
      entry.timer.stop();
      entry.timer.destroy();
    }
    root._timers = [];
    for (const n of toRemove) if (n) _safeCall(() => n.dismiss());
  }
}
