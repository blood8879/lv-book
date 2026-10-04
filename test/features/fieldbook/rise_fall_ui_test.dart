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
import 'package:lv_book/features/fieldbook/domain/reduction.dart';
import 'package:lv_book/features/fieldbook/presentation/fieldbook_edit_screen.dart';
import 'package:lv_book/features/fieldbook/presentation/reduction_method_selector.dart';
import 'package:lv_book/features/project/data/sample_project_service.dart';
import 'package:lv_book/features/settings/misclosure_tolerance_repository.dart';
import 'package:lv_book/features/settings/settings_screen.dart';
import 'package:lv_book/l10n/l10n.dart';

void main() {
  late _FakeFieldBookRepository fieldBookRepo;

  setUp(() => fieldBookRepo = _FakeFieldBookRepository());

  Widget editor({
    required Locale locale,
    ReductionMethod method = ReductionMethod.riseAndFall,
    MisclosureTolerance tolerance = MisclosureTolerance.defaults,
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
            date: DateTime(2026, 10, 5),
            startElevation: 100,
            closingMode: ClosingReferenceMode.loop,
            reductionMethod: method,
          ),
          projectId: 1,
        ),
      ),
    );
  }

  /// 360 × 800 phone (as the other editor tests) with large (1.3×) text.
  void useNarrowPhone(WidgetTester tester, {double textScale = 1.3}) {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  testWidgets('rise-and-fall editor at 360 px, 1.3× text (English)', (
    tester,
  ) async {
    useNarrowPhone(tester);
    await tester.pumpWidget(editor(locale: const Locale('en')));
    await tester.pumpAndSettle();

    expect(find.text('Rise/Fall'), findsOneWidget);
    expect(find.text('HI'), findsNothing);
    expect(find.text('+0.552'), findsOneWidget);
    expect(find.text('−0.328'), findsOneWidget);
    expect(find.text('+0.088'), findsOneWidget);
    expect(find.text('101.425'), findsNothing); // no HI values
    expect(find.text('ΣRise 0.640'), findsOneWidget);
    expect(find.text('ΣFall 0.639'), findsOneWidget);
    expect(find.text('R − F 0.001'), findsOneWidget);
    expect(find.text('Diff'), findsOneWidget);
    expect(find.text('✓ Rise/Fall check'), findsOneWidget);
    expect(find.text('Rise & Fall · Draft'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rise-and-fall editor at 360 px, 1.3× text (Korean)', (
    tester,
  ) async {
    useNarrowPhone(tester);
    await tester.pumpWidget(editor(locale: const Locale('ko')));
    await tester.pumpAndSettle();

    expect(find.text('승강'), findsOneWidget);
    expect(find.text('+0.552'), findsOneWidget);
    expect(find.text('Σ승 0.640'), findsOneWidget);
    expect(find.text('승−강 0.001'), findsOneWidget);
    expect(find.text('✓ 승강 검산'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('method is switched and persisted from the review panel', (
    tester,
  ) async {
    useNarrowPhone(tester, textScale: 1);
    await tester.pumpWidget(
      editor(
        locale: const Locale('en'),
        method: ReductionMethod.heightOfInstrument,
        tolerance: const MisclosureTolerance(unit: LengthUnit.feet),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('HI'), findsOneWidget);
    expect(find.text('ft'), findsOneWidget); // start RL unit label
    expect(find.byKey(const ValueKey('rise-fall-summary')), findsNothing);

    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    final segment = find.descendant(
      of: find.byKey(const ValueKey('reduction-method-selector')),
      matching: find.text('Rise & Fall'),
    );
    await tester.ensureVisible(segment);
    await tester.pumpAndSettle();
    expect(
      tester
          .getSize(find.byKey(const ValueKey('reduction-method-selector')))
          .height,
      greaterThanOrEqualTo(44),
    );
    await tester.tap(segment);
    await tester.pumpAndSettle();

    expect(
      fieldBookRepo.savedMethods.single.reductionMethod,
      ReductionMethod.riseAndFall,
    );
    expect(find.text('Rise/Fall'), findsOneWidget);
    expect(find.byKey(const ValueKey('rise-fall-summary')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('selector fits a 320 px sheet with 1.3× text', (tester) async {
    useNarrowPhone(tester);
    for (final locale in const [Locale('en'), Locale('ko')]) {
      var value = ReductionMethod.heightOfInstrument;
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: StatefulBuilder(
                builder: (context, setState) => ReductionMethodSelector(
                  value: value,
                  onChanged: (v) => setState(() => value = v),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.text(locale.languageCode == 'en' ? 'Rise & Fall' : '승강식'),
      );
      await tester.pumpAndSettle();
      expect(value, ReductionMethod.riseAndFall);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('unit dialog shows the not-converted note; tolerance in ft', (
    tester,
  ) async {
    LengthUnit? unit;
    MisclosureTolerance? tolerance;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Column(
            children: [
              TextButton(
                onPressed: () async {
                  unit = await showDialog<LengthUnit>(
                    context: context,
                    builder: (_) =>
                        const LengthUnitDialog(initial: LengthUnit.metres),
                  );
                },
                child: const Text('unit'),
              ),
              TextButton(
                onPressed: () async {
                  tolerance = await showDialog<MisclosureTolerance>(
                    context: context,
                    builder: (_) => const MisclosureToleranceDialog(
                      initial: MisclosureTolerance(unit: LengthUnit.feet),
                    ),
                  );
                },
                child: const Text('tolerance'),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('unit'));
    await tester.pumpAndSettle();
    expect(
      find.text('Only labels change; existing numbers are not converted.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Feet (ft)'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(unit, LengthUnit.feet);

    await tester.tap(find.text('tolerance'));
    await tester.pumpAndSettle();
    expect(find.text('Allowance (ft)'), findsOneWidget);
    expect(find.text('0.01'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '1');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Enter 0.0005–0.3 ft.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '0.02');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(tolerance!.unit, LengthUnit.feet);
    expect(tolerance!.fixedFt, 0.02);
    expect(tolerance!.fixedMm, MisclosureTolerance.defaultFixedMm);
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
  final savedMethods = <FieldBook>[];

  @override
  Future<int> updateReductionMethod(FieldBook fieldBook) async {
    savedMethods.add(fieldBook);
    return 1;
  }
}

class _StubFieldBookNotifier extends FieldBookListNotifier {
  @override
  Future<List<FieldBook>> build(int projectId) async => const [];
}

class _StubBenchmarkNotifier extends BenchmarkListNotifier {
  @override
  Future<List<BenchMark>> build(int projectId) async => const [];
}
