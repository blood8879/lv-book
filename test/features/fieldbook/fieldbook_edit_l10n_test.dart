import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lv_book/features/fieldbook/data/fieldbook_providers.dart';
import 'package:lv_book/features/fieldbook/data/measurement_repository.dart';
import 'package:lv_book/features/fieldbook/domain/fieldbook.dart';
import 'package:lv_book/features/fieldbook/domain/measurement.dart';
import 'package:lv_book/features/fieldbook/domain/measurement_validation.dart';
import 'package:lv_book/features/fieldbook/presentation/fieldbook_edit_screen.dart';
import 'package:lv_book/features/fieldbook/presentation/fieldbook_l10n.dart';
import 'package:lv_book/l10n/l10n.dart';

void main() {
  Widget app(Locale? locale) {
    return ProviderScope(
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
            ),
          ]),
        ),
        fieldBookListProvider.overrideWith(_StubFieldBookNotifier.new),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: locale == null
            ? null
            : AppLocalizations.localizationsDelegates,
        supportedLocales: locale == null
            ? const [Locale('en', 'US')]
            : AppLocalizations.supportedLocales,
        home: FieldBookEditScreen(
          fieldBook: FieldBook(
            id: 1,
            projectId: 1,
            title: 'Level run',
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

  testWidgets('field book editor renders in English', (tester) async {
    await useNarrowPhone(tester);
    await tester.pumpWidget(app(const Locale('en')));
    await tester.pumpAndSettle();

    expect(find.text('HI'), findsOneWidget);
    expect(find.text('RL'), findsOneWidget);
    expect(find.text('IH'), findsNothing);
    expect(find.text('GH'), findsNothing);
    expect(find.text('Start RL'), findsWidgets);
    // No closing reference: only the arithmetic check, labelled as such.
    expect(find.text('Misclosure'), findsNothing);
    expect(find.text('Arith. check'), findsOneWidget);
    expect(find.text('No closing RL'), findsOneWidget);
    expect(find.text('Closing RL'), findsOneWidget);
    expect(find.text('Not set'), findsOneWidget);
    expect(find.text('Arithmetic check: Within tolerance'), findsOneWidget);
    expect(find.text('Review'), findsOneWidget);
    expect(find.text('Draft'), findsOneWidget);
    expect(find.text('✓ First BS'), findsOneWidget);
    expect(find.textContaining(RegExp('[가-힣]')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('field book editor stays Korean without a delegate', (
    tester,
  ) async {
    await useNarrowPhone(tester);
    await tester.pumpWidget(app(null));
    await tester.pumpAndSettle();

    expect(find.text('IH'), findsOneWidget);
    expect(find.text('GH'), findsOneWidget);
    expect(find.text('검산 적합'), findsOneWidget);
    expect(find.text('✓ 첫 BS'), findsOneWidget);
  });

  test('validation codes map to English and Korean text', () {
    final result = MeasurementValidation.validate(
      measurements: [
        Measurement(fieldBookId: 1, orderIndex: 0, stationName: 'No.1', fs: 1),
      ],
      startElevation: 100,
    );
    final en = l10nFor(const Locale('en'));

    expect(result.issues, contains(MeasurementIssue.firstBsMissing));
    expect(
      result.localizedMessages(en),
      contains('The first row needs a backsight (BS).'),
    );
    expect(result.localizedJudgement(en), 'Check required');
    expect(result.localizedJudgement(l10nKo), result.judgementLabel);
    expect(result.localizedMessages(l10nKo), result.messages);
    for (final status in FieldBookReviewStatus.values) {
      expect(status.localizedLabel(l10nKo), status.label);
    }
    expect(FieldBookReviewStatus.needsCheck.localizedLabel(en), 'Needs check');
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
