import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:wallet/counter/domain/category_budget.dart';
import 'package:wallet/counter/domain/counter_category.dart';
import 'package:wallet/counter/domain/income_expense.dart';
import 'package:wallet/counter/infrastructure/backup_codec.dart';

CounterCategory _category({
  String uuid = 'c1',
  String name = 'Food',
  CategoryType type = CategoryType.expense,
}) {
  return CounterCategory(
    uuid: uuid,
    name: name,
    type: type,
    colorCode: 4289572686,
    iconCode: 57946,
    createdAt: DateTime.parse('2024-04-22 19:53:33.549989'),
    updatedAt: DateTime.parse('2024-04-25 17:05:17.817019'),
  );
}

void main() {
  group('encodeBackup / decodeBackup (xlsx workbook)', () {
    test('round-trips entries, categories, budgets and currency', () {
      final food = _category();
      final unused = _category(uuid: 'c2', name: 'Savings');
      final entry = IncomeExpense(
        uuid: 'e1',
        amount: -12.5,
        description: 'lunch, coffee\nand cake',
        category: food,
        createdAt: DateTime.parse('2024-05-16 14:06:52.958501'),
        updatedAt: DateTime.parse('2024-05-16 14:06:52.958501'),
      );
      final budget = CategoryBudget(
        categoryUuid: 'c1',
        limit: 300,
        createdAt: DateTime.parse('2024-05-01 00:00:00.000'),
        updatedAt: DateTime.parse('2024-05-01 00:00:00.000'),
      );

      final bytes = encodeBackup(
        currency: r'$',
        categories: [food, unused],
        budgets: [budget],
        entries: [entry],
      );
      // The workbook is a real .xlsx (ZIP container starting with "PK").
      expect(bytes[0], 0x50);
      expect(bytes[1], 0x4B);

      final restored = decodeBackup(bytes);

      expect(restored.currency, r'$');
      // The unused category (no transaction) survives the round-trip.
      expect(restored.categories.map((c) => c.uuid), ['c1', 'c2']);
      expect(restored.categories.first.name, 'Food');
      expect(restored.categories.first.iconCode, 57946);
      expect(restored.categories.first.colorCode, 4289572686);

      expect(restored.budgets.single.categoryUuid, 'c1');
      expect(restored.budgets.single.limit, 300);

      final e = restored.entries.single;
      expect(e.uuid, 'e1');
      expect(e.amount, -12.5);
      // Commas and newlines live natively in a spreadsheet cell.
      expect(e.description, 'lunch, coffee\nand cake');
      // Transaction is re-linked to its category via the categoryUuid column.
      expect(e.category?.uuid, 'c1');
      expect(e.category?.name, 'Food');
      expect(e.createdAt, DateTime.parse('2024-05-16 14:06:52.958501'));
    });

    test('empty backup produces a readable workbook with no data', () {
      final bytes = encodeBackup(
        currency: 'TMT',
        categories: [],
        budgets: [],
        entries: [],
      );
      final restored = decodeBackup(bytes);
      expect(restored.currency, 'TMT');
      expect(restored.categories, isEmpty);
      expect(restored.budgets, isEmpty);
      expect(restored.entries, isEmpty);
    });

    test('a category with no icon/color round-trips as null', () {
      final minimal = CounterCategory(
        uuid: 'c9',
        name: 'Aýlyk',
        type: CategoryType.income,
        createdAt: DateTime.parse('2024-05-11 14:02:21.045416'),
        updatedAt: DateTime.parse('2024-05-11 14:02:21.045416'),
      );
      final restored = decodeBackup(
        encodeBackup(
          currency: '',
          categories: [minimal],
          budgets: [],
          entries: [],
        ),
      );
      expect(restored.categories.single.iconCode, isNull);
      expect(restored.categories.single.colorCode, isNull);
      expect(restored.categories.single.type, CategoryType.income);
    });
  });

  group('decodeBackup (legacy CSV fallback)', () {
    final rows = [
      [
        'u1',
        '-50',
        '',
        'Taksi',
        '2024-05-16 14:06:52.958501',
        '2024-05-16 14:06:52.958501',
      ].join(','),
      [
        'u2',
        '500',
        '',
        'Algy',
        '2024-05-11 14:00:49.604038',
        '2024-05-08 12:04:27.255515',
      ].join(','),
    ];

    test('parses one-transaction-per-line CSV exported by older versions', () {
      final restored = decodeBackup(utf8.encode('${rows.join('\n')}\n'));
      expect(restored.entries.map((e) => e.uuid), ['u1', 'u2']);
      expect(restored.entries.first.description, 'Taksi');
      // A legacy CSV carries only transactions.
      expect(restored.categories, isEmpty);
      expect(restored.budgets, isEmpty);
      expect(restored.currency, isNull);
    });

    test('skips blank lines instead of aborting the restore', () {
      final restored = decodeBackup(utf8.encode('${rows.first}\n\n'));
      expect(restored.entries, hasLength(1));
    });
  });

  group('decodeBackup (errors)', () {
    test('throws on a file that is neither a workbook nor valid CSV', () {
      expect(
        () => decodeBackup(utf8.encode('not a real backup')),
        throwsA(isA<Object>()),
      );
    });
  });
}
