import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lv_book/core/constants/app_constants.dart';
import 'package:lv_book/features/ads/ad_providers.dart';
import 'package:lv_book/features/ads/ad_settings_repository.dart';
import 'package:lv_book/features/benchmark/data/benchmark_providers.dart';
import 'package:lv_book/features/benchmark/domain/benchmark.dart';
import 'package:lv_book/features/export/bulk_export_screen.dart';
import 'package:lv_book/features/fieldbook/data/fieldbook_providers.dart';
import 'package:lv_book/features/fieldbook/data/fieldbook_repository.dart';
import 'package:lv_book/features/fieldbook/data/measurement_repository.dart';
import 'package:lv_book/features/fieldbook/domain/fieldbook.dart';
import 'package:lv_book/features/fieldbook/domain/measurement.dart';
import 'package:lv_book/features/fieldbook/domain/misclosure.dart';
import 'package:lv_book/features/fieldbook/presentation/fieldbook_edit_screen.dart';
import 'package:lv_book/features/pro/pro_pdf_settings_screen.dart';
import 'package:lv_book/features/pro/pro_providers.dart';
import 'package:lv_book/features/pro/pro_settings_repository.dart';
import 'package:lv_book/features/project/data/project_providers.dart';
import 'package:lv_book/features/project/data/sample_project_service.dart';
import 'package:lv_book/features/project/domain/project.dart';
import 'package:lv_book/features/project/presentation/project_list_screen.dart';
import 'package:lv_book/features/purchase/purchase_controller.dart';
import 'package:lv_book/features/purchase/purchase_providers.dart';
import 'package:lv_book/features/quickmemo/presentation/quick_memo_fab.dart';
import 'package:lv_book/features/settings/misclosure_tolerance_repository.dart';
import 'package:lv_book/l10n/l10n.dart';

/// Edge-to-edge: the app draws under a 24 dp status bar and a 48 dp
/// 3-button navigation bar; bottom controls must stay above the latter.
const _screen = Size(360, 800);
const _statusBar = 24.0;
const _navBar = 48.0;
const _navBarTop = 800 - _navBar;

/// [width] is widened for screens whose rows overflow with the wide test font.
void _useEdgeToEdgePhone(WidgetTester tester, {double width = 360}) {
  tester.view.physicalSize = Size(width, _screen.height);
  tester.view.devicePixelRatio = 1;
  const insets = FakeViewPadding(top: _statusBar, bottom: _navBar);
  tester.view.padding = insets;
  tester.view.viewPadding = insets;
  addTearDown(tester.view.reset);
}

/// Soft keyboard up: it covers the navigation bar, so the bottom padding
/// drops to 0 while the view padding keeps the bar height.
void _openKeyboard(WidgetTester tester, double height) {
  tester.view.viewInsets = FakeViewPadding(bottom: height);
  tester.view.padding = const FakeViewPadding(top: _statusBar);
}

void _expectAboveNavBar(WidgetTester tester, Finder finder) {
  expect(finder, findsOneWidget);
  final rect = tester.getRect(finder);
  expect(
    rect.bottom,
    lessThanOrEqualTo(_navBarTop),
    reason: '$finder bottom ${rect.bottom} overlaps the navigation bar',
  );
}

Widget _app({required Widget home, List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    ),
  );
}

