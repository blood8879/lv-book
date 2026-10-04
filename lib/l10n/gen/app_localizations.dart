import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

  /// No description provided for @coreAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get coreAdd;

  /// App name (MaterialApp title, app bar). Korean: 레벨 야장.
  ///
  /// In en, this message translates to:
  /// **'Lv Book'**
  String get coreAppName;

  /// Name of the one-time Pro purchase. Never call it a subscription.
  ///
  /// In en, this message translates to:
  /// **'Lv Book Pro'**
  String get coreAppProName;

  /// No description provided for @coreCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get coreCancel;

  /// No description provided for @coreClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get coreClose;

  /// Generic confirm/acknowledge button (Korean 확인).
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get coreConfirm;

  /// No description provided for @coreDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get coreDelete;

  /// Generic edit button (Korean 수정).
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get coreEdit;

  /// Generic error with technical detail appended.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String coreErrorWithDetail(String error);

  /// Shown when a picked CSV/JSON file is not valid UTF-8.
  ///
  /// In en, this message translates to:
  /// **'Only UTF-8 files are supported. In Excel, save the file again as \"CSV UTF-8 (Comma delimited)\".'**
  String get coreFileNotUtf8;

  /// Misclosure judgement: exceeds tolerance (Korean 확인 필요). A warning, never 'Fail'/'Rejected'.
  ///
  /// In en, this message translates to:
  /// **'Check required'**
  String get coreJudgementCheckRequired;

  /// Short form of the within-tolerance judgement for tight cells/pills (Korean 적합).
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get coreJudgementOk;

  /// Misclosure judgement: within tolerance (Korean 적합). Long form.
  ///
  /// In en, this message translates to:
  /// **'Within tolerance'**
  String get coreJudgementWithinTolerance;

  /// No description provided for @coreProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing…'**
  String get coreProcessing;

  /// No description provided for @coreRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get coreRetry;

  /// No description provided for @coreSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get coreSave;

  /// No description provided for @coreSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get coreSaved;

  /// Number of selected items.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{None selected} =1{1 selected} other{{count} selected}}'**
  String coreSelectedCount(int count);

  /// Project detail tab for BM/TBM management (Korean BM 관리).
  ///
  /// In en, this message translates to:
  /// **'Benchmarks'**
  String get projectDetailTabBenchmarks;

  /// Project detail tab listing level books (Korean 야장).
  ///
  /// In en, this message translates to:
  /// **'Level books'**
  String get projectDetailTabLevelBooks;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
