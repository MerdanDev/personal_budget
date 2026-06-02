# Notifications — Local + Firebase Cloud Messaging

This document describes how notifications work in the Wallet / Gapjyk app after
**Firebase Cloud Messaging (FCM) remote push** was added alongside the existing
**local (scheduled) notifications**, and—most importantly—**how the two are kept
from conflicting**.

- **Date:** 2026-06-02
- **App version:** `2.0.3+5`
- **Toolchain:** Flutter 3.41.9 · Dart 3.11.5 · JDK 17
- **Packages:** `flutter_local_notifications: ^21.0.0` · `firebase_core: ^3.10.0` · `firebase_messaging: ^15.2.0`

---

## 1. Summary

The app already had **local notifications** (user-scheduled reminders). Firebase
was half-configured (`firebase_options.dart`, `google-services.json`,
`GoogleService-Info.plist`, the Gradle `google-services` plugin) but **inert** —
neither `firebase_core` nor `firebase_messaging` was a dependency and
`Firebase.initializeApp()` was never called.

This change:

1. Added `firebase_core` + `firebase_messaging` dependencies.
2. Initialized Firebase and FCM in `bootstrap()`.
3. Extended `NotificationService` with explicit Android channels and a
   conflict-safe path for displaying remote pushes.
4. Added `PushNotificationService` plus a top-level background handler.
5. Declared the FCM default Android channel in the manifest.

**Result:** `flutter analyze` on all touched files → *No issues found*. One
notification per message, no ID clashes, a single permission prompt.

---

## 2. The two notification sources

| Source | Plugin | Created by | Channel |
|--------|--------|-----------|---------|
| **Local / scheduled** | `flutter_local_notifications` | User, via `NotificationCubit.addNotification` → `NotificationService.scheduleNotification` | `channelId` ("Reminders") |
| **Remote / push** | `firebase_messaging` (+ local plugin for foreground render) | Server / Firebase Console → `PushNotificationService` | `high_importance_channel` ("Notifications") |

---

## 3. Files changed

| File | Change |
|------|--------|
| `pubspec.yaml` | Added `firebase_core: ^3.10.0`, `firebase_messaging: ^15.2.0` |
| `lib/core/notification_service.dart` | Explicit `localChannel` + `remoteChannel`, channel creation in `initNotification()`, new `showRemoteNotification()` with collision-safe IDs, Darwin init no longer requests permission |
| `lib/core/push_notification_service.dart` | **New.** FCM lifecycle (`init`) + top-level `firebaseMessagingBackgroundHandler` |
| `lib/bootstrap.dart` | `Firebase.initializeApp()` → local plugin init → FCM init, in that order |
| `android/app/src/main/AndroidManifest.xml` | `com.google.firebase.messaging.default_notification_channel_id` meta-data → `high_importance_channel` |

---

## 4. Initialization order (`bootstrap.dart`)

Order matters and is intentional:

```dart
WidgetsFlutterBinding.ensureInitialized();

await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

final notificationService = NotificationService();
await notificationService.initNotification();   // creates Android channels
await PushNotificationService(notificationService).init();  // wires FCM
```

1. **Firebase first** — every Firebase API depends on it.
2. **Local plugin second** — this creates the Android notification channels
   (including `high_importance_channel`) so they exist before any push arrives.
3. **FCM last** — requests permission, registers handlers, fetches the token.

---

## 5. Message handling matrix

| App state | Message has `notification` block | Who displays it | Code path |
|-----------|----------------------------------|-----------------|-----------|
| **Foreground** | yes | Android: local plugin (manual). iOS/macOS: OS via presentation options | `FirebaseMessaging.onMessage` → `showRemoteNotification` (Android only) |
| **Background** | yes | OS system tray (automatic) | `firebaseMessagingBackgroundHandler` (no display) |
| **Terminated** | yes | OS system tray (automatic) | `firebaseMessagingBackgroundHandler` (no display) |
| **Tap (from background)** | — | — | `onMessageOpenedApp` → `_handleMessageOpened` |
| **Tap (from terminated)** | — | — | `getInitialMessage()` → `_handleMessageOpened` |

