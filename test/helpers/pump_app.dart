import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet/core/currency_cubit.dart';
import 'package:wallet/counter/counter.dart';
import 'package:wallet/l10n/l10n.dart';

extension PumpApp on WidgetTester {
  /// Pumps [widget] wrapped in a [MaterialApp] configured with the app's
  /// localization delegates.
  ///
  /// [CurrencyCubit] is always provided: any widget rendering an amount reads
  /// it to format the symbol, so it is needed even when [withAppBlocs] is off.
  ///
  /// Set [withAppBlocs] to also provide the [CounterCubit] and [CounterBloc]
  /// that the counter pages depend on. Requires `initTestPreferences()` to have
  /// run first, since both read from shared preferences on creation.
  ///
  /// [CounterBloc] and [CurrencyCubit] are singletons, so they are provided
  /// with `.value` — `create:` would close the process-wide instance when the
  /// widget is disposed, breaking every later test in the file.
  Future<void> pumpApp(Widget widget, {bool withAppBlocs = false}) {
    final child = withAppBlocs
        ? MultiBlocProvider(
            providers: [
              BlocProvider<CounterCubit>(create: (_) => CounterCubit()),
              BlocProvider<CounterBloc>.value(value: CounterBloc()),
            ],
            child: widget,
          )
        : widget;

    return pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<CurrencyCubit>.value(
          value: CurrencyCubit(),
          child: child,
        ),
      ),
    );
  }
}
