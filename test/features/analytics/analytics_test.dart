import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:lv_book/core/database/database_helper.dart';
import 'package:lv_book/features/ads/ad_providers.dart';
import 'package:lv_book/features/ads/ad_settings_repository.dart';
import 'package:lv_book/features/analytics/analytics_events.dart';
import 'package:lv_book/features/analytics/analytics_providers.dart';
import 'package:lv_book/features/analytics/analytics_settings_repository.dart';
import 'package:lv_book/features/analytics/firebase_analytics_service.dart';
import 'package:lv_book/features/export/bulk_export_screen.dart';
import 'package:lv_book/features/fieldbook/data/fieldbook_providers.dart';
import 'package:lv_book/features/fieldbook/data/measurement_repository.dart';
import 'package:lv_book/features/fieldbook/domain/fieldbook.dart';
import 'package:lv_book/features/fieldbook/domain/measurement.dart';
import 'package:lv_book/features/fieldbook/domain/misclosure.dart';
import 'package:lv_book/features/pro/pro_providers.dart';
import 'package:lv_book/features/pro/pro_settings_repository.dart';
import 'package:lv_book/features/project/data/project_providers.dart';
import 'package:lv_book/features/project/data/project_repository.dart';
import 'package:lv_book/features/project/domain/project.dart';
import 'package:lv_book/features/purchase/purchase_controller.dart';
import 'package:lv_book/features/purchase/purchase_providers.dart';
import 'package:lv_book/features/review/review_prompt_policy.dart';
import 'package:lv_book/features/settings/misclosure_tolerance_repository.dart';
import 'package:lv_book/features/settings/settings_screen.dart';
import 'package:lv_book/l10n/l10n.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'fake_analytics_service.dart';

