import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';

import '../../l10n/l10n.dart';

/// Thrown when a picked file is not valid UTF-8 (e.g. CP949/EUC-KR CSV saved
/// by Excel).
///
/// UI shows `error.localizedMessage(context.l10n)`. [message] is the Korean
/// text, kept for callers not yet converted.
class TextFileEncodingException implements Exception {
  const TextFileEncodingException();

  /// User-facing message in the language of [l10n].
  String localizedMessage(AppLocalizations l10n) => l10n.coreFileNotUtf8;

  /// Korean message (legacy; prefer [localizedMessage]).
  String get message => localizedMessage(l10nKo);

  @override
  String toString() => localizedMessage(l10nKo);
}

/// Opens the platform file picker and returns the selected file's text
/// content (UTF-8). Returns null when the user cancels.
class TextFilePicker {
  static Future<String?> pick({required List<String> extensions}) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: extensions,
      withData: true,
    );
    final file = result?.files.firstOrNull;
    if (file == null) return null;

    final bytes = file.bytes;
    if (bytes != null) return decodeUtf8(bytes);
    final path = file.path;
    if (path != null) return decodeUtf8(await File(path).readAsBytes());
    return null;
  }

  /// Strictly decodes UTF-8 and strips a leading BOM. Throws
  /// [TextFileEncodingException] for malformed input instead of silently
  /// substituting replacement characters.
  static String decodeUtf8(List<int> bytes) {
    final String text;
    try {
      text = utf8.decode(bytes);
    } on FormatException {
      throw const TextFileEncodingException();
    }
    return text.startsWith('﻿') ? text.substring(1) : text;
  }
}
