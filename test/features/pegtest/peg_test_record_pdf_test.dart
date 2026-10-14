import 'dart:convert';

import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:lv_book/features/fieldbook/domain/misclosure.dart';
import 'package:lv_book/features/pegtest/domain/peg_test_record.dart';
import 'package:lv_book/features/pegtest/presentation/peg_test_record_pdf.dart';
import 'package:lv_book/features/pro/pro_pdf_settings.dart';
import 'package:lv_book/l10n/l10n.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final en = l10nFor(const Locale('en'));
  final ko = l10nFor(const Locale('ko'));

  PegTestRecord record({LengthUnit unit = LengthUnit.metres, String? note}) =>
      PegTestRecord(
        createdAt: DateTime(2026, 10, 15, 9, 30),
        instrument: 'DL-500 #1234',
        observer: '김측량',
        unit: unit,
        a1: 1.525,
        b1: 1.230,
        a2: 1.410,
        b2: 1.120,
        pegDistance: 40,
        toleranceEntry: unit == LengthUnit.metres ? 3 : 0.01,
        note: note,
      );

  // 1×1 transparent PNG.
  const signaturePng =
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';

  bool isPdf(List<int> bytes) =>
      bytes.length > 1000 && ascii.decode(bytes.sublist(0, 5)) == '%PDF-';

  test('English PDF with company and signature', () async {
    final bytes = await PegTestRecordPdf.generate(
      record: record(note: 'Before section 3'),
      l10n: en,
      proSettings: const ProPdfSettings(
        companyName: 'ACME Survey',
        authorName: 'J. Smith',
        footerNote: 'QA-07',
        signaturePng: signaturePng,
      ),
    );
    expect(isPdf(bytes), isTrue);
  });

  test('Korean PDF without settings (feet)', () async {
    final bytes = await PegTestRecordPdf.generate(
      record: record(unit: LengthUnit.feet),
      l10n: ko,
    );
    expect(isPdf(bytes), isTrue);
  });

  test('header and result rows', () {
    expect(PegTestRecordPdf.headerItemsForTest(record(), en), [
      'Date: 2026-10-15 09:30',
      'Instrument: DL-500 #1234',
      'Observer: 김측량',
      'Unit: m',
    ]);
    final rows = PegTestRecordPdf.resultRowsForTest(record(), en);
    expect(rows, [
      ('True difference (A − B)', '+0.295 m'),
      ('Correct B reading', '1.115 m'),
      ('Collimation error over A–B', '+5.0 mm'),
      ('Error per 100 m', '+12.5 mm'),
      ('Line of sight angle', '+25.8″'),
      ('Tolerance', '±3 mm over A–B'),
    ]);
    final noMeta = PegTestRecord(
      unit: LengthUnit.metres,
      a1: 1,
      b1: 1,
      a2: 1,
      b2: 1,
      pegDistance: 30,
      toleranceEntry: 3,
    );
    expect(PegTestRecordPdf.headerItemsForTest(noMeta, ko).sublist(1, 3), [
      '장비: -',
      '관측자: -',
    ]);
  });
}
