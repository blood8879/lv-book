import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lv_book/features/benchmark/data/benchmark_providers.dart';
import 'package:lv_book/features/benchmark/domain/benchmark.dart';
import 'package:lv_book/features/fieldbook/data/fieldbook_providers.dart';
import 'package:lv_book/features/fieldbook/data/fieldbook_repository.dart';
import 'package:lv_book/features/fieldbook/data/measurement_repository.dart';
import 'package:lv_book/features/fieldbook/domain/fieldbook.dart';
import 'package:lv_book/features/fieldbook/domain/measurement.dart';
import 'package:lv_book/features/fieldbook/domain/misclosure.dart';
import 'package:lv_book/features/fieldbook/presentation/fieldbook_edit_screen.dart';
import 'package:lv_book/features/project/data/sample_project_service.dart';
import 'package:lv_book/features/settings/misclosure_tolerance_repository.dart';
import 'package:lv_book/features/settings/settings_screen.dart';
import 'package:lv_book/l10n/l10n.dart';

void main() {
  late _FakeFieldBookRepository fieldBookRepo;

  setUp(() => fieldBookRepo = _FakeFieldBookRepository());

  Widget editor({
    required ClosingReferenceMode mode,
    double? closingElevation,
    MisclosureTolerance tolerance = MisclosureTolerance.defaults,
    Locale locale = const Locale('en'),
  }) {
    return ProviderScope(
      overrides: [
        measurementRepositoryProvider.overrideWithValue(
          _FakeMeasurementRepository(
            SampleProjectService.buildMeasurements(fieldBookId: 1),
          ),
        ),
        fieldBookRepositoryProvider.overrideWithValue(fieldBookRepo),
        fieldBookListProvider.overrideWith(_StubFieldBookNotifier.new),
        benchmarkListProvider.overrideWith(_StubBenchmarkNotifier.new),
        misclosureToleranceProvider.overrideWith((ref) async => tolerance),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: FieldBookEditScreen(
          fieldBook: FieldBook(
            id: 1,
            projectId: 1,
            title: 'Sample',
            date: DateTime(2026, 10, 4),
            startBmId: 1,
            startElevation: 100,
            closingMode: mode,
            closingElevation: closingElevation,
          ),
          projectId: 1,
        ),
      ),
    );
  }

  Future<void> useNarrowPhone(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('sample loop shows +0.0010 within the default 1 mm', (
    tester,
  ) async {
    await useNarrowPhone(tester);
    await tester.pumpWidget(editor(mode: ClosingReferenceMode.loop));
    await tester.pumpAndSettle();

    expect(find.text('Misclosure'), findsOneWidget);
    expect(find.text('+0.0010'), findsOneWidget);
    expect(find.text('Allowed ±0.0010'), findsOneWidget);
    expect(find.text('Loop · 100.000'), findsOneWidget);
    expect(find.text('Misclosure: Within tolerance'), findsOneWidget);
    expect(find.text('✓ Tolerance'), findsOneWidget);
    expect(find.text('✓ Arithmetic check'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('c·√n setting widens the allowed value (Korean)', (tester) async {
    await useNarrowPhone(tester);
    await tester.pumpWidget(
      editor(
        mode: ClosingReferenceMode.manual,
        closingElevation: 99.995,
        tolerance: const MisclosureTolerance.sqrtSetups(5),
        locale: const Locale('ko'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('+0.0060'), findsOneWidget);
    expect(find.text('허용 ±0.0087'), findsOneWidget);
    expect(find.text('폐합오차 적합'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('exceeding the tolerance is flagged as Check required', (
    tester,
  ) async {
    await useNarrowPhone(tester);
    await tester.pumpWidget(
      editor(mode: ClosingReferenceMode.manual, closingElevation: 99.995),
    );
    await tester.pumpAndSettle();

    expect(find.text('+0.0060'), findsOneWidget);
    expect(
      find.text('Exceeds tolerance — check the readings.'),
      findsOneWidget,
    );
    expect(find.text('! Tolerance'), findsOneWidget);
    expect(find.textContaining('Fail'), findsNothing);
  });

  testWidgets('closing reference sheet: manual RL, other BM, none', (
    tester,
  ) async {
    await useNarrowPhone(tester);
    await tester.pumpWidget(editor(mode: ClosingReferenceMode.none));
    await tester.pumpAndSettle();
    expect(find.text('Not set'), findsOneWidget);
    expect(find.text('Arith. check'), findsOneWidget);

    // Manual RL with validation.
    await tester.tap(find.byKey(const ValueKey('closing-reference-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Manual RL'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid RL.'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, '100.003');
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(fieldBookRepo.saved.last.closingMode, ClosingReferenceMode.manual);
    expect(fieldBookRepo.saved.last.closingElevation, 100.003);
    expect(find.text('Manual · 100.003'), findsOneWidget);
    expect(find.text('-0.0020'), findsOneWidget);

    // Other BM: the out-of-service BM is not offered; elevation snapshotted.
    await tester.tap(find.byKey(const ValueKey('closing-reference-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Other BM'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<BenchMark>));
    await tester.pumpAndSettle();
    expect(find.text('BM-9 (90.000m)'), findsNothing);
    await tester.tap(find.text('BM-2 (100.001m)').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    final saved = fieldBookRepo.saved.last;
    expect(saved.closingMode, ClosingReferenceMode.benchmark);
    expect(saved.closingBmId, 2);
    expect(saved.closingElevation, 100.001);
    expect(find.text('BM-2 · 100.001'), findsOneWidget);
    expect(find.text('0.0000'), findsOneWidget);

    // Back to none.
    await tester.tap(find.byKey(const ValueKey('closing-reference-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('None'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(fieldBookRepo.saved.last.closingMode, ClosingReferenceMode.none);
    expect(find.text('Not set'), findsOneWidget);
    expect(find.text('Arithmetic check: Within tolerance'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tolerance dialog validates and returns the rule', (
    tester,
  ) async {
    MisclosureTolerance? result;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showDialog<MisclosureTolerance>(
                context: context,
                builder: (_) => const MisclosureToleranceDialog(
                  initial: MisclosureTolerance.defaults,
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Allowance (mm)'), findsOneWidget);

    await tester.tap(find.text('c·√n'));
    await tester.pumpAndSettle();
    expect(find.text('c (mm)'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '0');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Enter 0.1–100 mm.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '5');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(result, const MisclosureTolerance.sqrtSetups(5));
    expect(
      misclosureToleranceSummary(l10nFor(const Locale('en')), result!),
      '5 mm × √n (n = setups)',
    );
    expect(
      misclosureToleranceSummary(l10nKo, MisclosureTolerance.defaults),
      '고정 ±1 mm',
    );
  });
}

class _FakeMeasurementRepository extends MeasurementRepository {
  final List<Measurement> initial;

  _FakeMeasurementRepository(this.initial);

  @override
  Future<List<Measurement>> getByFieldBookId(int fieldBookId) async => initial;

  @override
  Future<void> replaceForFieldBook(
    int fieldBookId,
    List<Measurement> measurements, {
    double? startElevation,
  }) async {}
}

class _FakeFieldBookRepository extends FieldBookRepository {
  final saved = <FieldBook>[];

  @override
  Future<int> updateClosingReference(FieldBook fieldBook) async {
    saved.add(fieldBook);
    return 1;
  }
}

class _StubFieldBookNotifier extends FieldBookListNotifier {
  @override
  Future<List<FieldBook>> build(int projectId) async => const [];
}

class _StubBenchmarkNotifier extends BenchmarkListNotifier {
  @override
  Future<List<BenchMark>> build(int projectId) async => [
    BenchMark(id: 1, projectId: 1, name: 'BM-1', elevation: 100),
    BenchMark(id: 2, projectId: 1, name: 'BM-2', elevation: 100.001),
    BenchMark(
      id: 9,
      projectId: 1,
      name: 'BM-9',
      elevation: 90,
      status: BenchMarkStatus.stopped,
    ),
  ];
}
