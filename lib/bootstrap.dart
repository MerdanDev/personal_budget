import 'dart:async';
import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:wallet/core/analytics_service.dart';
import 'package:wallet/core/currency_cubit.dart';
import 'package:wallet/core/notification_service.dart';
import 'package:wallet/core/push_notification_service.dart';
import 'package:wallet/core/shared_preference.dart';
import 'package:wallet/core/widget_service.dart';
import 'package:wallet/counter/bloc/bloc.dart';
import 'package:wallet/counter/cubit/counter_cubit.dart';
import 'package:wallet/firebase_options.dart';

class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    log('onChange(${bloc.runtimeType}, $change)');
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    log('onError(${bloc.runtimeType}, $error, $stackTrace)');
    super.onError(bloc, error, stackTrace);
  }
}

Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
  FlutterError.onError = (details) {
    log(details.exceptionAsString(), stackTrace: details.stack);
  };
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Anonymous usage analytics (DAU/WAU/MAU) — no user is identified.
  await AnalyticsService.init();

  final notificationService = NotificationService();
  await notificationService.initNotification();
  // Wire FCM up after the local plugin so its Android channels already exist
  // and foreground pushes can be rendered through the same plugin.
  await PushNotificationService(notificationService).init();

  tz.initializeTimeZones();

  Bloc.observer = const AppBlocObserver();
  final pref = await SharedPreferences.getInstance();
  SingletonSharedPreference.init(pref);

  // Bridge balance/income/expense to the home-screen widget and start
  // listening for its button taps. Reads persisted data directly, so it only
  // needs SharedPreferences to be ready.
  await WidgetService.init();

  // Add cross-flavor configuration here

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => CounterCubit(),
        ),
        BlocProvider(
          create: (_) => CounterBloc(),
        ),
        BlocProvider(
          create: (_) => CurrencyCubit(),
        ),
      ],
      child: await builder(),
    ),
  );
}
