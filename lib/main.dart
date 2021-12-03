import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:personal_budget/bloc/balance_bloc.dart';
import 'package:personal_budget/screens/HomeScreen.dart';

void main() {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
  };
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MultiBlocProvider(
    providers: [
      BlocProvider(create: (_) => BalanceBloc()..add(LoadEvent())),
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
