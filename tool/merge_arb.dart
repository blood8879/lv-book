// Merges per-area ARB fragments (lib/l10n/src/<area>_<locale>.arb) into the
// gen-l10n inputs lib/l10n/app_<locale>.arb.
//
//   dart run tool/merge_arb.dart          # write lib/l10n/app_*.arb
//   dart run tool/merge_arb.dart --check  # exit 1 if app_*.arb are stale
//
// Fails loudly (exit 1) on:
//   * a fragment for an unknown area or locale,
//   * a key that does not start with one of its area's prefixes,
//   * a key defined in more than one fragment,
//   * a key present in one locale but not the other,
//   * orphan "@key" metadata or a malformed fragment.
//
// Normally run through `tool/l10n.sh`, which also runs `flutter gen-l10n`.
// See docs/i18n-guide.md.
import 'dart:convert';
import 'dart:io';

/// Supported locales. The first one is the gen-l10n template (en).
const List<String> kLocales = ['en', 'ko'];

/// Area -> allowed key prefixes. A key must be `<prefix><UpperCaseOrDigit>...`.
/// One fragment per area keeps parallel work conflict-free.
const Map<String, List<String>> kAreaPrefixes = {
  'core': ['core'],
  'fieldbook': ['fieldbook', 'import', 'quickMemo'],
  'export': ['export'],
  'benchmark_project': ['project', 'benchmark'],
  'settings_pro': ['settings', 'pro', 'purchase', 'ads', 'backup'],
};

const String kSrcDir = 'lib/l10n/src';
const String kOutDir = 'lib/l10n';

class ArbMergeException implements Exception {
  final List<String> errors;
  ArbMergeException(this.errors);

  @override
  String toString() => 'ARB merge failed:\n  - ${errors.join('\n  - ')}';
}

final RegExp _fragmentName = RegExp(r'^([a-z_]+)_([a-z]{2})\.arb$');
final RegExp _camelKey = RegExp(r'^[a-z][a-zA-Z0-9]*$');

/// Merges all fragments under [srcDir] and returns locale -> merged JSON text
/// (deterministic: keys sorted, metadata right after its message).
Map<String, String> mergeArbFragments(Directory srcDir) {
  final errors = <String>[];
  // locale -> area -> decoded fragment
  final fragments = <String, Map<String, Map<String, dynamic>>>{
    for (final l in kLocales) l: {},
  };

  final files =
      srcDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.arb'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  for (final file in files) {
    final name = file.uri.pathSegments.last;
    final match = _fragmentName.firstMatch(name);
    if (match == null) {
      errors.add('$name: expected <area>_<locale>.arb');
      continue;
    }
    final area = match.group(1)!;
    final locale = match.group(2)!;
    if (!kAreaPrefixes.containsKey(area)) {
      errors.add(
        '$name: unknown area "$area" (known: ${kAreaPrefixes.keys.join(', ')})',
      );
      continue;
    }
    if (!kLocales.contains(locale)) {
      errors.add('$name: unsupported locale "$locale"');
      continue;
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(file.readAsStringSync());
    } on FormatException catch (e) {
      errors.add('$name: invalid JSON (${e.message})');
      continue;
    }
    if (decoded is! Map<String, dynamic>) {
      errors.add('$name: top level must be a JSON object');
      continue;
    }
    fragments[locale]![area] = decoded;
  }

  // Validate each fragment and collect messages.
  // locale -> key -> (area, value, metadata?)
  final merged =
      <String, Map<String, ({String area, Object value, Object? meta})>>{
        for (final l in kLocales) l: {},
      };
  for (final locale in kLocales) {
    for (final entry in fragments[locale]!.entries) {
      final area = entry.key;
      final data = entry.value;
      final file = '${area}_$locale.arb';
      for (final key in data.keys) {
        if (key == '@@locale') {
          if (data[key] != locale) {
            errors.add('$file: @@locale is "${data[key]}", expected "$locale"');
          }
          continue;
        }
        if (key.startsWith('@')) {
          if (!data.containsKey(key.substring(1))) {
            errors.add('$file: metadata "$key" has no matching message');
          }
          continue;
        }
        final value = data[key];
        if (value is! String) {
          errors.add('$file: "$key" must be a string');
          continue;
        }
        if (!_camelKey.hasMatch(key)) {
          errors.add('$file: "$key" is not lowerCamelCase');
        }
        final prefixes = kAreaPrefixes[area]!;
        final okPrefix = prefixes.any(
          (p) =>
              key.length > p.length &&
              key.startsWith(p) &&
              RegExp(r'[A-Z0-9]').hasMatch(key[p.length]),
        );
        if (!okPrefix) {
          errors.add(
            '$file: "$key" must start with one of ${prefixes.join('/')} '
            'followed by an upper-case letter',
          );
        }
        final existing = merged[locale]![key];
        if (existing != null) {
          errors.add(
            'duplicate key "$key" in ${existing.area}_$locale.arb and $file',
          );
          continue;
        }
        merged[locale]![key] = (area: area, value: value, meta: data['@$key']);
      }
    }
  }

  // Locale parity.
  final template = kLocales.first;
  final templateKeys = merged[template]!.keys.toSet();
  for (final locale in kLocales.skip(1)) {
    final keys = merged[locale]!.keys.toSet();
    for (final k in templateKeys.difference(keys)) {
      errors.add('"$k" (${merged[template]![k]!.area}) missing in $locale');
    }
    for (final k in keys.difference(templateKeys)) {
      errors.add('"$k" (${merged[locale]![k]!.area}) missing in $template');
    }
  }
  for (final locale in kLocales) {
    for (final area in kAreaPrefixes.keys) {
      final present = fragments[locale]!.containsKey(area);
      final presentElsewhere = kLocales.any(
        (l) => fragments[l]!.containsKey(area),
      );
      if (!present && presentElsewhere) {
        errors.add('missing fragment ${area}_$locale.arb');
      }
    }
  }

  if (errors.isNotEmpty) throw ArbMergeException(errors);

  const encoder = JsonEncoder.withIndent('  ');
  final out = <String, String>{};
  for (final locale in kLocales) {
    final map = <String, Object?>{'@@locale': locale};
    final keys = merged[locale]!.keys.toList()..sort();
    for (final key in keys) {
      final m = merged[locale]![key]!;
      map[key] = m.value;
      // gen-l10n reads placeholder metadata from the template (en); other
      // locales keep metadata only if the fragment author supplied it.
      if (m.meta != null) map['@$key'] = m.meta;
    }
    out[locale] = '${encoder.convert(map)}\n';
  }
  return out;
}

void main(List<String> args) {
  final check = args.contains('--check');
  final Map<String, String> result;
  try {
    result = mergeArbFragments(Directory(kSrcDir));
  } on ArbMergeException catch (e) {
    stderr.writeln(e);
    exitCode = 1;
    return;
  }
  var stale = false;
  for (final entry in result.entries) {
    final file = File('$kOutDir/app_${entry.key}.arb');
    final current = file.existsSync() ? file.readAsStringSync() : null;
    if (current == entry.value) continue;
    if (check) {
      stderr.writeln('${file.path} is stale. Run tool/l10n.sh');
      stale = true;
    } else {
      file.writeAsStringSync(entry.value);
      stdout.writeln('wrote ${file.path}');
    }
  }
  if (stale) exitCode = 1;
  if (!check) {
    stdout.writeln('ARB fragments merged (${result.keys.join('/')}).');
  }
}
