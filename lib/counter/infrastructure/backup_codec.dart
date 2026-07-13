import 'dart:convert';

import 'package:excel/excel.dart';
import 'package:wallet/counter/domain/category_budget.dart';
import 'package:wallet/counter/domain/counter_category.dart';
import 'package:wallet/counter/domain/income_expense.dart';

/// Schema version written into the Settings sheet. Bump when the workbook shape
/// changes in a way importers need to branch on.
const int backupVersion = 2;

/// Sheet (tab) names in the exported workbook. Each data type gets its own
/// sheet so the file opens as labelled tabs in Excel / Google Sheets / Numbers.
const String _sheetTransactions = 'Transactions';
const String _sheetCategories = 'Categories';
const String _sheetBudgets = 'Budgets';
const String _sheetSettings = 'Settings';

/// The full contents of a restore: transactions plus everything that gives them
/// meaning — the category list (including categories with no transactions),
/// monthly budgets, and the chosen currency symbol.
class BackupData {
  const BackupData({
    this.currency,
    this.categories = const [],
    this.budgets = const [],
    this.entries = const [],
  });

  final String? currency;
  final List<CounterCategory> categories;
  final List<CategoryBudget> budgets;
  final List<IncomeExpense> entries;
}

/// Serialises a complete backup to `.xlsx` bytes. Transactions reference their
/// category by uuid (the full category lives on the Categories sheet), amounts
/// and limits are written as real numbers so they stay usable in spreadsheet
/// formulas, and dates are ISO-8601 text for unambiguous round-trips.
List<int> encodeBackup({
  required String currency,
  required List<CounterCategory> categories,
  required List<CategoryBudget> budgets,
  required List<IncomeExpense> entries,
}) {
  final excel = Excel.createExcel();

  final tx = excel[_sheetTransactions]
    ..appendRow(
      _textRow([
        'uuid',
        'amount',
        'description',
        'categoryUuid',
        'createdAt',
        'updatedAt',
      ]),
    );
  for (final e in entries) {
    tx.appendRow([
      TextCellValue(e.uuid),
      DoubleCellValue(e.amount),
      TextCellValue(e.description ?? ''),
      TextCellValue(e.category?.uuid ?? ''),
      TextCellValue(e.createdAt.toIso8601String()),
      TextCellValue(e.updatedAt.toIso8601String()),
    ]);
  }

  final cat = excel[_sheetCategories]
    ..appendRow(
      _textRow([
        'uuid',
        'name',
        'type',
        'iconCode',
        'colorCode',
        'createdAt',
        'updatedAt',
      ]),
    );
  for (final c in categories) {
    cat.appendRow([
      TextCellValue(c.uuid),
      TextCellValue(c.name),
      TextCellValue(c.type.name),
      if (c.iconCode != null) IntCellValue(c.iconCode!) else null,
      if (c.colorCode != null) IntCellValue(c.colorCode!) else null,
      TextCellValue(c.createdAt.toIso8601String()),
      TextCellValue(c.updatedAt.toIso8601String()),
    ]);
  }

  final bud = excel[_sheetBudgets]
    ..appendRow(
      _textRow(['categoryUuid', 'limit', 'createdAt', 'updatedAt']),
    );
  for (final b in budgets) {
    bud.appendRow([
      TextCellValue(b.categoryUuid),
      DoubleCellValue(b.limit),
      TextCellValue(b.createdAt.toIso8601String()),
      TextCellValue(b.updatedAt.toIso8601String()),
    ]);
  }

  excel[_sheetSettings]
    ..appendRow(_textRow(['key', 'value']))
    ..appendRow(_textRow(['version', '$backupVersion']))
    ..appendRow(_textRow(['currency', currency]));

  // createExcel() seeds a blank default sheet; drop it so only our tabs remain.
  excel.delete('Sheet1');

  final bytes = excel.encode();
  if (bytes == null) {
    throw StateError('Failed to encode backup workbook');
  }
  return bytes;
}

/// Parses backup file [bytes], transparently handling both the current `.xlsx`
/// workbook and the legacy line-based CSV (one transaction per line) that
/// earlier versions exported. The format is detected from the bytes, so a
/// `.csv` backup taken before this change still restores.
///
/// Throws when [bytes] is neither a readable workbook nor parseable CSV — the
/// caller surfaces that to the user rather than restoring partial data.
BackupData decodeBackup(List<int> bytes) {
  // `.xlsx` is a ZIP container; its files always start with the "PK" signature.
  final isZip = bytes.length >= 2 && bytes[0] == 0x50 && bytes[1] == 0x4B;
  if (isZip) {
    return _decodeWorkbook(Excel.decodeBytes(bytes));
  }
  return _decodeLegacyCsv(utf8.decode(bytes));
}

