import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Stores quick-memo recordings relative to the app documents directory.
///
/// iOS changes the app container path (and thus the absolute documents path)
/// across app updates, so absolute paths saved in the database go stale. New
/// rows store a path relative to the documents directory
/// (`quick_memos/memo_123.m4a`); legacy rows that still hold an absolute path
/// are re-anchored under the current documents directory when the original
/// file no longer exists.
class QuickMemoAudioPaths {
  const QuickMemoAudioPaths._();

  /// Sub-directory (under app documents) holding recordings.
  static const dirName = 'quick_memos';

  /// Value to persist for [absolutePath]: relative to [documentsDir] when the
  /// file lives inside it, otherwise the path unchanged.
  static String toStored(String absolutePath, String documentsDir) {
    if (!p.isAbsolute(absolutePath)) return absolutePath;
    if (p.isWithin(documentsDir, absolutePath)) {
      return p.relative(absolutePath, from: documentsDir);
    }
    return absolutePath;
  }

  /// Absolute path for a [stored] value under the current [documentsDir].
  ///
  /// Relative values are joined onto [documentsDir]. Legacy absolute values are
  /// returned as-is when they still exist; otherwise their `quick_memos/...`
  /// tail (or basename) is tried under [documentsDir]. If nothing exists the
  /// best candidate is returned so callers can show a "missing file" state.
  static String resolve(
    String stored,
    String documentsDir, {
    bool Function(String path)? exists,
  }) {
    final fileExists = exists ?? (String path) => File(path).existsSync();
    if (!p.isAbsolute(stored)) return p.join(documentsDir, stored);
    if (fileExists(stored)) return stored;

    final candidates = <String>[];
    final segments = p.split(stored);
    final dirIndex = segments.lastIndexOf(dirName);
    if (dirIndex >= 0 && dirIndex < segments.length - 1) {
      candidates.add(p.joinAll([documentsDir, ...segments.sublist(dirIndex)]));
    }
    final basename = p.basename(stored);
    candidates.add(p.join(documentsDir, dirName, basename));
    candidates.add(p.join(documentsDir, basename));

    for (final candidate in candidates) {
      if (fileExists(candidate)) return candidate;
    }
    return candidates.first;
  }

  static Future<String> _documentsDir() async =>
      (await getApplicationDocumentsDirectory()).path;

  /// [toStored] against the device's current documents directory.
  static Future<String> toStoredOnDevice(String absolutePath) async =>
      toStored(absolutePath, await _documentsDir());

  /// [resolve] against the device's current documents directory.
  static Future<String> resolveOnDevice(String stored) async =>
      resolve(stored, await _documentsDir());
}
