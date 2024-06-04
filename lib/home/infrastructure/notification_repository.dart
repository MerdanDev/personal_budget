import 'dart:convert';

import 'package:wallet/core/shared_preference.dart';
import 'package:wallet/home/domain/scheduled_notification.dart';

class NotificationRepository {
  static Future<bool> setNotificationList(
    List<ScheduledNotification> data,
  ) async {
    return SingletonSharedPreference.setNotificationList(
      jsonEncode(data.map((e) => e.toMap()).toList()),
    );
  }

  static List<ScheduledNotification> getNotificationList() {
    final rawData = SingletonSharedPreference.loadNotificationList();
    if (rawData == null) {
      return [];
    } else {
      final decoded = jsonDecode(rawData) as List;

      return decoded
          .map((e) => ScheduledNotification.fromMap(e as Map<String, dynamic>))
          .toList();
    }
  }
}
