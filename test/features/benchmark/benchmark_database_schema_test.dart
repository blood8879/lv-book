import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lv_book/core/constants/app_constants.dart';

void main() {
  test('benchmark location schema is declared for database version 7', () {
    final helper = File(
      'lib/core/database/database_helper.dart',
    ).readAsStringSync();

    expect(AppConstants.dbVersion, greaterThanOrEqualTo(7));
    for (final column in [
      "kind TEXT NOT NULL DEFAULT 'bm'",
      'photo_path TEXT',
      'latitude REAL',
      'longitude REAL',
      'coordinate_accuracy_m REAL',
      'coordinate_captured_at TEXT',
    ]) {
      expect(helper, contains(column));
    }
    expect(
      RegExp(
        r'if \(oldVersion < 6\)[\s\S]*ALTER TABLE benchmarks ADD COLUMN kind',
      ).hasMatch(helper),
      isTrue,
    );
  });
}
