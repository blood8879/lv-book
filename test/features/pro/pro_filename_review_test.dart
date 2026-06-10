import 'package:flutter_test/flutter_test.dart';
import 'package:lv_book/features/fieldbook/domain/fieldbook.dart';
import 'package:lv_book/features/pro/pro_pdf_settings.dart';

void main() {
  test('Pro filename pattern formats export files safely', () {
    final settings = const ProPdfSettings(
      fileNamePattern: ProFileNamePattern.siteSectionDateTitle,
    );
    final fileName = settings.formatFileName(
      projectName: '1공구/현장',
      fieldBook: FieldBook(
        projectId: 1,
        title: 'A구간:야장',
        date: DateTime(2026, 6, 8),
        workSection: 'STA.0+000',
      ),
      extension: 'pdf',
    );

    expect(fileName, '1공구_현장_STA.0+000_2026-06-08_A구간_야장.pdf');
  });

  test('empty filename pattern falls back to field book title', () {
    final settings = const ProPdfSettings();
    final fileName = settings.formatFileName(
      projectName: '',
      fieldBook: FieldBook(projectId: 1, title: '야장 A', date: DateTime(2026)),
      extension: 'csv',
    );

    expect(fileName, '야장 A.csv');
  });
}
