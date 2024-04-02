import 'package:flutter/material.dart';

enum DateFilter {
  day(iconData: Icons.calendar_view_day),
  week(iconData: Icons.calendar_view_week),
  month(iconData: Icons.calendar_view_month),
  // quarterMonth(iconData: Icons.date_range),
  // halfMonth(iconData: Icons.calendar_month),
  year(iconData: Icons.event_available),
  all(iconData: Icons.all_inclusive);

  const DateFilter({required this.iconData});

  final IconData iconData;

  static DateFilter fromString(String? value) {
    if ('week' == value) {
      return week;
    } else if ('month' == value) {
      return month;
      // } else if ('quarterMonth' == value) {
      //   return quarterMonth;
      // } else if ('halfMonth' == value) {
      //   return halfMonth;
    } else if ('year' == value) {
      return year;
    } else {
      return all;
    }
  }
}
