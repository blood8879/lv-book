import '../fieldbook/domain/fieldbook.dart';
import '../pro/pro_pdf_settings.dart';

class ExportFileNamer {
  final Set<String> _used = {};

  String next({
    required FieldBook fieldBook,
    required String extension,
    required String projectName,
    ProPdfSettings? proSettings,
  }) {
    final name = proSettings == null
        ? _formatFreeName(fieldBook: fieldBook, extension: extension)
        : proSettings.formatFileName(
            projectName: projectName,
            fieldBook: fieldBook,
            extension: extension,
          );
    return _unique(name);
  }

  String _unique(String fileName) {
    if (_used.add(fileName)) return fileName;

    final dot = fileName.lastIndexOf('.');
    final base = dot < 0 ? fileName : fileName.substring(0, dot);
    final extension = dot < 0 ? '' : fileName.substring(dot);
    var index = 2;
    while (true) {
      final candidate = '$base-$index$extension';
      if (_used.add(candidate)) return candidate;
      index += 1;
    }
  }

  static String _formatFreeName({
    required FieldBook fieldBook,
    required String extension,
  }) {
    final safeBase = _safeFileName(fieldBook.title);
    final safeExtension = extension.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    return '$safeBase.$safeExtension';
  }

  static String _safeFileName(String value) {
    final sanitized = value.trim().replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    return sanitized.isEmpty ? 'fieldbook' : sanitized;
  }
}
