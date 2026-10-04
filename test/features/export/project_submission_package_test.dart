import 'package:flutter_test/flutter_test.dart';
import 'package:archive/archive.dart';
import 'package:lv_book/features/export/project_submission_package.dart';
import 'package:lv_book/features/fieldbook/domain/fieldbook.dart';
import 'package:lv_book/features/fieldbook/domain/measurement.dart';
import 'package:lv_book/l10n/l10n.dart';

void main() {
  test('Pro user generates project submission package manifest', () {
    final manifest = ProjectSubmissionPackage.buildManifest(
      projectName: '현장 A',
      fieldBooks: [
        FieldBook(
          id: 1,
          projectId: 1,
          title: '야장 A',
          date: DateTime(2026, 6, 8),
        ),
      ],
      measurementsByFieldBookId: {
        1: [
          Measurement(
            fieldBookId: 1,
            orderIndex: 0,
            stationName: 'BM.1',
            bs: 1,
          ),
        ],
      },
      fileNames: const ['야장 A.pdf', '야장 A.csv'],
      l10n: l10nKo,
    );

    expect(manifest, contains('현장 A'));
    expect(manifest, contains('야장 A.pdf'));
    expect(manifest, contains('측점 1개'));
  });

  test('empty package rejects with message', () {
    expect(
      () => ProjectSubmissionPackage.buildManifest(
        projectName: '현장 A',
        fieldBooks: const [],
        measurementsByFieldBookId: const {},
        fileNames: const [],
        l10n: l10nKo,
      ),
      throwsA(isA<ProjectSubmissionPackageException>()),
    );
  });

  test('Pro project submission package creates readable zip bytes', () {
    final bytes = ProjectSubmissionPackage.buildZipBytes({
      '야장 A.pdf': [1, 2, 3],
      'manifest.txt': '현장 A'.codeUnits,
    });

    final archive = ZipDecoder().decodeBytes(bytes);
    expect(archive.files.map((file) => file.name), contains('야장 A.pdf'));
    expect(archive.files.map((file) => file.name), contains('manifest.txt'));
  });

  test('submission package preserves duplicate filenames with suffixes', () {
    final bytes = ProjectSubmissionPackage.buildZipBytesFromFiles([
      ProjectSubmissionPackageFile(name: '현장_요약.csv', bytes: 'field'.codeUnits),
      ProjectSubmissionPackageFile(
        name: '현장_요약.csv',
        bytes: 'summary'.codeUnits,
      ),
      ProjectSubmissionPackageFile(
        name: '현장_manifest.txt',
        bytes: 'a'.codeUnits,
      ),
      ProjectSubmissionPackageFile(
        name: '현장_manifest.txt',
        bytes: 'b'.codeUnits,
      ),
    ]);

    final archive = ZipDecoder().decodeBytes(bytes);
    final entries = {for (final file in archive.files) file.name: file};

    expect(
      entries.keys,
      containsAll([
        '현장_요약.csv',
        '현장_요약-2.csv',
        '현장_manifest.txt',
        '현장_manifest-2.txt',
      ]),
    );
    expect(
      String.fromCharCodes(entries['현장_요약.csv']!.content as List<int>),
      'field',
    );
    expect(
      String.fromCharCodes(entries['현장_요약-2.csv']!.content as List<int>),
      'summary',
    );
  });

  test('empty zip package rejects with message', () {
    expect(
      () => ProjectSubmissionPackage.buildZipBytes(const {}),
      throwsA(isA<ProjectSubmissionPackageException>()),
    );
  });
}
