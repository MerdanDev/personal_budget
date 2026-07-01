import 'dart:async';
import 'dart:convert';

import 'package:wallet/core/shared_preference.dart';
import 'package:wallet/core/widget_service.dart';
import 'package:wallet/counter/domain/category_budget.dart';
import 'package:wallet/counter/domain/counter_category.dart';
import 'package:wallet/counter/domain/date_filter.dart';
import 'package:wallet/counter/domain/income_expense.dart';

class CounterRepository {
  static Future<bool> setIncomeExpenseList(List<IncomeExpense> data) async {
    final result = await SingletonSharedPreference.setIncomeExpenseList(
      jsonEncode(data.map((e) => e.toMap()).toList()),
    );
    // Keep the home-screen widget in step with every add/edit/delete. Fire and
    // forget — widget refresh must never delay or fail the data write.
    unawaited(WidgetService.sync());
    return result;
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

  /// Whether a pre-migration snapshot of the income/expense data exists.
  static bool hasIncomeExpenseBackup() {
    final raw = SingletonSharedPreference.loadIncomeExpenseBackup();
    return raw != null && raw.isNotEmpty;
  }

  /// Decodes the one-time snapshot taken before the title→category migration,
  /// or null if none was stored.
  static List<IncomeExpense>? getIncomeExpenseBackup() {
    final raw = SingletonSharedPreference.loadIncomeExpenseBackup();
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final decoded = jsonDecode(raw) as List;
    return decoded
        .map((e) => IncomeExpense.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  /// Drops the pre-migration snapshot once it is no longer needed (e.g. after
  /// a restore), so it cannot later overwrite newer data.
  static Future<bool> clearIncomeExpenseBackup() {
    return SingletonSharedPreference.clearIncomeExpenseBackup();
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

  static Future<bool> setCategoryBudgetList(List<CategoryBudget> data) async {
    return SingletonSharedPreference.setCategoryBudgetList(
      jsonEncode(data.map((e) => e.toMap()).toList()),
    );
  }

  static List<CategoryBudget> getCategoryBudgetList() {
    final rawData = SingletonSharedPreference.loadCategoryBudgetList();
    if (rawData == null) {
      return [];
    } else {
      final decoded = jsonDecode(rawData) as List;

      return decoded
          .map((e) => CategoryBudget.fromMap(e as Map<String, dynamic>))
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
