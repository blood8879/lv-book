// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get coreAdd => 'Add';

  @override
  String get coreAppName => 'Lv Book';

  @override
  String get coreAppProName => 'Lv Book Pro';

  @override
  String get coreCancel => 'Cancel';

  @override
  String get coreClose => 'Close';

  @override
  String get coreConfirm => 'OK';

  @override
  String get coreDelete => 'Delete';

  @override
  String get coreEdit => 'Edit';

  @override
  String coreErrorWithDetail(String error) {
    return 'Error: $error';
  }

  @override
  String get coreFileNotUtf8 =>
      'Only UTF-8 files are supported. In Excel, save the file again as \"CSV UTF-8 (Comma delimited)\".';

  @override
  String get coreJudgementCheckRequired => 'Check required';

  @override
  String get coreJudgementOk => 'OK';

  @override
  String get coreJudgementWithinTolerance => 'Within tolerance';

  @override
  String get coreProcessing => 'Processing…';

  @override
  String get coreRetry => 'Retry';

  @override
  String get coreSave => 'Save';

  @override
  String get coreSaved => 'Saved';

  @override
  String coreSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selected',
      one: '1 selected',
      zero: 'None selected',
    );
    return '$_temp0';
  }

  @override
  String get projectDetailTabBenchmarks => 'Benchmarks';

  @override
  String get projectDetailTabLevelBooks => 'Level books';
}
