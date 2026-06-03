import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:wallet/core/shared_preference.dart';
import 'package:wallet/core/widget_service.dart';

/// Holds the currency symbol shown next to every monetary amount. It is a
/// free-text value chosen during onboarding (and editable in settings), so it
/// can be a sign like `$`/`€` or a short code like `TMT`/`m`.
class CurrencyCubit extends Cubit<String> {
  factory CurrencyCubit() => instance;
  CurrencyCubit._internal()
      : super(SingletonSharedPreference.loadCurrencySymbol() ?? defaultSymbol);

  static final CurrencyCubit instance = CurrencyCubit._internal();

  static const String defaultSymbol = 'TMT';

  Future<void> changeSymbol(String symbol) async {
    final trimmed = symbol.trim();
    if (trimmed == state) return;
    await SingletonSharedPreference.setCurrencySymbol(trimmed);
    emit(trimmed);
    // Re-render the widget so its amounts pick up the new symbol.
    unawaited(WidgetService.sync());
  }
}

/// Formats [amount] with two decimals and appends the currency [symbol] when
/// one is set, e.g. `12.50 TMT`. Falls back to the bare number for an empty
/// symbol.
String formatAmount(double amount, String symbol) {
  final value = amount.toStringAsFixed(2);
  return symbol.isEmpty ? value : '$value $symbol';
}
