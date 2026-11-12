/// Google Analytics for Firebase event catalogue (the one place where event
/// names, parameter keys and parameter values are defined).
///
/// Privacy rule: never send anything the user typed or picked. No readings,
/// elevations, coordinates, project / field book / site / company / BM names,
/// notes, memo text or file names. Parameters are limited to booleans, numbers
/// (counts, buckets) and the fixed strings in [AnalyticsValues]; any other
/// string is dropped by [sanitizeAnalyticsParams] before it reaches Firebase.
///
/// | Event                     | Parameters                                          | Logged from |
/// |---------------------------|-----------------------------------------------------|-------------|
/// | `screen_view`             | `screen_name`, `screen_class` ([AnalyticsScreens])  | `AnalyticsRouteObserver` (named page routes) |
/// | `fieldbook_created`       | `method` (blank/copy/import), `reduction_method`    | field book list: create sheet, duplicate, import |
/// | `fieldbook_first_entry`   | `reduction_method`                                  | field book editor: first save with a BS/FS reading |
/// | `misclosure_checked`      | `result` (pass/fail/no_reference), `arithmetic_ok`, `tolerance_mode`, `unit`, `reduction_method` | field book editor: export button |
/// | `export_success`          | `format`, `bulk`, `share_status` (single) / `file_count` (bulk) | export screen, bulk export screen |
/// | `export_failed`           | `format`, `bulk`                                    | export screen, bulk export screen |
/// | `import_success`          | `format` (csv/xlsx), `row_count` (bucket), `has_warnings` | field book list: import dialog |
/// | `import_failed`           | `format` (csv/xlsx), `stage` (parse/save)           | field book list: import dialog |
/// | `backup_restored`         | `field_book_count` (bucket)                         | field book list: restore backup |
/// | `project_created`         | `method` (manual/sample)                            | project list notifier / sample project |
/// | `benchmark_created`       | `kind` (bm/tbm)                                     | benchmark list notifier |
/// | `quick_memo_used`         | `has_text`, `has_audio`                             | quick memo list notifier (saved memo) |
/// | `peg_test_used`           | `action` (save/copy), `result` (pass/fail), `unit`  | peg test screen |
/// | `pro_paywall_view`        | `source` (settings/project_banner/bulk_export/benchmark_location) | settings Pro panel, bulk export lock, BM location panel |
/// | `pro_purchase_start`      | –                                                   | `PurchaseController.buyPro` |
/// | `pro_purchase_success`    | –                                                   | purchase stream: Pro purchased |
/// | `pro_purchase_failed`     | `reason` (canceled/error/start_failed/product_not_ready) | `PurchaseController` |
/// | `pro_restore`             | `result` (restored/nothing/pending/error/unavailable) | `PurchaseController.restorePurchases` |
/// | `review_prompt_requested` | `success`                                           | `ReviewPromptCoordinator.requestReview` |
///
/// User property: `is_pro` ("true"/"false"), set by `LvBookApp` whenever the
/// Pro entitlement (`adsRemovedProvider`) is known.
///
/// Google Play's automatic `in_app_purchase` event is left as is; the app
/// does not log the GA4 `purchase` ecommerce event on top of it.
library;

abstract final class AnalyticsEvents {
  static const fieldbookCreated = 'fieldbook_created';
  static const fieldbookFirstEntry = 'fieldbook_first_entry';
  static const misclosureChecked = 'misclosure_checked';
  static const exportSuccess = 'export_success';
  static const exportFailed = 'export_failed';
  static const importSuccess = 'import_success';
  static const importFailed = 'import_failed';
  static const backupRestored = 'backup_restored';
  static const projectCreated = 'project_created';
  static const benchmarkCreated = 'benchmark_created';
  static const quickMemoUsed = 'quick_memo_used';
  static const pegTestUsed = 'peg_test_used';
  static const proPaywallView = 'pro_paywall_view';
  static const proPurchaseStart = 'pro_purchase_start';
  static const proPurchaseSuccess = 'pro_purchase_success';
  static const proPurchaseFailed = 'pro_purchase_failed';
  static const proRestore = 'pro_restore';
  static const reviewPromptRequested = 'review_prompt_requested';

  static const all = {
    fieldbookCreated,
    fieldbookFirstEntry,
    misclosureChecked,
    exportSuccess,
    exportFailed,
    importSuccess,
    importFailed,
    backupRestored,
    projectCreated,
    benchmarkCreated,
    quickMemoUsed,
    pegTestUsed,
    proPaywallView,
    proPurchaseStart,
    proPurchaseSuccess,
    proPurchaseFailed,
    proRestore,
    reviewPromptRequested,
  };
}

abstract final class AnalyticsParams {
  static const method = 'method';
  static const reductionMethod = 'reduction_method';
  static const result = 'result';
  static const arithmeticOk = 'arithmetic_ok';
  static const toleranceMode = 'tolerance_mode';
  static const unit = 'unit';
  static const format = 'format';
  static const bulk = 'bulk';
  static const shareStatus = 'share_status';
  static const fileCount = 'file_count';
  static const rowCount = 'row_count';
  static const hasWarnings = 'has_warnings';
  static const stage = 'stage';
  static const fieldBookCount = 'field_book_count';
  static const kind = 'kind';
  static const hasText = 'has_text';
  static const hasAudio = 'has_audio';
  static const action = 'action';
  static const source = 'source';
  static const reason = 'reason';
  static const success = 'success';
}

