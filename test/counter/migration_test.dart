import 'package:flutter_test/flutter_test.dart';
import 'package:wallet/counter/domain/income_expense.dart';

/// Guards the upgrade path for users who installed a build where IncomeExpense
/// still carried a `title`. Reading their persisted JSON / CSV must not crash
/// and must preserve any real title text by folding it into the description.
void main() {
  group('IncomeExpense.fromMap (legacy title)', () {
    Map<String, dynamic> legacyMap({
      String? title,
      String? description,
      Map<String, dynamic>? category,
    }) {
      return <String, dynamic>{
        'uuid': 'u1',
        'amount': -12.5,
        'title': title,
        'description': description,
        'category': category,
        'createdAt': '2024-05-16T14:06:52.958501',
        'updatedAt': '2024-05-16T14:06:52.958501',
      };
    }

    test('title with no description becomes the description', () {
      final e = IncomeExpense.fromMap(legacyMap(title: 'Lunch'));
      expect(e.description, 'Lunch');
    });

    test('title and description are merged, title first', () {
      final e = IncomeExpense.fromMap(
        legacyMap(title: 'Taxi', description: 'to the airport'),
      );
      expect(e.description, 'Taxi to the airport');
    });

    test('title that echoes the category name is dropped', () {
      final e = IncomeExpense.fromMap(
        legacyMap(
          title: 'Food',
          category: <String, dynamic>{
            'uuid': 'c1',
            'name': 'Food',
            'type': 'expense',
            'createdAt': '2024-05-16T14:06:52.958501',
            'updatedAt': '2024-05-16T14:06:52.958501',
          },
        ),
      );
      expect(e.description, isNull);
      expect(e.category?.name, 'Food');
    });

    test('missing title key does not crash', () {
      final map = legacyMap(description: 'note')..remove('title');
      final e = IncomeExpense.fromMap(map);
      expect(e.description, 'note');
    });

    test('migration is idempotent (re-reading produces the same value)', () {
      final once = IncomeExpense.fromMap(
        legacyMap(title: 'Coffee', description: 'morning'),
      );
      // toMap no longer emits a title, so a second read folds nothing further.
      final twice = IncomeExpense.fromMap(once.toMap());
      expect(twice.description, once.description);
      expect(twice.toMap().containsKey('title'), isFalse);
    });
  });

  group('IncomeExpense.fromList (legacy CSV)', () {
    test('6-column row (no category) folds title into description', () {
      final row = [
        'u1',
        '-50',
        'Taksi', // legacy title column
        '',
        '2024-05-16 14:06:52.958501',
        '2024-05-16 14:06:52.958501',
      ];
      final e = IncomeExpense.fromList(row);
      expect(e.description, 'Taksi');
      expect(e.category, isNull);
    });

    test('13-column row (with category) still parses', () {
      final row = [
        'u1',
        '500',
        'Algy',
        'desc',
        '2024-05-11 14:00:49.604038',
        '2024-05-08 12:04:27.255515',
        // embedded category (7 columns)
        'c1',
        'Transaction',
        'income',
        '58459',
        '4282279424',
        '2024-05-11 14:00:38.921277',
        '2024-05-11 14:00:38.921277',
      ];
      final e = IncomeExpense.fromList(row);
      expect(e.category?.name, 'Transaction');
      expect(e.description, 'Algy desc');
    });
  });
}
