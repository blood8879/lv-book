// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get coreAdd => '추가';

  @override
  String get coreAppName => '레벨 야장';

  @override
  String get coreAppProName => '레벨 야장 Pro';

  @override
  String get coreCancel => '취소';

  @override
  String get coreClose => '닫기';

  @override
  String get coreConfirm => '확인';

  @override
  String get coreDelete => '삭제';

  @override
  String get coreEdit => '수정';

  @override
  String coreErrorWithDetail(String error) {
    return '오류: $error';
  }

  @override
  String get coreFileNotUtf8 =>
      'UTF-8 형식의 파일만 지원합니다. Excel에서 \"CSV UTF-8(쉼표로 분리)\" 형식으로 다시 저장해 주세요.';

  @override
  String get coreJudgementCheckRequired => '확인 필요';

  @override
  String get coreJudgementOk => '적합';

  @override
  String get coreJudgementWithinTolerance => '적합';

  @override
  String get coreProcessing => '처리 중';

  @override
  String get coreRetry => '다시 시도';

  @override
  String get coreSave => '저장';

  @override
  String get coreSaved => '저장됨';

  @override
  String coreSelectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count개 선택됨',
      zero: '선택 없음',
    );
    return '$_temp0';
  }

  @override
  String get projectDetailTabBenchmarks => 'BM 관리';

  @override
  String get projectDetailTabLevelBooks => '야장';
}
