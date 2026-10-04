import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lv_book/features/fieldbook/data/fieldbook_providers.dart';
import 'package:lv_book/features/fieldbook/data/measurement_repository.dart';
import 'package:lv_book/features/fieldbook/domain/fieldbook.dart';
import 'package:lv_book/features/fieldbook/domain/measurement.dart';
import 'package:lv_book/features/fieldbook/domain/measurement_validation.dart';
import 'package:lv_book/features/fieldbook/presentation/fieldbook_edit_screen.dart';

void main() {
  late _RecordingMeasurementRepository repo;

  Widget app({required Widget home}) {
    return ProviderScope(
      overrides: [
        measurementRepositoryProvider.overrideWithValue(repo),
        fieldBookListProvider.overrideWith(_StubFieldBookNotifier.new),
      ],
      child: MaterialApp(home: home),
    );
  }

  FieldBook fieldBook() => FieldBook(
    id: 1,
    projectId: 1,
    title: '구조 복제 야장',
    date: DateTime(2026, 6, 8),
    startElevation: 100,
  );

  setUp(() {
    repo = _RecordingMeasurementRepository([
      Measurement(fieldBookId: 1, orderIndex: 0, stationName: 'BM.1'),
      Measurement(fieldBookId: 1, orderIndex: 1, stationName: 'No.1'),
      Measurement(fieldBookId: 1, orderIndex: 2, stationName: 'No.2'),
    ]);
  });

  testWidgets('save keeps station-only template rows and start elevation', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        home: FieldBookEditScreen(fieldBook: fieldBook(), projectId: 1),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, '100.000'),
      '123.456',
    );
    await tester.tap(find.byIcon(Icons.save));
    await tester.pumpAndSettle();

    expect(repo.saves, isNotEmpty);
    final last = repo.saves.last;
    expect(last.rows.map((m) => m.stationName).toList(), [
      'BM.1',
      'No.1',
      'No.2',
    ]);
    expect(last.startElevation, 123.456);
  });

  testWidgets('pop after edit flushes save without using disposed ref', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) =>
                    FieldBookEditScreen(fieldBook: fieldBook(), projectId: 1),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, '100.000'),
      '101.5',
    );
    await tester.pump();
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(tester.takeException(), isNull);
    expect(repo.saves, hasLength(1));
    expect(repo.saves.single.startElevation, 101.5);
  });

  test('trailing unmeasured station rows do not block validation', () {
    final result = MeasurementValidation.validate(
      measurements: [
        Measurement(fieldBookId: 1, orderIndex: 0, stationName: 'BM.1', bs: 1),
        Measurement(fieldBookId: 1, orderIndex: 1, stationName: 'No.1', fs: 1),
        Measurement(fieldBookId: 1, orderIndex: 2, stationName: 'No.2'),
      ],
      startElevation: 100,
    );

    expect(result.canExport, isTrue);
  });
}

class _SavedCall {
  final List<Measurement> rows;
  final double? startElevation;

  const _SavedCall(this.rows, this.startElevation);
}

class _RecordingMeasurementRepository extends MeasurementRepository {
  final List<Measurement> initial;
  final List<_SavedCall> saves = [];

  _RecordingMeasurementRepository(this.initial);

  @override
  Future<List<Measurement>> getByFieldBookId(int fieldBookId) async {
    return initial;
  }

  @override
  Future<void> replaceForFieldBook(
    int fieldBookId,
    List<Measurement> measurements, {
    double? startElevation,
  }) async {
    saves.add(_SavedCall(measurements, startElevation));
  }
}

class _StubFieldBookNotifier extends FieldBookListNotifier {
  @override
  Future<List<FieldBook>> build(int projectId) async => const [];
}
