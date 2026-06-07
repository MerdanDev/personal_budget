# Receipt OCR — Scan payment checks into records

This document describes the **receipt scanning** feature, which lets users
photograph a payment check (restaurant bill, store receipt, commerce order) and
have its **grand total** pre-fill the amount and its **full text** pre-fill the
description of an income/expense record — so users no longer need to keep paper
checks; the check's data lives in the app.

- **Date:** 2026-06-04
- **App version:** `2.0.3+5`
- **Toolchain:** Flutter 3.41.9 · Dart 3.11.5 · JDK 17
- **Packages added:** `flutter_tesseract_ocr: ^0.4.31` · `image: ^4.3.0` · `image_picker: ^1.1.2`

---

## 1. Summary

A typical check has a table of rows (name, quantity, unit price, line total) and
a bottom block with the grand total plus tax/tips. The feature:

1. Lets the user capture the check from **camera or gallery** (`image_picker`).
2. Runs **on-device OCR** (`flutter_tesseract_ocr`, `rus+eng`) — no network,
   free, private; nothing leaves the device. Tesseract was chosen over ML Kit
   because it recognizes **Cyrillic** offline (see §7).
3. Detects the **grand total** and pre-fills the amount field.
4. Writes the **entire recognized text** into the description so every line of
   the check is preserved digitally.
5. The user verifies/edits the fields, picks a category, and saves through the
   existing add/edit flow.

**Design decisions**

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Image source | Camera **and** gallery via `image_picker` | One dependency, most flexible |
| Description content | Full OCR text of the check | Nothing lost; user can trim |
| Entry point | Scan icon in the AppBar of the add/edit dialog | Pre-fills the open form |
| Store the image? | **No** — text only | `IncomeExpense` unchanged, no migration |
| OCR engine | Tesseract (`rus+eng`) | Offline Cyrillic — the priority; ML Kit can't do Cyrillic (see §7) |
| Preprocessing | Grayscale + contrast | Lifts accuracy on photographed receipts |

---

## 2. Architecture

```
IncomeExpenseDialog (UI)
  └─ scan icon → choose Camera | Gallery
       └─ ReceiptScannerService.scan(source)
            1. image_picker → File
            2. preprocess: grayscale + contrast → temp PNG  (image pkg)
            3. FlutterTesseractOcr.extractText(png, 'rus+eng')  → String
            4. parseTotalFromLines(text.split('\n'))            → double?
            └─ ReceiptScanResult { amount, fullText }
  └─ setState: fill mainController / secondaryController / descriptionController
```

- **Service:** `lib/counter/infrastructure/receipt_scanner_service.dart` — UI-free.
- **Pure parser:** `parseTotalFromLines(List<String>)` is separated out and unit-tested
  (`test/counter/receipt_total_parser_test.dart`); this is where the value and
  the risk live.
- **Model unchanged:** the result flows through the existing controllers, then
  the existing `IncomeExpenseEvent` / `UpdateIncomeExpenseEvent`. See
  `lib/counter/domain/income_expense.dart`.

---

## 3. Total-detection strategy

`parseTotalFromLines` is heuristic but ordered most-confident-first:

1. **Keyword line.** Scan lines bottom-to-top; prefer a line whose text matches
   total keywords (case-insensitive, multi-language): `total`, `grand total`,
   `amount due`, `balance due`, `итого`, `всего`, `сумма`, `jemi`, `jemy`,
   `umumy`. Take the **last/rightmost** monetary number on that line.
2. **Number normalization.** Tolerates thousands separators and both decimal
   conventions: `1,234.56`, `1.234,56`, `1234.56`, `1 234,56`. Rule: strip
   spaces; if both `.` and `,` are present, the **last** one is the decimal
   separator; a single `,`/`.` with exactly 2 trailing digits is treated as the
   decimal point, otherwise as a thousands separator.
3. **Fallback.** If no keyword line is found, take the **largest** monetary value
   in the whole check — the grand total is almost always the biggest number.
4. **Give up.** Returns `null` if nothing parses; the user types the amount
   manually. The description is still filled with whatever text was recognized.

The parsed `double` is split into integer + 2-digit cents to fill the dialog's
two amount controllers (mirroring the existing split in the dialog's
`initState`).

---

## 4. UI behavior

- A full-width **"Scan receipt"** `OutlinedButton.icon` sits at the top of the
  form, above the amount — a clear alternative to typing. An **info**
  `IconButton` sits beside it; tapping it opens a dialog with a **Beta** badge,
  a "results may vary, double-check" notice, and image-quality tips (lighting,
  flat surface, fill the frame, hold steady).
- While scanning it shows an inline spinner, swaps its label to "Reading
  receipt…", and is disabled (double-tap guarded). The rest of the form stays
  interactive because OCR is async and preprocessing runs in a background
  isolate (see §2).
