import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wallet/counter/counter.dart';
import 'package:wallet/counter/domain/income_expense.dart';
import 'package:wallet/home/presentation/category_screen.dart';
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
            title: Text(context.l10n.back_up),
            onTap: () async {
              const name = 'back_up.csv';
              final status = await Permission.storage.request();
              if (status.isDenied) {
                // Request permission again or handle denial
                return;
              } else if (status.isPermanentlyDenied) {
                // Open app settings to grant permission
                final result = await openAppSettings();
                if (!result) {
                  return;
                }
              }
              var dialogTitle = 'Please select an output file:';
              if (context.mounted) {
                dialogTitle = context.l10n.select_output_file;
              }
              final outputFile = await FilePicker.platform.saveFile(
                dialogTitle: dialogTitle,
                fileName: name,
              );
              if (outputFile != null) {
                final data = CounterBloc.instance.data;
                // User canceled the picker
                final file = File(outputFile);
                final sink = file.openWrite();
                for (final item in data) {
                  final row = item.toListString();
                  sink
                    ..writeAll(row, ',')
                    ..writeln();
                }
                await sink.close();
                await file.create();

                if (context.mounted) {
                  final snackBar = SnackBar(
                    content: Text('${context.l10n.save_success} ${file.path}'),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(snackBar);
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_backup_restore),
            title: Text(context.l10n.restore_back_up),
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
