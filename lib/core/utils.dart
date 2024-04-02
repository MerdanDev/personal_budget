bool isSameMonth(DateTime date1, DateTime date2) {
  return date1.year == date2.year && date1.month == date2.month;
}

bool isSameWeek(DateTime date1, DateTime date2) {
  final firstDayOfWeek1 = date1.subtract(
    Duration(
      days: date1.weekday - DateTime.monday,
    ),
  );
  final firstDayOfWeek2 = date2.subtract(
    Duration(
      days: date2.weekday - DateTime.monday,
    ),
  );

  return DateTime(
        firstDayOfWeek1.year,
        firstDayOfWeek1.month,
        firstDayOfWeek1.day,
      ) ==
      DateTime(
        firstDayOfWeek2.year,
        firstDayOfWeek2.month,
        firstDayOfWeek2.day,
      );
}

bool isSameDay(DateTime date1, DateTime date2) {
  return date1.year == date2.year &&
      date1.month == date2.month &&
      date1.day == date2.day;
}
