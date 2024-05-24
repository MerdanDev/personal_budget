import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wallet/counter/counter.dart';
import 'package:wallet/counter/domain/income_expense.dart';
import 'package:wallet/home/presentation/category_screen.dart';
import 'package:wallet/l10n/application/localization_cubit.dart';
import 'package:wallet/l10n/l10n.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
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

              final outputFile = await FilePicker.platform.saveFile(
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
              final result = await FilePicker.platform.pickFiles();

              if (result != null) {
                final file = File(result.files.single.path!);
                final list = await csvToIncomeExpense(file.path);
                CounterBloc.instance.add(RestoreBackUp(list: list));
              } else {
                // User canceled the picker
              }
            },
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
