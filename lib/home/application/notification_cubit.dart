import 'package:bloc/bloc.dart';
import 'package:wallet/core/notification_service.dart';
import 'package:wallet/home/domain/scheduled_notification.dart';
import 'package:wallet/home/infrastructure/notification_repository.dart';

class NotificationCubit extends Cubit<List<ScheduledNotification>> {
  factory NotificationCubit() => instance;

  NotificationCubit._internal() : super([]) {
    final data = NotificationRepository.getNotificationList()
      ..removeWhere(
        (element) => 0 < DateTime.now().compareTo(element.dateTime),
      );
    NotificationRepository.setNotificationList(data);
    emit(data);
  }

  static NotificationCubit instance = NotificationCubit._internal();

  void addNotification({
    required DateTime dateTime,
    String? title,
    String? body,
    String? payLoad,
  }) {
    late final int id;
    if (state.isEmpty) {
      id = 1;
    } else {
      id = state.last.id + 1;
    }
    final data = [
      ...state,
      ScheduledNotification(
        id: id,
        dateTime: dateTime,
        body: body,
        title: title,
        payLoad: payLoad,
      ),
    ];

    NotificationService().scheduleNotification(
      scheduledNotificationDateTime: dateTime,
      body: body,
      title: title,
    );
    NotificationRepository.setNotificationList(data);
    emit(data);
  }

  void deleteNotification(int id) {
    final data = [
      ...state..removeWhere((element) => element.id == id),
    ];

    NotificationService().deleteNotification(id);
    NotificationRepository.setNotificationList(data);
    emit(data);
  }
}
