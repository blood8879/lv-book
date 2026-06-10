import 'package:flutter_test/flutter_test.dart';
import 'package:lv_book/features/export/export_file_namer.dart';
import 'package:lv_book/features/fieldbook/domain/fieldbook.dart';
import 'package:lv_book/features/pro/pro_pdf_settings.dart';

void main() {
  test('Free single export keeps title-based file names', () {
    final namer = ExportFileNamer();
    final fieldBook = FieldBook(
      projectId: 1,
      title: 'A/구간 야장',
      date: DateTime(2026, 6, 8),
    );

    final fileName = namer.next(
      fieldBook: fieldBook,
      extension: 'pdf',
      projectName: '현장 A',
    );

    expect(fileName, 'A_구간 야장.pdf');
  });

  test(
    'Pro export applies configured project and section filename pattern',
    () {
      final namer = ExportFileNamer();
      final settings = const ProPdfSettings(
        fileNamePattern: ProFileNamePattern.siteSectionDateTitle,
      );
      final fieldBook = FieldBook(
        projectId: 1,
        title: '야장 A',
        date: DateTime(2026, 6, 8),
        workSection: 'STA.0+000~0+120',
      );

      final fileName = namer.next(
        fieldBook: fieldBook,
        extension: 'csv',
        projectName: '현장 A',
        proSettings: settings,
      );

      expect(fileName, '현장 A_STA.0+000~0+120_2026-06-08_야장 A.csv');
    },
  );

  test('duplicate bulk export names are made unique before packaging', () {
    final namer = ExportFileNamer();
    final fieldBook = FieldBook(
      projectId: 1,
      title: '반복 야장',
      date: DateTime(2026, 6, 8),
    );

    final names = [
      namer.next(fieldBook: fieldBook, extension: 'pdf', projectName: ''),
      namer.next(fieldBook: fieldBook, extension: 'pdf', projectName: ''),
      namer.next(fieldBook: fieldBook, extension: 'pdf', projectName: ''),
    ];

    expect(names, ['반복 야장.pdf', '반복 야장-2.pdf', '반복 야장-3.pdf']);
  });
}
