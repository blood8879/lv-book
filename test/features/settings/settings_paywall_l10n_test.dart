import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:lv_book/features/ads/ad_providers.dart';
import 'package:lv_book/features/ads/ad_settings_repository.dart';
import 'package:lv_book/features/backup/project_backup_service.dart';
import 'package:lv_book/features/pro/pro_pdf_settings.dart';
import 'package:lv_book/features/purchase/purchase_controller.dart';
import 'package:lv_book/features/purchase/purchase_providers.dart';
import 'package:lv_book/features/settings/settings_screen.dart';
import 'package:lv_book/l10n/l10n.dart';

void main() {
  testWidgets('English paywall shows the store price as a one-time purchase', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await tester.pumpWidget(_buildSettings(locale: const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Lv Book Pro'), findsOneWidget);
      expect(find.text(r'$4.99 · one-time purchase'), findsOneWidget);
      expect(find.text('Buy Lv Book Pro'), findsOneWidget);
      expect(find.text('Restore purchase'), findsOneWidget);
      expect(find.text('TBM/BM photo & location'), findsOneWidget);
      expect(find.textContaining('one-time purchase'), findsWidgets);
      expect(
        find.textContaining(RegExp('subscri', caseSensitive: false)),
        findsNothing,
      );
      expect(
        find.textContaining(RegExp('month', caseSensitive: false)),
        findsNothing,
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('Korean paywall keeps the existing wording', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    try {
      await tester.pumpWidget(_buildSettings(locale: const Locale('ko')));
      await tester.pumpAndSettle();

      expect(find.text('설정'), findsOneWidget);
      expect(find.text(r'$4.99 · 일회성 구매'), findsOneWidget);
      expect(find.text('레벨 야장 Pro 구매'), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  test('purchase notices render in both languages', () {
    final en = l10nFor(const Locale('en'));
    const nothing = PurchaseNotice(PurchaseNoticeCode.nothingToRestore);
    expect(nothing.localizedMessage(en), 'No purchases to restore.');
    expect(nothing.localizedMessage(l10nKo), '복원할 구매 내역이 없습니다.');
    expect(nothing.isError, isTrue);
    expect(
      const PurchaseNotice(PurchaseNoticeCode.proActivated).isError,
      isFalse,
    );
    expect(
      const PurchaseNotice(
        PurchaseNoticeCode.purchaseError,
        'Store says no',
      ).localizedMessage(en),
      'Store says no',
    );
  });

  test('backup errors render in both languages', () {
    const error = ProjectBackupException.of(ProjectBackupError.unsupported);
    expect(
      error.localizedMessage(l10nFor(const Locale('en'))),
      "This backup file isn't supported.",
    );
    expect(error.message, '지원하지 않는 백업 파일입니다.');
  });

  test('built-in preset names follow the app language until renamed', () {
    final en = l10nFor(const Locale('en'));
    final koDefaults = ProDocumentPresets.defaults();
    final enDefaults = ProDocumentPresets.defaults(l10n: en);

    expect(koDefaults.active.name, '기본 야장');
    expect(enDefaults.active.name, 'Standard level book');
    expect(
      enDefaults.presets.last.settings.watermarkText,
      en.proInspectionWatermarkDefault,
    );
    // Saved Korean default name is displayed in English (value unchanged).
    expect(koDefaults.active.displayName(en), 'Standard level book');
    expect(enDefaults.active.displayName(l10nKo), '기본 야장');

    final renamed = koDefaults.renamePreset('basic', '감리 제출');
    expect(renamed.active.displayName(en), '감리 제출');
    expect(ProDocumentTemplate.inspection.label(en), 'Inspection');
    expect(ProFileNamePattern.siteDateTitle.label(en), 'Site_Date_Level book');
  });
}

Widget _buildSettings({required Locale locale}) {
  return ProviderScope(
    overrides: [
      adsRemovedProvider.overrideWith((ref) async => false),
      purchaseControllerProvider.overrideWith((ref) {
        final controller = PurchaseController(
          adSettingsRepository: _MemoryAdSettingsRepository(),
          inAppPurchase: _FakeInAppPurchase(),
        );
        controller.initialize();
        return controller;
      }),
    ],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const SettingsScreen(),
    ),
  );
}

class _FakeInAppPurchase implements InAppPurchase {
  final _controller = StreamController<List<PurchaseDetails>>.broadcast();

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _controller.stream;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<ProductDetailsResponse> queryProductDetails(
    Set<String> identifiers,
  ) async {
    return ProductDetailsResponse(
      productDetails: [
        ProductDetails(
          id: PurchaseController.proProductId,
          title: 'Lv Book Pro',
          description: '',
          price: r'$4.99',
          rawPrice: 4.99,
          currencyCode: 'USD',
        ),
      ],
      notFoundIDs: const [],
    );
  }

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
