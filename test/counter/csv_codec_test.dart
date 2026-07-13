import 'package:flutter_test/flutter_test.dart';
import 'package:wallet/counter/domain/counter_category.dart';
import 'package:wallet/counter/domain/csv_codec.dart';
import 'package:wallet/counter/domain/income_expense.dart';

void main() {
  group('csvEncodeField / csvDecodeField', () {
    test('round-trips characters that would break the CSV', () {
      const samples = [
        'plain',
        'lunch, coffee',
        'a;b;c',
        'line one\nline two',
        'carriage\r\nreturn',
        'already %2C encoded',
        '100% sure, maybe',
        '',
      ];
      for (final s in samples) {
        expect(csvDecodeField(csvEncodeField(s)), s, reason: 'failed for "$s"');
      }
    });

    test('encoded field contains no raw comma or line break', () {
      final encoded = csvEncodeField('a,b\nc\rd');
      expect(encoded.contains(','), isFalse);
      expect(encoded.contains('\n'), isFalse);
      expect(encoded.contains('\r'), isFalse);
    });

    test('legacy text without escapes decodes unchanged', () {
      // Older backups predate the codec and hold no %NN sequences.
      expect(csvDecodeField('Nahar'), 'Nahar');
    });
  });

  group('CSV serialisation round-trip', () {
    test('IncomeExpense description with a comma survives', () {
      final entry = IncomeExpense(
        uuid: 'u1',
        amount: -12.5,
        description: 'lunch, coffee & cake',
        createdAt: DateTime.parse('2024-05-16 14:06:52.958501'),
        updatedAt: DateTime.parse('2024-05-16 14:06:52.958501'),
      );
      // A single CSV line, as written by the backup export.
      final line = entry.toListString().join(',');
      final restored = IncomeExpense.fromList(line.split(','));
      expect(restored.description, 'lunch, coffee & cake');
      expect(restored.uuid, entry.uuid);
      expect(restored.amount, entry.amount);
    });

    test('CounterCategory name with a comma survives', () {
      final category = CounterCategory(
        uuid: 'c1',
        name: 'Food, Drinks',
        type: CategoryType.expense,
        colorCode: 4289572686,
        iconCode: 57946,
        createdAt: DateTime.parse('2024-04-22 19:53:33.549989'),
        updatedAt: DateTime.parse('2024-04-25 17:05:17.817019'),
      );
      final line = category.toListString().join(',');
      final restored = CounterCategory.fromList(line.split(','));
      expect(restored.name, 'Food, Drinks');
      expect(restored, category);
    });
  });
}
