import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:wallet/core/currency_cubit.dart';
import 'package:wallet/core/push_notification_service.dart';
import 'package:wallet/core/shared_preference.dart';
import 'package:wallet/counter/infrastructure/counter_repository.dart';
import 'package:wallet/counter/presentation/widgets/add_income_expense_dialog.dart';
import 'package:wallet/l10n/application/localization_cubit.dart';
import 'package:wallet/l10n/arb/app_localizations.dart';

/// Bridges the app's balance/income/expense figures to the native home-screen
/// widgets (Android RemoteViews + iOS WidgetKit) and routes widget button taps
/// back into the app's add dialog.
///
/// Data is written through `home_widget`'s shared storage — a private
/// SharedPreferences file on Android and an App Group on iOS — which the
/// native widget then reads. The widget never mutates data itself; its buttons
/// deep-link into the app via [_scheme] URIs so the user lands on the add
/// dialog where an amount can be entered.
///
/// Tap delivery differs per platform:
///  * Android — `home_widget` reports the launching intent (matched by action),
///    surfaced via [HomeWidget.widgetClicked] /
///    [HomeWidget.initiallyLaunchedFromHomeWidget].
///  * iOS — the app runs under `FlutterSceneDelegate`, where `home_widget`'s
///    URL hooks (`application:openURL:`) are never called. A custom
///    `SceneDelegate` captures the URL instead and forwards it over
///    [_iosChannel].
class WidgetService {
  WidgetService._();

  /// iOS App Group that the Runner target and the widget extension both join.
  /// Must match the group declared in the entitlements of both targets.
  static const String _appGroupId = 'group.dev.merdan.wallet';

  /// Android widget provider class, fully qualified. Used to target updates.
  static const String _androidProviderName = 'WalletWidgetProvider';

  /// iOS WidgetKit widget kind, as declared in the Swift `Widget` definition.
  static const String _iOSWidgetName = 'WalletWidget';

  /// Custom URI scheme the widget buttons launch the app with. The native
  /// layouts build the deep links below verbatim, so keep them in sync:
  ///   expense → `wallet://add?type=expense`
  ///   income  → `wallet://add?type=income`
  static const String _scheme = 'wallet';

  /// Channel the iOS `SceneDelegate` uses to hand widget-tap URLs to Flutter.
  /// `onUri` is invoked for taps while running; `getInitial` is pulled at
  /// startup for the URL that cold-launched the app.
  static const MethodChannel _iosChannel =
      MethodChannel('dev.merdan.wallet/widget');

  // Shared-storage keys read by the native widget layouts.
  static const String _kBalance = 'balance';
  static const String _kIncome = 'income';
  static const String _kExpense = 'expense';
  static const String _kBalanceNegative = 'balance_negative';
  static const String _kAddExpenseLabel = 'add_expense';
  static const String _kAddIncomeLabel = 'add_income';

  static bool _initialized = false;

  /// The most recent tap awaiting navigation. Held until the navigator is
  /// mounted (cold launch) and onboarding is complete.
  static Uri? _pendingUri;

  /// Registers the app group, wires up tap handling, and pushes an initial
  /// snapshot. Call once at startup after SharedPreferences is ready.
  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    await HomeWidget.setAppGroupId(_appGroupId);

    // Android: home_widget reports the launching/relaunching intent.
    HomeWidget.widgetClicked.listen(_handleUri);
    unawaited(HomeWidget.initiallyLaunchedFromHomeWidget().then(_handleUri));

    // iOS: taps arrive over the custom scene channel instead.
    if (Platform.isIOS) {
      _iosChannel.setMethodCallHandler((call) async {
        if (call.method == 'onUri') {
          _handleUri(_tryParse(call.arguments));
        }
        return null;
      });
      unawaited(_consumeIosInitial());
    }