void main() {
  testWidgets('home FAB and app-wide quick memo FAB clear the nav bar', (
    tester,
  ) async {
    _useEdgeToEdgePhone(tester, width: 800);
    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adsRemovedProvider.overrideWith((ref) async => true),
          projectListProvider.overrideWith(_EmptyProjectListNotifier.new),
          purchaseControllerProvider.overrideWith(
            (ref) => PurchaseController(
              adSettingsRepository: _MemoryAdSettingsRepository(),
            ),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          navigatorKey: navigatorKey,
          // Same overlay as LvBookApp.builder.
          builder: (context, child) => Stack(
            children: [
              Positioned.fill(child: child!),
              QuickMemoFab(navigatorKey: navigatorKey),
            ],
          ),
          home: const ProjectListScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    _expectAboveNavBar(tester, find.byType(FloatingActionButton));
    final quickMemo = find.descendant(
      of: find.byType(QuickMemoFab),
      matching: find.byType(InkWell),
    );
    _expectAboveNavBar(tester, quickMemo);
    // Still 80 dp above the navigation bar, as before edge-to-edge.
    expect(tester.getRect(quickMemo).bottom, _navBarTop - 80);

    // The banner slot is the Scaffold bottom bar and absorbs the inset, so
    // body lists only add the FAB clearance; outside it the inset is added.
    expect(
      AppConstants.quickMemoFabListBottomPadding(
        tester.element(find.text('Add your first site')),
      ),
      AppConstants.quickMemoFabClearance,
    );
    expect(
      AppConstants.quickMemoFabListBottomPadding(
        tester.element(find.byType(QuickMemoFab)),
      ),
      AppConstants.quickMemoFabClearance + _navBar,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('PDF settings footer Save button clears the nav bar', (
    tester,
  ) async {
    _useEdgeToEdgePhone(tester, width: 800);
    await tester.pumpWidget(
      _app(
        overrides: [
          proSettingsRepositoryProvider.overrideWith(
            (ref) => ProSettingsRepository(store: MemoryProSettingsStore()),
          ),
        ],
        home: const ProPdfSettingsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    _expectAboveNavBar(tester, find.widgetWithText(FilledButton, 'Save'));
    _expectAboveNavBar(tester, find.byType(OutlinedButton).last);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bulk export share button clears the nav bar', (tester) async {
    _useEdgeToEdgePhone(tester, width: 800);
    await tester.pumpWidget(
      _app(
        overrides: [adsRemovedProvider.overrideWith((ref) async => true)],
        home: BulkExportScreen(
          projectId: 1,
          fieldBooks: [
            FieldBook(id: 1, projectId: 1, title: 'A', date: DateTime(2026)),
            FieldBook(id: 2, projectId: 1, title: 'B', date: DateTime(2026)),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    _expectAboveNavBar(
      tester,
      find.ancestor(
        of: find.byIcon(Icons.ios_share),
        matching: find.byWidgetPredicate((w) => w is FilledButton),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  group('field book editor', () {
    Widget editor() => _app(
      overrides: [
        measurementRepositoryProvider.overrideWithValue(
          _FakeMeasurementRepository(
            SampleProjectService.buildMeasurements(fieldBookId: 1),
          ),
        ),
        fieldBookRepositoryProvider.overrideWithValue(
          _FakeFieldBookRepository(),
        ),
        fieldBookListProvider.overrideWith(_StubFieldBookNotifier.new),
        benchmarkListProvider.overrideWith(_StubBenchmarkNotifier.new),
        misclosureToleranceProvider.overrideWith(
          (ref) async => MisclosureTolerance.defaults,
        ),
      ],
      home: FieldBookEditScreen(
        fieldBook: FieldBook(
          id: 1,
          projectId: 1,
          title: 'Sample',
          date: DateTime(2026, 10, 4),
          startBmId: 1,
          startElevation: 100,
          closingMode: ClosingReferenceMode.none,
        ),
        projectId: 1,
      ),
    );

    testWidgets('summary clears the nav bar, no double gap over keyboard', (
      tester,
    ) async {
      _useEdgeToEdgePhone(tester);
      await tester.pumpWidget(editor());
      await tester.pumpAndSettle();

      final sumBs = find.text('ΣBS');
      _expectAboveNavBar(tester, sumBs);
      final gapOverNavBar = _navBarTop - tester.getRect(sumBs).bottom;

      // Keyboard up: the summary rides on top of the keyboard with the same
      // gap it had over the navigation bar (no nav-bar padding added).
      const keyboard = 300.0;
      _openKeyboard(tester, keyboard);
      await tester.pumpAndSettle();
      final gapOverKeyboard =
          (_screen.height - keyboard) - tester.getRect(sumBs).bottom;
      expect(gapOverKeyboard, closeTo(gapOverNavBar, 0.01));
      expect(tester.takeException(), isNull);
    });

    testWidgets('closing reference sheet Apply button clears the nav bar', (
      tester,
    ) async {
      _useEdgeToEdgePhone(tester);
      await tester.pumpWidget(editor());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('closing-reference-button')));
      await tester.pumpAndSettle();

      final apply = find.widgetWithText(FilledButton, 'Apply');
      _expectAboveNavBar(tester, apply);
      // The sheet's scrollable content ends exactly at the navigation bar.
      final content = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(SingleChildScrollView),
      );
      expect(tester.getRect(content).bottom, _navBarTop);

      // Keyboard up (manual RL entry): the content ends at the keyboard,
      // without the navigation bar inset stacked on top of it.
      await tester.tap(find.text('Manual RL'));
      await tester.pumpAndSettle();
      const keyboard = 300.0;
      _openKeyboard(tester, keyboard);
      await tester.pumpAndSettle();
      expect(tester.getRect(content).bottom, _screen.height - keyboard);
      expect(tester.takeException(), isNull);
    });
  });
}

class _EmptyProjectListNotifier extends ProjectListNotifier {
  @override
  Future<List<Project>> build() async => const [];
}

class _MemoryAdSettingsRepository extends AdSettingsRepository {
  @override
  Future<bool> areAdsRemoved() async => true;

  @override
  Future<void> setAdsRemoved(bool removed) async {}
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
  @override
  Future<int> updateClosingReference(FieldBook fieldBook) async => 1;
}

class _StubFieldBookNotifier extends FieldBookListNotifier {
  @override
  Future<List<FieldBook>> build(int projectId) async => const [];
}

class _StubBenchmarkNotifier extends BenchmarkListNotifier {
  @override
  Future<List<BenchMark>> build(int projectId) async => [
    BenchMark(id: 1, projectId: 1, name: 'BM-1', elevation: 100),
  ];
}
