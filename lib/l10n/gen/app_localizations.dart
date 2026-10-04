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

  /// Small label above the native ad card.
  ///
  /// In en, this message translates to:
  /// **'Ad'**
  String get adsNativeAdLabel;

  /// Fixed ad policy rule; translate faithfully.
  ///
  /// In en, this message translates to:
  /// **'An adaptive banner that fits the screen width is shown at the bottom.'**
  String get adsPolicyBannerSubtitle;

  /// No description provided for @adsPolicyBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Banner ads'**
  String get adsPolicyBannerTitle;

  /// Fixed ad policy rule; translate faithfully.
  ///
  /// In en, this message translates to:
  /// **'Shown only after sharing completes, at most 3 times a day and at least 10 minutes apart.'**
  String get adsPolicyExportSubtitle;

  /// No description provided for @adsPolicyExportTitle.
  ///
  /// In en, this message translates to:
  /// **'Export ads'**
  String get adsPolicyExportTitle;

  /// No description provided for @adsPolicySection.
  ///
  /// In en, this message translates to:
  /// **'Ad policy'**
  String get adsPolicySection;

  /// No description provided for @backupErrorBenchmarkCorrupted.
  ///
  /// In en, this message translates to:
  /// **'BM data is corrupted.'**
  String get backupErrorBenchmarkCorrupted;

  /// No description provided for @backupErrorCorrupted.
  ///
  /// In en, this message translates to:
  /// **'The backup data is corrupted.'**
  String get backupErrorCorrupted;

  /// No description provided for @backupErrorFieldBookCorrupted.
  ///
  /// In en, this message translates to:
  /// **'Level book data is corrupted.'**
  String get backupErrorFieldBookCorrupted;

  /// No description provided for @backupErrorInvalidFormat.
  ///
  /// In en, this message translates to:
  /// **'The backup file format is invalid.'**
  String get backupErrorInvalidFormat;

  /// No description provided for @backupErrorMeasurementCorrupted.
  ///
  /// In en, this message translates to:
  /// **'Station data is corrupted.'**
  String get backupErrorMeasurementCorrupted;

  /// No description provided for @backupErrorPhotoCorrupted.
  ///
  /// In en, this message translates to:
  /// **'Photo backup data is corrupted.'**
  String get backupErrorPhotoCorrupted;

  /// No description provided for @backupErrorProjectNotFound.
  ///
  /// In en, this message translates to:
  /// **'Project not found.'**
  String get backupErrorProjectNotFound;

  /// No description provided for @backupErrorUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This backup file isn\'t supported.'**
  String get backupErrorUnsupported;

  /// GPS accuracy, 1 decimal, formatted by caller.
  ///
  /// In en, this message translates to:
  /// **'Accuracy {accuracy} m'**
  String benchmarkAccuracy(String accuracy);

  /// No description provided for @benchmarkAddDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Add BM'**
  String get benchmarkAddDialogTitle;

  /// No description provided for @benchmarkCopyCoordinateButton.
  ///
  /// In en, this message translates to:
  /// **'Copy coordinates'**
  String get benchmarkCopyCoordinateButton;

  /// Clipboard text; 6 decimals formatted by caller.
  ///
  /// In en, this message translates to:
  /// **'Lat {latitude}, Lon {longitude}'**
  String benchmarkCopyCoordinateText(String latitude, String longitude);

  /// No description provided for @benchmarkDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\" (elevation: {elevation})?'**
  String benchmarkDeleteConfirm(String name, String elevation);

  /// No description provided for @benchmarkDeleteDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete BM'**
  String get benchmarkDeleteDialogTitle;

  /// No description provided for @benchmarkDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get benchmarkDescriptionLabel;

  /// No description provided for @benchmarkEditDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit BM'**
  String get benchmarkEditDialogTitle;

  /// No description provided for @benchmarkElevationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 100.000'**
  String get benchmarkElevationHint;

  /// No description provided for @benchmarkElevationInvalidError.
  ///
  /// In en, this message translates to:
  /// **'Enter the elevation as a number (m)'**
  String get benchmarkElevationInvalidError;

  /// No description provided for @benchmarkElevationLabel.
  ///
  /// In en, this message translates to:
  /// **'Elevation (m) *'**
  String get benchmarkElevationLabel;

  /// elevation formatted with 3 decimals by the caller.
  ///
  /// In en, this message translates to:
  /// **'Elevation {elevation} m'**
  String benchmarkElevationLine(String elevation);

  /// No description provided for @benchmarkEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Add a BM/TBM as your elevation reference with the + button,\nthen load it as the start RL when writing a level book.'**
  String get benchmarkEmptyMessage;

  /// No description provided for @benchmarkEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a BM (benchmark)'**
  String get benchmarkEmptyTitle;

  /// No description provided for @benchmarkKindLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get benchmarkKindLabel;

  /// kind is BM or TBM.
  ///
  /// In en, this message translates to:
  /// **'Type: {kind}'**
  String benchmarkKindLine(String kind);

  /// No description provided for @benchmarkLocationHintLabel.
  ///
  /// In en, this message translates to:
  /// **'Location hint'**
  String get benchmarkLocationHintLabel;

  /// No description provided for @benchmarkLocationLine.
  ///
  /// In en, this message translates to:
  /// **'Location: {hint}'**
  String benchmarkLocationLine(String hint);

  /// No description provided for @benchmarkLocationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission was denied.'**
  String get benchmarkLocationPermissionDenied;

  /// Location permission notice (design rule: keep exact Korean).
  ///
  /// In en, this message translates to:
  /// **'Location permission was permanently denied. Allow it in the app settings.'**
  String get benchmarkLocationPermissionDeniedForever;

  /// No description provided for @benchmarkLocationServiceOff.
  ///
  /// In en, this message translates to:
  /// **'Location services are turned off on this device.'**
  String get benchmarkLocationServiceOff;

  /// No description provided for @benchmarkMapOpenError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open a map app. Copy the coordinates instead.'**
  String get benchmarkMapOpenError;

  /// No description provided for @benchmarkNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. BM.1'**
  String get benchmarkNameHint;

  /// No description provided for @benchmarkNameLabel.
  ///
  /// In en, this message translates to:
  /// **'BM name *'**
  String get benchmarkNameLabel;

  /// No description provided for @benchmarkNameRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Enter a BM name'**
  String get benchmarkNameRequiredError;

  /// No description provided for @benchmarkNoSavedCoordinate.
  ///
  /// In en, this message translates to:
  /// **'No saved coordinates.'**
  String get benchmarkNoSavedCoordinate;

  /// No description provided for @benchmarkNoSavedPhoto.
  ///
  /// In en, this message translates to:
  /// **'No saved photo.'**
  String get benchmarkNoSavedPhoto;

  /// No description provided for @benchmarkOpenMapButton.
  ///
  /// In en, this message translates to:
  /// **'Open map'**
  String get benchmarkOpenMapButton;

  /// No description provided for @benchmarkPhotoFileMissing.
  ///
  /// In en, this message translates to:
  /// **'Photo file not found.'**
  String get benchmarkPhotoFileMissing;

  /// No description provided for @benchmarkPhotoNeedsSavedBm.
  ///
  /// In en, this message translates to:
  /// **'Photos can only be added to a saved BM.'**
  String get benchmarkPhotoNeedsSavedBm;

  /// No description provided for @benchmarkPhotoSaveError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the photo.'**
  String get benchmarkPhotoSaveError;

  /// No description provided for @benchmarkPhotoSaved.
  ///
  /// In en, this message translates to:
  /// **'Photo saved'**
  String get benchmarkPhotoSaved;

  /// No description provided for @benchmarkPickPhotoButton.
  ///
  /// In en, this message translates to:
  /// **'Choose photo'**
  String get benchmarkPickPhotoButton;

  /// No description provided for @benchmarkProLocationPromo.
  ///
  /// In en, this message translates to:
  /// **'With Pro you can save TBM/BM photos and coordinates.'**
  String get benchmarkProLocationPromo;

  /// No description provided for @benchmarkProLocationSaved.
  ///
  /// In en, this message translates to:
  /// **'Pro location info saved'**
  String get benchmarkProLocationSaved;

  /// No description provided for @benchmarkProLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Pro location record'**
  String get benchmarkProLocationTitle;

  /// Pro is a one-time purchase.
  ///
  /// In en, this message translates to:
  /// **'Available after buying Lv Book Pro.'**
  String get benchmarkProRequired;

  /// No description provided for @benchmarkProtectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Protection/check notes'**
  String get benchmarkProtectionLabel;

  /// No description provided for @benchmarkProtectionLine.
  ///
  /// In en, this message translates to:
  /// **'Protection: {note}'**
  String benchmarkProtectionLine(String note);

  /// BM re-check warning (design rule: keep exact Korean).
  ///
  /// In en, this message translates to:
  /// **'No last-checked date. Re-check required'**
  String get benchmarkRecheckNoVerifiedDate;

  /// BM re-check warning (design rule: keep exact Korean).
  ///
  /// In en, this message translates to:
  /// **'This BM is out of service. It can\'t be used as the start BM of a new level book.'**
  String get benchmarkRecheckOutOfService;

  /// BM re-check warning (design rule: keep exact Korean).
  ///
  /// In en, this message translates to:
  /// **'This BM is possibly damaged. Re-check it on site before use.'**
  String get benchmarkRecheckPossiblyDamaged;

  /// BM re-check warning (design rule: keep exact Korean).
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day since the last check. Re-check required} other{{days} days since the last check. Re-check required}}'**
  String benchmarkRecheckStale(int days);

  /// No description provided for @benchmarkRemovePhotoButton.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get benchmarkRemovePhotoButton;

  /// No description provided for @benchmarkSaveCurrentCoordinate.
  ///
  /// In en, this message translates to:
  /// **'Save current coordinates'**
  String get benchmarkSaveCurrentCoordinate;

  /// No description provided for @benchmarkSavingCoordinate.
  ///
  /// In en, this message translates to:
  /// **'Saving coordinates'**
  String get benchmarkSavingCoordinate;

  /// No description provided for @benchmarkStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get benchmarkStatusLabel;

  /// BM status (enum stopped).
  ///
  /// In en, this message translates to:
  /// **'Out of service'**
  String get benchmarkStatusOutOfService;

  /// BM status (enum damagedSuspected).
  ///
  /// In en, this message translates to:
  /// **'Possibly damaged'**
  String get benchmarkStatusPossiblyDamaged;

  /// BM status (enum available).
  ///
  /// In en, this message translates to:
  /// **'Usable'**
  String get benchmarkStatusUsable;

  /// No description provided for @benchmarkTakePhotoButton.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get benchmarkTakePhotoButton;

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

  /// App bar action: deselect all.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get exportBulkDeselectAll;

  /// No description provided for @exportBulkError.
  ///
  /// In en, this message translates to:
  /// **'Bulk export didn\'t complete: {error}'**
  String exportBulkError(String error);

  /// Bulk export format segment: PDF and CSV.
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get exportBulkFormatBoth;

  /// No description provided for @exportBulkManifestSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Lists the selected level books, generated files and station counts.'**
  String get exportBulkManifestSubtitle;

  /// No description provided for @exportBulkManifestTitle.
  ///
  /// In en, this message translates to:
  /// **'Include submission package manifest'**
  String get exportBulkManifestTitle;

  /// No description provided for @exportBulkNothingToExport.
  ///
  /// In en, this message translates to:
  /// **'No selected level book has data to export'**
  String get exportBulkNothingToExport;

  /// No description provided for @exportBulkProOnlyBody.
  ///
  /// In en, this message translates to:
  /// **'Share several level books as PDF/CSV at once.'**
  String get exportBulkProOnlyBody;

  /// No description provided for @exportBulkProOnlyTitle.
  ///
  /// In en, this message translates to:
  /// **'Pro feature'**
  String get exportBulkProOnlyTitle;

  /// Shown when a non-Pro user tries bulk export.
  ///
  /// In en, this message translates to:
  /// **'Available with Lv Book Pro (one-time purchase).'**
  String get exportBulkProRequired;

  /// App bar action: select all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get exportBulkSelectAll;

  /// No description provided for @exportBulkShareButton.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Share 1 level book} other{Share {count} level books}}'**
  String exportBulkShareButton(int count);

  /// No description provided for @exportBulkShared.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Shared 1 file} other{Shared {count} files}}'**
  String exportBulkShared(int count);

  /// No description provided for @exportBulkSummarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Puts each level book\'s BM, section, misclosure and result in one file.'**
  String get exportBulkSummarySubtitle;

  /// No description provided for @exportBulkSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Include check/submission summary CSV'**
  String get exportBulkSummaryTitle;

  /// Bulk export screen title.
  ///
  /// In en, this message translates to:
  /// **'Bulk export'**
  String get exportBulkTitle;

  /// Arithmetic check: ΣBS − ΣFS.
  ///
  /// In en, this message translates to:
  /// **'Difference'**
  String get exportCheckDifference;

  /// Arithmetic check: final reduced level.
  ///
  /// In en, this message translates to:
  /// **'Final RL'**
  String get exportCheckFinalRl;

  /// Arithmetic check: misclosure (4 decimals).
  ///
  /// In en, this message translates to:
  /// **'Misclosure'**
  String get exportCheckMisclosure;

  /// Arithmetic check judgement label. Never 'Pass/Fail'.
  ///
  /// In en, this message translates to:
  /// **'Result'**
  String get exportCheckResult;

  /// Arithmetic check: first reduced level.
  ///
  /// In en, this message translates to:
  /// **'Start RL'**
  String get exportCheckStartRl;

  /// Title of the arithmetic check box.
  ///
  /// In en, this message translates to:
  /// **'Arithmetic check'**
  String get exportCheckTitle;

  /// An arithmetic-check line in the PDF, e.g. 'ΣBS = 2.700'. Value is preformatted.
  ///
  /// In en, this message translates to:
  /// **'{label} = {value}'**
  String exportCheckValue(String label, String value);

  /// Measurement table column: backsight.
  ///
  /// In en, this message translates to:
  /// **'BS'**
  String get exportColumnBs;

  /// Measurement table column: foresight.
  ///
  /// In en, this message translates to:
  /// **'FS'**
  String get exportColumnFs;

  /// Measurement table column: height of instrument.
  ///
  /// In en, this message translates to:
  /// **'HI'**
  String get exportColumnHi;

  /// Measurement table column: row number.
  ///
  /// In en, this message translates to:
  /// **'No.'**
  String get exportColumnNo;

  /// Measurement table column: remarks (TP marker).
  ///
  /// In en, this message translates to:
  /// **'Remarks'**
  String get exportColumnRemarks;

  /// Measurement table column: reduced level.
  ///
  /// In en, this message translates to:
  /// **'RL'**
  String get exportColumnRl;

  /// Measurement table column: station name.
  ///
  /// In en, this message translates to:
  /// **'Station'**
  String get exportColumnStation;

  /// PDF header when Pro branding is on but no company name was entered.
  ///
  /// In en, this message translates to:
  /// **'Company name not set'**
  String get exportCompanyNotSet;

  /// No description provided for @exportCsvError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create the CSV: {error}'**
  String exportCsvError(String error);

  /// Title printed at the top of the exported PDF/CSV level book.
  ///
  /// In en, this message translates to:
  /// **'Differential leveling level book'**
  String get exportDocTitle;

  /// PDF title with the selected document template name.
  ///
  /// In en, this message translates to:
  /// **'Differential leveling level book · {template}'**
  String exportDocTitleWithTemplate(String template);

  /// Exported document field: author.
  ///
  /// In en, this message translates to:
  /// **'Prepared by'**
  String get exportFieldAuthor;

  /// Exported document field: starting benchmark elevation.
  ///
  /// In en, this message translates to:
  /// **'BM elevation'**
  String get exportFieldBmElevation;

  /// Exported document field.
  ///
  /// In en, this message translates to:
  /// **'Checker'**
  String get exportFieldChecker;

  /// Exported document field: company name.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get exportFieldCompany;

  /// Exported document field: survey date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get exportFieldDate;

  /// Exported document field.
  ///
  /// In en, this message translates to:
  /// **'Instrument'**
  String get exportFieldInstrument;

  /// Exported document field: job number.
  ///
  /// In en, this message translates to:
  /// **'Job no.'**
  String get exportFieldJobNumber;

  /// Exported document field: level book memo.
  ///
  /// In en, this message translates to:
  /// **'Memo'**
  String get exportFieldMemo;

  /// Exported document field.
  ///
  /// In en, this message translates to:
  /// **'Review date'**
  String get exportFieldReviewDate;

  /// Exported document field.
  ///
  /// In en, this message translates to:
  /// **'Review memo'**
  String get exportFieldReviewMemo;

  /// Exported document field.
  ///
  /// In en, this message translates to:
  /// **'Review status'**
  String get exportFieldReviewStatus;

  /// Exported document field: work section.
  ///
  /// In en, this message translates to:
  /// **'Section'**
  String get exportFieldSection;

  /// Exported document field: starting benchmark.
  ///
  /// In en, this message translates to:
  /// **'Start BM'**
  String get exportFieldStartBm;

  /// Exported document field.
  ///
  /// In en, this message translates to:
  /// **'Surveyor'**
  String get exportFieldSurveyor;

  /// Exported document field: level book title.
  ///
  /// In en, this message translates to:
  /// **'Level book'**
  String get exportFieldTitle;

  /// Exported document field.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get exportFieldWeather;

  /// CSV import warning.
  ///
  /// In en, this message translates to:
  /// **'The CSV has no date, so it was set to {date}.'**
  String exportImportDateMissing(String date);

  /// CSV import warning.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read the date \"{value}\", so it was set to {date}.'**
  String exportImportDateUnrecognized(String value, String date);

  /// Title for an imported level book when the CSV has none.
  ///
  /// In en, this message translates to:
  /// **'Imported level book'**
  String get exportImportDefaultTitle;

  /// CSV import error.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t find the measurement table header.'**
  String get exportImportHeaderNotFound;

  /// CSV import error; row is the 1-based CSV line.
  ///
  /// In en, this message translates to:
  /// **'Row {row}: {column} is not a valid number.'**
  String exportImportInvalidNumber(int row, String column);

  /// CSV import error: not UTF-8.
  ///
  /// In en, this message translates to:
  /// **'Only UTF-8 CSV is supported. Some characters are garbled, so the file can\'t be imported. In Excel, save it again as \"CSV UTF-8 (Comma delimited)\".'**
  String get exportImportUtf8Only;

  /// A label/value pair in an exported document.
  ///
  /// In en, this message translates to:
  /// **'{label}: {value}'**
  String exportLabelValue(String label, String value);

  /// Manifest: one level book line.
  ///
  /// In en, this message translates to:
  /// **'- {title}: {count, plural, =1{1 station} other{{count} stations}}, review status {status}'**
  String exportManifestFieldBookLine(String title, int count, String status);

  /// Manifest: number of files.
  ///
  /// In en, this message translates to:
  /// **'Files: {count}'**
  String exportManifestFileCount(int count);

  /// Manifest: heading for the file list.
  ///
  /// In en, this message translates to:
  /// **'Included files'**
  String get exportManifestIncludedFiles;

  /// Manifest: site name.
  ///
  /// In en, this message translates to:
  /// **'Site: {name}'**
  String exportManifestSite(String name);

  /// Manifest: no site name.
  ///
  /// In en, this message translates to:
  /// **'Site name not set'**
  String get exportManifestSiteNotSet;

  /// First line of the submission package manifest.
  ///
  /// In en, this message translates to:
  /// **'Lv Book submission package'**
  String get exportManifestTitle;

  /// Submission package error.
  ///
  /// In en, this message translates to:
  /// **'There are no level books to package.'**
  String get exportPackageNoFieldBooks;

  /// Submission package error.
  ///
  /// In en, this message translates to:
  /// **'There are no files to package.'**
  String get exportPackageNoFiles;

  /// Submission package error.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create the submission package ZIP.'**
  String get exportPackageZipError;

  /// No description provided for @exportPdfError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create the PDF: {error}'**
  String exportPdfError(String error);

  /// Review status in exported documents.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get exportReviewStatusDraft;

  /// Review status in exported documents.
  ///
  /// In en, this message translates to:
  /// **'Needs check'**
  String get exportReviewStatusNeedsCheck;

  /// Review status in exported documents.
  ///
  /// In en, this message translates to:
  /// **'Reviewed'**
  String get exportReviewStatusReviewed;

  /// Export screen title.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get exportScreenTitle;

  /// No description provided for @exportShareCsvTooltip.
  ///
  /// In en, this message translates to:
  /// **'Share CSV'**
  String get exportShareCsvTooltip;

  /// No description provided for @exportSharePdfTooltip.
  ///
  /// In en, this message translates to:
  /// **'Share PDF'**
  String get exportSharePdfTooltip;

  /// PDF signature box.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get exportSignatureApproved;

  /// PDF signature box.
  ///
  /// In en, this message translates to:
  /// **'Checked'**
  String get exportSignatureChecked;

  /// PDF signature box.
  ///
  /// In en, this message translates to:
  /// **'Prepared'**
  String get exportSignaturePrepared;

  /// Word appended to the summary CSV file name ('<site>_summary.csv').
  ///
  /// In en, this message translates to:
  /// **'summary'**
  String get exportSummaryFileSuffix;

  /// Summary report error.
  ///
  /// In en, this message translates to:
  /// **'Select level books to summarize.'**
  String get exportSummaryNoSelection;

  /// No description provided for @fieldbookAddTenRowsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add 10 rows'**
  String get fieldbookAddTenRowsTooltip;

  /// Validation bar headline; result is a judgement such as 'Within tolerance'.
  ///
  /// In en, this message translates to:
  /// **'Arithmetic check: {result}'**
  String fieldbookArithmeticCheckResult(String result);

  /// No description provided for @fieldbookBackupPasteHint.
  ///
  /// In en, this message translates to:
  /// **'Or paste the contents of a shared lvbook_backup.json.'**
  String get fieldbookBackupPasteHint;

  /// No description provided for @fieldbookBackupRestoredMessage.
  ///
  /// In en, this message translates to:
  /// **'Backup restored as a new project.'**
  String get fieldbookBackupRestoredMessage;

  /// No description provided for @fieldbookBmNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. BM.1'**
  String get fieldbookBmNameHint;

  /// No description provided for @fieldbookBmNameLabel.
  ///
  /// In en, this message translates to:
  /// **'BM name (optional)'**
  String get fieldbookBmNameLabel;

  /// No description provided for @fieldbookBulkExportButton.
  ///
  /// In en, this message translates to:
  /// **'Bulk export'**
  String get fieldbookBulkExportButton;

  /// No description provided for @fieldbookCheckEmptyRows.
  ///
  /// In en, this message translates to:
  /// **'Empty rows'**
  String get fieldbookCheckEmptyRows;

  /// No description provided for @fieldbookCheckFirstBs.
  ///
  /// In en, this message translates to:
  /// **'First BS'**
  String get fieldbookCheckFirstBs;

  /// No description provided for @fieldbookCheckLastFs.
  ///
  /// In en, this message translates to:
  /// **'Last FS'**
  String get fieldbookCheckLastFs;

  /// No description provided for @fieldbookCheckStationRows.
  ///
  /// In en, this message translates to:
  /// **'Station rows'**
  String get fieldbookCheckStationRows;

  /// No description provided for @fieldbookCheckTolerance.
  ///
  /// In en, this message translates to:
  /// **'Tolerance'**
  String get fieldbookCheckTolerance;

  /// No description provided for @fieldbookCheckTpComplete.
  ///
  /// In en, this message translates to:
  /// **'TP complete'**
  String get fieldbookCheckTpComplete;

  /// No description provided for @fieldbookCheckerLabel.
  ///
  /// In en, this message translates to:
  /// **'Checker'**
  String get fieldbookCheckerLabel;

  /// No description provided for @fieldbookChooseBackupFile.
  ///
  /// In en, this message translates to:
  /// **'Choose backup file (.json)'**
  String get fieldbookChooseBackupFile;

  /// No description provided for @fieldbookChooseCsvFile.
  ///
  /// In en, this message translates to:
  /// **'Choose CSV file (.csv)'**
  String get fieldbookChooseCsvFile;

  /// No description provided for @fieldbookColumnHi.
  ///
  /// In en, this message translates to:
  /// **'HI'**
  String get fieldbookColumnHi;

  /// No description provided for @fieldbookColumnNo.
  ///
  /// In en, this message translates to:
  /// **'Stn'**
  String get fieldbookColumnNo;

  /// No description provided for @fieldbookColumnRl.
  ///
  /// In en, this message translates to:
  /// **'RL'**
  String get fieldbookColumnRl;

  /// No description provided for @fieldbookContinueButton.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get fieldbookContinueButton;

  /// Name given to a duplicated level book or row.
  ///
  /// In en, this message translates to:
  /// **'{name} copy'**
  String fieldbookCopyName(String name);

  /// No description provided for @fieldbookCreateButton.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get fieldbookCreateButton;

  /// No description provided for @fieldbookCsvImportError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t import CSV: {error}'**
  String fieldbookCsvImportError(String error);

  /// No description provided for @fieldbookCsvImported.
  ///
  /// In en, this message translates to:
  /// **'CSV imported'**
  String get fieldbookCsvImported;

  /// No description provided for @fieldbookCsvImportedWithWarnings.
  ///
  /// In en, this message translates to:
  /// **'CSV imported. {warnings}'**
  String fieldbookCsvImportedWithWarnings(String warnings);

  /// No description provided for @fieldbookCsvPasteHint.
  ///
  /// In en, this message translates to:
  /// **'Or paste CSV exported from Lv Book.'**
  String get fieldbookCsvPasteHint;

  /// No description provided for @fieldbookDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete level book \"{title}\"?'**
  String fieldbookDeleteConfirm(String title);

  /// No description provided for @fieldbookDeleteRowConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete row {row}?'**
  String fieldbookDeleteRowConfirm(int row);

  /// No description provided for @fieldbookDeleteRowTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete row'**
  String get fieldbookDeleteRowTitle;

  /// No description provided for @fieldbookDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete level book'**
  String get fieldbookDeleteTitle;

  /// No description provided for @fieldbookDuplicateError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t duplicate level book: {error}'**
  String fieldbookDuplicateError(String error);

  /// No description provided for @fieldbookDuplicateStructure.
  ///
  /// In en, this message translates to:
  /// **'Duplicate structure'**
  String get fieldbookDuplicateStructure;

  /// No description provided for @fieldbookDuplicatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Level book structure duplicated'**
  String get fieldbookDuplicatedMessage;

  /// No description provided for @fieldbookEditStationTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit station'**
  String get fieldbookEditStationTitle;

  /// No description provided for @fieldbookEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Tap + to create a level book,\nor import existing records from CSV.'**
  String get fieldbookEmptyMessage;

  /// No description provided for @fieldbookEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your first level book'**
  String get fieldbookEmptyTitle;

  /// No description provided for @fieldbookEnterManually.
  ///
  /// In en, this message translates to:
  /// **'Enter manually'**
  String get fieldbookEnterManually;

  /// No description provided for @fieldbookExportCheckTitle.
  ///
  /// In en, this message translates to:
  /// **'Check before export'**
  String get fieldbookExportCheckTitle;

  /// No description provided for @fieldbookExportTooltip.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get fieldbookExportTooltip;

  /// No description provided for @fieldbookFabLabel.
  ///
  /// In en, this message translates to:
  /// **'Level book'**
  String get fieldbookFabLabel;

  /// No description provided for @fieldbookImportButton.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get fieldbookImportButton;

  /// No description provided for @fieldbookImportCsv.
  ///
  /// In en, this message translates to:
  /// **'Import CSV'**
  String get fieldbookImportCsv;

  /// No description provided for @fieldbookInstrumentLabel.
  ///
  /// In en, this message translates to:
  /// **'Instrument'**
  String get fieldbookInstrumentLabel;

  /// No description provided for @fieldbookIssueEmptyRows.
  ///
  /// In en, this message translates to:
  /// **'Remove rows with no readings.'**
  String get fieldbookIssueEmptyRows;

  /// No description provided for @fieldbookIssueExceedsTolerance.
  ///
  /// In en, this message translates to:
  /// **'Exceeds tolerance — check the readings.'**
  String get fieldbookIssueExceedsTolerance;

  /// No description provided for @fieldbookIssueFirstBsMissing.
  ///
  /// In en, this message translates to:
  /// **'The first row needs a backsight (BS).'**
  String get fieldbookIssueFirstBsMissing;

  /// No description provided for @fieldbookIssueLastFsMissing.
  ///
  /// In en, this message translates to:
  /// **'The last row needs a foresight (FS).'**
  String get fieldbookIssueLastFsMissing;

  /// No description provided for @fieldbookIssueNoStationRows.
  ///
  /// In en, this message translates to:
  /// **'Add at least one station row.'**
  String get fieldbookIssueNoStationRows;

  /// No description provided for @fieldbookIssueTpIncomplete.
  ///
  /// In en, this message translates to:
  /// **'TP rows need both BS and FS.'**
  String get fieldbookIssueTpIncomplete;

  /// No description provided for @fieldbookJobNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Job no.'**
  String get fieldbookJobNumberLabel;

  /// No description provided for @fieldbookNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New level book'**
  String get fieldbookNewTitle;

  /// No description provided for @fieldbookNoDataToExport.
  ///
  /// In en, this message translates to:
  /// **'No data to export'**
  String get fieldbookNoDataToExport;

  /// No description provided for @fieldbookNoSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get fieldbookNoSearchResults;

  /// No description provided for @fieldbookRestoreBackupError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t restore backup: {error}'**
  String fieldbookRestoreBackupError(String error);

  /// No description provided for @fieldbookRestoreBackupJson.
  ///
  /// In en, this message translates to:
  /// **'Restore backup JSON'**
  String get fieldbookRestoreBackupJson;

  /// No description provided for @fieldbookRestoreButton.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get fieldbookRestoreButton;

  /// No description provided for @fieldbookReviewMemoHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Confirmed by supervisor'**
  String get fieldbookReviewMemoHint;

  /// No description provided for @fieldbookReviewMemoLabel.
  ///
  /// In en, this message translates to:
  /// **'Review notes'**
  String get fieldbookReviewMemoLabel;

  /// No description provided for @fieldbookReviewPanelTitle.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get fieldbookReviewPanelTitle;

  /// No description provided for @fieldbookReviewSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save review'**
  String get fieldbookReviewSaveButton;

  /// No description provided for @fieldbookReviewSavedMessage.
  ///
  /// In en, this message translates to:
  /// **'Review info saved'**
  String get fieldbookReviewSavedMessage;

  /// No description provided for @fieldbookReviewStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Review status'**
  String get fieldbookReviewStatusLabel;

  /// No description provided for @fieldbookReviewTodayButton.
  ///
  /// In en, this message translates to:
  /// **'Set review date to today'**
  String get fieldbookReviewTodayButton;

  /// No description provided for @fieldbookReviewedOn.
  ///
  /// In en, this message translates to:
  /// **'Reviewed {date}'**
  String fieldbookReviewedOn(String date);

  /// No description provided for @fieldbookRowActionsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Row actions'**
  String get fieldbookRowActionsTooltip;

  /// No description provided for @fieldbookRowDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate row'**
  String get fieldbookRowDuplicate;

  /// No description provided for @fieldbookRowInsertBelow.
  ///
  /// In en, this message translates to:
  /// **'Insert row below'**
  String get fieldbookRowInsertBelow;

  /// No description provided for @fieldbookRowSetManualTp.
  ///
  /// In en, this message translates to:
  /// **'Set manual TP'**
  String get fieldbookRowSetManualTp;

  /// No description provided for @fieldbookRowUnsetManualTp.
  ///
  /// In en, this message translates to:
  /// **'Unset manual TP'**
  String get fieldbookRowUnsetManualTp;

  /// No description provided for @fieldbookSaveStatusAutosaved.
  ///
  /// In en, this message translates to:
  /// **'Autosaved'**
  String get fieldbookSaveStatusAutosaved;

  /// No description provided for @fieldbookSaveStatusError.
  ///
  /// In en, this message translates to:
  /// **'Not saved'**
  String get fieldbookSaveStatusError;

  /// No description provided for @fieldbookSaveStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Autosave pending'**
  String get fieldbookSaveStatusPending;

  /// No description provided for @fieldbookSaveStatusSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get fieldbookSaveStatusSaved;

  /// No description provided for @fieldbookSavedMessage.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get fieldbookSavedMessage;

  /// No description provided for @fieldbookSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Title, section, surveyor, date'**
  String get fieldbookSearchHint;

  /// No description provided for @fieldbookSearchLabel.
  ///
  /// In en, this message translates to:
  /// **'Search level books'**
  String get fieldbookSearchLabel;

  /// No description provided for @fieldbookSelectBm.
  ///
  /// In en, this message translates to:
  /// **'Select BM'**
  String get fieldbookSelectBm;

  /// No description provided for @fieldbookShareBackup.
  ///
  /// In en, this message translates to:
  /// **'Share project backup'**
  String get fieldbookShareBackup;

  /// No description provided for @fieldbookShareBackupError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t share backup: {error}'**
  String fieldbookShareBackupError(String error);

  /// No description provided for @fieldbookSiteDetailsSummary.
  ///
  /// In en, this message translates to:
  /// **'Surveyor, instrument, weather…'**
  String get fieldbookSiteDetailsSummary;

  /// No description provided for @fieldbookSiteDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Site details'**
  String get fieldbookSiteDetailsTitle;

  /// No description provided for @fieldbookStartBmLabel.
  ///
  /// In en, this message translates to:
  /// **'Start BM'**
  String get fieldbookStartBmLabel;

  /// No description provided for @fieldbookStartElevationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 100.000'**
  String get fieldbookStartElevationHint;

  /// No description provided for @fieldbookStartElevationLabel.
  ///
  /// In en, this message translates to:
  /// **'Start RL (m) *'**
  String get fieldbookStartElevationLabel;

  /// No description provided for @fieldbookStartRlLabel.
  ///
  /// In en, this message translates to:
  /// **'Start RL'**
  String get fieldbookStartRlLabel;

  /// No description provided for @fieldbookStationHelper.
  ///
  /// In en, this message translates to:
  /// **'Leave blank to show the row number ({row})'**
  String fieldbookStationHelper(int row);

  /// No description provided for @fieldbookStationHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. No.1, BM.1, TP.1'**
  String get fieldbookStationHint;

  /// No description provided for @fieldbookStationLabel.
  ///
  /// In en, this message translates to:
  /// **'Station'**
  String get fieldbookStationLabel;

  /// No description provided for @fieldbookStatusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get fieldbookStatusDraft;

  /// No description provided for @fieldbookStatusNeedsCheck.
  ///
  /// In en, this message translates to:
  /// **'Needs check'**
  String get fieldbookStatusNeedsCheck;

  /// No description provided for @fieldbookStatusReviewed.
  ///
  /// In en, this message translates to:
  /// **'Reviewed'**
  String get fieldbookStatusReviewed;

  /// No description provided for @fieldbookSummaryDiff.
  ///
  /// In en, this message translates to:
  /// **'Diff'**
  String get fieldbookSummaryDiff;

  /// No description provided for @fieldbookSummaryFinal.
  ///
  /// In en, this message translates to:
  /// **'Final RL'**
  String get fieldbookSummaryFinal;

  /// No description provided for @fieldbookSummaryMisclosure.
  ///
  /// In en, this message translates to:
  /// **'Misclosure'**
  String get fieldbookSummaryMisclosure;

  /// No description provided for @fieldbookSummaryStart.
  ///
  /// In en, this message translates to:
  /// **'Start RL'**
  String get fieldbookSummaryStart;

  /// No description provided for @fieldbookSurveyorLabel.
  ///
  /// In en, this message translates to:
  /// **'Surveyor'**
  String get fieldbookSurveyorLabel;

  /// No description provided for @fieldbookSurveyorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Surveyor {name}'**
  String fieldbookSurveyorSubtitle(String name);

  /// No description provided for @fieldbookTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Level book title'**
  String get fieldbookTitleHint;

  /// No description provided for @fieldbookTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Level book title *'**
  String get fieldbookTitleLabel;

  /// No description provided for @fieldbookToleranceCheckTitle.
  ///
  /// In en, this message translates to:
  /// **'Tolerance check required'**
  String get fieldbookToleranceCheckTitle;

  /// No description provided for @fieldbookWeatherLabel.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get fieldbookWeatherLabel;

  /// No description provided for @fieldbookWorkSectionLabel.
  ///
  /// In en, this message translates to:
  /// **'Section'**
  String get fieldbookWorkSectionLabel;

  /// No description provided for @proActiveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create submission documents without ads.'**
  String get proActiveSubtitle;

  /// No description provided for @proActiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Pro activated'**
  String get proActiveTitle;

  /// One-time purchase button.
  ///
  /// In en, this message translates to:
  /// **'Buy Lv Book Pro'**
  String get proBuyButton;

  /// Short feature pill.
  ///
  /// In en, this message translates to:
  /// **'TBM/BM photo & location'**
  String get proFeatureBenchmarkPhotoLocation;

  /// Short feature pill.
  ///
  /// In en, this message translates to:
  /// **'Bulk export'**
  String get proFeatureBulkExport;

  /// Short feature pill.
  ///
  /// In en, this message translates to:
  /// **'No ads'**
  String get proFeatureNoAds;

  /// Short feature pill.
  ///
  /// In en, this message translates to:
  /// **'Summary report'**
  String get proFeatureSummaryReport;

  /// No description provided for @proFileNameSiteDateTitle.
  ///
  /// In en, this message translates to:
  /// **'Site_Date_Level book'**
  String get proFileNameSiteDateTitle;

  /// No description provided for @proFileNameSiteSectionDateTitle.
  ///
  /// In en, this message translates to:
  /// **'Site_Section_Date_Level book'**
  String get proFileNameSiteSectionDateTitle;

  /// No description provided for @proFileNameTitleOnly.
  ///
  /// In en, this message translates to:
  /// **'Level book name'**
  String get proFileNameTitleOnly;

  /// Default watermark text of the built-in Inspection preset (new installs only).
  ///
  /// In en, this message translates to:
  /// **'Inspection'**
  String get proInspectionWatermarkDefault;

  /// No description provided for @proPdfAuthorHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Alex Kim'**
  String get proPdfAuthorHint;

  /// No description provided for @proPdfAuthorLabel.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get proPdfAuthorLabel;

  /// No description provided for @proPdfCompanyHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Acme Surveying Co.'**
  String get proPdfCompanyHint;

  /// No description provided for @proPdfCompanyLabel.
  ///
  /// In en, this message translates to:
  /// **'Company name'**
  String get proPdfCompanyLabel;

  /// Button and dialog title.
  ///
  /// In en, this message translates to:
  /// **'Export history'**
  String get proPdfExportHistory;

  /// No description provided for @proPdfExportHistoryClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get proPdfExportHistoryClearAll;

  /// No description provided for @proPdfExportHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No export history.'**
  String get proPdfExportHistoryEmpty;

  /// No description provided for @proPdfFileNamePreviewLabel.
  ///
  /// In en, this message translates to:
  /// **'File name preview'**
  String get proPdfFileNamePreviewLabel;

  /// No description provided for @proPdfFileNameRuleLabel.
  ///
  /// In en, this message translates to:
  /// **'File name rule'**
  String get proPdfFileNameRuleLabel;

  /// No description provided for @proPdfFooterNoteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Confirmed by site agent'**
  String get proPdfFooterNoteHint;

  /// No description provided for @proPdfFooterNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Footer note'**
  String get proPdfFooterNoteLabel;

  /// No description provided for @proPdfLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load settings: {error}'**
  String proPdfLoadError(String error);

  /// Tooltip and dialog title.
  ///
  /// In en, this message translates to:
  /// **'Add preset'**
  String get proPdfPresetAdd;

  /// No description provided for @proPdfPresetDeleteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete preset'**
  String get proPdfPresetDeleteTooltip;

  /// No description provided for @proPdfPresetDeletedMessage.
  ///
  /// In en, this message translates to:
  /// **'Preset deleted'**
  String get proPdfPresetDeletedMessage;

  /// No description provided for @proPdfPresetLabel.
  ///
  /// In en, this message translates to:
  /// **'Document preset'**
  String get proPdfPresetLabel;

  /// No description provided for @proPdfPresetNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Preset name'**
  String get proPdfPresetNameLabel;

  /// No description provided for @proPdfPresetNewName.
  ///
  /// In en, this message translates to:
  /// **'New preset'**
  String get proPdfPresetNewName;

  /// Tooltip and dialog title.
  ///
  /// In en, this message translates to:
  /// **'Rename preset'**
  String get proPdfPresetRename;

  /// Sample project name in the file name preview.
  ///
  /// In en, this message translates to:
  /// **'Riverside site'**
  String get proPdfPreviewSampleSite;

  /// Sample level book title in the file name preview.
  ///
  /// In en, this message translates to:
  /// **'Section A level book'**
  String get proPdfPreviewSampleTitle;

  /// No description provided for @proPdfSavedMessage.
  ///
  /// In en, this message translates to:
  /// **'Pro PDF settings saved'**
  String get proPdfSavedMessage;

  /// No description provided for @proPdfSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Pro PDF settings'**
  String get proPdfSettingsTitle;

  /// No description provided for @proPdfShowJudgementSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Include Within tolerance / Check required in PDF and CSV.'**
  String get proPdfShowJudgementSubtitle;

  /// No description provided for @proPdfShowJudgementTitle.
  ///
  /// In en, this message translates to:
  /// **'Show arithmetic check result'**
  String get proPdfShowJudgementTitle;

  /// No description provided for @proPdfSignatureDescription.
  ///
  /// In en, this message translates to:
  /// **'Register a handwritten signature for the PDF \'Prepared by\' box.'**
  String get proPdfSignatureDescription;

  /// No description provided for @proPdfSignatureDisplayError.
  ///
  /// In en, this message translates to:
  /// **'Can\'t display the signature'**
  String get proPdfSignatureDisplayError;

  /// No description provided for @proPdfSignatureEmpty.
  ///
  /// In en, this message translates to:
  /// **'No signature registered'**
  String get proPdfSignatureEmpty;

  /// No description provided for @proPdfSignatureLinesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Adds Prepared / Reviewed / Approved boxes at the bottom of the submission PDF.'**
  String get proPdfSignatureLinesSubtitle;

  /// No description provided for @proPdfSignatureLinesTitle.
  ///
  /// In en, this message translates to:
  /// **'Show sign-off boxes'**
  String get proPdfSignatureLinesTitle;

  /// No description provided for @proPdfSignatureRedo.
  ///
  /// In en, this message translates to:
  /// **'Sign again'**
  String get proPdfSignatureRedo;

  /// No description provided for @proPdfSignatureRegister.
  ///
  /// In en, this message translates to:
  /// **'Add signature'**
  String get proPdfSignatureRegister;

  /// No description provided for @proPdfSignatureTitle.
  ///
  /// In en, this message translates to:
  /// **'Author signature'**
  String get proPdfSignatureTitle;

  /// No description provided for @proPdfTemplateLabel.
  ///
  /// In en, this message translates to:
  /// **'Document template'**
  String get proPdfTemplateLabel;

  /// No description provided for @proPdfWatermarkHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Inspection'**
  String get proPdfWatermarkHint;

  /// No description provided for @proPdfWatermarkLabel.
  ///
  /// In en, this message translates to:
  /// **'Watermark'**
  String get proPdfWatermarkLabel;

  /// Pro is a one-time purchase; never say subscription.
  ///
  /// In en, this message translates to:
  /// **'Unlock Pro field features with a one-time purchase.'**
  String get proPitchSubtitle;

  /// Store-formatted price (already localized by the store) + one-time purchase.
  ///
  /// In en, this message translates to:
  /// **'{price} · one-time purchase'**
  String proPriceOneTimePurchase(String price);

  /// No description provided for @proSignatureClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get proSignatureClear;

  /// No description provided for @proSignatureDialogHint.
  ///
  /// In en, this message translates to:
  /// **'Sign in the box below with your finger or a stylus.'**
  String get proSignatureDialogHint;

  /// No description provided for @proSignatureDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Draw signature'**
  String get proSignatureDialogTitle;

  /// No description provided for @proSignatureEmptyError.
  ///
  /// In en, this message translates to:
  /// **'Please draw your signature'**
  String get proSignatureEmptyError;

  /// No description provided for @proSignatureSaveError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the signature'**
  String get proSignatureSaveError;

  /// PDF document template / default preset name.
  ///
  /// In en, this message translates to:
  /// **'Standard level book'**
  String get proTemplateBasic;

  /// PDF document template / default preset name.
  ///
  /// In en, this message translates to:
  /// **'Inspection'**
  String get proTemplateInspection;

  /// PDF document template / default preset name.
  ///
  /// In en, this message translates to:
  /// **'Submission'**
  String get proTemplateSubmission;

  /// No description provided for @projectBackupLastSharedTitle.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{Last backup shared 1 day ago} other{Last backup shared {days} days ago}}'**
  String projectBackupLastSharedTitle(int days);

  /// No description provided for @projectBackupLaterButton.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get projectBackupLaterButton;

  /// No description provided for @projectBackupNeverSharedTitle.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t shared a backup yet'**
  String get projectBackupNeverSharedTitle;

  /// No description provided for @projectBackupReminderMessage.
  ///
  /// In en, this message translates to:
  /// **'If you lose your phone or delete the app, your site records are lost. Keep the backup file in email or a cloud drive.'**
  String get projectBackupReminderMessage;

  /// No description provided for @projectBackupShareButton.
  ///
  /// In en, this message translates to:
  /// **'Share backup'**
  String get projectBackupShareButton;

  /// No description provided for @projectBackupShareError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t share the backup: {error}'**
  String projectBackupShareError(String error);

  /// No description provided for @projectBackupSharedMessage.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Shared the backup of 1 project.} other{Shared backups of {count} projects.}}'**
  String projectBackupSharedMessage(int count);

  /// No description provided for @projectCardStats.
  ///
  /// In en, this message translates to:
  /// **'{books, plural, =1{1 level book} other{{books} level books}}'**
  String projectCardStats(int books);

  /// No description provided for @projectCardStatsOpen.
  ///
  /// In en, this message translates to:
  /// **'{books, plural, =1{1 level book} other{{books} level books}} · {open} check required'**
  String projectCardStatsOpen(int books, int open);

  /// date is yyyy-MM-dd.
  ///
  /// In en, this message translates to:
  /// **'Updated · {date}'**
  String projectCardUpdated(String date);

  /// Cascade delete warning (design rule: keep exact Korean).
  ///
  /// In en, this message translates to:
  /// **'Delete project \"{name}\"?\nAll of its level books and BMs will also be deleted.'**
  String projectDeleteConfirm(String name);

  /// No description provided for @projectDeleteDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete project'**
  String get projectDeleteDialogTitle;

  /// No description provided for @projectDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get projectDescriptionLabel;

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

  /// No description provided for @projectEditDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit project'**
  String get projectEditDialogTitle;

  /// No description provided for @projectEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Create a site (project) to record BMs and level books.\nTry the sample project to see automatic calculation and the closure check first.'**
  String get projectEmptyMessage;

  /// No description provided for @projectEmptyNewButton.
  ///
  /// In en, this message translates to:
  /// **'Create project'**
  String get projectEmptyNewButton;

  /// No description provided for @projectEmptySampleButton.
  ///
  /// In en, this message translates to:
  /// **'Try sample project'**
  String get projectEmptySampleButton;

  /// No description provided for @projectEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Add your first site'**
  String get projectEmptyTitle;

  /// No description provided for @projectListQuickMemoTooltip.
  ///
  /// In en, this message translates to:
  /// **'Quick memo'**
  String get projectListQuickMemoTooltip;

  /// No description provided for @projectListSettingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get projectListSettingsTooltip;

  /// No description provided for @projectNewDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'New project'**
  String get projectNewDialogTitle;

  /// No description provided for @projectProActiveMessage.
  ///
  /// In en, this message translates to:
  /// **'TBM/BM photos & coordinates, ad removal and submission PDFs are available.'**
  String get projectProActiveMessage;

  /// No description provided for @projectProActiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Pro active'**
  String get projectProActiveTitle;

  /// Home Pro panel button that opens settings (one-time purchase).
  ///
  /// In en, this message translates to:
  /// **'Get Pro'**
  String get projectProGetButton;

  /// No description provided for @projectProPromoMessage.
  ///
  /// In en, this message translates to:
  /// **'Unlock TBM/BM photos & coordinates, submission PDFs and ad removal.'**
  String get projectProPromoMessage;

  /// date is yyyy-MM-dd.
  ///
  /// In en, this message translates to:
  /// **'Recent · {project} · {date}'**
  String projectRecentWorkSubtitle(String project, String date);

  /// No description provided for @projectSampleBenchmarkDescription.
  ///
  /// In en, this message translates to:
  /// **'Sample benchmark'**
  String get projectSampleBenchmarkDescription;

  /// No description provided for @projectSampleBenchmarkLocation.
  ///
  /// In en, this message translates to:
  /// **'Curb stone in front of the site office'**
  String get projectSampleBenchmarkLocation;

  /// Station name of the closing shot back on the BM.
  ///
  /// In en, this message translates to:
  /// **'{bm} (close)'**
  String projectSampleClosingStation(String bm);

  /// No description provided for @projectSampleCreateError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create the sample project. Please try again.'**
  String get projectSampleCreateError;

  /// No description provided for @projectSampleCreatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Sample project created. Open the level book to see the automatic calculation.'**
  String get projectSampleCreatedMessage;

  /// No description provided for @projectSampleDescription.
  ///
  /// In en, this message translates to:
  /// **'Sample for trying automatic calculation and the closure check. Delete it if you don\'t need it.'**
  String get projectSampleDescription;

  /// No description provided for @projectSampleInstrument.
  ///
  /// In en, this message translates to:
  /// **'Automatic level'**
  String get projectSampleInstrument;

  /// No description provided for @projectSampleLevelBookTitle.
  ///
  /// In en, this message translates to:
  /// **'Sample level book (BM-1 loop)'**
  String get projectSampleLevelBookTitle;

  /// No description provided for @projectSampleMemo.
  ///
  /// In en, this message translates to:
  /// **'Sample data. Change a value and HI/RL are recalculated automatically.'**
  String get projectSampleMemo;

  /// Name of the generated sample project (stored as data).
  ///
  /// In en, this message translates to:
  /// **'Sample site (deletable)'**
  String get projectSampleName;

  /// No description provided for @projectSampleSection.
  ///
  /// In en, this message translates to:
  /// **'Sample section'**
  String get projectSampleSection;

  /// Fictional surveyor name for the sample level book.
  ///
  /// In en, this message translates to:
  /// **'J. Smith'**
  String get projectSampleSurveyor;

  /// No description provided for @projectSampleWeather.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get projectSampleWeather;

  /// Required project (site) name field.
  ///
  /// In en, this message translates to:
  /// **'Site name *'**
  String get projectSiteNameLabel;

  /// Section header above the project cards.
  ///
  /// In en, this message translates to:
  /// **'Sites'**
  String get projectSitesHeader;

  /// No description provided for @projectSummaryLoading.
  ///
  /// In en, this message translates to:
  /// **'Organize level books and BMs by site.'**
  String get projectSummaryLoading;

  /// No description provided for @projectSummaryStatsAllReviewed.
  ///
  /// In en, this message translates to:
  /// **'{books, plural, =1{1 level book} other{{books} level books}} · All reviewed'**
  String projectSummaryStatsAllReviewed(int books);

  /// Home summary when some level books need checking.
  ///
  /// In en, this message translates to:
  /// **'{books, plural, =1{1 level book} other{{books} level books}} · {open} check required'**
  String projectSummaryStatsOpen(int books, int open);

  /// No description provided for @projectSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Managing 1 site} other{Managing {count} sites}}'**
  String projectSummaryTitle(int count);

  /// No description provided for @purchaseCanceledMessage.
  ///
  /// In en, this message translates to:
  /// **'Payment canceled.'**
  String get purchaseCanceledMessage;

  /// No description provided for @purchaseFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Payment didn\'t go through.'**
  String get purchaseFailedMessage;

  /// No description provided for @purchaseNothingToRestore.
  ///
  /// In en, this message translates to:
  /// **'No purchases to restore.'**
  String get purchaseNothingToRestore;

  /// No description provided for @purchasePendingMessage.
  ///
  /// In en, this message translates to:
  /// **'Processing your payment.'**
  String get purchasePendingMessage;

  /// No description provided for @purchaseProActivatedMessage.
  ///
  /// In en, this message translates to:
  /// **'Lv Book Pro is now active.'**
  String get purchaseProActivatedMessage;

  /// No description provided for @purchaseProductLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load product info: {error}'**
  String purchaseProductLoadError(String error);

  /// No description provided for @purchaseProductNotFound.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t find the {productId} product in Play Console.'**
  String purchaseProductNotFound(String productId);

  /// No description provided for @purchaseProductNotReady.
  ///
  /// In en, this message translates to:
  /// **'Pro product info isn\'t ready yet.'**
  String get purchaseProductNotReady;

  /// No description provided for @purchaseRestoreError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t restore purchase: {error}'**
  String purchaseRestoreError(String error);

  /// No description provided for @purchaseStartError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t start the purchase: {error}'**
  String purchaseStartError(String error);

  /// No description provided for @purchaseStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t start the purchase.'**
  String get purchaseStartFailed;

  /// No description provided for @purchaseStoreInitError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t initialize store purchases: {error}'**
  String purchaseStoreInitError(String error);

  /// No description provided for @purchaseStoreUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Store purchases are unavailable.'**
  String get purchaseStoreUnavailable;

  /// No description provided for @purchaseStoreUnsupportedPlatform.
  ///
  /// In en, this message translates to:
  /// **'Store purchases aren\'t available on this platform.'**
  String get purchaseStoreUnsupportedPlatform;

  /// No description provided for @purchaseUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t process the purchase update: {error}'**
  String purchaseUpdateError(String error);

  /// No description provided for @quickMemoAudioMissing.
  ///
  /// In en, this message translates to:
  /// **'Audio file not found.'**
  String get quickMemoAudioMissing;

  /// No description provided for @quickMemoComposerTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick field memo'**
  String get quickMemoComposerTitle;

  /// No description provided for @quickMemoDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this memo?'**
  String get quickMemoDeleteConfirm;

  /// No description provided for @quickMemoDeleteRecordingTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete recording'**
  String get quickMemoDeleteRecordingTooltip;

  /// No description provided for @quickMemoDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete memo'**
  String get quickMemoDeleteTitle;

  /// No description provided for @quickMemoEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Use the bolt button at the bottom left to leave a text or voice memo from any screen.'**
  String get quickMemoEmptyMessage;

  /// No description provided for @quickMemoEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No memos yet'**
  String get quickMemoEmptyTitle;

  /// No description provided for @quickMemoMicPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission is required.'**
  String get quickMemoMicPermissionRequired;

  /// No description provided for @quickMemoRecordHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the mic to record a voice memo'**
  String get quickMemoRecordHint;

  /// No description provided for @quickMemoRecorded.
  ///
  /// In en, this message translates to:
  /// **'Voice recorded · tap the mic to re-record'**
  String get quickMemoRecorded;

  /// No description provided for @quickMemoRecording.
  ///
  /// In en, this message translates to:
  /// **'Recording · {time}'**
  String quickMemoRecording(String time);

  /// No description provided for @quickMemoSaveError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save: {error}'**
  String quickMemoSaveError(String error);

  /// No description provided for @quickMemoSavedMessage.
  ///
  /// In en, this message translates to:
  /// **'Memo saved.'**
  String get quickMemoSavedMessage;

  /// No description provided for @quickMemoTextHint.
  ///
  /// In en, this message translates to:
  /// **'Type a memo (optional)'**
  String get quickMemoTextHint;

  /// No description provided for @quickMemoTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick memo'**
  String get quickMemoTitle;

  /// No description provided for @settingsAdsRemovedActiveSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your purchase is applied, so no ads are shown.'**
  String get settingsAdsRemovedActiveSubtitle;

  /// No description provided for @settingsAdsRemovedChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking ad removal status'**
  String get settingsAdsRemovedChecking;

  /// No description provided for @settingsAdsRemovedCheckingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Checking the store and local entitlement.'**
  String get settingsAdsRemovedCheckingSubtitle;

  /// Pro is a one-time purchase; never say subscription.
  ///
  /// In en, this message translates to:
  /// **'Remove all ads with a one-time purchase from the store.'**
  String get settingsAdsRemovedInactiveSubtitle;

  /// No description provided for @settingsAdsRemovedLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load ad removal status'**
  String get settingsAdsRemovedLoadError;

  /// No description provided for @settingsDocumentSection.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get settingsDocumentSection;

  /// No description provided for @settingsPdfSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set company name, template, watermark and signature.'**
  String get settingsPdfSettingsSubtitle;

  /// No description provided for @settingsPdfSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Submission PDF settings'**
  String get settingsPdfSettingsTitle;

  /// No description provided for @settingsPurchaseStatusSection.
  ///
  /// In en, this message translates to:
  /// **'Purchase status'**
  String get settingsPurchaseStatusSection;

  /// No description provided for @settingsRemoveAdsTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove ads'**
  String get settingsRemoveAdsTitle;

  /// No description provided for @settingsRestorePurchasePendingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Checking your purchase history with the store.'**
  String get settingsRestorePurchasePendingSubtitle;

  /// No description provided for @settingsRestorePurchaseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Restore the Pro purchase you already made.'**
  String get settingsRestorePurchaseSubtitle;

  /// No description provided for @settingsRestorePurchaseTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore purchase'**
  String get settingsRestorePurchaseTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;
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
