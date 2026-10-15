import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lv_book/l10n/l10n.dart';
import 'package:pdf/pdf.dart' show TtfParser;

Map<String, dynamic> _readArb(String locale) =>
    jsonDecode(File('lib/l10n/app_$locale.arb').readAsStringSync())
        as Map<String, dynamic>;

Map<String, String> _messages(Map<String, dynamic> arb) => {
  for (final e in arb.entries)
    if (!e.key.startsWith('@') && e.value is String) e.key: e.value as String,
};

/// Placeholder names with their ICU kind ('' for a plain `{name}`, or
/// 'plural' / 'select'), e.g. {'count:plural', 'name:'}.
Set<String> _placeholders(String message) => {
  for (final m in RegExp(
    r'\{(\w+)\s*(?:,\s*(plural|select)\s*,|\})',
  ).allMatches(message))
    '${m.group(1)}:${m.group(2) ?? ''}',
};

/// Placeholders as plain `{name}` regardless of kind (a plural variable
/// also appears as `{count}` inside its branches).
Set<String> _names(String message) =>
    _placeholders(message).map((p) => p.split(':').first).toSet();

void main() {
  final en = _messages(_readArb('en'));
  final es = _messages(_readArb('es'));

  group('Spanish ARB', () {
    test('has exactly the English key set', () {
      expect(es.keys.toSet(), en.keys.toSet());
    });

    test('keeps every placeholder, plural and select of English', () {
      final mismatches = <String>[];
      for (final key in en.keys) {
        final enMessage = en[key]!;
        final esMessage = es[key]!;
        if (!setEquals(_names(enMessage), _names(esMessage))) {
          mismatches.add('$key: ${_names(enMessage)} vs ${_names(esMessage)}');
        }
        final enKinds = _placeholders(
          enMessage,
        ).where((p) => !p.endsWith(':')).toSet();
        final esKinds = _placeholders(
          esMessage,
        ).where((p) => !p.endsWith(':')).toSet();
        if (!setEquals(enKinds, esKinds)) {
          mismatches.add('$key: $enKinds vs $esKinds');
        }
      }
      expect(mismatches, isEmpty);
    });

    test('is actually translated (not copied from English)', () {
      String words(String s) => s.replaceAll(RegExp(r'\{\w+\}'), '');
      final same = [
        for (final key in en.keys)
          if (en[key] == es[key] &&
              RegExp('[a-z]{4,}').hasMatch(words(en[key]!)))
            key,
      ];
      // Words that are the same in Spanish ("Lv Book" has no 4-letter word).
      expect(same, ['coreErrorWithDetail', 'fieldbookClosingManualShort']);
    });

    test('never judges misclosure as a failure or sells a subscription', () {
      final text = es.values.join('\n').toLowerCase();
      for (final word in [
        'falla',
        'fallido',
        'rechazad',
        'reprobad',
        'no apto',
        'suscripci',
        'al mes',
      ]) {
        expect(text, isNot(contains(word)), reason: word);
      }
    });

    test('plural messages render for 0, 1 and many', () {
      final l10n = l10nFor(const Locale('es'));
      expect(l10n.coreSelectedCount(0), 'Ninguno seleccionado');
      expect(l10n.coreSelectedCount(1), '1 seleccionado');
      expect(l10n.coreSelectedCount(3), '3 seleccionados');
      expect(l10n.exportBulkShareButton(1), 'Compartir 1 libreta');
      expect(l10n.exportBulkShareButton(1000000), 'Compartir 1000000 libretas');
      expect(l10n.projectCardStatsOpen(2, 1), '2 libretas · 1 por revisar');
      expect(l10n.coreErrorWithDetail('x'), 'Error: x');
    });

    test('NotoSansKR (PDF font) has a glyph for every Spanish string', () {
      final font = TtfParser(
        ByteData.sublistView(
          File('assets/fonts/NotoSansKR-Regular.ttf').readAsBytesSync(),
        ),
      );
      final text = StringBuffer('áéíóúüñÁÉÍÓÚÜÑ¿¡ºª')..writeAll(es.values);
      final missing = text
          .toString()
          .runes
          .where((rune) => rune > 0x20)
          .where((rune) => !font.charToGlyphIndexMap.containsKey(rune))
          .map(String.fromCharCode)
          .toSet();
      expect(missing, isEmpty);
    });
  });

  group('Spanish locale policy', () {
    test('every Spanish region resolves to es', () {
      for (final locale in const [
        Locale('es'),
        Locale('es', 'ES'),
        Locale('es', 'MX'),
        Locale('es', '419'),
        Locale('es', 'AR'),
        Locale.fromSubtags(languageCode: 'es', scriptCode: 'Latn'),
      ]) {
        expect(resolveAppLocale([locale]), kSpanishLocale, reason: '$locale');
      }
      expect(
        resolveAppLocale(const [Locale('fr'), Locale('es', 'MX')]),
        kSpanishLocale,
      );
      expect(
        resolveAppLocale(const [Locale('es', 'MX'), Locale('en', 'US')]),
        kSpanishLocale,
      );
      expect(
        resolveAppLocale(const [Locale('en', 'US'), Locale('es', 'MX')]),
        kEnglishLocale,
      );
      expect(l10nFor(const Locale('es', 'MX')).coreCancel, 'Cancelar');
      expect(
        AppLocalizations.supportedLocales,
        containsAll(const [kEnglishLocale, kKoreanLocale, kSpanishLocale]),
      );
    });
  });
}
