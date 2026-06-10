import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../ads/ad_providers.dart';
import '../benchmark/data/benchmark_repository.dart';
import '../fieldbook/data/fieldbook_providers.dart';
import '../fieldbook/domain/fieldbook.dart';
import '../pro/pro_providers.dart';
import '../project/data/project_providers.dart';
import 'bulk_export_service.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('일괄 내보내기'),
        actions: [
          TextButton(
            onPressed: _selectedIds.isEmpty ? null : _toggleAll,
            child: Text(
              _selectedIds.length == widget.fieldBooks.length ? '해제' : '전체',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!isPro) _buildLockedBanner(),
          _buildFormatSelector(),
          _buildPackageOptions(isPro),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
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
                  label: Text('${_selectedIds.length}개 야장 공유'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedBanner() {
    return Material(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: ListTile(
        leading: Icon(
          Icons.lock_outline,
          color: Theme.of(context).colorScheme.onSecondaryContainer,
        ),
        title: const Text('Pro 전용 기능'),
        subtitle: const Text('여러 야장을 한 번에 PDF/CSV로 공유할 수 있습니다.'),
      ),
    );
  }

  Widget _buildFormatSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: SegmentedButton<BulkExportFormat>(
        segments: const [
          ButtonSegment(
            value: BulkExportFormat.pdf,
            icon: Icon(Icons.picture_as_pdf),
            label: Text('PDF'),
          ),
          ButtonSegment(
            value: BulkExportFormat.csv,
            icon: Icon(Icons.table_chart),
            label: Text('CSV'),
          ),
          ButtonSegment(
            value: BulkExportFormat.both,
            icon: Icon(Icons.folder_copy_outlined),
            label: Text('둘 다'),
          ),
        ],
        selected: {_format},
        onSelectionChanged: (values) => setState(() => _format = values.first),
      ),
    );
  }

  Widget _buildPackageOptions(bool isPro) {
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
            title: const Text('제출 패키지 manifest 포함'),
            subtitle: const Text('선택한 야장, 생성 파일, 측점 수를 함께 정리합니다.'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          CheckboxListTile(
            value: _includeSummary,
            onChanged: isPro
                ? (value) => setState(() {
                    _includeSummary = value ?? false;
                  })
                : null,
            title: const Text('검측/제출 요약 CSV 포함'),
            subtitle: const Text('야장별 BM, 작업구간, 오차, 판정을 한 파일로 묶습니다.'),
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
    final messenger = ScaffoldMessenger.of(context);
    final selected = widget.fieldBooks
        .where((fieldBook) => _selectedIds.contains(fieldBook.id))
        .toList();

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
      );

      if (!mounted) return;
      if (fileCount == 0) {
        messenger.showSnackBar(
          const SnackBar(content: Text('내보낼 데이터가 있는 야장이 없습니다')),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text('$fileCount개 파일을 공유했습니다')),
        );
      }
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('일괄 내보내기 실패: $error')));
    } finally {
      if (mounted) {
        setState(() => _sharing = false);
      }
    }
  }
}
