import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';

/// Thrown when a picked file is not valid UTF-8 (e.g. CP949/EUC-KR CSV saved
/// by Excel). [message] is a user-facing Korean message.
class TextFileEncodingException implements Exception {
  final String message;

  const TextFileEncodingException([
    this.message =
        'UTF-8 형식의 파일만 지원합니다. Excel에서 "CSV UTF-8(쉼표로 분리)" 형식으로 다시 저장해 주세요.',
  ]);

  @override
  String toString() => message;
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
