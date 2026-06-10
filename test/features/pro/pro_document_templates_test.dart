import 'package:flutter_test/flutter_test.dart';
import 'package:lv_book/features/export/export_history_repository.dart';
import 'package:lv_book/features/pro/pro_pdf_settings.dart';

void main() {
  test('Pro template preset changes PDF header and footer', () {
    final settings = const ProPdfSettings().copyWith(
      documentTemplate: ProDocumentTemplate.inspection,
      watermarkText: '검측용',
      footerNote: '현장대리인 확인',
    );

    expect(settings.documentTemplate.title, '검측용');
    expect(settings.watermarkText, '검측용');
    expect(settings.footerNote, '현장대리인 확인');
  });

  test('export history records can be cleared locally', () {
    final repository = MemoryExportHistoryRepository();
    repository.record(
      ExportHistoryRecord(
        fileName: 'fieldbook.pdf',
        fieldBookTitle: 'A구간',
        format: 'pdf',
        exportedAt: DateTime(2026, 6, 3),
      ),
    );

    expect(repository.all(), hasLength(1));
    repository.clear();
    expect(repository.all(), isEmpty);
  });
}