/// The only string values a parameter may carry.
abstract final class AnalyticsValues {
  // fieldbook_created.method
  static const blank = 'blank';
  static const copy = 'copy';
  static const imported = 'import';

  // reduction_method
  static const heightOfInstrument = 'hi';
  static const riseAndFall = 'rise_fall';

  // misclosure_checked.result, peg_test_used.result
  static const pass = 'pass';
  static const fail = 'fail';
  static const noReference = 'no_reference';

  // tolerance_mode
  static const fixed = 'fixed';
  static const sqrtSetups = 'sqrt_setups';
  static const sqrtDistance = 'sqrt_distance';

  // unit
  static const metres = 'm';
  static const feet = 'ft';

  // format
  static const pdf = 'pdf';
  static const csv = 'csv';
  static const xlsx = 'xlsx';
  static const pdfCsv = 'pdf_csv';

  // share_status
  static const shared = 'shared';
  static const dismissed = 'dismissed';
  static const unavailable = 'unavailable';

  // import_failed.stage
  static const parse = 'parse';
  static const save = 'save';

  // project_created.method
  static const manual = 'manual';
  static const sample = 'sample';

  // benchmark_created.kind
  static const bm = 'bm';
  static const tbm = 'tbm';

  // pro_paywall_view.source
  static const sourceSettings = 'settings';
  static const sourceProjectBanner = 'project_banner';
  static const sourceBulkExport = 'bulk_export';
  static const sourceBenchmarkLocation = 'benchmark_location';

  // pro_purchase_failed.reason
  static const canceled = 'canceled';
  static const error = 'error';
  static const startFailed = 'start_failed';
  static const productNotReady = 'product_not_ready';

  // pro_restore.result (also error / unavailable / pending above)
  static const restored = 'restored';
  static const nothing = 'nothing';
  static const pending = 'pending';

  // user property is_pro
  static const trueValue = 'true';
  static const falseValue = 'false';

  static const all = {
    blank,
    copy,
    imported,
    heightOfInstrument,
    riseAndFall,
    pass,
    fail,
    noReference,
    fixed,
    sqrtSetups,
    sqrtDistance,
    metres,
    feet,
    pdf,
    csv,
    xlsx,
    pdfCsv,
    shared,
    dismissed,
    unavailable,
    parse,
    save,
    manual,
    sample,
    bm,
    tbm,
    sourceSettings,
    sourceProjectBanner,
    sourceBulkExport,
    sourceBenchmarkLocation,
    canceled,
    error,
    startFailed,
    productNotReady,
    restored,
    nothing,
    pending,
    trueValue,
    falseValue,
    ...AnalyticsBuckets.all,
  };
}

/// Count buckets so exact sizes of a user's data are never sent.
abstract final class AnalyticsBuckets {
  static const all = {'0', '1', '2-5', '6-20', '21-50', '51-100', '101+'};

  static String count(int n) {
    if (n <= 0) return '0';
    if (n == 1) return '1';
    if (n <= 5) return '2-5';
    if (n <= 20) return '6-20';
    if (n <= 50) return '21-50';
    if (n <= 100) return '51-100';
    return '101+';
  }
}

/// User property names.
abstract final class AnalyticsUserProperties {
  static const isPro = 'is_pro';
}

/// `screen_view` names, set as [RouteSettings.name] at the push sites.
abstract final class AnalyticsScreens {
  static const projectList = 'project_list';
  static const projectDetail = 'project_detail';
  static const fieldbookEdit = 'fieldbook_edit';
  static const export = 'export';
  static const bulkExport = 'bulk_export';
  static const settings = 'settings';
  static const proPdfSettings = 'pro_pdf_settings';
  static const pegTest = 'peg_test';
  static const pegTestHistory = 'peg_test_history';
  static const pegTestRecord = 'peg_test_record';
  static const quickMemoList = 'quick_memo_list';

  static const all = {
    projectList,
    projectDetail,
    fieldbookEdit,
    export,
    bulkExport,
    settings,
    proPdfSettings,
    pegTest,
    pegTestHistory,
    pegTestRecord,
    quickMemoList,
  };
}

/// GA4 limits: event/param names ≤ 40 chars, string values ≤ 100 chars.
const analyticsMaxNameLength = 40;
const analyticsMaxValueLength = 100;

final _namePattern = RegExp(r'^[a-z][a-z0-9_]*$');

/// Whether [name] is a valid GA4 event / parameter name.
bool isValidAnalyticsName(String name) =>
    name.length <= analyticsMaxNameLength && _namePattern.hasMatch(name);

/// Keeps only safe parameters: booleans, finite numbers and strings from
/// [AnalyticsValues.all] (or [AnalyticsScreens.all]) under valid keys. Any
/// other value — in particular free text — is dropped.
Map<String, Object> sanitizeAnalyticsParams(Map<String, Object?> params) {
  final result = <String, Object>{};
  for (final entry in params.entries) {
    final key = entry.key;
    final value = entry.value;
    if (!isValidAnalyticsName(key)) continue;
    if (value is bool) {
      result[key] = value;
    } else if (value is num) {
      if (value.isFinite) result[key] = value;
    } else if (value is String) {
      if (value.length <= analyticsMaxValueLength &&
          (AnalyticsValues.all.contains(value) ||
              AnalyticsScreens.all.contains(value))) {
        result[key] = value;
      }
    }
  }
  return result;
}
