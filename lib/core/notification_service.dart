import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Channel used for locally scheduled reminders created inside the app.
  /// The id is kept as `channelId` for backwards compatibility with
  /// notifications scheduled by previous versions.
  static const AndroidNotificationChannel localChannel =
      AndroidNotificationChannel(
    'channelId',
    'Reminders',
    description: 'Scheduled reminders you create in the app.',
    importance: Importance.max,
  );

  /// Channel used to surface remote (FCM) push notifications. Its id must match
  /// the `com.google.firebase.messaging.default_notification_channel_id`
  /// meta-data declared in AndroidManifest.xml so that notifications shown by
  /// the system (background/terminated) and the ones we show manually
  /// (foreground) land on the same channel.
  static const AndroidNotificationChannel remoteChannel =
      AndroidNotificationChannel(
    'high_importance_channel',
    'Notifications',
    description: 'Push notifications sent to you.',
    importance: Importance.max,
  );

  Future<void> initNotification() async {
    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initializationSettingsIOS = DarwinInitializationSettings(
      // We let FCM/iOS request authorization (see PushNotificationService) so
      // the user is only prompted once. Requesting here too would be harmless
      // but redundant.
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) async {},
    );

    // Create the Android channels explicitly so both local reminders and
    // remote pushes have a well defined, non-conflicting channel.
    final androidPlugin =
        notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(localChannel);
    await androidPlugin?.createNotificationChannel(remoteChannel);
  }

  NotificationDetails notificationDetails() {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        localChannel.id,
        localChannel.name,
        channelDescription: localChannel.description,
        importance: Importance.max,
      ),
      iOS: const DarwinNotificationDetails(),
    );
  }

  NotificationDetails _remoteNotificationDetails() {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        remoteChannel.id,
        remoteChannel.name,
        channelDescription: remoteChannel.description,
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );
  }

  Future<void> showNotification({
    int id = 0,
    String? title,
    String? body,
    String? payLoad,
  }) async {
    return notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: notificationDetails(),
    );
  }

  /// Displays an incoming FCM [message] using the dedicated remote channel.
  ///
  /// This is only needed when a notification arrives while the app is in the
  /// foreground: on Android the system tray does NOT auto-display foreground
  /// messages, so we show them ourselves. Background/terminated messages are
  /// shown by the OS automatically, so calling this for those would create a
  /// duplicate notification.
  ///
  /// To avoid colliding with locally scheduled reminders (which use small
  /// sequential ids starting at 1) the notification id is derived from the
  /// message id and constrained to a positive 31-bit int.
  Future<void> showRemoteNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final id =
        (message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch) &
            0x7fffffff;

    return notificationsPlugin.show(
      id: id,
      title: notification.title,
      body: notification.body,
      notificationDetails: _remoteNotificationDetails(),
      payload: message.data.isEmpty ? null : message.data.toString(),
    );
  }

  Future<List<PendingNotificationRequest>> getPendingList() async {
    await scheduleNotification(
      scheduledNotificationDateTime:
          DateTime.now().add(const Duration(minutes: 1)),
      title: 'Scheduled',
      id: 3,
    );
    final list = await notificationsPlugin.pendingNotificationRequests();

    return list;
  }

  Future<void> deleteNotification(int id) async {
    return notificationsPlugin.cancel(id: id);
  }

  Future<void> scheduleNotification({
    required DateTime scheduledNotificationDateTime,
    int id = 0,
    String? title,
    String? body,
    String? payLoad,
  }) async {
    return notificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(
        scheduledNotificationDateTime,
        tz.local,
      ),
      notificationDetails: notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}
