import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:lv_book/features/export/csv_exporter.dart';
import 'package:lv_book/features/export/export_labels.dart';
import 'package:lv_book/features/export/pdf_template.dart';
import 'package:lv_book/features/export/project_submission_package.dart';
import 'package:lv_book/features/fieldbook/domain/fieldbook.dart';
import 'package:lv_book/features/fieldbook/domain/measurement.dart';
import 'package:lv_book/features/fieldbook/domain/misclosure.dart';
import 'package:lv_book/features/fieldbook/domain/reduction.dart';
import 'package:lv_book/features/import/csv_importer.dart';
import 'package:lv_book/features/pegtest/domain/peg_test_record.dart';
import 'package:lv_book/features/pegtest/presentation/peg_test_record_pdf.dart';
import 'package:lv_book/features/pro/pro_pdf_settings.dart';
import 'package:lv_book/l10n/l10n.dart';

/// Runs [body] and returns everything it printed (the pdf package prints
/// "Unable to find a font to draw ..." for every missing glyph in debug).
Future<List<String>> _printsOf(Future<void> Function() body) async {
  final lines = <String>[];
  await runZoned(
    body,
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) => lines.add(line),
    ),
  );
  return lines;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final es = l10nFor(const Locale('es', 'MX'));
  final en = l10nFor(const Locale('en'));

  final fieldBook = FieldBook(
    id: 1,
    projectId: 1,
    title: 'Nivelación Ñuñoa – tramo 1',
    date: DateTime(2026, 6, 3),
    surveyor: 'José Muñoz',
    checker: 'Ángela Pérez',
    instrument: 'DL-500',
    weather: 'Soleado',
    workSection: 'Km 0+000~0+200',
    jobNumber: 'OT-2026-01',
    reviewStatus: FieldBookReviewStatus.reviewed,
    reviewMemo: '¿Revisado? ¡Sí!',
    reviewedAt: DateTime(2026, 6, 8),
  );
  final measurements = [
    Measurement(
      fieldBookId: 1,
      orderIndex: 0,
      stationName: 'BM.1',
      bs: 1.5,
      ih: 101.5,
      gh: 100,
    ),
    Measurement(
      fieldBookId: 1,
      orderIndex: 1,
      stationName: 'TP1',
      type: MeasurementType.tp,
      bs: 1.2,
      fs: 1.0,
      ih: 101.7,
      gh: 100.5,
      designLevel: 100.4,
    ),
    Measurement(
      fieldBookId: 1,
      orderIndex: 2,
      stationName: 'P-3',
      fs: 0.9,
      gh: 100.8,
      designLevel: 101,
    ),
    Measurement(
      fieldBookId: 1,
      orderIndex: 3,
      stationName: 'FIN',
      fs: 1.1,
      gh: 100.6,
    ),
  ];

  String spanishCsv({FieldBook? book}) => CsvExporter.withBom(
    CsvExporter.generateFieldBookCsv(
      fieldBook: book ?? fieldBook,
      measurements: measurements,
      bmName: 'BM.1',
      startElevation: 100,
      proSettings: const ProPdfSettings(includeCheckJudgement: true),
      l10n: es,
    ),
  );

  group('Spanish CSV', () {
    test('uses Spanish labels, the IS column and Spanish sums', () {
      final csv = spanishCsv();
      expect(csv, contains('Libreta de nivelación geométrica'));
      expect(csv, contains('Libreta,Nivelación Ñuñoa – tramo 1'));
      expect(csv, contains('Fecha,2026-06-03'));
      expect(csv, contains('Topógrafo,José Muñoz'));
      expect(csv, contains('Estado de revisión,Revisado'));
      expect(csv, contains('Cota del BM,100.000'));
      expect(csv, contains('N.º,Punto,VAt,VI,VAd,AI,Cota,Observaciones'));
      expect(csv, contains('Método de cálculo,Altura instrumental'));
      expect(csv, contains('ΣVAt,2.700,ΣVAd,'));
      expect(csv, contains('Error de cierre,'));
      expect(csv, contains('Resultado,'));
      // Decimals never follow the locale.
      expect(csv, contains('101.500'));
      expect(csv, isNot(contains('101,500')));
      expect(csv, isNot(contains(RegExp('[가-힣]'))));
    });

    test('round trips through the importer in every app language', () {
      final book = fieldBook.copyWith(
        reductionMethod: ReductionMethod.riseAndFall,
        showDesignLevel: true,
      );
      final csv = spanishCsv(book: book);
      expect(
        csv,
        contains(
          'N.º,Punto,VAt,VI,VAd,Ascenso,Descenso,Cota,Observaciones,'
          'Cota de proyecto,Corte(+)/Relleno(−)',
        ),
      );
      expect(csv, contains('Método de cálculo,Ascensos y descensos'));
      for (final l10n in [es, en, l10nKo]) {
        final result = CsvImporter.parse(
          csv,
          projectId: 7,
          fallbackDate: DateTime(2000),
          l10n: l10n,
          appUnit: LengthUnit.metres,
        );
        expect(result.errors, isEmpty);
        expect(result.warnings, isEmpty);
        final imported = result.fieldBook!;
        expect(imported.title, 'Nivelación Ñuñoa – tramo 1');
        expect(imported.date, DateTime(2026, 6, 3));
        expect(imported.startElevation, 100);
        expect(imported.surveyor, 'José Muñoz');
        expect(imported.checker, 'Ángela Pérez');
        expect(imported.workSection, 'Km 0+000~0+200');
        expect(imported.jobNumber, 'OT-2026-01');
        expect(imported.reductionMethod, ReductionMethod.riseAndFall);
        final rows = result.measurements;
        expect(rows.map((m) => m.stationName), ['BM.1', 'TP1', 'P-3', 'FIN']);
        expect(rows[1].type, MeasurementType.tp);
        expect(rows[2].fs, 0.9);
        expect(rows[2].designLevel, 101);
        expect(rows[3].gh, 100.6);
      }
    });

    test('a Spanish feet file warns in Spanish on a metres app', () {
      final csv = CsvExporter.generateFieldBookCsv(
        fieldBook: fieldBook,
        measurements: measurements,
        bmName: 'BM.1',
        startElevation: 100,
        tolerance: const MisclosureTolerance(unit: LengthUnit.feet),
        l10n: es,
      );
      final result = CsvImporter.parse(
        csv,
        projectId: 1,
        fallbackDate: DateTime(2000),
        l10n: es,
        appUnit: LengthUnit.metres,
      );
      expect(result.errors, isEmpty);
      expect(result.warnings, [
        'El archivo está en ft pero la app usa m. '
            'Los números se importaron sin cambios.',
      ]);
    });

    test('import errors are Spanish', () {
      final result = CsvImporter.parse(
        'Libreta,X\nCota del BM,100\n\n'
        'N.º,Punto,VAt,VAd,AI,Cota,Observaciones\n1,BM.1,abc,,,\n',
        projectId: 1,
        fallbackDate: DateTime(2026),
        l10n: es,
      );
      expect(result.errors.single, 'Fila 5: VAt no es un número válido.');
    });
  });

  group('Spanish PDF', () {
    test('table headers and check rows', () {
      expect(
        exportTableHeaders(
          es,
          method: ReductionMethod.riseAndFall,
          intermediateSights: exportUsesIntermediateColumn(es),
        ),
        [
          'N.º',
          'Punto',
          'VAt',
          'VI',
          'VAd',
          'Ascenso',
          'Descenso',
          'Cota',
          'Observaciones',
        ],
      );
      final closure = LevelClosureCheck.compute(
        measurements,
        startElevation: 100,
        closingElevation: 100.6,
        tolerance: MisclosureTolerance.defaults,
      );
      final rows = PdfExporter.checkRowsForTest(closure, l10n: es);
      expect(rows.first.map((cell) => cell.$1), ['ΣVAt', 'ΣVAd', 'Diferencia']);
    });

    test('builds with every Pro option and no missing glyph', () async {
      late List<int> bytes;
      final printed = await _printsOf(() async {
        bytes = await PdfExporter.generateFieldBookPdf(
          fieldBook: fieldBook.copyWith(
            memo: 'Nota: ¿cota? ¡ojo! – ü ñ á é í ó ú',
            reductionMethod: ReductionMethod.riseAndFall,
            showDesignLevel: true,
            closingMode: ClosingReferenceMode.loop,
          ),
          measurements: measurements,
          bmName: 'BM.1',
          startElevation: 100,
          proSettings: ProPdfSettings(
            companyName: 'Topografía Andina S.A.',
            authorName: 'José Muñoz',
            includeCheckJudgement: true,
            includeSignatureLines: true,
            documentTemplate: ProDocumentTemplate.submission,
            watermarkText: es.proInspectionWatermarkDefault,
            footerNote: 'Revisión nº 2',
          ),
          l10n: es,
        );
      });
      expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
      expect(bytes.length, greaterThan(1000));
      expect(
        printed.where((l) => l.contains('Unable to find a font')),
        isEmpty,
      );
    });

    test('two-peg test record PDF has no missing glyph', () async {
      late List<int> bytes;
      final printed = await _printsOf(() async {
        bytes = await PegTestRecordPdf.generate(
          record: PegTestRecord(
            createdAt: DateTime(2026, 10, 15, 9, 30),
            instrument: 'Nivel automático nº 3',
            observer: 'Íñigo Núñez',
            unit: LengthUnit.metres,
            a1: 1.525,
            b1: 1.230,
            a2: 1.410,
            b2: 1.120,
            pegDistance: 40,
            toleranceEntry: 3,
            note: '¿Retículo ajustado? ¡Sí!',
          ),
          l10n: es,
        );
      });
      expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
      expect(
        printed.where((l) => l.contains('Unable to find a font')),
        isEmpty,
      );
    });

    test('submission manifest is Spanish', () {
      final manifest = ProjectSubmissionPackage.buildManifest(
        projectName: 'Obra Ribera',
        fieldBooks: [fieldBook],
        measurementsByFieldBookId: {1: measurements},
        fileNames: const ['tramo1.pdf'],
        l10n: es,
      );
      expect(manifest, contains('Paquete de entrega de Lv Book'));
      expect(manifest, contains('Obra: Obra Ribera'));
      expect(
        manifest,
        contains(
          '- Nivelación Ñuñoa – tramo 1: 4 puntos, estado de revisión Revisado',
        ),
      );
    });
  });
}
