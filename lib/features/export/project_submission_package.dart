import 'package:archive/archive.dart';

import '../../l10n/l10n.dart';
import '../fieldbook/domain/fieldbook.dart';
import '../fieldbook/domain/measurement.dart';
import 'export_labels.dart';

enum ProjectSubmissionPackageError { noFiles, zipFailed, noFieldBooks }

class ProjectSubmissionPackageException implements Exception {
  final ProjectSubmissionPackageError code;

  const ProjectSubmissionPackageException(this.code);

  String localizedMessage(AppLocalizations l10n) => switch (code) {
    ProjectSubmissionPackageError.noFiles => l10n.exportPackageNoFiles,
    ProjectSubmissionPackageError.zipFailed => l10n.exportPackageZipError,
    ProjectSubmissionPackageError.noFieldBooks =>
      l10n.exportPackageNoFieldBooks,
  };

  /// Legacy Korean message; prefer [localizedMessage].
  String get message => localizedMessage(l10nKo);

  @override
  String toString() => message;
}

class ProjectSubmissionPackageFile {
  final String name;
  final List<int> bytes;

  const ProjectSubmissionPackageFile({required this.name, required this.bytes});
}

class ProjectSubmissionPackage {
  static List<int> buildZipBytes(Map<String, List<int>> files) {
    return buildZipBytesFromFiles([
      for (final entry in files.entries)
        ProjectSubmissionPackageFile(name: entry.key, bytes: entry.value),
    ]);
  }

  static List<int> buildZipBytesFromFiles(
    List<ProjectSubmissionPackageFile> files,
  ) {
    if (files.isEmpty) {
      throw const ProjectSubmissionPackageException(
        ProjectSubmissionPackageError.noFiles,
      );
    }

    final archive = Archive();
    final usedNames = <String>{};
    for (final file in files) {
      final name = _uniqueFileName(file.name, usedNames);
      archive.addFile(ArchiveFile.bytes(name, file.bytes));
    }

    final bytes = ZipEncoder().encode(archive);
    if (bytes.isEmpty) {
      throw const ProjectSubmissionPackageException(
        ProjectSubmissionPackageError.zipFailed,
      );
    }
    return bytes;
  }

  static String buildManifest({
    required String projectName,
    required List<FieldBook> fieldBooks,
    required Map<int, List<Measurement>> measurementsByFieldBookId,
    required List<String> fileNames,
    required AppLocalizations l10n,
  }) {
    if (fieldBooks.isEmpty) {
      throw const ProjectSubmissionPackageException(
        ProjectSubmissionPackageError.noFieldBooks,
      );
    }

    final buffer = StringBuffer()
      ..writeln(l10n.exportManifestTitle)
      ..writeln(
        l10n.exportManifestSite(
          projectName.trim().isEmpty
              ? l10n.exportManifestSiteNotSet
              : projectName.trim(),
        ),
      )
      ..writeln(l10n.exportManifestFileCount(fileNames.length))
      ..writeln();

    for (final fieldBook in fieldBooks) {
      final count = measurementsByFieldBookId[fieldBook.id]?.length ?? 0;
      buffer.writeln(
        l10n.exportManifestFieldBookLine(
          fieldBook.title,
          count,
          exportReviewStatusLabel(l10n, fieldBook.reviewStatus),
        ),
      );
      final reviewMemo = fieldBook.reviewMemo?.trim();
      if (reviewMemo != null && reviewMemo.isNotEmpty) {
        buffer.writeln(
          '  ${l10n.exportLabelValue(l10n.exportFieldReviewMemo, reviewMemo)}',
        );
      }
      final reviewedAt = fieldBook.reviewedAt;
      if (reviewedAt != null) {
        buffer.writeln(
          '  ${l10n.exportLabelValue(l10n.exportFieldReviewDate, _formatDate(reviewedAt))}',
        );
      }
    }

    if (fileNames.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln(l10n.exportManifestIncludedFiles);
      for (final fileName in fileNames) {
        buffer.writeln('- $fileName');
      }
    }

    return buffer.toString();
  }

  static String _uniqueFileName(String name, Set<String> usedNames) {
    final trimmed = name.trim().isEmpty ? 'file' : name.trim();
    if (usedNames.add(trimmed)) return trimmed;

    final dot = trimmed.lastIndexOf('.');
    final base = dot > 0 ? trimmed.substring(0, dot) : trimmed;
    final extension = dot > 0 ? trimmed.substring(dot) : '';
    var index = 2;
    while (true) {
      final candidate = '$base-$index$extension';
      if (usedNames.add(candidate)) return candidate;
      index++;
    }
  }

  static String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}
