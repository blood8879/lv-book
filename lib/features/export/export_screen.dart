import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_snackbar.dart';
import '../fieldbook/domain/fieldbook.dart';
import '../fieldbook/domain/measurement.dart';
import 'pdf_template.dart';
import 'csv_exporter.dart';
import '../ads/ad_manager.dart';
import '../ads/ad_providers.dart';
import '../pro/pro_pdf_settings.dart';
import '../pro/pro_providers.dart';
import '../project/data/project_providers.dart';
import 'export_file_namer.dart';
import 'export_history_repository.dart';

class ExportScreen extends ConsumerStatefulWidget {
  final FieldBook fieldBook;
  final List<Measurement> measurements;
  final String bmName;
  final double startElevation;

  const ExportScreen({
    super.key,
    required this.fieldBook,
    required this.measurements,
    required this.bmName,
    required this.startElevation,
  });

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  InterstitialAd? _interstitialAd;
  ProPdfSettings? _proPdfSettings;
  String _projectName = '';

  @override
  void initState() {
    super.initState();
    _loadInterstitialAd();
    _loadProPdfSettings();
    _loadProjectName();
  }

  Future<void> _loadInterstitialAd() async {
    if (!AdManager.supportsMobileAds) return;
    final settings = ref.read(adSettingsRepositoryProvider);
    if (!await settings.canShowInterstitial()) return;

    InterstitialAd.load(
      adUnitId: AdManager.interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          _interstitialAd?.dispose();
          _interstitialAd = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) => ad.dispose(),
            onAdFailedToShowFullScreenContent: (ad, error) => ad.dispose(),
          );
        },
        onAdFailedToLoad: (error) {},
      ),
    );
  }

  Future<void> _loadProPdfSettings() async {
    // PDF/CSV 문서 설정은 무료 사용자에게도 적용됩니다. (무료는 내보내기 시
    // 광고가 노출되며, 이 광고가 수익 모델을 유지합니다.)
    final settings = await ref
        .read(proSettingsRepositoryProvider)
        .getPdfSettings();
    if (mounted) {
      setState(() => _proPdfSettings = settings);
    }
  }

  Future<void> _loadProjectName() async {
    final project = await ref
        .read(projectRepositoryProvider)
        .getById(widget.fieldBook.projectId);
    if (mounted) {
      setState(() => _projectName = project?.name ?? '');
    }
  }

  Future<void> _showInterstitialAd() async {
    final ad = _interstitialAd;
    if (ad == null) return;

    final settings = ref.read(adSettingsRepositoryProvider);
    if (!await settings.canShowInterstitial()) {
      await ad.dispose();
      _interstitialAd = null;
      return;
    }

    await settings.recordInterstitialShown();
    await ad.show();
    _interstitialAd = null;
  }

  @override
  void dispose() {
    _interstitialAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내보내기'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'PDF 공유',
            onPressed: () => _sharePdf(context),
          ),
          IconButton(
            icon: const Icon(Icons.table_chart),
            tooltip: 'CSV 공유',
            onPressed: () => _shareCsv(context),
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => PdfExporter.generateFieldBookPdf(
          fieldBook: widget.fieldBook,
          measurements: widget.measurements,
          bmName: widget.bmName,
          startElevation: widget.startElevation,
          proSettings: _proPdfSettings,
        ),
        scrollViewDecoration: BoxDecoration(color: context.appColors.soft),
        canChangeOrientation: false,
        canChangePageFormat: false,
        // 공유/인쇄는 AppBar의 공유 흐름(내보내기 이력·광고)으로만 제공합니다.
        allowPrinting: false,
        allowSharing: false,
      ),
    );
  }

  Future<void> _sharePdf(BuildContext context) async {
    try {
      final pdfBytes = await PdfExporter.generateFieldBookPdf(
        fieldBook: widget.fieldBook,
        measurements: widget.measurements,
        bmName: widget.bmName,
        startElevation: widget.startElevation,
        proSettings: _proPdfSettings,
      );
      final dir = await getTemporaryDirectory();
      final fileName = ExportFileNamer().next(
        fieldBook: widget.fieldBook,
        extension: 'pdf',
        projectName: _projectName,
        proSettings: _proPdfSettings,
      );
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(pdfBytes);
      await Share.shareXFiles([XFile(file.path)]);
      await ExportHistoryRepository().record(
        ExportHistoryRecord(
          fileName: file.path.split('/').last,
          fieldBookTitle: widget.fieldBook.title,
          format: 'pdf',
          exportedAt: DateTime.now(),
        ),
      );
      await _showInterstitialAd();
    } catch (e) {
      if (context.mounted) {
        AppSnackbar.error(context, 'PDF 생성 실패: $e');
      }
    }
  }

  Future<void> _shareCsv(BuildContext context) async {
    try {
      final csvString = CsvExporter.generateFieldBookCsv(
        fieldBook: widget.fieldBook,
        measurements: widget.measurements,
        bmName: widget.bmName,
        startElevation: widget.startElevation,
        proSettings: _proPdfSettings,
      );
      final dir = await getTemporaryDirectory();
      final fileName = ExportFileNamer().next(
        fieldBook: widget.fieldBook,
        extension: 'csv',
        projectName: _projectName,
        proSettings: _proPdfSettings,
      );
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(CsvExporter.withBom(csvString));
      await Share.shareXFiles([XFile(file.path)]);
      await ExportHistoryRepository().record(
        ExportHistoryRecord(
          fileName: file.path.split('/').last,
          fieldBookTitle: widget.fieldBook.title,
          format: 'csv',
          exportedAt: DateTime.now(),
        ),
      );
      await _showInterstitialAd();
    } catch (e) {
      if (context.mounted) {
        AppSnackbar.error(context, 'CSV 생성 실패: $e');
      }
    }
  }
}
