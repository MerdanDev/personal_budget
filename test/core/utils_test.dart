import 'package:flutter_test/flutter_test.dart';
import 'package:wallet/core/utils.dart';

void main() {
  group('Utils test', () {
    test('Test for isSameWeek function', () {
      final datetime1 = DateTime(2024, 3, 27, 12);
      final datetime2 = DateTime(2024, 3, 25);

      expect(
        true,
        equals(
          isSameWeek(datetime1, datetime2),
        ),
      );
    });

    test('Test for isSameWeek function if not equal', () {
      final datetime1 = DateTime(2024, 3, 19);
      final datetime2 = DateTime(2024, 3, 25);

      expect(
        true,
        equals(
          isNot(isSameWeek(datetime1, datetime2)),
        ),
      );
    });
  });
}
