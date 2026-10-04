import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../l10n/l10n.dart';
import '../ads/ad_providers.dart';
import '../benchmark/data/benchmark_repository.dart';
import '../fieldbook/data/fieldbook_providers.dart';
import '../fieldbook/domain/fieldbook.dart';
import '../pro/pro_providers.dart';
import '../project/data/project_providers.dart';
import 'bulk_export_service.dart';
import '../../core/constants/app_constants.dart';

class BulkExportScreen extends ConsumerStatefulWidget {
  final int projectId;
  final List<FieldBook> fieldBooks;

  const BulkExportScreen({
    super.key,
    required this.projectId,
    required this.fieldBooks,
  });

  @override
  ConsumerState<BulkExportScreen> createState() => _BulkExportScreenState();
}

class _BulkExportScreenState extends ConsumerState<BulkExportScreen> {
  final Set<int> _selectedIds = {};
  BulkExportFormat _format = BulkExportFormat.pdf;
  bool _includePackageManifest = false;
  bool _includeSummary = false;
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    for (final fieldBook in widget.fieldBooks) {
      if (fieldBook.id != null) {
        _selectedIds.add(fieldBook.id!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPro = ref.watch(adsRemovedProvider).valueOrNull == true;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.exportBulkTitle),
        actions: [
          TextButton(
            onPressed: widget.fieldBooks.isEmpty ? null : _toggleAll,
            child: Text(
              _selectedIds.length == widget.fieldBooks.length
                  ? l10n.exportBulkDeselectAll
                  : l10n.exportBulkSelectAll,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!isPro) _buildLockedBanner(),
          Expanded(
            child: Opacity(
              opacity: isPro ? 1.0 : 0.5,
              child: Column(
                children: [
                  _buildFormatSelector(),
                  _buildPackageOptions(isPro),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        8,
                        8,
                        8,
                        AppConstants.quickMemoFabClearance,
                      ),
                      itemCount: widget.fieldBooks.length,
                      itemBuilder: (context, index) {
                        final fieldBook = widget.fieldBooks[index];
                        final id = fieldBook.id!;
                        final selected = _selectedIds.contains(id);

                        return CheckboxListTile(
                          value: selected,
                          onChanged: (_) => _toggle(id),
                          title: Text(fieldBook.title),
                          subtitle: Text(
                            DateFormat('yyyy-MM-dd').format(fieldBook.date),
                          ),
                          secondary: const Icon(Icons.description_outlined),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: isPro && !_sharing && _selectedIds.isNotEmpty
                      ? _share
                      : null,
                  icon: _sharing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.ios_share),
                  label: Text(l10n.exportBulkShareButton(_selectedIds.length)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedBanner() {
    final colors = context.appColors;
    final l10n = context.l10n;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.darkSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.darkSurface2,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.lock_outline, color: colors.amber),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.exportBulkProOnlyTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.exportBulkProOnlyBody,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: SegmentedButton<BulkExportFormat>(
        segments: [
          const ButtonSegment(
            value: BulkExportFormat.pdf,
            icon: Icon(Icons.picture_as_pdf),
            label: Text('PDF'),
          ),
          const ButtonSegment(
            value: BulkExportFormat.csv,
            icon: Icon(Icons.table_chart),
            label: Text('CSV'),
          ),
          ButtonSegment(
            value: BulkExportFormat.both,
            icon: const Icon(Icons.folder_copy_outlined),
            label: Text(context.l10n.exportBulkFormatBoth),
          ),
        ],
        selected: {_format},
        onSelectionChanged: (values) => setState(() => _format = values.first),
      ),
    );
  }

  Widget _buildPackageOptions(bool isPro) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          CheckboxListTile(
            value: _includePackageManifest,
            onChanged: isPro
                ? (value) => setState(() {
                    _includePackageManifest = value ?? false;
                  })
                : null,
            title: Text(l10n.exportBulkManifestTitle),
            subtitle: Text(l10n.exportBulkManifestSubtitle),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          CheckboxListTile(
            value: _includeSummary,
            onChanged: isPro
                ? (value) => setState(() {
                    _includeSummary = value ?? false;
                  })
                : null,
            title: Text(l10n.exportBulkSummaryTitle),
            subtitle: Text(l10n.exportBulkSummarySubtitle),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
    );
  }

  void _toggle(int fieldBookId) {
    setState(() {
      if (!_selectedIds.add(fieldBookId)) {
        _selectedIds.remove(fieldBookId);
      }
    });
  }

  void _toggleAll() {
    setState(() {
      if (_selectedIds.length == widget.fieldBooks.length) {
        _selectedIds.clear();
      } else {
        _selectedIds
          ..clear()
          ..addAll(widget.fieldBooks.map((fieldBook) => fieldBook.id!));
      }
    });
  }

  Future<void> _share() async {
    final selected = widget.fieldBooks
        .where((fieldBook) => _selectedIds.contains(fieldBook.id))
        .toList();
    final l10n = context.l10n;

    setState(() => _sharing = true);
    try {
      final project = await ref
          .read(projectRepositoryProvider)
          .getById(widget.projectId);
      final service = BulkExportService(
        adSettingsRepository: ref.read(adSettingsRepositoryProvider),
        proSettingsRepository: ref.read(proSettingsRepositoryProvider),
        measurementRepository: ref.read(measurementRepositoryProvider),
        benchMarkRepository: BenchMarkRepository(),
      );
      final fileCount = await service.shareFieldBooks(
        fieldBooks: selected,
        format: _format,
        projectName: project?.name ?? '',
        includeManifest: _includePackageManifest,
        includeSummary: _includeSummary,
        l10n: l10n,
      );

      if (!mounted) return;
      if (fileCount == 0) {
        AppSnackbar.error(context, l10n.exportBulkNothingToExport);
      } else {
        AppSnackbar.success(context, l10n.exportBulkShared(fileCount));
      }
    } catch (error) {
      if (!mounted) return;
      AppSnackbar.error(
        context,
        l10n.exportBulkError(
          error is StateError ? error.message : error.toString(),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _sharing = false);
      }
    }
  }
}