void main() {
  group('usage statistics setting', () {
    sqfliteFfiInit();
    final helper = DatabaseHelper.instance;
    late Database db;

    setUp(() async {
      db = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: helper.openDatabaseOptions(),
      );
      helper.setDatabaseForTesting(db);
    });

    tearDown(() async {
      helper.setDatabaseForTesting(null);
      await db.close();
    });

    test('defaults to on and persists the choice in app_settings', () async {
      final repository = AnalyticsSettingsRepository();
      expect(await repository.isUsageStatsEnabled(), isTrue);
      expect(await repository.readUsageStatsEnabled(), isTrue);

      await repository.setUsageStatsEnabled(false);
      expect(await AnalyticsSettingsRepository().isUsageStatsEnabled(), false);
      final rows = await db.query(
        'app_settings',
        where: 'key = ?',
        whereArgs: [AnalyticsSettingsRepository.usageStatsKey],
      );
      expect(rows.single['value'], 'false');

      await repository.setUsageStatsEnabled(true);
      expect(await repository.isUsageStatsEnabled(), isTrue);
    });

    test('an unreadable setting is reported as unknown, not as on', () async {
      helper.setDatabaseForTesting(null);
      final closed = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
      );
      await closed.close();
      helper.setDatabaseForTesting(closed);
      expect(await AnalyticsSettingsRepository().readUsageStatsEnabled(), null);
      helper.setDatabaseForTesting(db);
    });
  });

  testWidgets('settings switch persists and applies the choice at once', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      final analytics = FakeAnalyticsService();
      final settings = _MemoryAnalyticsSettingsRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            analyticsServiceProvider.overrideWithValue(analytics),
            analyticsSettingsRepositoryProvider.overrideWithValue(settings),
            adsRemovedProvider.overrideWith((ref) async => true),
            purchaseControllerProvider.overrideWith(_fakePurchaseController),
          ],
          child: MaterialApp(
            locale: const Locale('ko'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final tile = find.byKey(const ValueKey('usage-stats-switch'));
      await tester.scrollUntilVisible(tile, 200);
      expect(find.text('사용 통계 보내기'), findsOneWidget);
      expect(tester.widget<SwitchListTile>(tile).value, isTrue);

      await tester.tap(tile);
      await tester.pumpAndSettle();
      expect(settings.enabled, isFalse);
      expect(analytics.collection, [false]);
      expect(tester.widget<SwitchListTile>(tile).value, isFalse);
      // Pro user: no paywall impression.
      expect(analytics.named(AnalyticsEvents.proPaywallView), isEmpty);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('settings Pro panel logs one paywall view with its source', (
    tester,
  ) async {
    final analytics = FakeAnalyticsService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          analyticsServiceProvider.overrideWithValue(analytics),
          analyticsSettingsRepositoryProvider.overrideWithValue(
            _MemoryAnalyticsSettingsRepository(),
          ),
          adsRemovedProvider.overrideWith((ref) async => false),
          purchaseControllerProvider.overrideWith(_fakePurchaseController),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsScreen(
            paywallSource: AnalyticsValues.sourceProjectBanner,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Scrolling the panel away and back is still one view.
    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, 2000));
    await tester.pumpAndSettle();

    expect(analytics.named(AnalyticsEvents.proPaywallView).single.params, {
      AnalyticsParams.source: AnalyticsValues.sourceProjectBanner,
    });
  });

  group('parameter safety', () {
    test('free text is dropped; enums, booleans and numbers pass', () {
      final params = sanitizeAnalyticsParams({
        AnalyticsParams.format: AnalyticsValues.pdf,
        AnalyticsParams.bulk: true,
        AnalyticsParams.fileCount: 3,
        'site_name': '서울아산병원 현장',
        'note': 'BM.1 102.345',
        'elevation': double.nan,
        'Bad Key': AnalyticsValues.pdf,
        'missing': null,
      });
      expect(params, {
        AnalyticsParams.format: AnalyticsValues.pdf,
        AnalyticsParams.bulk: true,
        AnalyticsParams.fileCount: 3,
      });
    });

    test('catalogue names fit the GA4 limits', () {
      for (final name in [
        ...AnalyticsEvents.all,
        ...AnalyticsScreens.all,
        AnalyticsUserProperties.isPro,
      ]) {
        expect(isValidAnalyticsName(name), isTrue, reason: name);
      }
      for (final value in AnalyticsValues.all) {
        expect(value.length, lessThanOrEqualTo(analyticsMaxValueLength));
      }
    });

    test('counts are bucketed', () {
      expect(AnalyticsBuckets.count(0), '0');
      expect(AnalyticsBuckets.count(1), '1');
      expect(AnalyticsBuckets.count(4), '2-5');
      expect(AnalyticsBuckets.count(20), '6-20');
      expect(AnalyticsBuckets.count(37), '21-50');
      expect(AnalyticsBuckets.count(99), '51-100');
      expect(AnalyticsBuckets.count(5000), '101+');
    });

    test('Firebase service never forwards before init and never throws', () {
      // A failed init (no google-services.json) resolves to null: every call
      // is dropped silently.
      final service = FirebaseAnalyticsService(Future.value(null));
      service.logEvent(AnalyticsEvents.exportSuccess, {
        AnalyticsParams.format: AnalyticsValues.csv,
      });
      service.logEvent('Not A Valid Name');
      service.logScreenView('unknown_screen');
      service.setCollectionEnabled(true);
      service.setUserProperty(AnalyticsUserProperties.isPro, 'free text');
    });
  });

  group('Pro funnel (PurchaseController)', () {
    setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.android);
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    Future<(PurchaseController, _FakeInAppPurchase, FakeAnalyticsService)>
    start({OwnedPurchasesResult? owned}) async {
      final store = _FakeInAppPurchase();
      final analytics = FakeAnalyticsService();
      final controller = PurchaseController(
        adSettingsRepository: _MemoryAdSettingsRepository(),
        inAppPurchase: store,
        analytics: analytics,
        ownedPurchasesSource: _FakeOwnedPurchasesSource(
          owned ?? const OwnedPurchasesResult.success([]),
        ),
      );
      await controller.initialize();
      return (controller, store, analytics);
    }

    test('purchase start and success', () async {
      final (controller, store, analytics) = await start();
      await controller.buyPro();
      expect(analytics.named(AnalyticsEvents.proPurchaseStart), hasLength(1));

      store.emit([_pro(PurchaseStatus.purchased)]);
      await _settle();
      expect(analytics.named(AnalyticsEvents.proPurchaseSuccess), hasLength(1));
      expect(analytics.named(AnalyticsEvents.proRestore), isEmpty);
      controller.dispose();
    });

    test('a canceled purchase is reported as failed (canceled)', () async {
      final (controller, store, analytics) = await start();
      await controller.buyPro();
      store.emit([_pro(PurchaseStatus.canceled)]);
      await _settle();
      expect(analytics.named(AnalyticsEvents.proPurchaseFailed).single.params, {
        AnalyticsParams.reason: AnalyticsValues.canceled,
      });
      expect(analytics.named(AnalyticsEvents.proPurchaseSuccess), isEmpty);
      controller.dispose();
    });

    test('restore reports its result', () async {
      final (owned, _, ownedAnalytics) = await start(
        owned: OwnedPurchasesResult.success([_pro(PurchaseStatus.purchased)]),
      );
      await owned.restorePurchases();
      expect(ownedAnalytics.named(AnalyticsEvents.proRestore).single.params, {
        AnalyticsParams.result: AnalyticsValues.restored,
      });
      owned.dispose();

      final (none, _, noneAnalytics) = await start();
      await none.restorePurchases();
      expect(noneAnalytics.named(AnalyticsEvents.proRestore).single.params, {
        AnalyticsParams.result: AnalyticsValues.nothing,
      });
      none.dispose();
    });
  });

  test('review request is logged when the review API is called', () async {
    final analytics = FakeAnalyticsService();
    final coordinator = ReviewPromptCoordinator(
      policy: ReviewPromptPolicy(store: _MemoryReviewStore()),
      client: _FakeReviewClient(),
      analytics: analytics,
    );
    await coordinator.requestReview();
    expect(
      analytics.named(AnalyticsEvents.reviewPromptRequested).single.params,
      {AnalyticsParams.success: true},
    );
  });

  testWidgets('bulk export logs export_success without any user text', (
    tester,
  ) async {
    final tempDir = Directory.systemTemp.createTempSync('lvbook_analytics_');
    addTearDown(() => tempDir.deleteSync(recursive: true));
    final analytics = FakeAnalyticsService();
    final shared = <XFile>[];
    const secretTitle = 'Secret Site 현장 A';

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          analyticsServiceProvider.overrideWithValue(analytics),
          adsRemovedProvider.overrideWith((ref) async => true),
          adSettingsRepositoryProvider.overrideWithValue(
            _MemoryAdSettingsRepository()..adsRemoved = true,
          ),
          misclosureToleranceProvider.overrideWith(
            (ref) async => MisclosureTolerance.defaults,
          ),
          projectRepositoryProvider.overrideWithValue(_FakeProjectRepository()),
          proSettingsRepositoryProvider.overrideWithValue(
            ProSettingsRepository(store: MemoryProSettingsStore()),
          ),
          measurementRepositoryProvider.overrideWithValue(
            _MemoryMeasurementRepository(),
          ),
          bulkExportTemporaryDirectoryProvider.overrideWithValue(
            () async => tempDir,
          ),
          bulkExportShareProvider.overrideWithValue(
            (files) async => shared.addAll(files),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BulkExportScreen(
            projectId: 1,
            fieldBooks: [
              FieldBook(
                id: 1,
                projectId: 1,
                title: secretTitle,
                date: DateTime(2026, 6, 8),
                startElevation: 100,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('CSV'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.ios_share));
    // File writes are real I/O: alternate real waits with frame pumps.
    for (var i = 0; i < 100 && shared.isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump();
    }
    await tester.pumpAndSettle();

    expect(shared, hasLength(1));
    final event = analytics.named(AnalyticsEvents.exportSuccess).single;
    expect(event.params, {
      AnalyticsParams.format: AnalyticsValues.csv,
      AnalyticsParams.bulk: true,
      AnalyticsParams.fileCount: 1,
    });
    // Bulk export is Pro-only: a Pro user sees no paywall.
    expect(analytics.named(AnalyticsEvents.proPaywallView), isEmpty);
    for (final logged in analytics.events) {
      for (final value in logged.params.values) {
        expect('$value', isNot(contains('Secret')));
        expect('$value', isNot(contains('현장')));
      }
    }
  });

  testWidgets('bulk export lock banner logs one paywall view for free users', (
    tester,
  ) async {
    final analytics = FakeAnalyticsService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          analyticsServiceProvider.overrideWithValue(analytics),
          adsRemovedProvider.overrideWith((ref) async => false),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BulkExportScreen(
            projectId: 1,
            fieldBooks: [
              FieldBook(id: 1, projectId: 1, title: 'A', date: DateTime(2026)),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('CSV'));
    await tester.pumpAndSettle();

    expect(analytics.named(AnalyticsEvents.proPaywallView).single.params, {
      AnalyticsParams.source: AnalyticsValues.sourceBulkExport,
    });
  });

  test('route observer maps named page routes to screen views', () {
    final analytics = FakeAnalyticsService();
    final observer = AnalyticsRouteObserver(() => analytics);
    Route<void> page(String? name) => MaterialPageRoute<void>(
      settings: RouteSettings(name: name),
      builder: (_) => const SizedBox(),
    );

    observer.didPush(page('/'), null);
    observer.didPush(page(AnalyticsScreens.settings), null);
    observer.didPush(page(null), null);
    observer.didPush(page('some_unknown_route'), null);
    observer.didPop(page(AnalyticsScreens.pegTest), page('/'));
    expect(analytics.screens, [
      AnalyticsScreens.projectList,
      AnalyticsScreens.settings,
      AnalyticsScreens.projectList,
    ]);
  });
}

PurchaseController _fakePurchaseController(Ref ref) {
  final controller = PurchaseController(
    adSettingsRepository: _MemoryAdSettingsRepository(),
    inAppPurchase: _FakeInAppPurchase(),
    ownedPurchasesSource: _FakeOwnedPurchasesSource(
      const OwnedPurchasesResult.success([]),
    ),
  );
  controller.initialize();
  return controller;
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

PurchaseDetails _pro(PurchaseStatus status) => PurchaseDetails(
  productID: PurchaseController.proProductId,
  verificationData: PurchaseVerificationData(
    localVerificationData: '',
    serverVerificationData: '',
    source: 'test',
  ),
  transactionDate: null,
  status: status,
);

class _MemoryAnalyticsSettingsRepository extends AnalyticsSettingsRepository {
  bool? enabled;

  @override
  Future<bool> isUsageStatsEnabled() async => enabled ?? true;

  @override
  Future<void> setUsageStatsEnabled(bool enabled) async {
    this.enabled = enabled;
  }
}

class _FakeOwnedPurchasesSource implements OwnedPurchasesSource {
  final OwnedPurchasesResult result;

  _FakeOwnedPurchasesSource(this.result);

  @override
  Future<OwnedPurchasesResult> query() async => result;
}

class _FakeInAppPurchase implements InAppPurchase {
  final _controller = StreamController<List<PurchaseDetails>>.broadcast();

  void emit(List<PurchaseDetails> purchases) => _controller.add(purchases);

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _controller.stream;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<ProductDetailsResponse> queryProductDetails(
    Set<String> identifiers,
  ) async => ProductDetailsResponse(
    productDetails: [
      ProductDetails(
        id: PurchaseController.proProductId,
        title: 'Pro',
        description: '',
        price: r'$4.99',
        rawPrice: 4.99,
        currencyCode: 'USD',
      ),
    ],
    notFoundIDs: const [],
  );

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async =>
      true;

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MemoryAdSettingsRepository extends AdSettingsRepository {
  bool adsRemoved = false;

  @override
  Future<bool> areAdsRemoved() async => adsRemoved;

  @override
  Future<void> setAdsRemoved(bool removed) async {
    adsRemoved = removed;
  }
}

class _MemoryReviewStore implements ReviewPromptStore {
  final values = <String, String>{};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

class _FakeReviewClient implements AppReviewClient {
  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<void> requestReview() async {}

  @override
  Future<void> openStoreListing() async {}
}

class _FakeProjectRepository extends ProjectRepository {
  @override
  Future<Project?> getById(int id) async => Project(
    id: id,
    name: 'Secret Company 현장',
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
}

class _MemoryMeasurementRepository extends MeasurementRepository {
  @override
  Future<List<Measurement>> getByFieldBookId(int fieldBookId) async => [
    Measurement(
      fieldBookId: fieldBookId,
      orderIndex: 0,
      stationName: 'BM.1',
      bs: 1,
      gh: 100,
    ),
    Measurement(
      fieldBookId: fieldBookId,
      orderIndex: 1,
      stationName: 'END',
      fs: 1,
      gh: 100,
    ),
  ];
}
