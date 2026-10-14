import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/semantic_pill.dart';
import '../../../l10n/l10n.dart';
import '../../pro/pro_pdf_settings.dart';
import '../../pro/pro_providers.dart';
import '../data/peg_test_record_repository.dart';
import '../domain/peg_test_record.dart';
import 'peg_test_record_pdf.dart';
import 'peg_test_screen.dart';

/// Shares a generated peg test PDF ([fileName] in the temp directory) with
/// the same share sheet as the field book export. No interstitial here.
typedef PegTestPdfShare =
    Future<void> Function({required String fileName, required Uint8List bytes});

final pegTestPdfShareProvider = Provider<PegTestPdfShare>((ref) {
  return ({required String fileName, required Uint8List bytes}) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)]);
  };
});

final _dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm');

/// Saved two-peg tests, newest first.
class PegTestHistoryScreen extends ConsumerWidget {
  const PegTestHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final recordsAsync = ref.watch(pegTestRecordListProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.pegTestHistoryTitle)),
      body: recordsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text(l10n.coreErrorWithDetail('$error'))),
        data: (records) {
          if (records.isEmpty) {
            return EmptyState(
              icon: Icons.straighten,
              title: l10n.pegTestHistoryEmptyTitle,
              message: l10n.pegTestHistoryEmptyMessage,
            );
          }
          return ListView.separated(
            padding: EdgeInsets.fromLTRB(
              12,
              12,
              12,
              AppConstants.quickMemoFabListBottomPadding(context),
            ),
            itemCount: records.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) =>
                _RecordTile(record: records[index]),
          );
        },
      ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  final PegTestRecord record;

  const _RecordTile({required this.record});

  void _open(BuildContext context) {
    Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => PegTestRecordScreen(record: record)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final test = record.test;
    final details = [
      record.instrument ?? l10n.pegTestNoInstrument,
      if (record.observer != null) record.observer!,
    ].join(' · ');
    return Material(
      color: colors.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('peg-test-record-${record.id}'),
        onTap: () => _open(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _dateTimeFormat.format(record.createdAt),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: colors.ink,
                        fontFeatures: AppTypography.tabularFeatures,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      details,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: colors.subtext),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatPegTestError(test.error, record.unit),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colors.ink,
                      fontFeatures: AppTypography.tabularFeatures,
                    ),
                  ),
                  const SizedBox(height: 4),
                  SemanticPill(
                    label: pegTestVerdict(l10n, test),
                    variant: test.withinTolerance
                        ? SemanticPillVariant.green
                        : SemanticPillVariant.orange,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Read-only saved peg test: details, readings and the result card, with
/// share as PDF and delete. Pops `true` after a delete.
class PegTestRecordScreen extends ConsumerStatefulWidget {
  final PegTestRecord record;

  const PegTestRecordScreen({super.key, required this.record});

  @override
  ConsumerState<PegTestRecordScreen> createState() =>
      _PegTestRecordScreenState();
}

class _PegTestRecordScreenState extends ConsumerState<PegTestRecordScreen> {
  bool _sharing = false;

  PegTestRecord get _record => widget.record;

  Future<void> _sharePdf() async {
    if (_sharing) return;
    final l10n = context.l10n;
    setState(() => _sharing = true);
    try {
      ProPdfSettings? settings;
      try {
        settings = await ref.read(proPdfSettingsProvider.future);
      } catch (_) {
        settings = null; // Plain document without branding.
      }
      final bytes = await PegTestRecordPdf.generate(
        record: _record,
        l10n: l10n,
        proSettings: settings,
      );
      final stamp = DateFormat('yyyyMMdd_HHmm').format(_record.createdAt);
      await ref.read(pegTestPdfShareProvider)(
        fileName: 'two_peg_test_$stamp.pdf',
        bytes: bytes,
      );
    } catch (error) {
      if (mounted) AppSnackbar.error(context, l10n.pegTestPdfError('$error'));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _delete() async {
    final l10n = context.l10n;
    final colors = context.appColors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.pegTestDeleteTitle),
        content: Text(l10n.pegTestDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.coreCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: colors.err),
            child: Text(l10n.coreDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(pegTestRecordListProvider.notifier).delete(_record);
      if (!mounted) return;
      // The app-wide messenger keeps the snackbar on the list after the pop.
      AppSnackbar.success(context, l10n.pegTestDeleted);
      Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        AppSnackbar.error(context, l10n.coreErrorWithDetail('$error'));
      }
    }
  }

  Future<void> _copy() async {
    final l10n = context.l10n;
    await Clipboard.setData(
      ClipboardData(
        text: buildPegTestSummary(l10n, _record.test, _record.createdAt),
      ),
    );
    if (mounted) AppSnackbar.success(context, l10n.pegTestCopied);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final record = _record;
    final unit = record.unit;
    String reading(double value) => formatPegTestReading(value, unit);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.pegTestRecordTitle),
        actions: [
          IconButton(
            icon: _sharing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf),
            tooltip: l10n.pegTestSharePdfTooltip,
            onPressed: _sharing ? null : _sharePdf,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: l10n.coreDelete,
            onPressed: _delete,
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          12,
          12,
          12,
          AppConstants.quickMemoFabListBottomPadding(context),
        ),
        children: [
          _Panel(
            children: [
              _InfoRow(
                label: l10n.exportFieldDate,
                value: _dateTimeFormat.format(record.createdAt),
              ),
              _InfoRow(
                label: l10n.pegTestInstrumentLabel,
                value: record.instrument ?? '-',
              ),
              _InfoRow(
                label: l10n.pegTestObserverLabel,
                value: record.observer ?? '-',
              ),
              if (record.note != null)
                _InfoRow(label: l10n.pegTestNoteLabel, value: record.note!),
            ],
          ),
          const SizedBox(height: 12),
          _Panel(
            title: l10n.pegTestReadingsTitle,
            children: [
              Text(
                l10n.pegTestSetup1Title,
                style: TextStyle(fontSize: 12.5, color: colors.subtext),
              ),
              _InfoRow(
                label: l10n.pegTestReadingALabel(unit.symbol),
                value: reading(record.a1),
              ),
              _InfoRow(
                label: l10n.pegTestReadingBLabel(unit.symbol),
                value: reading(record.b1),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.pegTestSetup2Title,
                style: TextStyle(fontSize: 12.5, color: colors.subtext),
              ),
              _InfoRow(
                label: l10n.pegTestReadingALabel(unit.symbol),
                value: reading(record.a2),
              ),
              _InfoRow(
                label: l10n.pegTestReadingBLabel(unit.symbol),
                value: reading(record.b2),
              ),
              const SizedBox(height: 6),
              _InfoRow(
                label: l10n.pegTestDistanceLabel(unit.symbol),
                value: record.pegDistance.toStringAsFixed(3),
              ),
            ],
          ),
          const SizedBox(height: 12),
          PegTestResultCard(test: record.test, unit: unit, onCopy: _copy),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final String? title;
  final List<Widget> children;

  const _Panel({this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Text(title!, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
          ],
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label, style: TextStyle(color: colors.body)),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: colors.ink,
                fontFeatures: AppTypography.tabularFeatures,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
