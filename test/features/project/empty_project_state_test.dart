import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lv_book/core/widgets/empty_state.dart';
import 'package:lv_book/features/ads/ad_providers.dart';
import 'package:lv_book/features/ads/ad_settings_repository.dart';
import 'package:lv_book/features/project/data/project_providers.dart';
import 'package:lv_book/features/project/domain/project.dart';
import 'package:lv_book/features/project/presentation/project_list_screen.dart';
import 'package:lv_book/features/purchase/purchase_controller.dart';
import 'package:lv_book/features/purchase/purchase_providers.dart';

void main() {
  testWidgets('empty home offers new-project and sample-project actions', (
    tester,
  ) async {
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
        child: const MaterialApp(home: ProjectListScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('첫 현장을 추가하세요'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '새 프로젝트 만들기'), findsOneWidget);
    expect(
      find.widgetWithText(OutlinedButton, '예제 프로젝트로 둘러보기'),
      findsOneWidget,
    );

    // Primary action opens the same dialog as the FAB.
    await tester.tap(find.text('새 프로젝트 만들기'));
    await tester.pumpAndSettle();
    expect(find.text('새 프로젝트'), findsOneWidget);
  });

  testWidgets('EmptyState without actions renders no buttons', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EmptyState(icon: Icons.inbox, title: 'T', message: 'M'),
        ),
      ),
    );

    expect(find.byType(FilledButton), findsNothing);
    expect(find.byType(OutlinedButton), findsNothing);
  });

  testWidgets('busy action is disabled and shows a spinner', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: Icons.inbox,
            title: 'T',
            message: 'M',
            secondaryAction: EmptyStateAction(
              label: '예제',
              busy: true,
              onPressed: () => taps++,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('예제'));
    expect(taps, 0);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
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
