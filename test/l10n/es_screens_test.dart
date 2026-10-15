import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lv_book/app.dart';
import 'package:lv_book/features/ads/ad_providers.dart';
import 'package:lv_book/features/ads/ad_settings_repository.dart';
import 'package:lv_book/features/fieldbook/data/fieldbook_providers.dart';
import 'package:lv_book/features/fieldbook/data/measurement_repository.dart';
import 'package:lv_book/features/fieldbook/domain/fieldbook.dart';
import 'package:lv_book/features/fieldbook/domain/measurement.dart';
import 'package:lv_book/features/fieldbook/domain/reduction.dart';
import 'package:lv_book/features/fieldbook/presentation/fieldbook_edit_screen.dart';
import 'package:lv_book/features/project/data/project_providers.dart';
import 'package:lv_book/features/project/domain/project.dart';
import 'package:lv_book/features/project/presentation/project_list_screen.dart';
import 'package:lv_book/features/purchase/purchase_controller.dart';
import 'package:lv_book/features/purchase/purchase_providers.dart';
import 'package:lv_book/l10n/l10n.dart';

/// Spanish smoke tests on a narrow (360 px) phone: no overflow, no Korean or
/// English leftovers on the main screens.
void main() {
  const spanish = Locale('es');
  final hangul = RegExp('[가-힣]');

  Future<void> useNarrowPhone(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Widget localized(Widget home, {List<Override> overrides = const []}) =>
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          locale: spanish,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      );

  testWidgets('app shell on a Mexican Spanish device is Spanish', (
    tester,
  ) async {
    tester.platformDispatcher.localesTestValue = const [Locale('es', 'MX')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(const ProviderScope(child: LvBookApp()));
    await tester.pump();

    final navigator = tester.element(find.byType(Navigator).first);
    expect(Localizations.localeOf(navigator), spanish);
    expect(AppLocalizations.of(navigator)!.coreCancel, 'Cancelar');
    expect(MaterialLocalizations.of(navigator).backButtonTooltip, 'Atrás');
  });

  testWidgets('empty home fits a 360 px phone in Spanish', (tester) async {
    await useNarrowPhone(tester);
    await tester.pumpWidget(
      localized(
        const ProjectListScreen(),
        overrides: [
          adsRemovedProvider.overrideWith((ref) async => true),
          projectListProvider.overrideWith(_EmptyProjectListNotifier.new),
          purchaseControllerProvider.overrideWith(
            (ref) => PurchaseController(
              adSettingsRepository: _MemoryAdSettingsRepository(),
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Agregue su primera obra'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Crear proyecto'), findsOneWidget);
    expect(
      find.widgetWithText(OutlinedButton, 'Probar proyecto de ejemplo'),
      findsOneWidget,
    );
    expect(find.textContaining(hangul), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Crear proyecto'));
    await tester.pumpAndSettle();
    expect(find.text('Nuevo proyecto'), findsOneWidget);
    expect(find.text('Nombre de la obra *'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  Widget editor(FieldBook fieldBook) => localized(
    FieldBookEditScreen(fieldBook: fieldBook, projectId: 1),
    overrides: [
      measurementRepositoryProvider.overrideWithValue(
        _FakeMeasurementRepository([
          Measurement(
            fieldBookId: 1,
            orderIndex: 0,
            stationName: 'BM-1',
            bs: 1.5,
          ),
          Measurement(
            fieldBookId: 1,
            orderIndex: 1,
            stationName: 'No.1',
            fs: 1.5,
            designLevel: 99.9,
          ),
        ]),
      ),
      fieldBookListProvider.overrideWith(_StubFieldBookNotifier.new),
    ],
  );

  final book = FieldBook(
    id: 1,
    projectId: 1,
    title: 'Circuito A',
    date: DateTime(2026, 10, 4),
    startElevation: 100,
  );

  testWidgets('editor headers and summary are Spanish at 360 px', (
    tester,
  ) async {
    await useNarrowPhone(tester);
    await tester.pumpWidget(editor(book));
    await tester.pumpAndSettle();

    for (final header in ['Pto.', 'VAt', 'VAd', 'AI', 'Cota']) {
      expect(find.text(header), findsOneWidget, reason: header);
    }
    for (final english in ['BS', 'FS', 'HI', 'RL', 'ΣBS', 'ΣFS']) {
      expect(find.text(english), findsNothing, reason: english);
    }
    expect(find.text('ΣVAt'), findsOneWidget);
    expect(find.text('ΣVAd'), findsOneWidget);
    expect(find.text('Cota inicial'), findsWidgets);
    expect(find.text('Comp. arit.'), findsOneWidget);
    expect(
      find.text('Comprobación aritmética: Dentro de tolerancia'),
      findsOneWidget,
    );
    expect(find.text('✓ Primera VAt'), findsOneWidget);
    expect(find.textContaining(hangul), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('rise-and-fall editor with design columns fits at 360 px', (
    tester,
  ) async {
    await useNarrowPhone(tester);
    await tester.pumpWidget(
      editor(
        book.copyWith(
          reductionMethod: ReductionMethod.riseAndFall,
          showDesignLevel: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Asc/Desc'), findsOneWidget);
    expect(find.text('Cota proy.'), findsOneWidget);
    expect(find.text('Corte(+)/Rell.(−)'), findsOneWidget);
    expect(find.textContaining('ΣAsc'), findsOneWidget);
    expect(find.textContaining(hangul), findsNothing);
    expect(tester.takeException(), isNull);
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

class _StubFieldBookNotifier extends FieldBookListNotifier {
  @override
  Future<List<FieldBook>> build(int projectId) async => const [];
}
