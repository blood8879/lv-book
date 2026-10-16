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
  testWidgets('route length: prompt, formula and save (360 px, en/es)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    for (final locale in [const Locale('en'), const Locale('es')]) {
      final l10n = l10nFor(locale);
      final fieldBookRepo = _FakeFieldBookRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            measurementRepositoryProvider.overrideWithValue(
              _FakeMeasurementRepository(
                SampleProjectService.buildMeasurements(fieldBookId: 1),
              ),
            ),
            fieldBookRepositoryProvider.overrideWithValue(fieldBookRepo),
            fieldBookListProvider.overrideWith(_StubFieldBookNotifier.new),
            benchmarkListProvider.overrideWith(_StubBenchmarkNotifier.new),
            misclosureToleranceProvider.overrideWith(
              (ref) async => const MisclosureTolerance.sqrtDistance(10),
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
                title: 'K',
                date: DateTime(2026, 10, 16),
                startElevation: 100,
                closingMode: ClosingReferenceMode.loop,
              ),
              projectId: 1,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // No route length: the verdict asks for it instead of judging.
      expect(find.text(l10n.fieldbookIssueRouteLengthMissing), findsOneWidget);
      expect(
        find.text(l10n.fieldbookSummaryAllowedUnavailable),
        findsOneWidget,
      );

      await tester.tap(find.text(l10n.fieldbookReviewPanelTitle));
      await tester.pumpAndSettle();
      final field = find.byKey(const ValueKey('route-length-field'));
      await tester.ensureVisible(field);
      await tester.enterText(field, '2,4'); // decimal comma
      await tester.pumpAndSettle();

      expect(fieldBookRepo.saved.last.routeLength, 2.4);
      expect(
        find.text(l10n.fieldbookToleranceFormula('±10 mm·√2.40 km = ±15.5 mm')),
        findsOneWidget,
      );
      expect(find.text(l10n.fieldbookIssueRouteLengthMissing), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    }
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
  Future<int> updateRouteLength(FieldBook fieldBook) async {
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
  Future<List<BenchMark>> build(int projectId) async => const [];
}
