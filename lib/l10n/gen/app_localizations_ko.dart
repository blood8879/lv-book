// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get adsNativeAdLabel => 'AD 광고';

  @override
  String get adsPolicyBannerSubtitle => '화면 폭에 맞는 적응형 배너를 하단에 표시합니다.';

  @override
  String get adsPolicyBannerTitle => '배너 광고';

  @override
  String get adsPolicyExportSubtitle => '공유 완료 후 최대 하루 3회, 10분 간격으로만 표시합니다.';

  @override
  String get adsPolicyExportTitle => '내보내기 광고';

  @override
  String get adsPolicySection => '광고 노출 정책';

  @override
  String get backupErrorBenchmarkCorrupted => 'BM 데이터가 손상되었습니다.';

  @override
  String get backupErrorCorrupted => '백업 데이터가 손상되었습니다.';

  @override
  String get backupErrorFieldBookCorrupted => '야장 데이터가 손상되었습니다.';

  @override
  String get backupErrorInvalidFormat => '백업 파일 형식이 올바르지 않습니다.';

  @override
  String get backupErrorMeasurementCorrupted => '측점 데이터가 손상되었습니다.';

  @override
  String get backupErrorPhotoCorrupted => '사진 백업 데이터가 손상되었습니다.';

  @override
  String get backupErrorProjectNotFound => '프로젝트를 찾을 수 없습니다.';

  @override
  String get backupErrorUnsupported => '지원하지 않는 백업 파일입니다.';

  @override
  String benchmarkAccuracy(String accuracy) {
    return '정확도 ${accuracy}m';
  }

  @override
  String get benchmarkAddDialogTitle => '새 BM 추가';

  @override
  String get benchmarkCopyCoordinateButton => '좌표 복사';

  @override
  String benchmarkCopyCoordinateText(String latitude, String longitude) {
    return '위도 $latitude, 경도 $longitude';
  }

  @override
  String benchmarkDeleteConfirm(String name, String elevation) {
    return '\"$name\" (표고: $elevation)을 삭제하시겠습니까?';
  }

  @override
  String get benchmarkDeleteDialogTitle => 'BM 삭제';

  @override
  String get benchmarkDescriptionLabel => '설명 (선택)';

  @override
  String get benchmarkEditDialogTitle => 'BM 수정';

  @override
  String get benchmarkElevationHint => '예: 100.000';

  @override
  String benchmarkElevationInvalidError(String unit) {
    return '표고를 숫자($unit)로 입력하세요';
  }

  @override
  String benchmarkElevationLabel(String unit) {
    return '표고 ($unit) *';
  }

  @override
  String benchmarkElevationLine(String elevation, String unit) {
    return '표고 $elevation $unit';
  }

  @override
  String get benchmarkEmptyMessage =>
      '+ 버튼으로 표고 기준이 되는 BM/TBM을 추가하면\n야장 작성 시 시작 표고로 바로 불러올 수 있습니다.';

  @override
  String get benchmarkEmptyTitle => 'BM(기준점)을 등록하세요';

  @override
  String get benchmarkKindLabel => '종류';

  @override
  String benchmarkKindLine(String kind) {
    return '종류: $kind';
  }

  @override
  String get benchmarkLocationHintLabel => '현장 위치 힌트';

  @override
  String benchmarkLocationLine(String hint) {
    return '위치: $hint';
  }

  @override
  String get benchmarkLocationPermissionDenied => '위치 권한이 거부되었습니다.';

  @override
  String get benchmarkLocationPermissionDeniedForever =>
      '위치 권한이 영구적으로 거부되었습니다. 앱 설정에서 권한을 허용하세요.';

  @override
  String get benchmarkLocationServiceOff => '기기 위치 서비스가 꺼져 있습니다.';

  @override
  String get benchmarkMapOpenError => '지도 앱을 열 수 없습니다. 좌표를 복사해 사용하세요.';

  @override
  String get benchmarkNameHint => '예: BM.1';

  @override
  String get benchmarkNameLabel => 'BM 이름 *';

  @override
  String get benchmarkNameRequiredError => 'BM 이름을 입력하세요';

  @override
  String get benchmarkNoSavedCoordinate => '저장된 좌표가 없습니다.';

  @override
  String get benchmarkNoSavedPhoto => '저장된 사진이 없습니다.';

  @override
  String get benchmarkOpenMapButton => '지도 열기';

  @override
  String get benchmarkPhotoFileMissing => '사진 파일을 찾을 수 없습니다.';

  @override
  String get benchmarkPhotoNeedsSavedBm => '저장된 BM만 사진을 추가할 수 있습니다.';

  @override
  String get benchmarkPhotoSaveError => '사진을 저장하지 못했습니다.';

  @override
  String get benchmarkPhotoSaved => '사진 저장됨';

  @override
  String get benchmarkPickPhotoButton => '사진 선택';

  @override
  String get benchmarkProLocationPromo => 'Pro에서 TBM/BM 사진과 좌표를 저장할 수 있습니다.';

  @override
  String get benchmarkProLocationSaved => 'Pro 위치 정보 저장됨';

  @override
  String get benchmarkProLocationTitle => 'Pro 위치 기록';

  @override
  String get benchmarkProRequired => '레벨 야장 Pro 구매 후 사용할 수 있습니다.';

  @override
  String get benchmarkProtectionLabel => '보호/확인 메모';

  @override
  String benchmarkProtectionLine(String note) {
    return '보호: $note';
  }

  @override
  String get benchmarkRecheckNoVerifiedDate => '최종 확인일이 없습니다. 재확인 필요';

  @override
  String get benchmarkRecheckOutOfService =>
      '사용 중지 BM입니다. 새 야장의 시작 BM으로 사용할 수 없습니다.';

  @override
  String get benchmarkRecheckPossiblyDamaged =>
      '훼손 의심 BM입니다. 사용 전 현장에서 재확인하세요.';

  @override
  String benchmarkRecheckStale(int days) {
    return '마지막 확인 후 $days일이 지났습니다. 재확인 필요';
  }

  @override
  String get benchmarkRemovePhotoButton => '사진 제거';

  @override
  String get benchmarkSaveCurrentCoordinate => '현재 좌표 저장';

  @override
  String get benchmarkSavingCoordinate => '좌표 저장 중';

  @override
  String get benchmarkStatusLabel => '상태';

  @override
  String get benchmarkStatusOutOfService => '사용 중지';

  @override
  String get benchmarkStatusPossiblyDamaged => '훼손 의심';

  @override
  String get benchmarkStatusUsable => '사용 가능';

  @override
  String get benchmarkTakePhotoButton => '사진 촬영';

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
  String get exportBulkDeselectAll => '해제';

  @override
  String exportBulkError(String error) {
    return '일괄 내보내기 실패: $error';
  }

  @override
  String get exportBulkFormatBoth => '둘 다';

  @override
  String get exportBulkManifestSubtitle => '선택한 야장, 생성 파일, 측점 수를 함께 정리합니다.';

  @override
  String get exportBulkManifestTitle => '제출 패키지 manifest 포함';

  @override
  String get exportBulkNothingToExport => '내보낼 데이터가 있는 야장이 없습니다';

  @override
  String get exportBulkProOnlyBody => '여러 야장을 한 번에 PDF/CSV로 공유할 수 있습니다.';

  @override
  String get exportBulkProOnlyTitle => 'Pro 전용 기능';

  @override
  String get exportBulkProRequired => '레벨 야장 Pro 구매 후 사용할 수 있습니다.';

  @override
  String get exportBulkSelectAll => '전체';

  @override
  String exportBulkShareButton(int count) {
    return '$count개 야장 공유';
  }

  @override
  String exportBulkShared(int count) {
    return '$count개 파일을 공유했습니다';
  }

  @override
  String get exportBulkSummarySubtitle => '야장별 BM, 작업구간, 오차, 판정을 한 파일로 묶습니다.';

  @override
  String get exportBulkSummaryTitle => '검측/제출 요약 CSV 포함';

  @override
  String get exportBulkTitle => '일괄 내보내기';

  @override
  String get exportCheckAllowed => '허용';

  @override
  String get exportCheckDifference => 'ΣBS - ΣFS';

  @override
  String get exportCheckFinalRl => '최종 GH';

  @override
  String get exportCheckMisclosure => '폐합오차';

  @override
  String get exportCheckMisclosureUnavailable => '없음 (폐합 기준 없음)';

  @override
  String get exportCheckResult => '검산 판정';

  @override
  String get exportCheckRiseFallDifference => 'Σ승 − Σ강';

  @override
  String get exportCheckRlDifference => '최종 - 시작';

  @override
  String get exportCheckStartRl => '시작 GH';

  @override
  String get exportCheckSumFall => 'Σ강';

  @override
  String get exportCheckSumRise => 'Σ승';

  @override
  String get exportCheckTitle => '검산';

  @override
  String get exportCheckTitleWithClosure => '검산 및 폐합오차';

  @override
  String exportCheckValue(String label, String value) {
    return '$label = $value';
  }

  @override
  String exportClosingLoopName(String name) {
    return '$name (왕복)';
  }

  @override
  String get exportColumnBs => '후시(BS)';

  @override
  String get exportColumnFall => '강(−)';

  @override
  String get exportColumnFs => '전시(FS)';

  @override
  String get exportColumnHi => '기계고(IH)';

  @override
  String get exportColumnIs => '중간점(IS)';

  @override
  String get exportColumnNo => 'No.';

  @override
  String get exportColumnRemarks => '비고';

  @override
  String get exportColumnRise => '승(+)';

  @override
  String get exportColumnRl => '지반고(GH)';

  @override
  String get exportColumnStation => '측점명';

  @override
  String get exportCompanyNotSet => '회사명 미입력';

  @override
  String exportCsvError(String error) {
    return 'CSV 생성 실패: $error';
  }

  @override
  String get exportDocTitle => '직접수준측량 야장';

  @override
  String exportDocTitleWithTemplate(String template) {
    return '직접수준측량 야장 · $template';
  }

  @override
  String get exportFieldAuthor => '작성자';

  @override
  String get exportFieldBmElevation => 'BM 표고';

  @override
  String get exportFieldChecker => '검측자';

  @override
  String get exportFieldClosingBm => '폐합 BM';

  @override
  String get exportFieldClosingRl => '폐합 표고';

  @override
  String get exportFieldCompany => '회사명';

  @override
  String get exportFieldDate => '날짜';

  @override
  String get exportFieldInstrument => '장비';

  @override
  String get exportFieldJobNumber => '공사번호';

  @override
  String get exportFieldMemo => '메모';

  @override
  String get exportFieldReductionMethod => '기입 방식';

  @override
  String get exportFieldReviewDate => '검토일';

  @override
  String get exportFieldReviewMemo => '검토 메모';

  @override
  String get exportFieldReviewStatus => '검토 상태';

  @override
  String get exportFieldSection => '작업구간';

  @override
  String get exportFieldStartBm => '시작 BM';

  @override
  String get exportFieldSurveyor => '측량자';

  @override
  String get exportFieldTitle => '야장명';

  @override
  String get exportFieldUnit => '단위';

  @override
  String get exportFieldWeather => '날씨';

  @override
  String exportImportDateMissing(String date) {
    return '날짜 항목이 없어 $date로 설정했습니다.';
  }

  @override
  String exportImportDateUnrecognized(String value, String date) {
    return '날짜 \"$value\"를 인식할 수 없어 $date로 설정했습니다.';
  }

  @override
  String get exportImportDefaultTitle => '가져온 야장';

  @override
  String get exportImportHeaderNotFound => '측량 표 헤더를 찾을 수 없습니다.';

  @override
  String exportImportInvalidNumber(int row, String column) {
    return '$row행 $column 숫자 형식이 올바르지 않습니다.';
  }

  @override
  String exportImportUnitMismatch(String fileUnit, String appUnit) {
    return '파일 단위는 $fileUnit, 앱 단위는 $appUnit입니다. 값은 변환 없이 가져왔습니다.';
  }

  @override
  String get exportImportUtf8Only =>
      'UTF-8 CSV만 지원합니다. 글자가 깨진 문자가 있어 가져올 수 없습니다. Excel에서 \"CSV UTF-8(쉼표로 분리)\" 형식으로 다시 저장해 주세요.';

  @override
  String exportLabelValue(String label, String value) {
    return '$label: $value';
  }

  @override
  String exportManifestFieldBookLine(String title, int count, String status) {
    return '- $title: 측점 $count개, 검토 상태 $status';
  }

  @override
  String exportManifestFileCount(int count) {
    return '파일 수: $count';
  }

  @override
  String get exportManifestIncludedFiles => '포함 파일';

  @override
  String exportManifestSite(String name) {
    return '현장: $name';
  }

  @override
  String get exportManifestSiteNotSet => '현장명 미입력';

  @override
  String get exportManifestTitle => '레벨 야장 제출 패키지';

  @override
  String get exportPackageNoFieldBooks => '패키지로 만들 야장이 없습니다.';

  @override
  String get exportPackageNoFiles => '패키지로 만들 파일이 없습니다.';

  @override
  String get exportPackageZipError => '제출 패키지 ZIP 생성에 실패했습니다.';

  @override
  String exportPdfError(String error) {
    return 'PDF 생성 실패: $error';
  }

  @override
  String get exportReductionHi => '기고식';

  @override
  String get exportReductionRiseFall => '승강식';

  @override
  String get exportReviewStatusDraft => '작성중';

  @override
  String get exportReviewStatusNeedsCheck => '확인필요';

  @override
  String get exportReviewStatusReviewed => '검토완료';

  @override
  String get exportScreenTitle => '내보내기';

  @override
  String get exportShareCsvTooltip => 'CSV 공유';

  @override
  String get exportSharePdfTooltip => 'PDF 공유';

  @override
  String get exportSignatureApproved => '승인';

  @override
  String get exportSignatureChecked => '검토';

  @override
  String get exportSignaturePrepared => '작성';

  @override
  String get exportSummaryFileSuffix => '요약';

  @override
  String get exportSummaryNoSelection => '요약할 야장을 선택하세요.';

  @override
  String get fieldbookAddTenRowsTooltip => '10행 추가';

  @override
  String fieldbookArithmeticCheckResult(String result) {
    return '검산 $result';
  }

  @override
  String get fieldbookBackupPasteHint =>
      '또는 공유받은 lvbook_backup.json 내용을 붙여넣으세요.';

  @override
  String get fieldbookBackupRestoredMessage => '백업을 새 프로젝트로 복원했습니다.';

  @override
  String get fieldbookBmNameHint => '예: BM.1';

  @override
  String get fieldbookBmNameLabel => 'BM 이름 (선택)';

  @override
  String get fieldbookBulkExportButton => '일괄 내보내기';

  @override
  String get fieldbookCheckArithmetic => '검산';

  @override
  String get fieldbookCheckEmptyRows => '빈 행';

  @override
  String get fieldbookCheckFirstBs => '첫 BS';

  @override
  String get fieldbookCheckLastFs => '마지막 FS';

  @override
  String get fieldbookCheckRiseFall => '승강 검산';

  @override
  String get fieldbookCheckStationRows => '측점 행';

  @override
  String get fieldbookCheckTolerance => '허용오차';

  @override
  String get fieldbookCheckTpComplete => 'TP 완성';

  @override
  String get fieldbookCheckerLabel => '검측자';

  @override
  String get fieldbookChooseBackupFile => '백업 파일 선택 (.json)';

  @override
  String get fieldbookChooseCsvFile => 'CSV 파일 선택 (.csv)';

  @override
  String get fieldbookClosingApply => '적용';

  @override
  String get fieldbookClosingBmLabel => '폐합 BM';

  @override
  String fieldbookClosingElevationLabel(String unit) {
    return '폐합 표고 ($unit)';
  }

  @override
  String get fieldbookClosingInvalid => '올바른 표고를 입력하세요.';

  @override
  String get fieldbookClosingLabel => '폐합 표고';

  @override
  String get fieldbookClosingLoop => '시작 BM (왕복)';

  @override
  String get fieldbookClosingLoopShort => '왕복';

  @override
  String get fieldbookClosingManual => '표고 직접 입력';

  @override
  String get fieldbookClosingManualShort => '직접 입력';

  @override
  String get fieldbookClosingNoBm => '이 현장에 사용할 수 있는 BM이 없습니다.';

  @override
  String get fieldbookClosingNone => '없음';

  @override
  String get fieldbookClosingNotSet => '미설정';

  @override
  String get fieldbookClosingOtherBm => '다른 BM';

  @override
  String get fieldbookClosingSheetHelp =>
      '폐합오차 = 최종 표고 − 폐합 표고. 폐합 기준이 없으면 검산만 표시합니다.';

  @override
  String get fieldbookClosingSheetTitle => '폐합 기준';

  @override
  String fieldbookClosingSummary(String name, String rl) {
    return '$name · $rl';
  }

  @override
  String get fieldbookColumnHi => 'IH';

  @override
  String get fieldbookColumnNo => 'NO';

  @override
  String get fieldbookColumnRiseFall => '승강';

  @override
  String get fieldbookColumnRl => 'GH';

  @override
  String get fieldbookContinueButton => '계속';

  @override
  String fieldbookCopyName(String name) {
    return '$name 복사';
  }

  @override
  String get fieldbookCreateButton => '생성';

  @override
  String fieldbookCsvImportError(String error) {
    return 'CSV 가져오기 실패: $error';
  }

  @override
  String get fieldbookCsvImported => 'CSV를 가져왔습니다';

  @override
  String fieldbookCsvImportedWithWarnings(String warnings) {
    return 'CSV를 가져왔습니다. $warnings';
  }

  @override
  String get fieldbookCsvPasteHint => '또는 Lv Book에서 내보낸 CSV 내용을 붙여넣으세요.';

  @override
  String fieldbookDeleteConfirm(String title) {
    return '\"$title\" 야장을 삭제하시겠습니까?';
  }

  @override
  String fieldbookDeleteRowConfirm(int row) {
    return '$row번 행을 삭제하시겠습니까?';
  }

  @override
  String get fieldbookDeleteRowTitle => '행 삭제';

  @override
  String get fieldbookDeleteTitle => '야장 삭제';

  @override
  String fieldbookDuplicateError(String error) {
    return '야장 복제 실패: $error';
  }

  @override
  String get fieldbookDuplicateStructure => '구조 복제';

  @override
  String get fieldbookDuplicatedMessage => '야장 구조를 복제했습니다';

  @override
  String get fieldbookEditStationTitle => '측점명 수정';

  @override
  String get fieldbookEmptyMessage =>
      '+ 버튼으로 새 야장을 만들거나\nCSV 가져오기로 기존 기록을 불러올 수 있습니다.';

  @override
  String get fieldbookEmptyTitle => '첫 야장을 만들어 보세요';

  @override
  String get fieldbookEnterManually => '직접 입력';

  @override
  String get fieldbookExportCheckTitle => '내보내기 전 확인';

  @override
  String get fieldbookExportTooltip => '내보내기';

  @override
  String get fieldbookFabLabel => '야장';

  @override
  String get fieldbookImportButton => '가져오기';

  @override
  String get fieldbookImportCsv => 'CSV 가져오기';

  @override
  String get fieldbookInstrumentLabel => '장비';

  @override
  String get fieldbookIssueArithmeticMismatch => '검산이 맞지 않습니다. 지반고를 확인하세요.';

  @override
  String get fieldbookIssueEmptyRows => '측정값이 없는 행을 정리하세요.';

  @override
  String get fieldbookIssueExceedsTolerance => '허용오차를 초과했습니다.';

  @override
  String get fieldbookIssueFirstBsMissing => '첫 행에는 후시(BS)가 필요합니다.';

  @override
  String get fieldbookIssueLastFsMissing => '마지막 행에는 전시(FS)가 필요합니다.';

  @override
  String get fieldbookIssueNoStationRows => '측점 행이 필요합니다.';

  @override
  String get fieldbookIssueRiseFallMismatch =>
      '승강 검산(Σ승 − Σ강)이 ΣBS − ΣFS와 맞지 않습니다. 관측값을 확인하세요.';

  @override
  String get fieldbookIssueTpIncomplete => 'TP 행에는 후시(BS)와 전시(FS)가 모두 필요합니다.';

  @override
  String get fieldbookJobNumberLabel => '공사번호';

  @override
  String fieldbookMisclosureCheckResult(String result) {
    return '폐합오차 $result';
  }

  @override
  String get fieldbookNewTitle => '새 야장';

  @override
  String get fieldbookNoDataToExport => '내보낼 데이터가 없습니다';

  @override
  String get fieldbookNoSearchResults => '검색 결과가 없습니다';

  @override
  String get fieldbookReductionHelp =>
      '승강식은 관측마다 승(+)/강(−)을 표시하고 Σ승 − Σ강 검산을 추가합니다. 지반고는 같습니다.';

  @override
  String get fieldbookReductionHi => '기고식';

  @override
  String get fieldbookReductionMethodLabel => '기입 방식';

  @override
  String get fieldbookReductionRiseFall => '승강식';

  @override
  String fieldbookRestoreBackupError(String error) {
    return '백업 복원 실패: $error';
  }

  @override
  String get fieldbookRestoreBackupJson => '백업 JSON 복원';

  @override
  String get fieldbookRestoreButton => '복원';

  @override
  String get fieldbookReviewMemoHint => '예: 감리 확인 완료';

  @override
  String get fieldbookReviewMemoLabel => '검토 메모';

  @override
  String get fieldbookReviewPanelTitle => '검토 정보';

  @override
  String get fieldbookReviewSaveButton => '검토 정보 저장';

  @override
  String get fieldbookReviewSavedMessage => '검토 정보를 저장했습니다';

  @override
  String get fieldbookReviewStatusLabel => '검토 상태';

  @override
  String get fieldbookReviewTodayButton => '오늘 검토일 적용';

  @override
  String fieldbookReviewedOn(String date) {
    return '검토일 $date';
  }

  @override
  String get fieldbookRowActionsTooltip => '행 작업';

  @override
  String get fieldbookRowDuplicate => '행 복제';

  @override
  String get fieldbookRowInsertBelow => '아래 행 삽입';

  @override
  String get fieldbookRowSetManualTp => '수동 TP 지정';

  @override
  String get fieldbookRowUnsetManualTp => '수동 TP 해제';

  @override
  String get fieldbookSaveStatusAutosaved => '자동저장됨';

  @override
  String get fieldbookSaveStatusError => '저장 실패';

  @override
  String get fieldbookSaveStatusPending => '자동저장 대기';

  @override
  String get fieldbookSaveStatusSaved => '저장됨';

  @override
  String get fieldbookSavedMessage => '저장 완료';

  @override
  String get fieldbookSearchHint => '제목, 작업구간, 측량자, 날짜';

  @override
  String get fieldbookSearchLabel => '야장 검색';

  @override
  String get fieldbookSelectBm => 'BM 선택';

  @override
  String get fieldbookShareBackup => '프로젝트 백업 공유';

  @override
  String fieldbookShareBackupError(String error) {
    return '백업 공유 실패: $error';
  }

  @override
  String get fieldbookSiteDetailsSummary => '측량자·장비·날씨 등 6항목';

  @override
  String get fieldbookSiteDetailsTitle => '현장 메타데이터';

  @override
  String get fieldbookStartBmLabel => '시작 BM';

  @override
  String get fieldbookStartElevationHint => '예: 100.000';

  @override
  String fieldbookStartElevationLabel(String unit) {
    return '시작 표고 ($unit) *';
  }

  @override
  String get fieldbookStartRlLabel => '시작 표고';

  @override
  String fieldbookStationHelper(int row) {
    return '비우면 행 번호($row)로 표시됩니다';
  }

  @override
  String get fieldbookStationHint => '예: No.1, BM.1, TP.1';

  @override
  String get fieldbookStationLabel => '측점명';

  @override
  String get fieldbookStatusDraft => '작성중';

  @override
  String get fieldbookStatusNeedsCheck => '확인필요';

  @override
  String get fieldbookStatusReviewed => '검토완료';

  @override
  String fieldbookSummaryAllowed(String value) {
    return '허용 $value';
  }

  @override
  String get fieldbookSummaryArithmetic => '검산 오차';

  @override
  String get fieldbookSummaryDiff => '차';

  @override
  String get fieldbookSummaryFinal => '최종';

  @override
  String get fieldbookSummaryMisclosure => '폐합오차';

  @override
  String get fieldbookSummaryNoClosing => '폐합 기준 없음';

  @override
  String fieldbookSummaryRiseMinusFall(String value) {
    return '승−강 $value';
  }

  @override
  String get fieldbookSummaryStart => '시작';

  @override
  String fieldbookSummarySumFall(String value) {
    return 'Σ강 $value';
  }

  @override
  String fieldbookSummarySumRise(String value) {
    return 'Σ승 $value';
  }

  @override
  String get fieldbookSurveyorLabel => '측량자';

  @override
  String fieldbookSurveyorSubtitle(String name) {
    return '측량자 $name';
  }

  @override
  String get fieldbookTitleHint => '야장 제목';

  @override
  String get fieldbookTitleLabel => '야장 제목 *';

  @override
  String get fieldbookToleranceCheckTitle => '허용오차 확인 필요';

  @override
  String get fieldbookWeatherLabel => '날씨';

  @override
  String get fieldbookWorkSectionLabel => '작업구간';

  @override
  String get proActiveSubtitle => '광고 없이 제출용 문서를 만들 수 있습니다.';

  @override
  String get proActiveTitle => 'Pro 활성화됨';

  @override
  String get proBuyButton => '레벨 야장 Pro 구매';

  @override
  String get proFeatureBenchmarkPhotoLocation => 'TBM/BM 사진 좌표';

  @override
  String get proFeatureBulkExport => '일괄 내보내기';

  @override
  String get proFeatureNoAds => '광고 제거';

  @override
  String get proFeatureSummaryReport => '요약 보고서';

  @override
  String get proFileNameSiteDateTitle => '현장_날짜_야장명';

  @override
  String get proFileNameSiteSectionDateTitle => '현장_작업구간_날짜_야장명';

  @override
  String get proFileNameTitleOnly => '야장명';

  @override
  String get proInspectionWatermarkDefault => '검측용';

  @override
  String get proPdfAuthorHint => '예: 홍길동';

  @override
  String get proPdfAuthorLabel => '작성자';

  @override
  String get proPdfCompanyHint => '예: 주식회사 레벨측량';

  @override
  String get proPdfCompanyLabel => '회사명';

  @override
  String get proPdfExportHistory => '내보내기 이력';

  @override
  String get proPdfExportHistoryClearAll => '전체 삭제';

  @override
  String get proPdfExportHistoryEmpty => '내보내기 이력이 없습니다.';

  @override
  String get proPdfFileNamePreviewLabel => '파일명 미리보기';

  @override
  String get proPdfFileNameRuleLabel => '파일명 규칙';

  @override
  String get proPdfFooterNoteHint => '예: 현장대리인 확인';

  @override
  String get proPdfFooterNoteLabel => '하단 메모';

  @override
  String proPdfLoadError(String error) {
    return '설정을 불러오지 못했습니다: $error';
  }

  @override
  String get proPdfPresetAdd => '프리셋 추가';

  @override
  String get proPdfPresetDeleteTooltip => '프리셋 삭제';

  @override
  String get proPdfPresetDeletedMessage => '프리셋을 삭제했습니다';

  @override
  String get proPdfPresetLabel => '문서 프리셋';

  @override
  String get proPdfPresetNameLabel => '프리셋 이름';

  @override
  String get proPdfPresetNewName => '새 프리셋';

  @override
  String get proPdfPresetRename => '프리셋 이름 변경';

  @override
  String get proPdfPreviewSampleSite => '강남 현장';

  @override
  String get proPdfPreviewSampleTitle => 'A구간 야장';

  @override
  String get proPdfSavedMessage => 'Pro PDF 설정을 저장했습니다';

  @override
  String get proPdfSettingsTitle => 'Pro PDF 설정';

  @override
  String get proPdfShowJudgementSubtitle => 'PDF/CSV에 적합 또는 확인 필요 판정을 포함합니다.';

  @override
  String get proPdfShowJudgementTitle => '검산 판정 표시';

  @override
  String get proPdfSignatureDescription => 'PDF \'작성\'란에 들어갈 손글씨 서명을 등록합니다.';

  @override
  String get proPdfSignatureDisplayError => '서명을 표시할 수 없습니다';

  @override
  String get proPdfSignatureEmpty => '등록된 서명이 없습니다';

  @override
  String get proPdfSignatureLinesSubtitle => '제출용 PDF 하단에 작성/검토/승인란을 추가합니다.';

  @override
  String get proPdfSignatureLinesTitle => '확인 서명란 표시';

  @override
  String get proPdfSignatureRedo => '다시 서명';

  @override
  String get proPdfSignatureRegister => '서명 등록';

  @override
  String get proPdfSignatureTitle => '작성자 서명';

  @override
  String get proPdfTemplateLabel => '문서 템플릿';

  @override
  String get proPdfWatermarkHint => '예: 검측용';

  @override
  String get proPdfWatermarkLabel => '워터마크';

  @override
  String get proPitchSubtitle => '일회성 구매로 현장 기록 Pro 기능을 잠금 해제합니다.';

  @override
  String proPriceOneTimePurchase(String price) {
    return '$price · 일회성 구매';
  }

  @override
  String get proSignatureClear => '다시 쓰기';

  @override
  String get proSignatureDialogHint => '아래 영역에 손가락 또는 펜으로 서명하세요.';

  @override
  String get proSignatureDialogTitle => '서명 입력';

  @override
  String get proSignatureEmptyError => '서명을 입력해 주세요';

  @override
  String get proSignatureSaveError => '서명을 저장하지 못했습니다';

  @override
  String get proTemplateBasic => '기본 야장';

  @override
  String get proTemplateInspection => '검측용';

  @override
  String get proTemplateSubmission => '제출용';

  @override
  String projectBackupLastSharedTitle(int days) {
    return '마지막 백업 공유가 $days일 전이에요';
  }

  @override
  String get projectBackupLaterButton => '나중에';

  @override
  String get projectBackupNeverSharedTitle => '아직 백업을 공유한 적이 없어요';

  @override
  String get projectBackupReminderMessage =>
      '기기 분실·앱 삭제 시 현장 기록이 사라집니다. 백업 파일을 메일이나 드라이브에 보관하세요.';

  @override
  String get projectBackupShareButton => '백업 공유';

  @override
  String projectBackupShareError(String error) {
    return '백업 공유 실패: $error';
  }

  @override
  String projectBackupSharedMessage(int count) {
    return '프로젝트 $count개의 백업을 공유했습니다.';
  }

  @override
  String projectCardStats(int books) {
    return '야장 $books권';
  }

  @override
  String projectCardStatsOpen(int books, int open) {
    return '야장 $books권 · 검토 대기 $open건';
  }

  @override
  String projectCardUpdated(String date) {
    return '최근 업데이트 · $date';
  }

  @override
  String projectDeleteConfirm(String name) {
    return '\"$name\" 프로젝트를 삭제하시겠습니까?\n관련된 모든 야장과 BM도 삭제됩니다.';
  }

  @override
  String get projectDeleteDialogTitle => '프로젝트 삭제';

  @override
  String get projectDescriptionLabel => '설명 (선택)';

  @override
  String get projectDetailTabBenchmarks => 'BM 관리';

  @override
  String get projectDetailTabLevelBooks => '야장';

  @override
  String get projectEditDialogTitle => '프로젝트 수정';

  @override
  String get projectEmptyMessage =>
      '현장(프로젝트)을 만들고 BM과 야장을 기록합니다.\n예제 프로젝트로 자동 계산과 폐합 확인을 먼저 둘러볼 수 있습니다.';

  @override
  String get projectEmptyNewButton => '새 프로젝트 만들기';

  @override
  String get projectEmptySampleButton => '예제 프로젝트로 둘러보기';

  @override
  String get projectEmptyTitle => '첫 현장을 추가하세요';

  @override
  String get projectListQuickMemoTooltip => '빠른 메모';

  @override
  String get projectListSettingsTooltip => '설정';

  @override
  String get projectNewDialogTitle => '새 프로젝트';

  @override
  String get projectProActiveMessage =>
      'TBM/BM 사진 좌표, 일괄 내보내기, 광고 제거를 사용할 수 있습니다.';

  @override
  String get projectProActiveTitle => 'Pro 활성화됨';

  @override
  String get projectProGetButton => 'Pro 신청';

  @override
  String get projectProPromoMessage =>
      'TBM/BM 사진 좌표, 일괄 내보내기, 광고 제거를 잠금 해제하세요.';

  @override
  String projectRecentWorkSubtitle(String project, String date) {
    return '최근 작업 · $project · $date';
  }

  @override
  String get projectSampleBenchmarkDescription => '예제 기준점';

  @override
  String get projectSampleBenchmarkLocation => '현장 사무소 앞 경계석';

  @override
  String projectSampleClosingStation(String bm) {
    return '$bm (폐합)';
  }

  @override
  String get projectSampleCreateError => '예제 프로젝트를 만들지 못했습니다. 다시 시도해 주세요.';

  @override
  String get projectSampleCreatedMessage =>
      '예제 프로젝트를 만들었습니다. 야장을 열어 자동 계산을 확인해 보세요.';

  @override
  String get projectSampleDescription => '자동 계산·폐합 확인용 예제입니다. 필요 없으면 삭제하세요.';

  @override
  String get projectSampleInstrument => '자동 레벨';

  @override
  String get projectSampleLevelBookTitle => '예제 야장 (BM-1 왕복)';

  @override
  String get projectSampleMemo => '예제 데이터입니다. 값을 바꾸면 IH/GH가 자동으로 다시 계산됩니다.';

  @override
  String get projectSampleName => '예제 현장 (삭제 가능)';

  @override
  String get projectSampleSection => '예제 구간';

  @override
  String get projectSampleSurveyor => '홍길동';

  @override
  String get projectSampleWeather => '맑음';

  @override
  String get projectSiteNameLabel => '현장명 *';

  @override
  String get projectSitesHeader => '현장';

  @override
  String get projectSummaryLoading => '야장과 BM을 현장 단위로 정리합니다.';

  @override
  String projectSummaryStatsAllReviewed(int books) {
    return '야장 $books권 · 모두 검토 완료';
  }

  @override
  String projectSummaryStatsOpen(int books, int open) {
    return '야장 $books권 · 검토 대기 $open건';
  }

  @override
  String projectSummaryTitle(int count) {
    return '현장 $count개 관리 중';
  }

  @override
  String get purchaseCanceledMessage => '결제가 취소되었습니다.';

  @override
  String get purchaseFailedMessage => '결제가 실패했습니다.';

  @override
  String get purchaseNothingToRestore => '복원할 구매 내역이 없습니다.';

  @override
  String get purchasePendingMessage => '결제를 처리하는 중입니다.';

  @override
  String get purchaseProActivatedMessage => '레벨 야장 Pro가 활성화되었습니다.';

  @override
  String purchaseProductLoadError(String error) {
    return '상품 정보를 불러오지 못했습니다: $error';
  }

  @override
  String purchaseProductNotFound(String productId) {
    return 'Play Console에서 $productId 상품을 찾지 못했습니다.';
  }

  @override
  String get purchaseProductNotReady => 'Pro 상품 정보가 아직 준비되지 않았습니다.';

  @override
  String purchaseRestoreError(String error) {
    return '구매 복원에 실패했습니다: $error';
  }

  @override
  String purchaseStartError(String error) {
    return '결제를 시작하지 못했습니다: $error';
  }

  @override
  String get purchaseStartFailed => '결제를 시작하지 못했습니다.';

  @override
  String purchaseStoreInitError(String error) {
    return '스토어 결제를 초기화하지 못했습니다: $error';
  }

  @override
  String get purchaseStoreUnavailable => '스토어 결제를 사용할 수 없습니다.';

  @override
  String get purchaseStoreUnsupportedPlatform =>
      '현재 플랫폼에서는 스토어 결제를 사용할 수 없습니다.';

  @override
  String purchaseUpdateError(String error) {
    return '결제 업데이트를 처리하지 못했습니다: $error';
  }

  @override
  String get quickMemoAudioMissing => '음성 파일을 찾을 수 없습니다.';

  @override
  String get quickMemoComposerTitle => '빠른 현장 메모';

  @override
  String get quickMemoDeleteConfirm => '이 메모를 삭제하시겠습니까?';

  @override
  String get quickMemoDeleteRecordingTooltip => '녹음 삭제';

  @override
  String get quickMemoDeleteTitle => '메모 삭제';

  @override
  String get quickMemoEmptyMessage => '화면 왼쪽 아래 번개 버튼으로 어디서든 텍스트·음성 메모를 남겨보세요.';

  @override
  String get quickMemoEmptyTitle => '저장된 메모가 없어요';

  @override
  String get quickMemoMicPermissionRequired => '마이크 권한이 필요합니다.';

  @override
  String get quickMemoRecordHint => '마이크를 눌러 음성 메모를 녹음하세요';

  @override
  String get quickMemoRecorded => '음성 녹음됨 · 다시 녹음하려면 마이크를 누르세요';

  @override
  String quickMemoRecording(String time) {
    return '녹음 중 · $time';
  }

  @override
  String quickMemoSaveError(String error) {
    return '저장 실패: $error';
  }

  @override
  String get quickMemoSavedMessage => '메모를 저장했습니다.';

  @override
  String get quickMemoTextHint => '메모를 입력하세요 (선택)';

  @override
  String get quickMemoTitle => '빠른 메모';

  @override
  String get settingsAdsRemovedActiveSubtitle => '구매 상태가 적용되어 광고가 표시되지 않습니다.';

  @override
  String get settingsAdsRemovedChecking => '광고 제거 상태 확인 중';

  @override
  String get settingsAdsRemovedCheckingSubtitle => '스토어와 로컬 권한을 확인합니다.';

  @override
  String get settingsAdsRemovedInactiveSubtitle =>
      '스토어 상품 연결 후 일시구매로 모든 광고를 제거합니다.';

  @override
  String get settingsAdsRemovedLoadError => '광고 제거 상태를 불러오지 못했습니다';

  @override
  String get settingsCheckSection => '검산·폐합';

  @override
  String get settingsDocumentSection => '문서 설정';

  @override
  String get settingsPdfSettingsSubtitle => '회사명, 템플릿, 워터마크, 서명을 설정합니다.';

  @override
  String get settingsPdfSettingsTitle => '제출용 PDF 설정';

  @override
  String get settingsPurchaseStatusSection => '구매 상태';

  @override
  String get settingsRemoveAdsTitle => '광고 제거';

  @override
  String get settingsRestorePurchasePendingSubtitle =>
      '스토어에서 구매 내역을 확인하는 중입니다.';

  @override
  String get settingsRestorePurchaseSubtitle => '이미 구매한 Pro 권한을 복원합니다.';

  @override
  String get settingsRestorePurchaseTitle => '구매 복원';

  @override
  String get settingsTitle => '설정';

  @override
  String settingsToleranceCoefficientLabel(String unit) {
    return '계수 c ($unit)';
  }

  @override
  String get settingsToleranceFixedHelper => '모든 야장에 같은 허용값을 적용합니다.';

  @override
  String settingsToleranceFixedLabel(String unit) {
    return '허용값 ($unit)';
  }

  @override
  String settingsToleranceFixedSummary(String value, String unit) {
    return '고정 ±$value $unit';
  }

  @override
  String settingsToleranceInvalid(String min, String max, String unit) {
    return '$min–$max $unit 사이로 입력하세요.';
  }

  @override
  String get settingsToleranceModeFixed => '고정값';

  @override
  String get settingsToleranceModeSqrt => 'c·√n';

  @override
  String get settingsToleranceNote => '초과해도 경고만 표시되며 내보내기는 가능합니다.';

  @override
  String settingsToleranceSqrtHelper(String unit) {
    return '허용 = c × √n $unit, n = 기계 설치 횟수(BS 행 수)';
  }

  @override
  String settingsToleranceSqrtSummary(String value, String unit) {
    return '$value $unit × √n (n = 기계 설치 횟수)';
  }

  @override
  String get settingsToleranceTitle => '폐합 허용오차';

  @override
  String get settingsUnitFeet => '피트 (ft)';

  @override
  String get settingsUnitMetres => '미터 (m)';

  @override
  String get settingsUnitNote => '표시 단위만 바뀌며 기존 값은 변환되지 않습니다.';

  @override
  String get settingsUnitTitle => '단위';
}
