import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../l10n/l10n.dart';
import '../ads/ad_settings_repository.dart';
import '../benchmark/data/benchmark_repository.dart';
import '../fieldbook/data/measurement_repository.dart';
import '../fieldbook/domain/fieldbook.dart';
import '../fieldbook/domain/measurement.dart';
import '../fieldbook/domain/measurement_validation.dart';
import '../pro/pro_settings_repository.dart';
import 'csv_exporter.dart';
import 'export_file_namer.dart';
import 'pdf_template.dart';
import 'project_submission_package.dart';
import 'submission_summary_report.dart';

enum BulkExportFormat { pdf, csv, both }

typedef BulkExportShare = Future<void> Function(List<XFile> files);

class BulkExportService {
  /// Legacy Korean message; the service throws the app-language
  /// `exportBulkProRequired` text.
  static final proRequiredMessage = l10nKo.exportBulkProRequired;

  final AdSettingsRepository adSettingsRepository;
  final ProSettingsRepository proSettingsRepository;
  final MeasurementRepository measurementRepository;
  final BenchMarkRepository benchMarkRepository;
  final Future<Directory> Function() temporaryDirectoryProvider;
  final BulkExportShare shareFiles;

  BulkExportService({
    required this.adSettingsRepository,
    required this.proSettingsRepository,
    required this.measurementRepository,
    required this.benchMarkRepository,
    Future<Directory> Function()? temporaryDirectoryProvider,
    BulkExportShare? shareFiles,
  }) : temporaryDirectoryProvider =
           temporaryDirectoryProvider ?? getTemporaryDirectory,
       shareFiles = shareFiles ?? Share.shareXFiles;

  Future<bool> get isProEnabled => adSettingsRepository.areAdsRemoved();

  Future<int> shareFieldBooks({
    required List<FieldBook> fieldBooks,
    required BulkExportFormat format,
    String projectName = '',
    bool includeManifest = false,
    bool includeSummary = false,
    required AppLocalizations l10n,
  }) async {
    if (!await isProEnabled) {
      throw StateError(l10n.exportBulkProRequired);
    }

    final settings = await proSettingsRepository.getPdfSettings();
    final dir = await temporaryDirectoryProvider();
    final files = <XFile>[];
    final namer = ExportFileNamer();

    for (final fieldBook in fieldBooks) {
      final measurements = MeasurementValidation.trimTrailingUnmeasured(
        await measurementRepository.getByFieldBookId(fieldBook.id!),
      );
      if (measurements.isEmpty) continue;

      final bmName = await _resolveBmName(fieldBook);
      final startElevation =
          fieldBook.startElevation ?? measurements.first.gh ?? 0;

      if (format == BulkExportFormat.pdf || format == BulkExportFormat.both) {
        final fileName = namer.next(
          fieldBook: fieldBook,
          extension: 'pdf',
          projectName: projectName,
          proSettings: settings,
        );
        final file = File('${dir.path}/$fileName');
        final bytes = await PdfExporter.generateFieldBookPdf(
          fieldBook: fieldBook,
          measurements: measurements,
          bmName: bmName,
          startElevation: startElevation,
          proSettings: settings,
          l10n: l10n,
        );
        await file.writeAsBytes(bytes);
        files.add(XFile(file.path));
      }

      if (format == BulkExportFormat.csv || format == BulkExportFormat.both) {
        final fileName = namer.next(
          fieldBook: fieldBook,
          extension: 'csv',
          projectName: projectName,
          proSettings: settings,
        );
        final file = File('${dir.path}/$fileName');
        final csv = CsvExporter.generateFieldBookCsv(
          fieldBook: fieldBook,
          measurements: measurements,
          bmName: bmName,
          startElevation: startElevation,
          proSettings: settings,
          l10n: l10n,
        );
        await file.writeAsString(CsvExporter.withBom(csv));
        files.add(XFile(file.path));
      }
    }

    if (includeSummary && fieldBooks.isNotEmpty) {
      final summaryInputs = <FieldBookSummaryInput>[];
      for (final fieldBook in fieldBooks) {
        final measurements = await measurementRepository.getByFieldBookId(
          fieldBook.id!,
        );
        if (measurements.isEmpty) continue;
        summaryInputs.add(
          FieldBookSummaryInput(
            fieldBook: fieldBook,
            bmName: await _resolveBmName(fieldBook),
            startElevation:
                fieldBook.startElevation ?? measurements.first.gh ?? 0,
            measurements: measurements,
          ),
        );
      }
      if (summaryInputs.isNotEmpty) {
        final summaryName = _uniqueFileName(
          '${_safeFileName(projectName)}_${l10n.exportSummaryFileSuffix}.csv',
          files.map((file) => file.name),
        );
        final file = File('${dir.path}/$summaryName');
        await file.writeAsString(
          CsvExporter.withBom(
            SubmissionSummaryReport.generateCsv(summaryInputs, l10n: l10n),
          ),
        );
        files.add(XFile(file.path));
      }
    }

    if (includeManifest && fieldBooks.isNotEmpty) {
      final measurementsByFieldBookId = <int, List<Measurement>>{};
      for (final fieldBook in fieldBooks) {
        measurementsByFieldBookId[fieldBook.id!] = await measurementRepository
            .getByFieldBookId(fieldBook.id!);
      }
      final manifest = ProjectSubmissionPackage.buildManifest(
        projectName: projectName,
        fieldBooks: fieldBooks,
        measurementsByFieldBookId: measurementsByFieldBookId,
        fileNames: files.map((file) => file.name).toList(),
        l10n: l10n,
      );
      final manifestName = _uniqueFileName(
        '${_safeFileName(projectName)}_manifest.txt',
        files.map((file) => file.name),
      );
      final file = File('${dir.path}/$manifestName');
      await file.writeAsString(manifest);
      files.add(XFile(file.path));
    }

    if (files.isEmpty) return 0;

    if (includeManifest || includeSummary) {
      final packageName = _safeFileName(
        projectName.trim().isEmpty ? 'lv_book_submission' : projectName,
      );
      final zipFile = File('${dir.path}/${packageName}_submission.zip');
      final packageFiles = <ProjectSubmissionPackageFile>[];
      for (final file in files) {
        packageFiles.add(
          ProjectSubmissionPackageFile(
            name: file.name,
            bytes: await File(file.path).readAsBytes(),
          ),
        );
      }
      final zipBytes = ProjectSubmissionPackage.buildZipBytesFromFiles(
        packageFiles,
      );
      await zipFile.writeAsBytes(zipBytes);
      files
        ..clear()
        ..add(XFile(zipFile.path));
    }

    await shareFiles(files);
    return files.length;
  }

  Future<String> _resolveBmName(FieldBook fieldBook) async {
    if (fieldBook.startBmId == null) return 'BM';
    final bm = await benchMarkRepository.getById(fieldBook.startBmId!);
    return bm?.name ?? 'BM';
  }

  String _safeFileName(String value) {
    final sanitized = value.trim().replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    return sanitized.isEmpty ? 'fieldbook' : sanitized;
  }

  String _uniqueFileName(String fileName, Iterable<String> existingNames) {
    final usedNames = existingNames.toSet();
    if (usedNames.add(fileName)) return fileName;

    final dot = fileName.lastIndexOf('.');
    final base = dot > 0 ? fileName.substring(0, dot) : fileName;
    final extension = dot > 0 ? fileName.substring(dot) : '';
    var index = 2;
    while (true) {
      final candidate = '$base-$index$extension';
      if (usedNames.add(candidate)) return candidate;
      index++;
    }
  }
}
