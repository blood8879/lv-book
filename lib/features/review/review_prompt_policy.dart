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
/// dialog do the rest. Pure Dart so it can be unit-tested with a fake clock.
class ReviewPromptPolicy {
  static const firstLaunchAtKey = 'review_first_launch_at';
  static const exportCountKey = 'review_export_count';
  static const lastRequestedAtKey = 'review_last_requested_at';
  static const requestCountKey = 'review_request_count';

  static const minExports = 3;
  static const minInstallAge = Duration(days: 3);
  static const requestCooldown = Duration(days: 120);
  static const maxRequests = 3;

  final ReviewPromptStore store;
  final DateTime Function() clock;

  ReviewPromptPolicy({required this.store, DateTime Function()? clock})
    : clock = clock ?? DateTime.now;

  /// Stores the first-launch time once; later calls keep the original value.
  Future<DateTime> ensureFirstLaunchRecorded() async {
    final stored = DateTime.tryParse(await store.read(firstLaunchAtKey) ?? '');
    if (stored != null) return stored;
    final now = clock();
    await store.write(firstLaunchAtKey, now.toIso8601String());
    return now;
  }

  Future<void> recordSuccessfulExport() async {
    final count = await _readInt(exportCountKey);
    await store.write(exportCountKey, '${count + 1}');
  }

  Future<bool> isEligible() async {
    final now = clock();
    if (await _readInt(exportCountKey) < minExports) return false;
    if (await _readInt(requestCountKey) >= maxRequests) return false;

    final firstLaunch = await ensureFirstLaunchRecorded();
    if (now.difference(firstLaunch) < minInstallAge) return false;

    final lastRequested = DateTime.tryParse(
      await store.read(lastRequestedAtKey) ?? '',
    );
    if (lastRequested != null &&
        now.difference(lastRequested) < requestCooldown) {
      return false;
    }
    return true;
  }

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
class ReviewPromptCoordinator {
  final ReviewPromptPolicy policy;
  final AppReviewClient client;

  ReviewPromptCoordinator({required this.policy, required this.client});

  /// Call after an export share completed successfully.
  ///
  /// Always counts the export. When an interstitial ad was shown for this
  /// share the review request is skipped (and not counted as a request), so
  /// the two never stack. Never throws; returns whether a review was requested.
  Future<bool> onExportShared({required bool interstitialShown}) async {
    try {
      await policy.recordSuccessfulExport();
      if (interstitialShown) return false;
      if (!await policy.isEligible()) return false;
      if (!await client.isAvailable()) return false;
      await client.requestReview();
      await policy.recordRequested();
      return true;
    } catch (_) {
      // A review prompt must never break the export flow.
      return false;
    }
  }
}
