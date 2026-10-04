/// Localization entry point. Import this file (not gen/ directly) from app
/// code:
///
/// ```dart
/// import 'package:lv_book/l10n/l10n.dart';
/// Text(context.l10n.coreCancel)
/// ```
///
/// See docs/i18n-guide.md for the workflow and glossary.
library;

import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter/widgets.dart' show BuildContext;

import 'gen/app_localizations.dart';

export 'gen/app_localizations.dart';

/// Locales the app ships, in priority order. English is the fallback.
const Locale kEnglishLocale = Locale('en');
const Locale kKoreanLocale = Locale('ko');

extension L10nX on BuildContext {
  /// Strings for the current app locale.
  ///
  /// Falls back to Korean when no [AppLocalizations] delegate is installed
  /// (e.g. widget tests that pump a bare `MaterialApp`), so existing tests
  /// asserting Korean text keep passing.
  AppLocalizations get l10n => AppLocalizations.of(this) ?? l10nKo;
}

/// Korean strings, used as the no-delegate fallback.
final AppLocalizations l10nKo = lookupAppLocalizations(kKoreanLocale);

/// Strings for [locale] (resolved with [resolveAppLocale]). For services and
/// tests that have no [BuildContext].
AppLocalizations l10nFor(Locale locale) =>
    lookupAppLocalizations(resolveAppLocale([locale]));

/// Strings for the device's preferred languages, for code that runs with no
/// widget tree (e.g. background services). Prefer passing `context.l10n`
/// from the caller whenever a context exists.
AppLocalizations l10nForPlatform() => lookupAppLocalizations(
  resolveAppLocale(PlatformDispatcher.instance.locales),
);

/// App locale policy: the first preferred locale whose language is Korean or
/// English wins; anything else falls back to English.
Locale resolveAppLocale(Iterable<Locale>? preferred) {
  for (final locale in preferred ?? const <Locale>[]) {
    switch (locale.languageCode) {
      case 'ko':
        return kKoreanLocale;
      case 'en':
        return kEnglishLocale;
    }
  }
  return kEnglishLocale;
}
