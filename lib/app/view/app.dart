import 'package:flutter/material.dart';
import 'package:wallet/core/color_schemes.g.dart';
import 'package:wallet/counter/counter.dart';
import 'package:wallet/l10n/l10n.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      darkTheme: ThemeData.dark().copyWith(
        colorScheme: darkColorScheme,
      ),
      theme: ThemeData(
        appBarTheme: AppBarTheme(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        useMaterial3: true,
        colorScheme: lightColorScheme,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const CounterPage(),
    );
  }
}