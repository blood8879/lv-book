import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lv_book/features/ads/ad_providers.dart';
import 'package:lv_book/features/ads/ad_settings_repository.dart';
import 'package:lv_book/features/project/data/project_providers.dart';
import 'package:lv_book/features/project/domain/project.dart';
import 'package:lv_book/features/project/presentation/project_list_screen.dart';
import 'package:lv_book/features/purchase/purchase_controller.dart';
import 'package:lv_book/features/purchase/purchase_providers.dart';

void main() {
  testWidgets('home exposes a Pro application entry point', (tester) async {
    await tester.pumpWidget(_buildProjectList(adsRemoved: false));
    await tester.pumpAndSettle();

    expect(find.text('레벨 야장 Pro'), findsOneWidget);
    expect(find.text('Pro 신청'), findsOneWidget);
    expect(find.textContaining('TBM/BM 사진'), findsOneWidget);
  });

  testWidgets('Pro entry point opens purchase and restore controls', (
    tester,
  ) async {
    await tester.pumpWidget(_buildProjectList(adsRemoved: false));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Pro 신청'));
    await tester.pumpAndSettle();

    expect(find.text('설정'), findsOneWidget);
    expect(find.text('레벨 야장 Pro 구매'), findsOneWidget);
    expect(find.text('구매 복원'), findsOneWidget);
    expect(find.text('TBM/BM 사진 좌표'), findsOneWidget);
  });

  testWidgets('home does not invite already active Pro users to apply again', (
    tester,
  ) async {
    await tester.pumpWidget(_buildProjectList(adsRemoved: true));
    await tester.pumpAndSettle();

    expect(find.text('Pro 활성화됨'), findsOneWidget);
    expect(find.text('Pro 신청'), findsNothing);
  });
}

Widget _buildProjectList({required bool adsRemoved}) {
  return ProviderScope(
    overrides: [
      adsRemovedProvider.overrideWith((ref) async => adsRemoved),
      projectListProvider.overrideWith(_EmptyProjectListNotifier.new),
      purchaseControllerProvider.overrideWith(
        (ref) => PurchaseController(
          adSettingsRepository: _MemoryAdSettingsRepository(adsRemoved),
        ),
      ),
    ],
    child: const MaterialApp(home: ProjectListScreen()),
  );
}

class _EmptyProjectListNotifier extends ProjectListNotifier {
  @override
  Future<List<Project>> build() async => const [];
}

class _MemoryAdSettingsRepository extends AdSettingsRepository {
  bool _adsRemoved;

  _MemoryAdSettingsRepository(this._adsRemoved);

  @override
  Future<bool> areAdsRemoved() async => _adsRemoved;

  @override
  Future<void> setAdsRemoved(bool removed) async {
    _adsRemoved = removed;
  }
}
