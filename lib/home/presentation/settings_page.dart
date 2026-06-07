import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wallet/core/currency_cubit.dart';
import 'package:wallet/counter/counter.dart';
import 'package:wallet/counter/domain/income_expense.dart';
import 'package:wallet/counter/infrastructure/counter_repository.dart';
import 'package:wallet/home/presentation/category_screen.dart';
import 'package:wallet/l10n/application/localization_cubit.dart';
import 'package:wallet/l10n/l10n.dart';

/// App Store id for the iOS listing. Empty until the iOS app is published —
/// fill it in then so the rate button can open the App Store on iOS.
const String _appStoreId = '';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Future<void> _editCurrency(BuildContext context, String current) async {
    final controller = TextEditingController(text: current);
    final symbol = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(context.l10n.currency),
          content: TextField(
            controller: controller,
            textAlign: TextAlign.center,
            textCapitalization: TextCapitalization.characters,
            autofocus: true,
            decoration: InputDecoration(
              labelText: context.l10n.currencySymbol,
              hintText: context.l10n.currencyHint,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: Text(context.l10n.save),
            ),
          ],
        );
      },
    );
    if (symbol != null) {
      await CurrencyCubit.instance.changeSymbol(symbol);
    }
  }

  Future<void> _restorePreUpdate(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final successMessage = context.l10n.restoreSuccess;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(context.l10n.restorePreUpdate),
          content: Text(context.l10n.restorePreUpdateConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.l10n.restorePreUpdate),
            ),
          ],
        );
      },
    );
    if (confirmed ?? false) {
      CounterBloc.instance.add(RestorePreUpdateBackup());
      // Let the bloc process the event (it restores and clears the snapshot)
      // before rebuilding so the now-redundant restore tile disappears.
      await Future<void>.delayed(Duration.zero);
      messenger.showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
      if (mounted) setState(() {});
    }
  }

  Future<void> _rateApp(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final failedMessage = context.l10n.rateAppFailed;
    final inAppReview = InAppReview.instance;
    try {
      // Open the store listing directly so the user can leave a review,
      // since the native in-app prompt may be silently throttled.
      await inAppReview.openStoreListing(
        appStoreId: _appStoreId,
      );
    } on Object {
      messenger.showSnackBar(
        SnackBar(content: Text(failedMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.settings),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.category_outlined),
            title: Text(context.l10n.categories),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<CategoryScreen>(
                  builder: (context) {
                    return const CategoryScreen();
                  },
                ),
              );
            },
          ),
          BlocBuilder<CurrencyCubit, String>(
            bloc: CurrencyCubit.instance,
            builder: (context, symbol) {
              return ListTile(
                leading: const Icon(Icons.payments_outlined),
                title: Text(context.l10n.currency),
                subtitle: symbol.isNotEmpty ? Text(symbol) : null,
                onTap: () => _editCurrency(context, symbol),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.backup_outlined),
            title: Text(context.l10n.backUp),
            onTap: () async {
              const name = 'back_up.csv';
              var dialogTitle = 'Please select an output file:';
              if (context.mounted) {
                dialogTitle = context.l10n.select_output_file;
              }

              final data = CounterBloc.instance.data;
              // User canceled the picker
              final directory = await getApplicationDocumentsDirectory();
              final file = File('${directory.path}/$name');
              final sink = file.openWrite();
              for (final item in data) {
                final row = item.toListString();
                sink
                  ..writeAll(row, ',')
                  ..writeln();
              }
              await sink.close();
              await file.create();

              final outputFile = await FilePicker.saveFile(
                dialogTitle: dialogTitle,
                fileName: name,
                type: FileType.custom,
                allowedExtensions: ['csv'],
                bytes: await file.readAsBytes(),
              );

              if (context.mounted && outputFile != null) {
                final snackBar = SnackBar(
                  content: Text('${context.l10n.save_success} $outputFile'),
                );
                ScaffoldMessenger.of(context).showSnackBar(snackBar);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_backup_restore),
            title: Text(context.l10n.restore_backUp),
            onTap: () async {
              final result = await FilePicker.pickFiles();

              if (result != null) {
                final file = File(result.files.single.path!);
                final list = await csvToIncomeExpense(file.path);
                CounterBloc.instance.add(RestoreBackUp(list: list));
              } else {
                // User canceled the picker
              }
            },
          ),
          if (CounterRepository.hasIncomeExpenseBackup())
            ListTile(
              leading: const Icon(Icons.restore),
              title: Text(context.l10n.restorePreUpdate),
              subtitle: Text(context.l10n.restorePreUpdateSubtitle),
              onTap: () => _restorePreUpdate(context),
            ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(context.l10n.languageSettings),
            onTap: () async {
              final selectedLanguage = await showDialog<String>(
                context: context,
                builder: (BuildContext context) {
                  return SimpleDialog(
                    title: Text(context.l10n.selectLanguage),
                    children: [
                      ListTile(
                        onTap: () => Navigator.pop(context, 'tk'),
                        title: const Text('Türkmen'),
                      ),
                      ListTile(
                        onTap: () => Navigator.pop(context, 'en'),
                        title: const Text('English'),
                      ),
                      ListTile(
                        onTap: () => Navigator.pop(context, 'ru'),
                        title: const Text('Русский'),
                      ),
                    ],
                  );
                },
              );
              if (selectedLanguage != null) {
                await LocalizationCubit.instance.changeLocale(selectedLanguage);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.star_outline),
            title: Text(context.l10n.rateApp),
            subtitle: Text(context.l10n.rateAppSubtitle),
            onTap: () => _rateApp(context),
          ),
        ],
      ),
    );
  }
}

Future<List<IncomeExpense>> csvToIncomeExpense(String filePath) async {
  final file = File(filePath);
  final lines = await file.readAsLines();
  final data = <IncomeExpense>[];
  for (final line in lines) {
    data.add(
      IncomeExpense.fromList(line.split(',')),
    );
  }
  return data;
}
