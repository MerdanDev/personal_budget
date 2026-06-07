import 'package:flutter_test/flutter_test.dart';
import 'package:wallet/counter/infrastructure/receipt_scanner_service.dart';

void main() {
  group('parseTotalFromLines', () {
    test('picks the number on a TOTAL keyword line', () {
      final lines = [
        'Coffee 3.50',
        'Cake 4.00',
        'TOTAL 45.90',
      ];
      expect(parseTotalFromLines(lines), 45.90);
    });

    test('handles Cyrillic ИТОГО with spaced thousands and comma decimal', () {
      final lines = [
        'Товар 1 200,00',
        'ИТОГО 1 234,56',
      ];
      expect(parseTotalFromLines(lines), 1234.56);
    });

    test('handles Turkmen Jemi keyword', () {
      final lines = [
        'Çorba 12.00',
        'Jemi: 89.00',
      ];
      expect(parseTotalFromLines(lines), 89.00);
    });

    test('parses US convention 1,234.56', () {
      final lines = ['Total 1,234.56'];
      expect(parseTotalFromLines(lines), 1234.56);
    });

    test('parses EU convention 1.234,56', () {
      final lines = ['Total 1.234,56'];
      expect(parseTotalFromLines(lines), 1234.56);
    });

    test('falls back to the largest number when no keyword present', () {
      final lines = [
        'Item A 5.00',
        'Item B 12.50',
        'Item C 7.25',
      ];
      expect(parseTotalFromLines(lines), 12.50);
    });

    test('prefers the keyword line even if a larger number exists elsewhere',
        () {
      final lines = [
        'Subtotal 100.00',
        'Discount 90.00',
        'Total 10.00',
      ];
      expect(parseTotalFromLines(lines), 10.00);
    });

    test('takes the rightmost number on a keyword line', () {
      final lines = ['Total items 3 sum 42.00'];
      expect(parseTotalFromLines(lines), 42.00);
    });

    test('returns null when nothing parses', () {
      final lines = ['Thank you for your visit!', 'Come again'];
      expect(parseTotalFromLines(lines), isNull);
    });

    test('treats a lone comma without 2 decimals as thousands separator', () {
      final lines = ['Total 1,234'];
      expect(parseTotalFromLines(lines), 1234);
    });
  });
}
