import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lv_book/l10n/l10n.dart';

import '../../tool/merge_arb.dart' as merge_arb;

Map<String, dynamic> _readArb(String locale) =>
    jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync())
        as Map<String, dynamic>;

Set<String> _messageKeys(Map<String, dynamic> arb) =>
    arb.keys.where((k) => !k.startsWith('@')).toSet();

void main() {
  group('ARB files', () {
    test('fragments merge cleanly and app_*.arb are up to date', () {
      final merged = merge_arb.mergeArbFragments(Directory(merge_arb.kSrcDir));
      for (final locale in merge_arb.kLocales) {
        expect(
          File('lib/l10n/app_$locale.arb').readAsStringSync(),
          merged[locale],
          reason: 'lib/l10n/app_$locale.arb is stale: run tool/l10n.sh',
        );
      }
    });

    test('en and ko define identical key sets', () {
      expect(_messageKeys(_readArb('ko')), _messageKeys(_readArb('en')));
    });

    test('generated Dart knows every ARB key (gen-l10n was re-run)', () {
      final generated = File(
        'lib/l10n/gen/app_localizations.dart',
      ).readAsStringSync();
      for (final key in _messageKeys(_readArb('en'))) {
        expect(
          generated,
          contains(' $key'),
          reason: '"$key" missing from lib/l10n/gen: run tool/l10n.sh',
        );
      }
    });

    test('Korean judgement text never says 불합격; English never says Fail', () {
      for (final locale in ['en', 'ko']) {
        final text = _readArb(locale).values.whereType<String>().join('\n');
        expect(text, isNot(contains('불합격')));
        expect(text, isNot(contains(RegExp(r'\b(Fail|Failed|Rejected)\b'))));
        expect(text.toLowerCase(), isNot(contains('subscription')));
      }
    });
  });

  group('merge tool rejects', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('arb'));
    tearDown(() => dir.deleteSync(recursive: true));

    void write(String name, Map<String, Object> body) =>
        File('${dir.path}/$name').writeAsStringSync(jsonEncode(body));

    Matcher failsWith(String text) => throwsA(
      isA<merge_arb.ArbMergeException>().having(
        (e) => e.toString(),
        'errors',
        contains(text),
      ),
    );

    test('a key missing in one locale', () {
      write('core_en.arb', {'coreA': 'A', 'coreB': 'B'});
      write('core_ko.arb', {'coreA': '가'});
      expect(
        () => merge_arb.mergeArbFragments(dir),
        failsWith('"coreB" (core) missing in ko'),
      );
    });

    test('a duplicate key across fragments', () {
      write('core_en.arb', {'coreA': 'A'});
      write('core_ko.arb', {'coreA': '가'});
      write('export_en.arb', {'coreA': 'A'});
      write('export_ko.arb', {'coreA': '가'});
      expect(
        () => merge_arb.mergeArbFragments(dir),
        failsWith('duplicate key "coreA"'),
      );
    });

    test('a key without its area prefix', () {
      write('export_en.arb', {'shareTooltip': 'Share'});
      write('export_ko.arb', {'shareTooltip': '공유'});
      expect(
        () => merge_arb.mergeArbFragments(dir),
        failsWith('must start with one of export'),
      );
    });
  });

  group('locale policy', () {
    test('Korean device -> ko, everything else -> en', () {
      expect(resolveAppLocale(const [Locale('ko', 'KR')]), kKoreanLocale);
      expect(resolveAppLocale(const [Locale('en', 'US')]), kEnglishLocale);
      expect(resolveAppLocale(const [Locale('ja')]), kEnglishLocale);
      expect(
        resolveAppLocale(const [Locale('ja'), Locale('ko')]),
        kKoreanLocale,
      );
      expect(resolveAppLocale(null), kEnglishLocale);
      expect(resolveAppLocale(const []), kEnglishLocale);
    });

    test('l10nFor returns strings without a BuildContext', () {
      expect(l10nFor(const Locale('en')).coreAppName, 'Lv Book');
      expect(l10nFor(const Locale('ko', 'KR')).coreAppName, '레벨 야장');
      expect(l10nFor(const Locale('fr')).coreAppName, 'Lv Book');
      expect(l10nKo.coreCancel, '취소');
    });

    test('ICU placeholders and plurals', () {
      final en = l10nFor(kEnglishLocale);
      final ko = l10nFor(kKoreanLocale);
      expect(en.coreErrorWithDetail('x'), 'Error: x');
      expect(ko.coreErrorWithDetail('x'), '오류: x');
      expect(en.coreSelectedCount(0), 'None selected');
      expect(en.coreSelectedCount(1), '1 selected');
      expect(en.coreSelectedCount(3), '3 selected');
      expect(ko.coreSelectedCount(3), '3개 선택됨');
    });
  });

  testWidgets('context.l10n falls back to Korean without delegates', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(builder: (context) => Text(context.l10n.coreCancel)),
      ),
    );
    expect(find.text('취소'), findsOneWidget);
  });
}