BackupData _decodeWorkbook(Excel excel) {
  final categories = <CounterCategory>[];
  for (final row in _dataRows(excel, _sheetCategories, 'uuid')) {
    final uuid = _text(row, 0);
    if (uuid == null || uuid.isEmpty) continue;
    categories.add(
      CounterCategory(
        uuid: uuid,
        name: _text(row, 1) ?? '',
        type: CategoryType.fromString(_text(row, 2) ?? 'expense'),
        iconCode: _int(row, 3),
        colorCode: _int(row, 4),
        createdAt: _date(row, 5),
        updatedAt: _date(row, 6),
      ),
    );
  }
  final byUuid = {for (final c in categories) c.uuid: c};

  final entries = <IncomeExpense>[];
  for (final row in _dataRows(excel, _sheetTransactions, 'uuid')) {
    final uuid = _text(row, 0);
    if (uuid == null || uuid.isEmpty) continue;
    final description = _text(row, 2);
    entries.add(
      IncomeExpense(
        uuid: uuid,
        amount: _num(row, 1) ?? 0,
        description:
            (description == null || description.isEmpty) ? null : description,
        category: byUuid[_text(row, 3)],
        createdAt: _date(row, 4),
        updatedAt: _date(row, 5),
      ),
    );
  }

  final budgets = <CategoryBudget>[];
  for (final row in _dataRows(excel, _sheetBudgets, 'categoryUuid')) {
    final uuid = _text(row, 0);
    if (uuid == null || uuid.isEmpty) continue;
    budgets.add(
      CategoryBudget(
        categoryUuid: uuid,
        limit: _num(row, 1) ?? 0,
        createdAt: _date(row, 2),
        updatedAt: _date(row, 3),
      ),
    );
  }

  String? currency;
  for (final row in _dataRows(excel, _sheetSettings, 'key')) {
    if (_text(row, 0) == 'currency') currency = _text(row, 1);
  }

  return BackupData(
    currency: currency,
    categories: categories,
    budgets: budgets,
    entries: entries,
  );
}

BackupData _decodeLegacyCsv(String content) {
  // Legacy CSV: one IncomeExpense per line. Blank lines are skipped so a
  // trailing newline (or a stray blank) doesn't abort the whole restore.
  final entries = <IncomeExpense>[];
  for (final line in const LineSplitter().convert(content)) {
    if (line.trim().isEmpty) continue;
    entries.add(IncomeExpense.fromList(line.split(',')));
  }
  return BackupData(entries: entries);
}

/// Rows of [sheetName] with the header stripped. The first row is dropped only
/// when it actually looks like our header (first cell == [headerFirstCell]), so
/// a hand-edited sheet without a header still restores every data row.
Iterable<List<Data?>> _dataRows(
  Excel excel,
  String sheetName,
  String headerFirstCell,
) {
  final sheet = excel.tables[sheetName];
  if (sheet == null) return const [];
  final rows = sheet.rows;
  if (rows.isEmpty) return const [];
  final first = rows.first.isEmpty ? null : rows.first.first?.value?.toString();
  return first == headerFirstCell ? rows.skip(1) : rows;
}

List<CellValue?> _textRow(List<String> values) =>
    values.map<CellValue?>(TextCellValue.new).toList();

String? _text(List<Data?> row, int i) =>
    i < row.length ? row[i]?.value?.toString() : null;

double? _num(List<Data?> row, int i) {
  final v = i < row.length ? row[i]?.value : null;
  return switch (v) {
    IntCellValue() => v.value.toDouble(),
    DoubleCellValue() => v.value,
    TextCellValue() => double.tryParse(v.value.toString()),
    _ => null,
  };
}

int? _int(List<Data?> row, int i) {
  final v = i < row.length ? row[i]?.value : null;
  return switch (v) {
    IntCellValue() => v.value,
    DoubleCellValue() => v.value.toInt(),
    TextCellValue() => int.tryParse(v.value.toString()),
    _ => null,
  };
}

DateTime _date(List<Data?> row, int i) => DateTime.parse(_text(row, i)!);
