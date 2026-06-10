import 'package:archive/archive.dart';

import '../fieldbook/domain/fieldbook.dart';
import '../fieldbook/domain/measurement.dart';

class ProjectSubmissionPackageException implements Exception {
  final String message;

  const ProjectSubmissionPackageException(this.message);

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
      throw const ProjectSubmissionPackageException('패키지로 만들 파일이 없습니다.');
    }

    final archive = Archive();
    final usedNames = <String>{};
    for (final file in files) {
      final name = _uniqueFileName(file.name, usedNames);
      archive.addFile(ArchiveFile.bytes(name, file.bytes));
    }

    final bytes = ZipEncoder().encode(archive);
    if (bytes.isEmpty) {
      throw const ProjectSubmissionPackageException('제출 패키지 ZIP 생성에 실패했습니다.');
    }
    return bytes;
  }

  static String buildManifest({
    required String projectName,
    required List<FieldBook> fieldBooks,
    required Map<int, List<Measurement>> measurementsByFieldBookId,
    required List<String> fileNames,
  }) {
    if (fieldBooks.isEmpty) {
      throw const ProjectSubmissionPackageException('패키지로 만들 야장이 없습니다.');
    }

    final buffer = StringBuffer()
      ..writeln('레벨 야장 제출 패키지')
      ..writeln(
        '현장: ${projectName.trim().isEmpty ? '현장명 미입력' : projectName.trim()}',
      )
      ..writeln('파일 수: ${fileNames.length}')
      ..writeln();

    for (final fieldBook in fieldBooks) {
      final count = measurementsByFieldBookId[fieldBook.id]?.length ?? 0;
      buffer.writeln(
        '- ${fieldBook.title}: 측점 $count개, 검토 상태 ${fieldBook.reviewStatus.label}',
      );
      final reviewMemo = fieldBook.reviewMemo?.trim();
      if (reviewMemo != null && reviewMemo.isNotEmpty) {
        buffer.writeln('  검토 메모: $reviewMemo');
      }
      final reviewedAt = fieldBook.reviewedAt;
      if (reviewedAt != null) {
        buffer.writeln('  검토일: ${_formatDate(reviewedAt)}');
      }
    }

    if (fileNames.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('포함 파일');
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
