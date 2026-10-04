import 'package:flutter_test/flutter_test.dart';
import 'package:lv_book/features/export/bulk_export_service.dart';
import 'package:lv_book/features/export/csv_exporter.dart';
import 'package:lv_book/features/fieldbook/domain/fieldbook.dart';
import 'package:lv_book/l10n/l10n.dart';

void main() {
  test('free user can still use single PDF and CSV export', () {
    final csv = CsvExporter.generateFieldBookCsv(
      fieldBook: FieldBook(projectId: 1, title: '무료 야장', date: DateTime(2026)),
      measurements: const [],
      bmName: 'BM.1',
      startElevation: 100,
      l10n: l10nKo,
    );

    expect(csv, contains('무료 야장'));
    expect(csv, contains('시작 BM'));
  });

  test('non Pro user cannot use batch or package export', () {
    expect(BulkExportService.proRequiredMessage, '레벨 야장 Pro 구매 후 사용할 수 있습니다.');
  });
}
