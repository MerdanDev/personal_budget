import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet/counter/counter.dart';
import 'package:wallet/l10n/l10n.dart';

extension PumpApp on WidgetTester {
  /// Pumps [widget] wrapped in a [MaterialApp] configured with the app's
  /// localization delegates.
  ///
  /// Set [withAppBlocs] to provide the [CounterCubit] and [CounterBloc] that
  /// the counter pages depend on. Requires `initTestPreferences()` to have run
  /// first, since [CounterBloc] reads from shared preferences on creation.
  Future<void> pumpApp(Widget widget, {bool withAppBlocs = false}) {
    final child = withAppBlocs
        ? MultiBlocProvider(
            providers: [
              BlocProvider<CounterCubit>(create: (_) => CounterCubit()),
              BlocProvider<CounterBloc>(create: (_) => CounterBloc()),
            ],
            child: widget,
          )
        : widget;

    return pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );
  }
}
