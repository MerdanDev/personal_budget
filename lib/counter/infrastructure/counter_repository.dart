import 'dart:convert';

import 'package:wallet/core/shared_preference.dart';
import 'package:wallet/counter/domain/counter_category.dart';
import 'package:wallet/counter/domain/date_filter.dart';
import 'package:wallet/counter/domain/income_expense.dart';

class CounterRepository {
  static Future<bool> setIncomeExpenseList(List<IncomeExpense> data) async {
    return SingletonSharedPreference.setIncomeExpenseList(
      jsonEncode(data.map((e) => e.toMap()).toList()),
    );
  }

  static List<IncomeExpense> getIncomeExpenseList() {
    final rawData = SingletonSharedPreference.loadIncomeExpenseList();
    if (rawData == null) {
      return [];
    } else {
      final decoded = jsonDecode(rawData) as List;

      return decoded
          .map((e) => IncomeExpense.fromMap(e as Map<String, dynamic>))
          .toList();
    }
  }

  static Future<bool> setCounterCategoryList(List<CounterCategory> data) async {
    return SingletonSharedPreference.setCounterCategory(
      jsonEncode(data.map((e) => e.toMap()).toList()),
    );
  }

  static List<CounterCategory> getCounterCategoryList() {
    final rawData = SingletonSharedPreference.loadCounterCategory();
    if (rawData == null) {
      return [];
    } else {
      final decoded = jsonDecode(rawData) as List;

      return decoded
          .map((e) => CounterCategory.fromMap(e as Map<String, dynamic>))
          .toList();
    }
  }

  static Future<bool> setDateFilter(DateFilter dateFilter) async {
    return SingletonSharedPreference.setDateFilter(dateFilter.name);
  }

  static DateFilter getDateFilter() {
    return DateFilter.fromString(SingletonSharedPreference.loadDateFilter());
  }
}
