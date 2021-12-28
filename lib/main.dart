import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:personal_budget/bloc/balance_bloc.dart';
import 'package:personal_budget/bloc/data_bloc.dart' as d;
import 'package:personal_budget/screens/home_screen.dart';

void main() {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
  };
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MultiBlocProvider(
    providers: [
      BlocProvider(create: (_) => BalanceBloc()..add(LoadEvent())),
      BlocProvider(create: (_) => d.DataBloc()),
    ],
    child: MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gapjyk',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(title: 'Gapjyk'),
    );
  }
}
