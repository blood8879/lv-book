import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lv_book/features/fieldbook/data/fieldbook_providers.dart';
import 'package:lv_book/features/fieldbook/data/measurement_repository.dart';
import 'package:lv_book/features/fieldbook/domain/fieldbook.dart';
import 'package:lv_book/features/fieldbook/domain/measurement.dart';
import 'package:lv_book/features/fieldbook/presentation/fieldbook_edit_screen.dart';

void main() {
  setUp(() {
    _ReviewFieldBookNotifier.saved = null;
  });

  testWidgets('editor saves review status memo and reviewed date', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          measurementRepositoryProvider.overrideWithValue(
            _MemoryMeasurementRepository(),
          ),
          fieldBookListProvider.overrideWith(_ReviewFieldBookNotifier.new),
        ],
        child: MaterialApp(
          home: FieldBookEditScreen(
            projectId: 1,
            fieldBook: FieldBook(
              id: 1,
              projectId: 1,
              title: '검토 야장',
              date: DateTime(2026, 6, 8),
              startElevation: 100,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('검토 정보'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byType(DropdownButtonFormField<FieldBookReviewStatus>),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('검토완료').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, '검토 메모'), '감리 확인 완료');
    await tester.tap(find.text('오늘 검토일 적용'));
    await tester.pump();
    await tester.tap(find.text('검토 정보 저장'));
    await tester.pump();

    final saved = _ReviewFieldBookNotifier.saved;
    expect(saved, isNotNull);
    expect(saved!.reviewStatus, FieldBookReviewStatus.reviewed);
    expect(saved.reviewMemo, '감리 확인 완료');
    expect(saved.reviewedAt, isNotNull);
    expect(find.text('검토 정보를 저장했습니다'), findsOneWidget);
  });
}

class _MemoryMeasurementRepository extends MeasurementRepository {
  @override
  Future<List<Measurement>> getByFieldBookId(int fieldBookId) async {
    return const [];
  }
}

class _ReviewFieldBookNotifier extends FieldBookListNotifier {
  static FieldBook? saved;

  @override
  Future<List<FieldBook>> build(int projectId) async {
    return const [];
  }

  @override
  Future<void> updateFieldBook(FieldBook fieldBook) async {
    saved = fieldBook;
  }
}