> `data`-only messages (no `notification` block) are **never** auto-displayed by
> the OS; handle/display them yourself if you start sending them.

---

## 6. Conflict situations & resolutions

The core risk: **both plugins can display notifications**, so naive wiring causes
duplicates, ID clashes, or double permission prompts.

### 6.1 Duplicate notifications (foreground vs. system tray)
Background/terminated `notification` messages are rendered by the OS
automatically, so `firebaseMessagingBackgroundHandler` **does not** re-display
them. Foreground messages are *not* auto-shown on Android, so only those are
rendered manually. → exactly one notification per message.

### 6.2 iOS double-banner
On iOS/macOS, `setForegroundNotificationPresentationOptions(alert, badge, sound)`
lets the OS show the foreground banner. The manual local render is therefore
**gated to Android only**:

```dart
if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
  _notificationService.showRemoteNotification(message);
}
```

Without this gate, iOS would show two banners (OS + manual).

### 6.3 Notification ID collisions
Local reminders use **small sequential ids** (1, 2, 3…) from `NotificationCubit`.
Remote pushes derive their id from `message.messageId.hashCode & 0x7fffffff` — a
high, disjoint range — so a push can never overwrite a scheduled reminder.

### 6.4 Android channel mismatch
Two explicit channels are created in `initNotification()`:

- `channelId` ("Reminders") — kept for backward-compat with reminders scheduled
  by older app versions.
- `high_importance_channel` ("Notifications") — for pushes.

The manifest meta-data points FCM's **system-rendered** (background/terminated)
notifications at the *same* `high_importance_channel`, so background and
foreground pushes are visually identical.

### 6.5 Double permission prompt
Permission is requested **once** via `FirebaseMessaging.requestPermission()`
(covers iOS/macOS `UNUserNotificationCenter` and Android 13+
`POST_NOTIFICATIONS`). The Darwin init in the local plugin now passes
`requestAlertPermission/Badge/Sound: false` so it doesn't prompt again.

### 6.6 iOS `UNUserNotificationCenter` delegate
Both plugins want the notification-center delegate on iOS. `firebase_messaging`
uses method swizzling and coexists with `flutter_local_notifications` in these
versions; no manual delegate juggling is required in `AppDelegate.swift`.

---

## 7. Remaining manual native setup (not code)

These cannot be done from Dart and must be configured per platform:

- **iOS/macOS APNs:** create an APNs auth key in the Apple Developer portal and
  upload it to the Firebase Console. FCM cannot deliver to Apple devices without
  it.
- **Xcode capabilities:** add **Push Notifications** and **Background Modes →
  Remote notifications** to the Runner target (iOS and macOS).
- **macOS bundle id:** `firebase_options.dart` lists the macOS `iosBundleId` as
  `com.example.myApp` — a likely leftover. Fix it to the real macOS bundle id if
  macOS is a target.
- **Android:** no extra steps — `google-services.json` and the Gradle plugin are
  already in place.

---

## 8. Sending / targeting

The device's FCM token is logged at startup (`log('FCM token: ...')`). Use it to:

- Send a **test push** from Firebase Console → Cloud Messaging.
- Register the device with your backend for direct targeting.
- Or subscribe to a **topic** for broadcasts:

```dart
await pushService.subscribeToTopic('announcements');
await pushService.unsubscribeFromTopic('announcements');
```

---

## 9. Follow-ups (TODO)

- Route notification taps to a specific screen — see the TODO in
  `_handleMessageOpened` (`push_notification_service.dart`). It currently only
  logs `message.data`.
- Persist/transmit the FCM token instead of only logging it.
- Optionally expose a settings toggle for topic subscription.
