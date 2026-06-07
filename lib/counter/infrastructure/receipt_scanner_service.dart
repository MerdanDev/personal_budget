import 'dart:io';
import 'dart:isolate';

import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Outcome of scanning a payment check.
///
/// [amount] is the detected grand total (`null` when none could be parsed —
/// the user then types it manually). [fullText] is the entire recognized text
/// of the check, used to pre-fill the record description so no data is lost.
class ReceiptScanResult {
  const ReceiptScanResult({required this.fullText, this.amount});

  final double? amount;
  final String fullText;
}

/// Captures a receipt image and reads it with on-device Tesseract OCR.
///
/// Tesseract is used (instead of ML Kit) because it recognizes **Cyrillic**
/// offline, which ML Kit cannot. Recognition runs with `rus+eng` so Russian and
/// Latin/Turkmen receipts both produce a clear description with no network.
/// Returns `null` when the user cancels the picker. The total-detection logic
/// lives in the pure [parseTotalFromLines] function so it stays unit-testable.
class ReceiptScannerService {
  ReceiptScannerService({ImagePicker? picker})
      : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Languages passed to Tesseract; order is a preference hint.
  static const _language = 'rus+eng';

  /// Tesseract engine args. `psm: 4` assumes a single column of text of
  /// variable sizes (a receipt); preserving interword spaces keeps columns
  /// readable in the description.
  static const _args = <String, String>{
    'psm': '4',
    'preserve_interword_spaces': '1',
  };

  /// Picks an image from [source], preprocesses it, runs OCR, and parses the
  /// total.
  ///
  /// Returns `null` if the user dismisses the picker. Throws if OCR fails; the
  /// caller is expected to surface that to the user.
  Future<ReceiptScanResult?> scan(ImageSource source) async {
    final file = await _picker.pickImage(source: source);
    if (file == null) return null;

    final prepared = await _preprocess(file.path);
    final text = await FlutterTesseractOcr.extractText(
      prepared,
      language: _language,
      args: _args,
    );
    return ReceiptScanResult(
      fullText: text.trim(),
      amount: parseTotalFromLines(text.split('\n')),
    );
  }

  /// Grayscales and boosts contrast to lift OCR accuracy on photographed
  /// receipts, writing a PNG to a temp file.
  ///
  /// The decode/encode is CPU-heavy pure-Dart work, so it runs in a background
  /// isolate via [Isolate.run] to keep the UI thread responsive. (The Tesseract
  /// call itself already runs on a native background thread.) Falls back to the
  /// original path if the image can't be decoded.
  Future<String> _preprocess(String path) async {
    final dir = await getTemporaryDirectory();
    final outPath = '${dir.path}/receipt_ocr.png';
    final ok = await Isolate.run(() => _grayscaleContrastToPng(path, outPath));
    return ok ? outPath : path;
  }
}

/// Top-level so it can be sent to an isolate. Reads [inPath], grayscales and
/// boosts contrast, and writes a PNG to [outPath]. Returns `false` (leaving the
/// original untouched) when the image can't be decoded.
bool _grayscaleContrastToPng(String inPath, String outPath) {
  final decoded = img.decodeImage(File(inPath).readAsBytesSync());
  if (decoded == null) return false;

  final processed = img.adjustColor(img.grayscale(decoded), contrast: 1.3);
  File(outPath).writeAsBytesSync(img.encodePng(processed));
  return true;
}

/// Keywords that mark a grand-total line, across the app's languages.
const _totalKeywords = <String>[
  'grand total',
  'amount due',
  'balance due',
  'total',
  'итого',
  'всего',
  'сумма',
  'jemi',
  'jemy',
  'umumy',
];

/// Matches a monetary number: optional thousands groups and an optional decimal
/// part, using either `.` or `,` as separators, optionally spaced.
final _moneyRegExp = RegExp(r'\d{1,3}(?:[.,\s]\d{3})*(?:[.,]\d{1,2})?|\d+');

/// Detects the grand total among receipt text [lines]. Pure and unit-tested.
///
/// Most-confident-first: a line containing a total keyword wins (rightmost
/// number on it); otherwise the largest monetary value in the whole check is
/// taken, since the grand total is almost always the biggest number. Returns
/// `null` when nothing parses.
double? parseTotalFromLines(List<String> lines) {
  // 1. Prefer a keyword line, scanning bottom-to-top (totals sit near the end).
  for (final line in lines.reversed) {
    final lower = line.toLowerCase();
    if (_totalKeywords.any(lower.contains)) {
      final value = _lastNumberIn(line);
      if (value != null) return value;
    }
  }

  // 2. Fallback: the largest monetary value anywhere on the check.
  double? largest;
  for (final line in lines) {
    for (final match in _moneyRegExp.allMatches(line)) {
      final value = _parseMoney(match.group(0)!);
      if (value != null && (largest == null || value > largest)) {
        largest = value;
      }
    }
  }
  return largest;
}

/// Returns the last parseable monetary number in [line], or `null`.
double? _lastNumberIn(String line) {
  double? last;
  for (final match in _moneyRegExp.allMatches(line)) {
    final value = _parseMoney(match.group(0)!);
    if (value != null) last = value;
  }
  return last;
}

/// Normalizes a raw monetary token into a [double].
///
/// Handles `1,234.56`, `1.234,56`, `1 234,56`, `1234.56` and plain integers.
/// When both `.` and `,` appear the last one is the decimal separator; a lone
/// `,`/`.` with exactly two trailing digits is decimal, otherwise it is a
/// thousands separator.
double? _parseMoney(String raw) {
  var s = raw.replaceAll(' ', '');
  if (s.isEmpty) return null;

  final hasDot = s.contains('.');
  final hasComma = s.contains(',');

  if (hasDot && hasComma) {
    // The separator that appears last is the decimal point.
    final decimalIsComma = s.lastIndexOf(',') > s.lastIndexOf('.');
    if (decimalIsComma) {
      s = s.replaceAll('.', '').replaceAll(',', '.');
    } else {
      s = s.replaceAll(',', '');
    }
  } else if (hasComma) {
    s = _normalizeSingleSeparator(s, ',');
  } else if (hasDot) {
    s = _normalizeSingleSeparator(s, '.');
  }

  return double.tryParse(s);
}

/// Resolves a single repeated [sep]: decimal only when it appears once with
/// exactly two trailing digits, otherwise treated as a thousands separator.
String _normalizeSingleSeparator(String s, String sep) {
  final parts = s.split(sep);
  final isDecimal = parts.length == 2 && parts.last.length == 2;
  if (isDecimal) {
    return '${parts.first}.${parts.last}';
  }
  return s.replaceAll(sep, '');
}
