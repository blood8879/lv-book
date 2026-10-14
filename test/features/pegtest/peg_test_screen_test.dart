import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lv_book/features/fieldbook/domain/misclosure.dart';
import 'package:lv_book/features/pegtest/data/peg_test_record_repository.dart';
import 'package:lv_book/features/pegtest/data/peg_test_settings_repository.dart';
import 'package:lv_book/features/pegtest/domain/peg_test_record.dart';
import 'package:lv_book/features/pegtest/presentation/peg_test_screen.dart';
import 'package:lv_book/features/settings/misclosure_tolerance_repository.dart';
import 'package:lv_book/l10n/l10n.dart';

void main() {
  Future<_MemoryPegTestRepository> pumpScreen(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    LengthUnit unit = LengthUnit.metres,
    PegTestSettings initial = const PegTestSettings(),
    _MemoryPegTestRecordRepository? records,
  }) async {
    // Tall view so the result card (below the record details) is built.
    if (tester.view.physicalSize.height / tester.view.devicePixelRatio < 1600) {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
    }
    final repository = _MemoryPegTestRepository(initial);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          misclosureToleranceProvider.overrideWith(
            (ref) async => MisclosureTolerance.defaults.copyWith(unit: unit),
          ),
          pegTestSettingsRepositoryProvider.overrideWithValue(repository),
          pegTestRecordRepositoryProvider.overrideWithValue(
            records ?? _MemoryPegTestRecordRepository(),
          ),
        ],
        child: MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const PegTestScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return repository;
  }

  Future<void> enterReadings(WidgetTester tester, {String b2 = '1.120'}) async {
    await tester.enterText(find.byKey(const ValueKey('peg-test-a1')), '1.525');
    await tester.enterText(find.byKey(const ValueKey('peg-test-b1')), '1.230');
    await tester.enterText(find.byKey(const ValueKey('peg-test-a2')), '1.410');
    await tester.enterText(find.byKey(const ValueKey('peg-test-b2')), b2);
    await tester.enterText(
      find.byKey(const ValueKey('peg-test-distance')),
      '40',
    );
    await tester.pumpAndSettle();
  }

  testWidgets('worked example shows the error and adjustment verdict', (
    tester,
  ) async {
    final repository = await pumpScreen(tester);
    expect(find.text('Two-peg test'), findsOneWidget);
    expect(
      find.text(
        'Enter all four readings and the peg distance to see the result.',
      ),
      findsOneWidget,
    );

    await enterReadings(tester);
    expect(find.text('Adjustment required'), findsOneWidget);
    expect(find.text('+5.0 mm'), findsOneWidget);
    expect(find.text('+12.5 mm'), findsOneWidget);
    expect(find.text('+25.8″'), findsOneWidget);
    expect(find.text('1.115 m'), findsOneWidget);
    expect(
      find.text('Adjust the reticle until the B staff reads 1.115 m.'),
      findsOneWidget,
    );

    // Inputs are persisted (debounced) for the next visit.
    await tester.pump(const Duration(seconds: 1));
    expect(repository.savedInputs?['b2'], '1.120');
    expect(repository.savedInputs?['distance'], '40');

    // A small error is within tolerance.
    await tester.enterText(find.byKey(const ValueKey('peg-test-b2')), '1.117');
    await tester.pumpAndSettle();
    expect(find.text('Within tolerance'), findsOneWidget);
    expect(find.text('Adjustment required'), findsNothing);
  });

  testWidgets('zero peg distance shows an error and no result', (tester) async {
    await pumpScreen(tester);
    await enterReadings(tester);
    await tester.enterText(
      find.byKey(const ValueKey('peg-test-distance')),
      '0',
    );
    await tester.pumpAndSettle();
    expect(find.text('Enter a distance greater than 0.'), findsOneWidget);
    expect(find.byKey(const ValueKey('peg-test-verdict')), findsNothing);
  });

  testWidgets('copy result puts the summary on the clipboard', (tester) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    // Tall view so the whole result card fits without scrolling.
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await pumpScreen(tester);
    await enterReadings(tester);
    await tester.tap(find.text('Copy result'));
    await tester.pumpAndSettle();
    expect(copied, contains('Result: Adjustment required'));
    expect(find.text('Result copied'), findsOneWidget);
  });

  testWidgets('save record → appears in history → delete', (tester) async {
    tester.view.physicalSize = const Size(800, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final records = _MemoryPegTestRecordRepository(
      metadata: (instrument: 'DL-500 #1234', observer: 'Kim'),
    );
    await pumpScreen(tester, records: records);

    // Save is disabled until there is a result.
    final save = find.byKey(const ValueKey('peg-test-save-record'));
    expect(tester.widget<FilledButton>(save).onPressed, isNull);
    // Instrument / observer are prefilled from the last record / field book.
    expect(find.text('DL-500 #1234 · Kim'), findsOneWidget);

    await enterReadings(tester);
    await tester.tap(find.text('Record details (optional)'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('peg-test-note')),
      'Before section 3',
    );
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.text('Record saved'), findsOneWidget);
    expect(records.records, hasLength(1));
    final saved = records.records.single;
    expect(saved.instrument, 'DL-500 #1234');
    expect(saved.observer, 'Kim');
    expect(saved.note, 'Before section 3');
    expect(saved.b2, 1.120);
    expect(saved.unit, LengthUnit.metres);
    expect(saved.toleranceEntry, 3.0);

    await tester.tap(find.byTooltip('Saved tests'));
    await tester.pumpAndSettle();
    expect(find.text('Saved two-peg tests'), findsOneWidget);
    expect(find.text('DL-500 #1234 · Kim'), findsOneWidget);
    expect(find.text('+5.0 mm'), findsOneWidget);
    expect(find.text('Adjustment required'), findsOneWidget);

    await tester.tap(find.byKey(ValueKey('peg-test-record-${saved.id}')));
    await tester.pumpAndSettle();
    expect(find.text('Two-peg test record'), findsOneWidget);
    expect(find.text('Before section 3'), findsOneWidget);
    expect(find.text('1.115 m'), findsOneWidget);
    // Read-only: no save button on a saved record.
    expect(find.byKey(const ValueKey('peg-test-save-record')), findsNothing);

    await tester.tap(find.byTooltip('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete this record?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(records.records, isEmpty);
    expect(find.text('Saved two-peg tests'), findsOneWidget);
    expect(find.text('No saved tests yet'), findsOneWidget);
    expect(find.text('Record deleted'), findsOneWidget);
  });

  testWidgets('restores saved inputs and edits the tolerance (Korean, ft)', (
    tester,
  ) async {
    final repository = await pumpScreen(
      tester,
      locale: const Locale('ko'),
      unit: LengthUnit.feet,
      initial: const PegTestSettings(
        inputs: {
          'a1': '5.000',
          'b1': '4.000',
          'a2': '5.200',
          'b2': '4.215',
          'distance': '150',
        },
      ),
    );
    expect(find.text('2점법 시준 검사'), findsOneWidget);
    expect(find.text('+0.0150 ft'), findsOneWidget);
    expect(find.text('조정 필요'), findsOneWidget);

    await tester.tap(find.byTooltip('허용오차 수정'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '0.02');
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();
    expect(repository.savedTolerance, (LengthUnit.feet, 0.02));
    expect(find.text('적합'), findsOneWidget);
  });
}

class _MemoryPegTestRecordRepository extends PegTestRecordRepository {
  final List<PegTestRecord> records = [];
  PegTestMetadata metadata;
  var _nextId = 1;

  _MemoryPegTestRecordRepository({
    this.metadata = (instrument: null, observer: null),
  });

  @override
  Future<int> create(PegTestRecord record) async {
    final id = _nextId++;
    records.add(PegTestRecord.fromMap({...record.toMap(), 'id': id}));
    return id;
  }

  @override
  Future<List<PegTestRecord>> list() async =>
      records.reversed.toList(growable: false);

  @override
  Future<int> delete(int id) async {
    final before = records.length;
    records.removeWhere((record) => record.id == id);
    return before - records.length;
  }

  @override
  Future<PegTestMetadata> lastMetadata() async => metadata;
}

class _MemoryPegTestRepository extends PegTestSettingsRepository {
  final PegTestSettings initial;
  Map<String, String>? savedInputs;
  (LengthUnit, double)? savedTolerance;

  _MemoryPegTestRepository(this.initial);

  @override
  Future<PegTestSettings> load() async => initial;

  @override
  Future<void> saveTolerance(LengthUnit unit, double value) async {
    savedTolerance = (unit, value);
  }

  @override
  Future<void> saveInputs(Map<String, String> inputs) async {
    savedInputs = inputs;
  }
}