- Tapping it shows a Camera / Gallery chooser, then runs OCR.
- On success (`setState`): amount controllers are set if a total was found;
  `descriptionController` is set to the full text (appended, not overwritten, if
  the user already typed a note).
- Failures show a localized `SnackBar`; a cancelled picker is silent and leaves
  the form untouched.

New localization keys (added to `app_en.arb`, `app_ru.arb`, `app_tk.arb`):
`scanReceipt`, `scanFromCamera`, `scanFromGallery`, `scanningReceipt`,
`scanFailed`, `scanInfo`, `scanBetaBadge`, `scanBetaNotice`, `scanTipsTitle`,
`scanTip1`–`scanTip4`.

---

## 5. Platform configuration

### Trained data (both platforms)
- `assets/tessdata/eng.traineddata` and `assets/tessdata/rus.traineddata`
  (from `tessdata_fast`, ~3.9 MB + ~3.7 MB) ship in the app bundle for offline
  use.
- `assets/tessdata_config.json` lists those files; both the config and
  `assets/tessdata/` are declared under `flutter: assets:` in `pubspec.yaml`.
  `flutter_tesseract_ocr` reads them via this config on Android.

### Android — `android/app/src/main/AndroidManifest.xml`
- `<uses-permission android:name="android.permission.CAMERA" />`
- `minSdk` is `flutter.minSdkVersion` (≥ 21), already met by
  Tesseract4Android. `multiDexEnabled true` already set. No ML Kit metadata.

### iOS — `ios/Runner/Info.plist` (+ manual Xcode step)
- `NSCameraUsageDescription` — "Used to scan payment receipts."
- `NSPhotoLibraryUsageDescription` — "Used to pick a receipt photo to scan."
- Podfile platform stays at `14.0` (the ML Kit 15.5 bump was reverted).
- **Manual step:** drag `assets/tessdata` into the **Runner** group in Xcode and
  add it **as a folder reference** (blue folder, "Create folder references"), so
  the `.traineddata` files are copied into the app bundle. Tesseract on iOS reads
  them from the bundle, not from Flutter assets. Without this, scanning throws on
  device.

---

## 6. Verification

1. `flutter pub get`; on iOS `cd ios && pod install`, then do the manual Xcode
   tessdata folder-reference step (§5) — required or device scans throw.
2. **Unit tests** — `parseTotalFromLines` covering `TOTAL 45.90`,
   `ИТОГО 1 234,56`, `Jemi: 89.00`, both separator conventions, no-keyword
   fallback to largest, and unparseable → `null`. Run `flutter test`.
3. **Manual (real device — camera needs hardware):** Add Expense → scan icon →
   Camera → photograph a real check → amount = grand total, description = full
   text → pick category → Save.
4. Repeat via **Gallery**, and with a **Russian (Cyrillic)** receipt to confirm
   the description is legible (not garbled).
5. Permission prompt appears once; denial handled gracefully (SnackBar, no
   crash).
6. Edge cases: cancelled picker leaves the form unchanged; unreadable image
   leaves the amount blank for manual entry.

---

## 7. Language / script support — why Tesseract, not ML Kit

**Priority (confirmed):** users mostly photograph receipts; the most important
outcome is a **clear description, fully offline**. In this region that means
**Russian (Cyrillic)** receipts must read cleanly without internet.

**ML Kit can't do it.** ML Kit on-device text recognition has **no Cyrillic
model** — its scripts are Latin, Chinese, Devanagari, Japanese, Korean. Cyrillic
is *not* a flag or a separate pod; the engine simply cannot read it. (Modern
Turkmen uses a **Latin** alphabet, so only Russian was the gap.) Cloud Vision
*can* read Cyrillic but needs internet and sends the image off-device — excluded.

**Decision: Tesseract replaces ML Kit.** A single `flutter_tesseract_ocr` pass
with `rus+eng` covers Russian, Turkmen/Latin and digits offline, in one engine.
`parseTotalFromLines` is unchanged — it runs on whatever lines the engine
returns, and its Cyrillic keywords (`итого`, `сумма`, `всего`) now actually
match.

| Engine | Cyrillic | Offline | Notes |
|--------|----------|---------|-------|
| ML Kit Latin | ✗ garbled | ✅ | rejected — no Cyrillic |
| **Tesseract `rus+eng`** (chosen) | ✅ | ✅ | +~7.6 MB assets, slower per scan, needs preprocessing |
| Cloud Vision | ✅ | ✗ | rejected — needs internet |
| Apple Vision | ✅ | ✅ | iOS-only — not cross-platform |

**Known trade-off:** Tesseract on photographed thermal receipts is *moderate*
accuracy, weaker than ML Kit on clean Latin photos. We mitigate with grayscale +
contrast preprocessing (`image` package). Tuning `psm` and further preprocessing
(deskew, adaptive threshold) are the levers if real-world accuracy disappoints.

## 8. Out of scope (possible follow-ups)

- Storing the receipt image on the record.
- Parsing individual line items into structured rows.
