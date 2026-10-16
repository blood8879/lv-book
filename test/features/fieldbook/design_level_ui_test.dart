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
import 'package:lv_book/l10n/l10n.dart';

void main() {
  late _FakeFieldBookRepository fieldBookRepo;
  late _FakeMeasurementRepository measurementRepo;

  setUp(() {
    fieldBookRepo = _FakeFieldBookRepository();
    measurementRepo = _FakeMeasurementRepository(
      SampleProjectService.buildMeasurements(fieldBookId: 1),
    );
  });

  Widget editor({required Locale locale, bool showDesign = false}) {
    return ProviderScope(
      overrides: [
        measurementRepositoryProvider.overrideWithValue(measurementRepo),
        fieldBookRepositoryProvider.overrideWithValue(fieldBookRepo),
        fieldBookListProvider.overrideWith(_StubFieldBookNotifier.new),
        benchmarkListProvider.overrideWith(_StubBenchmarkNotifier.new),
        misclosureToleranceProvider.overrideWith(
          (ref) async => MisclosureTolerance.defaults,
        ),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: FieldBookEditScreen(
          fieldBook: FieldBook(
            id: 1,
            projectId: 1,
            title: 'Formation',
            date: DateTime(2026, 10, 15),
            startElevation: 100,
            closingMode: ClosingReferenceMode.loop,
            showDesignLevel: showDesign,
          ),
          projectId: 1,
        ),
      ),
    );
  }

  void useNarrowPhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Finder cell(int row, String col) => find.byKey(ValueKey('cell-$row-$col'));

  testWidgets('existing books show no design columns', (tester) async {
    useNarrowPhone(tester);
    await tester.pumpWidget(editor(locale: const Locale('en')));
    await tester.pumpAndSettle();

    expect(find.text('Design'), findsNothing);
    expect(find.text('Cut(+)/Fill(−)'), findsNothing);
    expect(cell(0, 'dl'), findsNothing);
    expect(find.byKey(const ValueKey('design-table-scroll')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('toggle, enter design levels, see cut/fill (English, 360 px)', (
    tester,
  ) async {
    useNarrowPhone(tester);
    await tester.pumpWidget(editor(locale: const Locale('en')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
    final toggle = find.byKey(const ValueKey('design-level-switch'));
    await tester.ensureVisible(toggle);
    await tester.pumpAndSettle();
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(fieldBookRepo.savedFlags.single.showDesignLevel, isTrue);
    await tester.tap(find.text('Review')); // collapse the panel
    await tester.pumpAndSettle();

    expect(find.text('Design'), findsOneWidget);
    expect(find.text('Cut(+)/Fill(−)'), findsOneWidget);
    // 360 px is narrower than the design table: it scrolls horizontally.
    expect(find.byKey(const ValueKey('design-table-scroll')), findsOneWidget);

    // No.1 (row 2, RL 100.224) and No.2 (row 4, RL 100.147).
    await tester.enterText(cell(2, 'dl'), '100.099');
    await tester.enterText(cell(4, 'dl'), '100.187');
    await tester.pump();
    await tester.ensureVisible(find.text('C 0.125'));
    await tester.pumpAndSettle();
    expect(find.text('C 0.125'), findsOneWidget);
    expect(find.text('F 0.040'), findsOneWidget);

    // Autosave goes through the normal save path with the design levels.
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    final saved = measurementRepo.saves.last;
    expect(saved.map((m) => m.designLevel).whereType<double>(), [
      100.099,
      100.187,
    ]);
    expect(saved.length, 6); // no extra rows
    expect(tester.takeException(), isNull);
  });

  testWidgets('FS → Design → next BS keyboard navigation (Korean labels)', (
    tester,
  ) async {
    useNarrowPhone(tester);
    measurementRepo = _FakeMeasurementRepository([
      for (final m in SampleProjectService.buildMeasurements(fieldBookId: 1))
        m.stationName == 'No.1' ? m.copyWith(designLevel: 100.5) : m,
    ]);
    await tester.pumpWidget(
      editor(locale: const Locale('ko'), showDesign: true),
    );
    await tester.pumpAndSettle();

    expect(find.text('계획고'), findsOneWidget);
    expect(find.text('절토(+)/성토(−)'), findsOneWidget);
    // Stored design level is shown formatted; RL 100.224 − 100.5 → fill.
    expect(find.text('100.500'), findsOneWidget);
    expect(find.text('성 0.276'), findsOneWidget);

    bool focused(Finder finder) => tester
        .widget<EditableText>(
          find.descendant(of: finder, matching: find.byType(EditableText)),
        )
        .focusNode
        .hasFocus;

    await tester.showKeyboard(cell(2, 'fs'));
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();
    expect(focused(cell(2, 'dl')), isTrue);
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();
    expect(focused(cell(3, 'bs')), isTrue);

    // Clearing a design level clears its cut/fill.
    await tester.enterText(cell(2, 'dl'), '');
    await tester.pump();
    expect(find.text('성 0.276'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  String targetText(WidgetTester tester, int row) =>
      tester.widget<Text>(find.byKey(ValueKey('cell-$row-target'))).data!;

  testWidgets('target reading: HI in effect − design, also with no reading', (
    tester,
  ) async {
    useNarrowPhone(tester);
    await tester.pumpWidget(
      editor(locale: const Locale('en'), showDesign: true),
    );
    await tester.pumpAndSettle();

    expect(find.text('Target'), findsOneWidget);
    // No.1 (row 2) after TP-1: HI 102.164 − 100.099 = 2.065.
    await tester.enterText(cell(2, 'dl'), '100.099');
    // Row 6 has no reading yet: the HI after TP-2 (101.397) still applies.
    await tester.enterText(cell(6, 'dl'), '100.5');
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(targetText(tester, 2), '2.065');
    expect(targetText(tester, 6), '0.897');
    // No design level: blank.
    expect(targetText(tester, 0), '');
    expect(targetText(tester, 4), '');
    // The new column keeps the table scrollable on a 360 px phone.
    expect(find.byKey(const ValueKey('design-table-scroll')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('target column fits in Korean and Spanish', (tester) async {
    useNarrowPhone(tester);
    for (final (locale, header) in [
      (const Locale('ko'), '목표 시'),
      (const Locale('es'), 'Lect. obj.'),
    ]) {
      await tester.pumpWidget(editor(locale: locale, showDesign: true));
      await tester.pumpAndSettle();
      expect(find.text(header), findsOneWidget);
      // Header cells keep ≥ 75 pt in the scrolling design table.
      final headerCell = find
          .ancestor(of: find.text(header), matching: find.byType(Expanded))
          .first;
      expect(tester.getSize(headerCell).width, greaterThanOrEqualTo(75));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    }
  });
}

class _FakeMeasurementRepository extends MeasurementRepository {
  final List<Measurement> initial;
  final saves = <List<Measurement>>[];

  _FakeMeasurementRepository(this.initial);

  @override
  Future<List<Measurement>> getByFieldBookId(int fieldBookId) async => initial;

  @override
  Future<void> replaceForFieldBook(
    int fieldBookId,
    List<Measurement> measurements, {
    double? startElevation,
  }) async {
    saves.add(measurements);
  }
}

class _FakeFieldBookRepository extends FieldBookRepository {
  final savedFlags = <FieldBook>[];

  @override
  Future<int> updateShowDesignLevel(FieldBook fieldBook) async {
    savedFlags.add(fieldBook);
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
