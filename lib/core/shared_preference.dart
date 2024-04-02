import 'package:shared_preferences/shared_preferences.dart';
import 'package:wallet/core/key_data.dart';

class SingletonSharedPreference {
  factory SingletonSharedPreference() {
    return instance;
  }
  SingletonSharedPreference._internal(this._pref);

  static void init(SharedPreferences pref) {
    instance = SingletonSharedPreference._internal(pref);
  }

  static late SingletonSharedPreference instance;

  final SharedPreferences _pref;

  static String? loadIncomeExpenseList() {
    return instance._pref.getString(KeyData.incomeExpenseList);
  }

  static Future<bool> setIncomeExpenseList(String data) {
    return instance._pref.setString(KeyData.incomeExpenseList, data);
  }

  static String? loadCounterCategory() {
    return instance._pref.getString(KeyData.counterCategoryList);
  }

  static Future<bool> setCounterCategory(String data) {
    return instance._pref.setString(KeyData.counterCategoryList, data);
  }

  static String? loadDateFilter() {
    return instance._pref.getString(KeyData.dateFilterState);
  }

  static Future<bool> setDateFilter(String data) {
    return instance._pref.setString(KeyData.dateFilterState, data);
  }
}