    await sync();
  }

  /// Recomputes the all-time totals from persisted data and pushes them to the
  /// native widget. Safe to call after any mutation; failures are swallowed so
  /// widget syncing never breaks the main flow.
  static Future<void> sync() async {
    try {
      final data = CounterRepository.getIncomeExpenseList();
      final symbol = CurrencyCubit.instance.state;

      var income = 0.0;
      var expense = 0.0;
      for (final e in data) {
        if (e.amount > 0) {
          income += e.amount;
        } else {
          expense += e.amount;
        }
      }
      final balance = income + expense; // expense is stored negative.

      await HomeWidget.saveWidgetData<String>(
        _kBalance,
        formatAmount(balance, symbol),
      );
      await HomeWidget.saveWidgetData<String>(
        _kIncome,
        formatAmount(income, symbol),
      );
      await HomeWidget.saveWidgetData<String>(
        _kExpense,
        formatAmount(expense.abs(), symbol),
      );
      await HomeWidget.saveWidgetData<bool>(_kBalanceNegative, balance < 0);

      // Push the button labels in the app's currently selected language so the
      // native widget text matches the in-app locale (which can differ from
      // the device locale via the in-app language override).
      final l10n = _localizations();
      await HomeWidget.saveWidgetData<String>(
        _kAddExpenseLabel,
        l10n.addExpense,
      );
      await HomeWidget.saveWidgetData<String>(_kAddIncomeLabel, l10n.addIncome);

      await HomeWidget.updateWidget(
        androidName: _androidProviderName,
        iOSName: _iOSWidgetName,
      );
    } catch (_) {
      // Widget storage may be unavailable on web/desktop or if the platform
      // channel is missing; never let that bubble into business logic.
    }
  }

  /// Pulls the URL that cold-launched the app from the iOS scene channel,
  /// retrying briefly because the `SceneDelegate` may not have created the
  /// channel yet when this runs during bootstrap.
  static Future<void> _consumeIosInitial() async {
    for (var attempt = 0; attempt < 20; attempt++) {
      try {
        final initial = await _iosChannel.invokeMethod<String>('getInitial');
        if (initial != null) _handleUri(Uri.tryParse(initial));
        return;
      } on MissingPluginException {
        await Future<void>.delayed(const Duration(milliseconds: 150));
      } catch (_) {
        return;
      }
    }
  }

  static Uri? _tryParse(Object? value) =>
      value is String ? Uri.tryParse(value) : null;

  /// Resolves [AppLocalizations] for the app's selected locale without a
  /// BuildContext. Falls back to English if that locale isn't supported, so a
  /// device-locale default never aborts the widget sync.
  static AppLocalizations _localizations() {
    final locale = LocalizationCubit.instance.state;
    try {
      return lookupAppLocalizations(Locale(locale.languageCode));
    } catch (_) {
      return lookupAppLocalizations(const Locale('en'));
    }
  }

  /// Validates a widget deep link and queues it for navigation.
  static void _handleUri(Uri? uri) {
    if (uri == null) return;
    if (uri.scheme != _scheme || uri.host != 'add') return;
    _pendingUri = uri;
    unawaited(_consumePending());
  }

  /// Opens the add dialog matching the queued tap. Waits for the navigator to
  /// mount (cold launch delivers the tap during bootstrap, before `runApp`
  /// builds the widget tree) and routes through the global [navigatorKey]
  /// because the tap is handled outside any widget's build context.
  static Future<void> _consumePending() async {
    final uri = _pendingUri;
    if (uri == null) return;

    for (var i = 0; navigatorKey.currentState == null && i < 50; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;

    // A widget on the home screen implies onboarding is done, but guard so we
    // never push the add dialog over the onboarding flow.
    if (!SingletonSharedPreference.loadOnboardingCompleted()) {
      _pendingUri = null;
      return;
    }

    // Superseded by a newer tap while we were waiting.
    if (!identical(_pendingUri, uri)) return;
    _pendingUri = null;

    final isMinus = uri.queryParameters['type'] != 'income';
    await navigator.push<void>(
      MaterialPageRoute<void>(
        builder: (_) => IncomeExpenseDialog(isMinus: isMinus),
        fullscreenDialog: true,
      ),
    );
  }
}
