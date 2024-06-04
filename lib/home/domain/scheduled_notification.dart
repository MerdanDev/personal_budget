class ScheduledNotification {
  ScheduledNotification({
    required this.id,
    required this.dateTime,
    this.title,
    this.body,
    this.payLoad,
  });
  factory ScheduledNotification.fromMap(Map<String, dynamic> map) {
    return ScheduledNotification(
      id: map['id'] as int,
      title: map['title'] as String?,
      body: map['body'] as String?,
      payLoad: map['payLoad'] as String?,
      dateTime: DateTime.parse(map['dateTime'] as String),
    );
  }

  final int id;
  final String? title;
  final String? body;
  final String? payLoad;
  final DateTime dateTime;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'payLoad': payLoad,
      'dateTime': dateTime.toString(),
    };
  }
}
