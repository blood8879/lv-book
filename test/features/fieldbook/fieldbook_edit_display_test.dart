import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lv_book/features/fieldbook/data/fieldbook_providers.dart';
import 'package:lv_book/features/fieldbook/data/measurement_repository.dart';
import 'package:lv_book/features/fieldbook/domain/fieldbook.dart';
import 'package:lv_book/features/fieldbook/domain/measurement.dart';
import 'package:lv_book/features/fieldbook/presentation/fieldbook_edit_screen.dart';
import 'package:lv_book/features/quickmemo/presentation/quick_memo_fab.dart';

void main() {
  Widget app(MeasurementRepository repo) {
    return ProviderScope(
      overrides: [
        measurementRepositoryProvider.overrideWithValue(repo),
        fieldBookListProvider.overrideWith(_StubFieldBookNotifier.new),
      ],
      child: MaterialApp(
        home: FieldBookEditScreen(
          fieldBook: FieldBook(
            id: 1,
            projectId: 1,
            title: '표시 형식 야장',
            date: DateTime(2026, 10, 4),
            startElevation: 100,
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

  test('formatReadingText pads to 3 decimals without rounding', () {
    expect(formatReadingText(1.94), '1.940');
    expect(formatReadingText(1.25), '1.250');
    expect(formatReadingText(-0.5), '-0.500');
    expect(formatReadingText(1.2345), '1.2345');
  });

  testWidgets('loaded BS/FS values are shown with 3 decimals', (tester) async {
    await useNarrowPhone(tester);
    await tester.pumpWidget(
      app(
        _FakeMeasurementRepository([
          Measurement(
            fieldBookId: 1,
            orderIndex: 0,
            stationName: 'BM-1',
            bs: 1.94,
          ),
          Measurement(
            fieldBookId: 1,
            orderIndex: 1,
            stationName: 'No.1',
            fs: 1.25,
          ),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, '1.940'), findsOneWidget);
    expect(find.widgetWithText(TextField, '1.250'), findsOneWidget);
    expect(find.widgetWithText(TextField, '1.94'), findsNothing);
  });

  testWidgets('typed value is formatted only after the cell loses focus', (
    tester,
  ) async {
    await useNarrowPhone(tester);
    await tester.pumpWidget(app(_FakeMeasurementRepository(const [])));
    await tester.pumpAndSettle();

    final cells = find.byType(TextField);
    // Index 0 is the start elevation field; 1 is row 1 BS, 2 is row 1 FS.
    await tester.enterText(cells.at(1), '1.5');
    await tester.pump();
    expect(find.widgetWithText(TextField, '1.5'), findsOneWidget);

    await tester.tap(cells.at(2));
    await tester.pump();
    expect(find.widgetWithText(TextField, '1.500'), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 2));
  });

  testWidgets('long station names wrap in the NO column at 360pt', (
    tester,
  ) async {
    await useNarrowPhone(tester);
    await tester.pumpWidget(
      app(
        _FakeMeasurementRepository([
          Measurement(
            fieldBookId: 1,
            orderIndex: 0,
            stationName: 'BM-1 (폐합)',
            bs: 1.94,
          ),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    final name = tester.widget<Text>(find.text('BM-1 (폐합)'));
    expect(name.maxLines, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets('HideQuickMemoFab hides the FAB only while its page is on top', (
    tester,
  ) async {
    final controller = QuickMemoFabController();
    addTearDown(controller.dispose);
    final navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        navigatorObservers: [controller],
        builder: (context, child) => QuickMemoFabScope(
          controller: controller,
          child: Stack(
            children: [
              Positioned.fill(child: child!),
              QuickMemoFab(navigatorKey: navigatorKey, controller: controller),
            ],
          ),
        ),
        home: const Scaffold(body: Text('home')),
      ),
    );
    expect(find.byIcon(Icons.bolt), findsOneWidget);

    navigatorKey.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) =>
            const HideQuickMemoFab(child: Scaffold(body: Text('editor'))),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.bolt), findsNothing);

    // A dialog over the editor does not bring the FAB back.
    showDialog<void>(
      context: navigatorKey.currentContext!,
      builder: (_) => const AlertDialog(content: Text('dialog')),
    );
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.bolt), findsNothing);

    navigatorKey.currentState!.pop();
    await tester.pumpAndSettle();
    navigatorKey.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
    expect(find.byIcon(Icons.bolt), findsOneWidget);
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

class _StubFieldBookNotifier extends FieldBookListNotifier {
  @override
  Future<List<FieldBook>> build(int projectId) async => const [];
}
