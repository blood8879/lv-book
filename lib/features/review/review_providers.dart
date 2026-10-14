import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/database/database_helper.dart';
import 'review_prompt_policy.dart';

/// [ReviewPromptStore] backed by the shared `app_settings` table.
class AppSettingsReviewPromptStore implements ReviewPromptStore {
  @override
  Future<String?> read(String key) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'app_settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  @override
  Future<void> write(String key, String value) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('app_settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}

/// Google Play / App Store review API via `in_app_review`.
class InAppReviewClient implements AppReviewClient {
  final InAppReview _inAppReview = InAppReview.instance;

  @override
  Future<bool> isAvailable() => _inAppReview.isAvailable();

  @override
  Future<void> requestReview() => _inAppReview.requestReview();

  @override
  Future<void> openStoreListing() => _inAppReview.openStoreListing();
}

final appReviewClientProvider = Provider<AppReviewClient>(
  (ref) => InAppReviewClient(),
);

final reviewPromptPolicyProvider = Provider<ReviewPromptPolicy>(
  (ref) => ReviewPromptPolicy(store: AppSettingsReviewPromptStore()),
);

final reviewPromptCoordinatorProvider = Provider<ReviewPromptCoordinator>(
  (ref) => ReviewPromptCoordinator(
    policy: ref.watch(reviewPromptPolicyProvider),
    client: ref.watch(appReviewClientProvider),
  ),
);
