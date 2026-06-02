import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:wallet/core/notification_service.dart';
import 'package:wallet/firebase_options.dart';

/// Global navigator key so notification taps (which originate outside the
/// widget tree) can present UI. Wired into [MaterialApp.navigatorKey] in
/// `lib/app/view/app.dart`.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Background / terminated message handler.
///
/// Must be a top-level (or static) function so it can be invoked from the
/// background FlutterEngine isolate. Firebase has to be re-initialized here
/// because this runs in its own isolate that does not share state with `main`.
///
/// When the FCM message carries a `notification` block, the OS already renders
/// it in the system tray on its own — so we must NOT re-display it here, that
/// would duplicate the notification. We only need this handler for processing
/// `data`-only messages or doing background work.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  log('Handling a background FCM message: ${message.messageId}');
}

/// Wraps [FirebaseMessaging] and coordinates it with the local notification
/// plugin so the two notification sources do not conflict.
class PushNotificationService {
  PushNotificationService(this._notificationService);

  final NotificationService _notificationService;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Initializes FCM. Assumes [Firebase.initializeApp] has already run and the
  /// local notification plugin (and its Android channels) is already set up.
  Future<void> init() async {
    // 1. Permission. Going through FirebaseMessaging requests the single
    // UNUserNotificationCenter authorization on iOS/macOS and POST_NOTIFICATIONS
    // on Android 13+, so we don't prompt twice from the local plugin.
    await _messaging.requestPermission();

    // 2. Register the background handler (no-op display, see above).
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 3. Foreground presentation.
    //
    // iOS/macOS: ask the OS to show the banner itself while in foreground.
    // Android: there is no such option, so we display foreground messages
    // manually via the local notification plugin (see onMessage below). If we
    // also enabled OS presentation on iOS *and* displayed manually, iOS would
    // show two notifications — so the manual display is gated to Android only.
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 4. Foreground messages.
    FirebaseMessaging.onMessage.listen((message) {
      log('Foreground FCM message: ${message.messageId}');
      // Only Android needs manual rendering; iOS/macOS is handled by the
      // presentation options above to avoid duplicate banners. Guard against
      // web where the local notification plugin is unavailable.
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        _notificationService.showRemoteNotification(message);
      }
    });

    // 5. App opened from a notification (background -> foreground tap).
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpened);

    // 6. App launched from terminated state by tapping a notification.
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpened(initialMessage);
    }

    // 7. Token. Send this to your backend / topic so the device can be
    // targeted. Logged for now.
    final token = await _messaging.getToken();
    log('FCM token: $token');
    _messaging.onTokenRefresh.listen((newToken) {
      log('FCM token refreshed: $newToken');
    });
  }

  void _handleMessageOpened(RemoteMessage message) {
    log('Notification opened app: ${message.messageId} data=${message.data}');

    final title =
        message.notification?.title ?? message.data['title'] as String?;
    final body = message.notification?.body ??
        message.data['body'] as String? ??
        (message.data.isEmpty ? null : message.data.toString());

    if (title == null && body == null) return;

    // Taps from the terminated state run during bootstrap (before the first
    // frame), so defer until the navigator exists.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = navigatorKey.currentContext;
      if (context == null) return;
      showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: title == null ? null : Text(title),
            content:
                body == null ? null : SingleChildScrollView(child: Text(body)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(MaterialLocalizations.of(context).okButtonLabel),
              ),
            ],
          );
        },
      );
    });
  }

  /// Subscribe to a topic to receive broadcast pushes (e.g. announcements).
  Future<void> subscribeToTopic(String topic) =>
      _messaging.subscribeToTopic(topic);

  Future<void> unsubscribeFromTopic(String topic) =>
      _messaging.unsubscribeFromTopic(topic);

  Future<String?> getToken() => _messaging.getToken();
}
