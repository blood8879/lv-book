// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get adsNativeAdLabel => 'Ad';

  @override
  String get adsPolicyBannerSubtitle =>
      'An adaptive banner that fits the screen width is shown at the bottom.';

  @override
  String get adsPolicyBannerTitle => 'Banner ads';

  @override
  String get adsPolicyExportSubtitle =>
      'Shown only after sharing completes, at most 3 times a day and at least 10 minutes apart.';

  @override
  String get adsPolicyExportTitle => 'Export ads';

  @override
  String get adsPolicySection => 'Ad policy';

  @override
  String get backupErrorBenchmarkCorrupted => 'BM data is corrupted.';

  @override
  String get backupErrorCorrupted => 'The backup data is corrupted.';

  @override
  String get backupErrorFieldBookCorrupted => 'Level book data is corrupted.';

  @override
  String get backupErrorInvalidFormat => 'The backup file format is invalid.';

  @override
  String get backupErrorMeasurementCorrupted => 'Station data is corrupted.';

  @override
  String get backupErrorPhotoCorrupted => 'Photo backup data is corrupted.';

  @override
  String get backupErrorProjectNotFound => 'Project not found.';

  @override
  String get backupErrorUnsupported => 'This backup file isn\'t supported.';

  @override
  String benchmarkAccuracy(String accuracy) {
    return 'Accuracy $accuracy m';
  }

  @override
  String get benchmarkAddDialogTitle => 'Add BM';

  @override
  String get benchmarkCopyCoordinateButton => 'Copy coordinates';

  @override
  String benchmarkCopyCoordinateText(String latitude, String longitude) {
    return 'Lat $latitude, Lon $longitude';
  }

  @override
  String benchmarkDeleteConfirm(String name, String elevation) {
    return 'Delete \"$name\" (elevation: $elevation)?';
  }

  @override
  String get benchmarkDeleteDialogTitle => 'Delete BM';

  @override
  String get benchmarkDescriptionLabel => 'Description (optional)';

  @override
  String get benchmarkEditDialogTitle => 'Edit BM';

  @override
  String get benchmarkElevationHint => 'e.g. 100.000';

  @override
  String get benchmarkElevationInvalidError =>
      'Enter the elevation as a number (m)';

  @override
  String get benchmarkElevationLabel => 'Elevation (m) *';

  @override
  String benchmarkElevationLine(String elevation) {
    return 'Elevation $elevation m';
  }

  @override
  String get benchmarkEmptyMessage =>
      'Add a BM/TBM as your elevation reference with the + button,\nthen load it as the start RL when writing a level book.';

  @override
  String get benchmarkEmptyTitle => 'Add a BM (benchmark)';

  @override
  String get benchmarkKindLabel => 'Type';

  @override
  String benchmarkKindLine(String kind) {
    return 'Type: $kind';
  }

  @override
  String get benchmarkLocationHintLabel => 'Location hint';

  @override
  String benchmarkLocationLine(String hint) {
    return 'Location: $hint';
  }

  @override
  String get benchmarkLocationPermissionDenied =>
      'Location permission was denied.';

  @override
  String get benchmarkLocationPermissionDeniedForever =>
      'Location permission was permanently denied. Allow it in the app settings.';

  @override
  String get benchmarkLocationServiceOff =>
      'Location services are turned off on this device.';

  @override
  String get benchmarkMapOpenError =>
      'Couldn\'t open a map app. Copy the coordinates instead.';

  @override
  String get benchmarkNameHint => 'e.g. BM.1';

  @override
  String get benchmarkNameLabel => 'BM name *';

  @override
  String get benchmarkNameRequiredError => 'Enter a BM name';

  @override
  String get benchmarkNoSavedCoordinate => 'No saved coordinates.';

  @override
  String get benchmarkNoSavedPhoto => 'No saved photo.';

  @override
  String get benchmarkOpenMapButton => 'Open map';

  @override
  String get benchmarkPhotoFileMissing => 'Photo file not found.';

  @override
  String get benchmarkPhotoNeedsSavedBm =>
      'Photos can only be added to a saved BM.';

  @override
  String get benchmarkPhotoSaveError => 'Couldn\'t save the photo.';

  @override
  String get benchmarkPhotoSaved => 'Photo saved';

  @override
  String get benchmarkPickPhotoButton => 'Choose photo';

  @override
  String get benchmarkProLocationPromo =>
      'With Pro you can save TBM/BM photos and coordinates.';

  @override
  String get benchmarkProLocationSaved => 'Pro location info saved';

  @override
  String get benchmarkProLocationTitle => 'Pro location record';

  @override
  String get benchmarkProRequired => 'Available after buying Lv Book Pro.';

  @override
  String get benchmarkProtectionLabel => 'Protection/check notes';

  @override
  String benchmarkProtectionLine(String note) {
    return 'Protection: $note';
  }

  @override
  String get benchmarkRecheckNoVerifiedDate =>
      'No last-checked date. Re-check required';

  @override
  String get benchmarkRecheckOutOfService =>
      'This BM is out of service. It can\'t be used as the start BM of a new level book.';

  @override
  String get benchmarkRecheckPossiblyDamaged =>
      'This BM is possibly damaged. Re-check it on site before use.';

  @override
  String benchmarkRecheckStale(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days since the last check. Re-check required',
      one: '1 day since the last check. Re-check required',
    );
    return '$_temp0';
  }

  @override
  String get benchmarkRemovePhotoButton => 'Remove photo';

  @override
  String get benchmarkSaveCurrentCoordinate => 'Save current coordinates';

  @override
  String get benchmarkSavingCoordinate => 'Saving coordinates';

  @override
  String get benchmarkStatusLabel => 'Status';

  @override
  String get benchmarkStatusOutOfService => 'Out of service';

  @override
  String get benchmarkStatusPossiblyDamaged => 'Possibly damaged';

  @override
  String get benchmarkStatusUsable => 'Usable';

  @override
  String get benchmarkTakePhotoButton => 'Take photo';

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
  String get exportBulkDeselectAll => 'Clear';

  @override
  String exportBulkError(String error) {
    return 'Bulk export didn\'t complete: $error';
  }

  @override
  String get exportBulkFormatBoth => 'Both';

  @override
  String get exportBulkManifestSubtitle =>
      'Lists the selected level books, generated files and station counts.';

  @override
  String get exportBulkManifestTitle => 'Include submission package manifest';

  @override
  String get exportBulkNothingToExport =>
      'No selected level book has data to export';

  @override
  String get exportBulkProOnlyBody =>
      'Share several level books as PDF/CSV at once.';

  @override
  String get exportBulkProOnlyTitle => 'Pro feature';

  @override
  String get exportBulkProRequired =>
      'Available with Lv Book Pro (one-time purchase).';

  @override
  String get exportBulkSelectAll => 'All';

  @override
  String exportBulkShareButton(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Share $count level books',
      one: 'Share 1 level book',
    );
    return '$_temp0';
  }

  @override
  String exportBulkShared(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Shared $count files',
      one: 'Shared 1 file',
    );
    return '$_temp0';
  }

  @override
  String get exportBulkSummarySubtitle =>
      'Puts each level book\'s BM, section, misclosure and result in one file.';

  @override
  String get exportBulkSummaryTitle => 'Include check/submission summary CSV';

  @override
  String get exportBulkTitle => 'Bulk export';

  @override
  String get exportCheckAllowed => 'Allowed';

  @override
  String get exportCheckDifference => 'Difference';

  @override
  String get exportCheckFinalRl => 'Final RL';

  @override
  String get exportCheckMisclosure => 'Misclosure';

  @override
  String get exportCheckMisclosureUnavailable => 'n/a (no closing RL)';

  @override
  String get exportCheckResult => 'Result';

  @override
  String get exportCheckRlDifference => 'Final - Start';

  @override
  String get exportCheckStartRl => 'Start RL';

  @override
  String get exportCheckTitle => 'Arithmetic check';

  @override
  String get exportCheckTitleWithClosure => 'Arithmetic check and misclosure';

  @override
  String exportCheckValue(String label, String value) {
    return '$label = $value';
  }

  @override
  String exportClosingLoopName(String name) {
    return '$name (loop)';
  }

  @override
  String get exportColumnBs => 'BS';

  @override
  String get exportColumnFs => 'FS';

  @override
  String get exportColumnHi => 'HI';

  @override
  String get exportColumnNo => 'No.';

  @override
  String get exportColumnRemarks => 'Remarks';

  @override
  String get exportColumnRl => 'RL';

  @override
  String get exportColumnStation => 'Station';

  @override
  String get exportCompanyNotSet => 'Company name not set';

  @override
  String exportCsvError(String error) {
    return 'Couldn\'t create the CSV: $error';
  }

  @override
  String get exportDocTitle => 'Differential leveling level book';

  @override
  String exportDocTitleWithTemplate(String template) {
    return 'Differential leveling level book · $template';
  }

  @override
  String get exportFieldAuthor => 'Prepared by';

  @override
  String get exportFieldBmElevation => 'BM elevation';

  @override
  String get exportFieldChecker => 'Checker';

  @override
  String get exportFieldClosingBm => 'Closing BM';

  @override
  String get exportFieldClosingRl => 'Closing RL';

  @override
  String get exportFieldCompany => 'Company';

  @override
  String get exportFieldDate => 'Date';

  @override
  String get exportFieldInstrument => 'Instrument';

  @override
  String get exportFieldJobNumber => 'Job no.';

  @override
  String get exportFieldMemo => 'Memo';

  @override
  String get exportFieldReviewDate => 'Review date';

  @override
  String get exportFieldReviewMemo => 'Review memo';

  @override
  String get exportFieldReviewStatus => 'Review status';

  @override
  String get exportFieldSection => 'Section';

  @override
  String get exportFieldStartBm => 'Start BM';

  @override
  String get exportFieldSurveyor => 'Surveyor';

  @override
  String get exportFieldTitle => 'Level book';

  @override
  String get exportFieldWeather => 'Weather';

  @override
  String exportImportDateMissing(String date) {
    return 'The CSV has no date, so it was set to $date.';
  }

  @override
  String exportImportDateUnrecognized(String value, String date) {
    return 'Couldn\'t read the date \"$value\", so it was set to $date.';
  }

  @override
  String get exportImportDefaultTitle => 'Imported level book';

  @override
  String get exportImportHeaderNotFound =>
      'Couldn\'t find the measurement table header.';

  @override
  String exportImportInvalidNumber(int row, String column) {
    return 'Row $row: $column is not a valid number.';
  }

  @override
  String get exportImportUtf8Only =>
      'Only UTF-8 CSV is supported. Some characters are garbled, so the file can\'t be imported. In Excel, save it again as \"CSV UTF-8 (Comma delimited)\".';

  @override
  String exportLabelValue(String label, String value) {
    return '$label: $value';
  }

  @override
  String exportManifestFieldBookLine(String title, int count, String status) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stations',
      one: '1 station',
    );
    return '- $title: $_temp0, review status $status';
  }

  @override
  String exportManifestFileCount(int count) {
    return 'Files: $count';
  }

  @override
  String get exportManifestIncludedFiles => 'Included files';

  @override
  String exportManifestSite(String name) {
    return 'Site: $name';
  }

  @override
  String get exportManifestSiteNotSet => 'Site name not set';

  @override
  String get exportManifestTitle => 'Lv Book submission package';

  @override
  String get exportPackageNoFieldBooks =>
      'There are no level books to package.';

  @override
  String get exportPackageNoFiles => 'There are no files to package.';

  @override
  String get exportPackageZipError =>
      'Couldn\'t create the submission package ZIP.';

  @override
  String exportPdfError(String error) {
    return 'Couldn\'t create the PDF: $error';
  }

  @override
  String get exportReviewStatusDraft => 'Draft';

  @override
  String get exportReviewStatusNeedsCheck => 'Needs check';

  @override
  String get exportReviewStatusReviewed => 'Reviewed';

  @override
  String get exportScreenTitle => 'Export';

  @override
  String get exportShareCsvTooltip => 'Share CSV';

  @override
  String get exportSharePdfTooltip => 'Share PDF';

  @override
  String get exportSignatureApproved => 'Approved';

  @override
  String get exportSignatureChecked => 'Checked';

  @override
  String get exportSignaturePrepared => 'Prepared';

  @override
  String get exportSummaryFileSuffix => 'summary';

  @override
  String get exportSummaryNoSelection => 'Select level books to summarize.';

  @override
  String get fieldbookAddTenRowsTooltip => 'Add 10 rows';

  @override
  String fieldbookArithmeticCheckResult(String result) {
    return 'Arithmetic check: $result';
  }

  @override
  String get fieldbookBackupPasteHint =>
      'Or paste the contents of a shared lvbook_backup.json.';

  @override
  String get fieldbookBackupRestoredMessage =>
      'Backup restored as a new project.';

  @override
  String get fieldbookBmNameHint => 'e.g. BM.1';

  @override
  String get fieldbookBmNameLabel => 'BM name (optional)';

  @override
  String get fieldbookBulkExportButton => 'Bulk export';

  @override
  String get fieldbookCheckArithmetic => 'Arithmetic check';

  @override
  String get fieldbookCheckEmptyRows => 'Empty rows';

  @override
  String get fieldbookCheckFirstBs => 'First BS';

  @override
  String get fieldbookCheckLastFs => 'Last FS';

  @override
  String get fieldbookCheckStationRows => 'Station rows';

  @override
  String get fieldbookCheckTolerance => 'Tolerance';

  @override
  String get fieldbookCheckTpComplete => 'TP complete';

  @override
  String get fieldbookCheckerLabel => 'Checker';

  @override
  String get fieldbookChooseBackupFile => 'Choose backup file (.json)';

  @override
  String get fieldbookChooseCsvFile => 'Choose CSV file (.csv)';

  @override
  String get fieldbookClosingApply => 'Apply';

  @override
  String get fieldbookClosingBmLabel => 'Closing BM';

  @override
  String get fieldbookClosingElevationLabel => 'Closing RL (m)';

  @override
  String get fieldbookClosingInvalid => 'Enter a valid RL.';

  @override
  String get fieldbookClosingLabel => 'Closing RL';

  @override
  String get fieldbookClosingLoop => 'Start BM (loop)';

  @override
  String get fieldbookClosingLoopShort => 'Loop';

  @override
  String get fieldbookClosingManual => 'Manual RL';

  @override
  String get fieldbookClosingManualShort => 'Manual';

  @override
  String get fieldbookClosingNoBm => 'No usable BM in this project.';

  @override
  String get fieldbookClosingNone => 'None';

  @override
  String get fieldbookClosingNotSet => 'Not set';

  @override
  String get fieldbookClosingOtherBm => 'Other BM';

  @override
  String get fieldbookClosingSheetHelp =>
      'Misclosure = Final RL − closing RL. Without a closing reference only the arithmetic check is shown.';

  @override
  String get fieldbookClosingSheetTitle => 'Closing reference';

  @override
  String fieldbookClosingSummary(String name, String rl) {
    return '$name · $rl';
  }

  @override
  String get fieldbookColumnHi => 'HI';

  @override
  String get fieldbookColumnNo => 'Stn';

  @override
  String get fieldbookColumnRl => 'RL';

  @override
  String get fieldbookContinueButton => 'Continue';

  @override
  String fieldbookCopyName(String name) {
    return '$name copy';
  }

  @override
  String get fieldbookCreateButton => 'Create';

  @override
  String fieldbookCsvImportError(String error) {
    return 'Couldn\'t import CSV: $error';
  }

  @override
  String get fieldbookCsvImported => 'CSV imported';

  @override
  String fieldbookCsvImportedWithWarnings(String warnings) {
    return 'CSV imported. $warnings';
  }

  @override
  String get fieldbookCsvPasteHint => 'Or paste CSV exported from Lv Book.';

  @override
  String fieldbookDeleteConfirm(String title) {
    return 'Delete level book \"$title\"?';
  }

  @override
  String fieldbookDeleteRowConfirm(int row) {
    return 'Delete row $row?';
  }

  @override
  String get fieldbookDeleteRowTitle => 'Delete row';

  @override
  String get fieldbookDeleteTitle => 'Delete level book';

  @override
  String fieldbookDuplicateError(String error) {
    return 'Couldn\'t duplicate level book: $error';
  }

  @override
  String get fieldbookDuplicateStructure => 'Duplicate structure';

  @override
  String get fieldbookDuplicatedMessage => 'Level book structure duplicated';

  @override
  String get fieldbookEditStationTitle => 'Edit station';

  @override
  String get fieldbookEmptyMessage =>
      'Tap + to create a level book,\nor import existing records from CSV.';

  @override
  String get fieldbookEmptyTitle => 'Create your first level book';

  @override
  String get fieldbookEnterManually => 'Enter manually';

  @override
  String get fieldbookExportCheckTitle => 'Check before export';

  @override
  String get fieldbookExportTooltip => 'Export';

  @override
  String get fieldbookFabLabel => 'Level book';

  @override
  String get fieldbookImportButton => 'Import';

  @override
  String get fieldbookImportCsv => 'Import CSV';

  @override
  String get fieldbookInstrumentLabel => 'Instrument';

  @override
  String get fieldbookIssueArithmeticMismatch =>
      'Arithmetic check doesn\'t balance — check the RLs.';

  @override
  String get fieldbookIssueEmptyRows => 'Remove rows with no readings.';

  @override
  String get fieldbookIssueExceedsTolerance =>
      'Exceeds tolerance — check the readings.';

  @override
  String get fieldbookIssueFirstBsMissing =>
      'The first row needs a backsight (BS).';

  @override
  String get fieldbookIssueLastFsMissing =>
      'The last row needs a foresight (FS).';

  @override
  String get fieldbookIssueNoStationRows => 'Add at least one station row.';

  @override
  String get fieldbookIssueTpIncomplete => 'TP rows need both BS and FS.';

  @override
  String get fieldbookJobNumberLabel => 'Job no.';

  @override
  String fieldbookMisclosureCheckResult(String result) {
    return 'Misclosure: $result';
  }

  @override
  String get fieldbookNewTitle => 'New level book';

  @override
  String get fieldbookNoDataToExport => 'No data to export';

  @override
  String get fieldbookNoSearchResults => 'No results';

  @override
  String fieldbookRestoreBackupError(String error) {
    return 'Couldn\'t restore backup: $error';
  }

  @override
  String get fieldbookRestoreBackupJson => 'Restore backup JSON';

  @override
  String get fieldbookRestoreButton => 'Restore';

  @override
  String get fieldbookReviewMemoHint => 'e.g. Confirmed by supervisor';

  @override
  String get fieldbookReviewMemoLabel => 'Review notes';

  @override
  String get fieldbookReviewPanelTitle => 'Review';

  @override
  String get fieldbookReviewSaveButton => 'Save review';

  @override
  String get fieldbookReviewSavedMessage => 'Review info saved';

  @override
  String get fieldbookReviewStatusLabel => 'Review status';

  @override
  String get fieldbookReviewTodayButton => 'Set review date to today';

  @override
  String fieldbookReviewedOn(String date) {
    return 'Reviewed $date';
  }

  @override
  String get fieldbookRowActionsTooltip => 'Row actions';

  @override
  String get fieldbookRowDuplicate => 'Duplicate row';

  @override
  String get fieldbookRowInsertBelow => 'Insert row below';

  @override
  String get fieldbookRowSetManualTp => 'Set manual TP';

  @override
  String get fieldbookRowUnsetManualTp => 'Unset manual TP';

  @override
  String get fieldbookSaveStatusAutosaved => 'Autosaved';

  @override
  String get fieldbookSaveStatusError => 'Not saved';

  @override
  String get fieldbookSaveStatusPending => 'Autosave pending';

  @override
  String get fieldbookSaveStatusSaved => 'Saved';

  @override
  String get fieldbookSavedMessage => 'Saved';

  @override
  String get fieldbookSearchHint => 'Title, section, surveyor, date';

  @override
  String get fieldbookSearchLabel => 'Search level books';

  @override
  String get fieldbookSelectBm => 'Select BM';

  @override
  String get fieldbookShareBackup => 'Share project backup';

  @override
  String fieldbookShareBackupError(String error) {
    return 'Couldn\'t share backup: $error';
  }

  @override
  String get fieldbookSiteDetailsSummary => 'Surveyor, instrument, weather…';

  @override
  String get fieldbookSiteDetailsTitle => 'Site details';

  @override
  String get fieldbookStartBmLabel => 'Start BM';

  @override
  String get fieldbookStartElevationHint => 'e.g. 100.000';

  @override
  String get fieldbookStartElevationLabel => 'Start RL (m) *';

  @override
  String get fieldbookStartRlLabel => 'Start RL';

  @override
  String fieldbookStationHelper(int row) {
    return 'Leave blank to show the row number ($row)';
  }

  @override
  String get fieldbookStationHint => 'e.g. No.1, BM.1, TP.1';

  @override
  String get fieldbookStationLabel => 'Station';

  @override
  String get fieldbookStatusDraft => 'Draft';

  @override
  String get fieldbookStatusNeedsCheck => 'Needs check';

  @override
  String get fieldbookStatusReviewed => 'Reviewed';

  @override
  String fieldbookSummaryAllowed(String value) {
    return 'Allowed $value';
  }

  @override
  String get fieldbookSummaryArithmetic => 'Arith. check';

  @override
  String get fieldbookSummaryDiff => 'Diff';

  @override
  String get fieldbookSummaryFinal => 'Final RL';

  @override
  String get fieldbookSummaryMisclosure => 'Misclosure';

  @override
  String get fieldbookSummaryNoClosing => 'No closing RL';

  @override
  String get fieldbookSummaryStart => 'Start RL';

  @override
  String get fieldbookSurveyorLabel => 'Surveyor';

  @override
  String fieldbookSurveyorSubtitle(String name) {
    return 'Surveyor $name';
  }

  @override
  String get fieldbookTitleHint => 'Level book title';

  @override
  String get fieldbookTitleLabel => 'Level book title *';

  @override
  String get fieldbookToleranceCheckTitle => 'Tolerance check required';

  @override
  String get fieldbookWeatherLabel => 'Weather';

  @override
  String get fieldbookWorkSectionLabel => 'Section';

  @override
  String get proActiveSubtitle => 'Create submission documents without ads.';

  @override
  String get proActiveTitle => 'Pro activated';

  @override
  String get proBuyButton => 'Buy Lv Book Pro';

  @override
  String get proFeatureBenchmarkPhotoLocation => 'TBM/BM photo & location';

  @override
  String get proFeatureBulkExport => 'Bulk export';

  @override
  String get proFeatureNoAds => 'No ads';

  @override
  String get proFeatureSummaryReport => 'Summary report';

  @override
  String get proFileNameSiteDateTitle => 'Site_Date_Level book';

  @override
  String get proFileNameSiteSectionDateTitle => 'Site_Section_Date_Level book';

  @override
  String get proFileNameTitleOnly => 'Level book name';

  @override
  String get proInspectionWatermarkDefault => 'Inspection';

  @override
  String get proPdfAuthorHint => 'e.g. Alex Kim';

  @override
  String get proPdfAuthorLabel => 'Author';

  @override
  String get proPdfCompanyHint => 'e.g. Acme Surveying Co.';

  @override
  String get proPdfCompanyLabel => 'Company name';

  @override
  String get proPdfExportHistory => 'Export history';

  @override
  String get proPdfExportHistoryClearAll => 'Clear all';

  @override
  String get proPdfExportHistoryEmpty => 'No export history.';

  @override
  String get proPdfFileNamePreviewLabel => 'File name preview';

  @override
  String get proPdfFileNameRuleLabel => 'File name rule';

  @override
  String get proPdfFooterNoteHint => 'e.g. Confirmed by site agent';

  @override
  String get proPdfFooterNoteLabel => 'Footer note';

  @override
  String proPdfLoadError(String error) {
    return 'Couldn\'t load settings: $error';
  }

  @override
  String get proPdfPresetAdd => 'Add preset';

  @override
  String get proPdfPresetDeleteTooltip => 'Delete preset';

  @override
  String get proPdfPresetDeletedMessage => 'Preset deleted';

  @override
  String get proPdfPresetLabel => 'Document preset';

  @override
  String get proPdfPresetNameLabel => 'Preset name';

  @override
  String get proPdfPresetNewName => 'New preset';

  @override
  String get proPdfPresetRename => 'Rename preset';

  @override
  String get proPdfPreviewSampleSite => 'Riverside site';

  @override
  String get proPdfPreviewSampleTitle => 'Section A level book';

  @override
  String get proPdfSavedMessage => 'Pro PDF settings saved';

  @override
  String get proPdfSettingsTitle => 'Pro PDF settings';

  @override
  String get proPdfShowJudgementSubtitle =>
      'Include Within tolerance / Check required in PDF and CSV.';

  @override
  String get proPdfShowJudgementTitle => 'Show arithmetic check result';

  @override
  String get proPdfSignatureDescription =>
      'Register a handwritten signature for the PDF \'Prepared by\' box.';

  @override
  String get proPdfSignatureDisplayError => 'Can\'t display the signature';

  @override
  String get proPdfSignatureEmpty => 'No signature registered';

  @override
  String get proPdfSignatureLinesSubtitle =>
      'Adds Prepared / Checked / Approved boxes at the bottom of the submission PDF.';

  @override
  String get proPdfSignatureLinesTitle => 'Show sign-off boxes';

  @override
  String get proPdfSignatureRedo => 'Sign again';

  @override
  String get proPdfSignatureRegister => 'Add signature';

  @override
  String get proPdfSignatureTitle => 'Author signature';

  @override
  String get proPdfTemplateLabel => 'Document template';

  @override
  String get proPdfWatermarkHint => 'e.g. Inspection';

  @override
  String get proPdfWatermarkLabel => 'Watermark';

  @override
  String get proPitchSubtitle =>
      'Unlock Pro field features with a one-time purchase.';

  @override
  String proPriceOneTimePurchase(String price) {
    return '$price · one-time purchase';
  }

  @override
  String get proSignatureClear => 'Clear';

  @override
  String get proSignatureDialogHint =>
      'Sign in the box below with your finger or a stylus.';

  @override
  String get proSignatureDialogTitle => 'Draw signature';

  @override
  String get proSignatureEmptyError => 'Please draw your signature';

  @override
  String get proSignatureSaveError => 'Couldn\'t save the signature';

  @override
  String get proTemplateBasic => 'Standard level book';

  @override
  String get proTemplateInspection => 'Inspection';

  @override
  String get proTemplateSubmission => 'Submission';

  @override
  String projectBackupLastSharedTitle(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Last backup shared $days days ago',
      one: 'Last backup shared 1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get projectBackupLaterButton => 'Later';

  @override
  String get projectBackupNeverSharedTitle =>
      'You haven\'t shared a backup yet';

  @override
  String get projectBackupReminderMessage =>
      'If you lose your phone or delete the app, your site records are lost. Keep the backup file in email or a cloud drive.';

  @override
  String get projectBackupShareButton => 'Share backup';

  @override
  String projectBackupShareError(String error) {
    return 'Couldn\'t share the backup: $error';
  }

  @override
  String projectBackupSharedMessage(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Shared backups of $count projects.',
      one: 'Shared the backup of 1 project.',
    );
    return '$_temp0';
  }

  @override
  String projectCardStats(int books) {
    String _temp0 = intl.Intl.pluralLogic(
      books,
      locale: localeName,
      other: '$books level books',
      one: '1 level book',
    );
    return '$_temp0';
  }

  @override
  String projectCardStatsOpen(int books, int open) {
    String _temp0 = intl.Intl.pluralLogic(
      books,
      locale: localeName,
      other: '$books level books',
      one: '1 level book',
    );
    return '$_temp0 · $open to review';
  }

  @override
  String projectCardUpdated(String date) {
    return 'Updated · $date';
  }

  @override
  String projectDeleteConfirm(String name) {
    return 'Delete project \"$name\"?\nAll of its level books and BMs will also be deleted.';
  }

  @override
  String get projectDeleteDialogTitle => 'Delete project';

  @override
  String get projectDescriptionLabel => 'Description (optional)';

  @override
  String get projectDetailTabBenchmarks => 'Benchmarks';

  @override
  String get projectDetailTabLevelBooks => 'Level books';

  @override
  String get projectEditDialogTitle => 'Edit project';

  @override
  String get projectEmptyMessage =>
      'Create a site (project) to record BMs and level books.\nTry the sample project to see automatic calculation and the closure check first.';

  @override
  String get projectEmptyNewButton => 'Create project';

  @override
  String get projectEmptySampleButton => 'Try sample project';

  @override
  String get projectEmptyTitle => 'Add your first site';

  @override
  String get projectListQuickMemoTooltip => 'Quick memo';

  @override
  String get projectListSettingsTooltip => 'Settings';

  @override
  String get projectNewDialogTitle => 'New project';

  @override
  String get projectProActiveMessage =>
      'TBM/BM photos & coordinates, bulk export and ad removal are available.';

  @override
  String get projectProActiveTitle => 'Pro active';

  @override
  String get projectProGetButton => 'Get Pro';

  @override
  String get projectProPromoMessage =>
      'Unlock TBM/BM photos & coordinates, bulk export and ad removal.';

  @override
  String projectRecentWorkSubtitle(String project, String date) {
    return 'Recent · $project · $date';
  }

  @override
  String get projectSampleBenchmarkDescription => 'Sample benchmark';

  @override
  String get projectSampleBenchmarkLocation =>
      'Curb stone in front of the site office';

  @override
  String projectSampleClosingStation(String bm) {
    return '$bm (close)';
  }

  @override
  String get projectSampleCreateError =>
      'Couldn\'t create the sample project. Please try again.';

  @override
  String get projectSampleCreatedMessage =>
      'Sample project created. Open the level book to see the automatic calculation.';

  @override
  String get projectSampleDescription =>
      'Sample for trying automatic calculation and the closure check. Delete it if you don\'t need it.';

  @override
  String get projectSampleInstrument => 'Automatic level';

  @override
  String get projectSampleLevelBookTitle => 'Sample level book (BM-1 loop)';

  @override
  String get projectSampleMemo =>
      'Sample data. Change a value and HI/RL are recalculated automatically.';

  @override
  String get projectSampleName => 'Sample site (deletable)';

  @override
  String get projectSampleSection => 'Sample section';

  @override
  String get projectSampleSurveyor => 'J. Smith';

  @override
  String get projectSampleWeather => 'Clear';

  @override
  String get projectSiteNameLabel => 'Site name *';

  @override
  String get projectSitesHeader => 'Sites';

  @override
  String get projectSummaryLoading => 'Organize level books and BMs by site.';

  @override
  String projectSummaryStatsAllReviewed(int books) {
    String _temp0 = intl.Intl.pluralLogic(
      books,
      locale: localeName,
      other: '$books level books',
      one: '1 level book',
    );
    return '$_temp0 · All reviewed';
  }

  @override
  String projectSummaryStatsOpen(int books, int open) {
    String _temp0 = intl.Intl.pluralLogic(
      books,
      locale: localeName,
      other: '$books level books',
      one: '1 level book',
    );
    return '$_temp0 · $open to review';
  }

  @override
  String projectSummaryTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Managing $count sites',
      one: 'Managing 1 site',
    );
    return '$_temp0';
  }

  @override
  String get purchaseCanceledMessage => 'Payment canceled.';

  @override
  String get purchaseFailedMessage => 'Payment didn\'t go through.';

  @override
  String get purchaseNothingToRestore => 'No purchases to restore.';

  @override
  String get purchasePendingMessage => 'Processing your payment.';

  @override
  String get purchaseProActivatedMessage => 'Lv Book Pro is now active.';

  @override
  String purchaseProductLoadError(String error) {
    return 'Couldn\'t load product info: $error';
  }

  @override
  String purchaseProductNotFound(String productId) {
    return 'Couldn\'t find the $productId product in Play Console.';
  }

  @override
  String get purchaseProductNotReady => 'Pro product info isn\'t ready yet.';

  @override
  String purchaseRestoreError(String error) {
    return 'Couldn\'t restore purchase: $error';
  }

  @override
  String purchaseStartError(String error) {
    return 'Couldn\'t start the purchase: $error';
  }

  @override
  String get purchaseStartFailed => 'Couldn\'t start the purchase.';

  @override
  String purchaseStoreInitError(String error) {
    return 'Couldn\'t initialize store purchases: $error';
  }

  @override
  String get purchaseStoreUnavailable => 'Store purchases are unavailable.';

  @override
  String get purchaseStoreUnsupportedPlatform =>
      'Store purchases aren\'t available on this platform.';

  @override
  String purchaseUpdateError(String error) {
    return 'Couldn\'t process the purchase update: $error';
  }

  @override
  String get quickMemoAudioMissing => 'Audio file not found.';

  @override
  String get quickMemoComposerTitle => 'Quick field memo';

  @override
  String get quickMemoDeleteConfirm => 'Delete this memo?';

  @override
  String get quickMemoDeleteRecordingTooltip => 'Delete recording';

  @override
  String get quickMemoDeleteTitle => 'Delete memo';

  @override
  String get quickMemoEmptyMessage =>
      'Use the bolt button at the bottom left to leave a text or voice memo from any screen.';

  @override
  String get quickMemoEmptyTitle => 'No memos yet';

  @override
  String get quickMemoMicPermissionRequired =>
      'Microphone permission is required.';

  @override
  String get quickMemoRecordHint => 'Tap the mic to record a voice memo';

  @override
  String get quickMemoRecorded => 'Voice recorded · tap the mic to re-record';

  @override
  String quickMemoRecording(String time) {
    return 'Recording · $time';
  }

  @override
  String quickMemoSaveError(String error) {
    return 'Couldn\'t save: $error';
  }

  @override
  String get quickMemoSavedMessage => 'Memo saved.';

  @override
  String get quickMemoTextHint => 'Type a memo (optional)';

  @override
  String get quickMemoTitle => 'Quick memo';

  @override
  String get settingsAdsRemovedActiveSubtitle =>
      'Your purchase is applied, so no ads are shown.';

  @override
  String get settingsAdsRemovedChecking => 'Checking ad removal status';

  @override
  String get settingsAdsRemovedCheckingSubtitle =>
      'Checking the store and local entitlement.';

  @override
  String get settingsAdsRemovedInactiveSubtitle =>
      'Remove all ads with a one-time purchase from the store.';

  @override
  String get settingsAdsRemovedLoadError => 'Couldn\'t load ad removal status';

  @override
  String get settingsCheckSection => 'Leveling check';

  @override
  String get settingsDocumentSection => 'Documents';

  @override
  String get settingsPdfSettingsSubtitle =>
      'Set company name, template, watermark and signature.';

  @override
  String get settingsPdfSettingsTitle => 'Submission PDF settings';

  @override
  String get settingsPurchaseStatusSection => 'Purchase status';

  @override
  String get settingsRemoveAdsTitle => 'Remove ads';

  @override
  String get settingsRestorePurchasePendingSubtitle =>
      'Checking your purchase history with the store.';

  @override
  String get settingsRestorePurchaseSubtitle =>
      'Restore the Pro purchase you already made.';

  @override
  String get settingsRestorePurchaseTitle => 'Restore purchase';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsToleranceCoefficientLabel => 'c (mm)';

  @override
  String get settingsToleranceFixedHelper =>
      'Allowed |misclosure| for every level book.';

  @override
  String get settingsToleranceFixedLabel => 'Allowance (mm)';

  @override
  String settingsToleranceFixedSummary(String mm) {
    return 'Fixed ±$mm mm';
  }

  @override
  String settingsToleranceInvalid(String min, String max) {
    return 'Enter $min–$max mm.';
  }

  @override
  String get settingsToleranceModeFixed => 'Fixed';

  @override
  String get settingsToleranceModeSqrt => 'c·√n';

  @override
  String get settingsToleranceNote =>
      'Exceeding it is a warning; export is still allowed.';

  @override
  String get settingsToleranceSqrtHelper =>
      'Allowed = c × √n mm, n = instrument setups (BS rows).';

  @override
  String settingsToleranceSqrtSummary(String mm) {
    return '$mm mm × √n (n = setups)';
  }

  @override
  String get settingsToleranceTitle => 'Misclosure tolerance';
}
