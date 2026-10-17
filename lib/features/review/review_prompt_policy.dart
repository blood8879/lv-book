/// Key/value persistence used by [ReviewPromptPolicy].
///
/// Production uses the `app_settings` table; tests use an in-memory map.
abstract class ReviewPromptStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

/// Decides when the Google Play in-app review dialog may be requested.
///
/// Play policy: never incentivise or pre-gate a rating, so the app only asks
/// right after a value moment (a completed export share) and lets the native
/// dialog do the rest. The platform enforces its own quota on top of this, so
/// there is no lifetime cap here. Pure Dart so it can be unit-tested with a
/// fake clock.
class ReviewPromptPolicy {
  static const exportCountKey = 'review_export_count';
  static const lastRequestedAtKey = 'review_last_requested_at';
  static const requestCountKey = 'review_request_count';

  static const minExports = 2;
  static const requestCooldown = Duration(days: 30);

  final ReviewPromptStore store;
  final DateTime Function() clock;

  ReviewPromptPolicy({required this.store, DateTime Function()? clock})
    : clock = clock ?? DateTime.now;

  Future<void> recordSuccessfulExport() async {
    final count = await _readInt(exportCountKey);
    await store.write(exportCountKey, '${count + 1}');
  }

  Future<bool> isEligible() async {
    if (await _readInt(exportCountKey) < minExports) return false;

    final lastRequested = DateTime.tryParse(
      await store.read(lastRequestedAtKey) ?? '',
    );
    if (lastRequested != null &&
        clock().difference(lastRequested) < requestCooldown) {
      return false;
    }
    return true;
  }

  /// Starts the cooldown. The request count is informational only.
  Future<void> recordRequested() async {
    final count = await _readInt(requestCountKey);
    await store.write(requestCountKey, '${count + 1}');
    await store.write(lastRequestedAtKey, clock().toIso8601String());
  }

  Future<int> _readInt(String key) async =>
      int.tryParse(await store.read(key) ?? '') ?? 0;
}

/// Platform review API, abstracted so tests never touch platform channels.
abstract class AppReviewClient {
  Future<bool> isAvailable();
  Future<void> requestReview();
  Future<void> openStoreListing();
}

/// Glue between export flows, [ReviewPromptPolicy] and [AppReviewClient].
///
/// None of the methods throw: a review prompt must never break an export.
class ReviewPromptCoordinator {
  final ReviewPromptPolicy policy;
  final AppReviewClient client;

  ReviewPromptCoordinator({required this.policy, required this.client});

  /// Call after an export share completed successfully (not dismissed).
  ///
  /// Counts the export and returns whether a review should be requested now
  /// (policy eligible and the platform API available).
  Future<bool> onExportSucceeded() async {
    try {
      await policy.recordSuccessfulExport();
      if (!await policy.isEligible()) return false;
      return await client.isAvailable();
    } catch (_) {
      return false;
    }
  }

  /// Asks the platform for the review dialog, then starts the cooldown.
  ///
  /// The cooldown is recorded once the request was attempted, even if the
  /// plugin threw, so a broken review API cannot keep suppressing ads on every
  /// export. Returns whether the request call completed without error.
  Future<bool> requestReview() async {
    var ok = false;
    try {
      await client.requestReview();
      ok = true;
    } catch (_) {
      // Swallowed: see class doc.
    }
    try {
      await policy.recordRequested();
    } catch (_) {}
    return ok;
  }

  /// Share-completion flow for screens that may show an interstitial.
  ///
  /// - Dismissed share sheet: not a value moment; no export is counted and no
  ///   review is requested, but [showInterstitial] still runs as before.
  /// - Successful share: review first. If a review will be requested, the
  ///   interstitial is skipped this time so the two never stack; otherwise
  ///   [showInterstitial] runs.
  ///
  /// Returns whether a review was requested.
  Future<bool> handleShareResult({
    required bool dismissed,
    required Future<void> Function() showInterstitial,
  }) async {
    if (dismissed) {
      await showInterstitial();
      return false;
    }
    if (await onExportSucceeded()) {
      await requestReview();
      return true;
    }
    await showInterstitial();
    return false;
  }

  /// Share-completion flow for screens without an interstitial (Pro bulk).
  Future<bool> onExportSharedWithoutAd() async {
    if (!await onExportSucceeded()) return false;
    await requestReview();
    return true;
  }
}
