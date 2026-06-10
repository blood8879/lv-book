import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../data/fieldbook_providers.dart';
import '../domain/fieldbook.dart';
import '../domain/fieldbook_quick_start.dart';
import '../domain/fieldbook_search.dart';
import '../domain/fieldbook_templates.dart';
import '../../benchmark/data/benchmark_providers.dart';
import '../../benchmark/domain/benchmark.dart';
import '../../benchmark/domain/benchmark_recheck.dart';
import '../../backup/project_backup_providers.dart';
import '../../backup/project_backup_service.dart';
import '../../export/bulk_export_screen.dart';
import '../../import/csv_importer.dart';
import '../../project/data/project_providers.dart';
import 'fieldbook_edit_screen.dart';

class FieldBookListScreen extends ConsumerWidget {
  final int projectId;

  const FieldBookListScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fieldBooksAsync = ref.watch(fieldBookListProvider(projectId));

    return Scaffold(
      body: fieldBooksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (fieldBooks) => _FieldBookListContent(
          projectId: projectId,
          fieldBooks: fieldBooks,
          onDuplicate: (fieldBook) =>
              _duplicateFieldBook(context, ref, fieldBook),
          onDelete: (fieldBook) => _confirmDelete(context, ref, fieldBook),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showActionSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('야장'),
      ),
    );
  }

  void _showActionSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.note_add_outlined),
              title: const Text('새 야장'),
              onTap: () {
                Navigator.pop(sheetContext);
                _showCreateDialog(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload_file_outlined),
              title: const Text('CSV 가져오기'),
              onTap: () {
                Navigator.pop(sheetContext);
                _showCsvImportDialog(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.backup_outlined),
              title: const Text('프로젝트 백업 공유'),
              onTap: () {
                Navigator.pop(sheetContext);
                _shareProjectBackup(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.restore_page_outlined),
              title: const Text('백업 JSON 복원'),
              onTap: () {
                Navigator.pop(sheetContext);
                _showBackupRestoreDialog(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareProjectBackup(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final service = ref.read(projectBackupServiceProvider);
      final data = await service.collectProject(projectId);
      final source = ProjectBackupService.encode(data);
      final safeName = data.project.name.trim().replaceAll(
        RegExp(r'[\\/:*?"<>|]'),
        '_',
      );
      await ref.read(projectBackupShareProvider)(
        fileName: '${safeName}_lvbook_backup.json',
        source: source,
      );
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('백업 공유 실패: $error')));
    }
  }

  Future<void> _showBackupRestoreDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final controller = TextEditingController();
    try {
      final source = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('백업 JSON 복원'),
          content: TextField(
            controller: controller,
            minLines: 6,
            maxLines: 10,
            decoration: const InputDecoration(
              hintText: '공유받은 lvbook_backup.json 내용을 붙여넣으세요.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('복원'),
            ),
          ],
        ),
      );
      if (source == null || source.trim().isEmpty) return;

      await ref.read(projectBackupServiceProvider).restoreAsNewProject(source);
      ref.invalidate(fieldBookListProvider(projectId));
      ref.invalidate(projectListProvider);
      if (context.mounted) {
        final messenger = ScaffoldMessenger.of(context)..clearSnackBars();
        messenger.showSnackBar(
          const SnackBar(content: Text('백업을 새 프로젝트로 복원했습니다.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        final messenger = ScaffoldMessenger.of(context)..clearSnackBars();
        messenger.showSnackBar(SnackBar(content: Text('백업 복원 실패: $error')));
      }
    }
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final elevationController = TextEditingController();
    final bmNameController = TextEditingController();
    final surveyorController = TextEditingController();
    final checkerController = TextEditingController();
    final instrumentController = TextEditingController();
    final weatherController = TextEditingController();
    final workSectionController = TextEditingController();
    final jobNumberController = TextEditingController();
    final benchmarksAsync = ref.read(benchmarkListProvider(projectId));
    final allBenchmarks = benchmarksAsync.valueOrNull ?? [];
    final benchmarks = BenchMarkRecheck.selectableForFieldBook(allBenchmarks);
    final existingFieldBooks =
        ref.read(fieldBookListProvider(projectId)).valueOrNull ?? const [];
    final quickStart = FieldBookQuickStart.suggest(
      fieldBooks: existingFieldBooks,
      benchmarks: benchmarks,
    );
    surveyorController.text = quickStart.surveyor ?? '';
    checkerController.text = quickStart.checker ?? '';
    instrumentController.text = quickStart.instrument ?? '';
    weatherController.text = quickStart.weather ?? '';
    workSectionController.text = quickStart.workSection ?? '';
    jobNumberController.text = quickStart.jobNumber ?? '';
    BenchMark? selectedBm =
        quickStart.startBm ?? (benchmarks.isNotEmpty ? benchmarks.first : null);
    bool useCustomBm = benchmarks.isEmpty; // default to custom if no BMs exist
    if (quickStart.startBm != null) useCustomBm = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('새 야장'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: '야장 제목 *'),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                // Toggle between BM selection and custom input
                if (benchmarks.isNotEmpty)
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('BM 선택'),
                          selected: !useCustomBm,
                          onSelected: (_) =>
                              setState(() => useCustomBm = false),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('직접 입력'),
                          selected: useCustomBm,
                          onSelected: (_) => setState(() => useCustomBm = true),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                if (!useCustomBm && benchmarks.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<BenchMark>(
                        initialValue: selectedBm,
                        decoration: const InputDecoration(labelText: '시작 BM'),
                        items: benchmarks.map((bm) {
                          return DropdownMenuItem(
                            value: bm,
                            child: Text(
                              '${bm.name} (${bm.elevation.toStringAsFixed(3)}m)',
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => selectedBm = value);
                        },
                      ),
                      if (selectedBm != null &&
                          BenchMarkRecheck.warningFor(
                                selectedBm!,
                                now: DateTime.now(),
                              ) !=
                              null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            BenchMarkRecheck.warningFor(
                              selectedBm!,
                              now: DateTime.now(),
                            )!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  )
                else ...[
                  TextField(
                    controller: bmNameController,
                    decoration: const InputDecoration(
                      labelText: 'BM 이름 (선택)',
                      hintText: '예: BM.1',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: elevationController,
                    decoration: const InputDecoration(
                      labelText: '시작 표고 (m) *',
                      hintText: '예: 100.000',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: const Text('현장 메타데이터'),
                  children: [
                    TextField(
                      controller: surveyorController,
                      decoration: const InputDecoration(labelText: '측량자'),
                    ),
                    TextField(
                      controller: checkerController,
                      decoration: const InputDecoration(labelText: '검측자'),
                    ),
                    TextField(
                      controller: instrumentController,
                      decoration: const InputDecoration(labelText: '장비'),
                    ),
                    TextField(
                      controller: weatherController,
                      decoration: const InputDecoration(labelText: '날씨'),
                    ),
                    TextField(
                      controller: workSectionController,
                      decoration: const InputDecoration(labelText: '작업구간'),
                    ),
                    TextField(
                      controller: jobNumberController,
                      decoration: const InputDecoration(labelText: '공사번호'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () async {
                final title = titleController.text.trim();
                if (title.isEmpty) return;

                double? elevation;
                int? bmId;

                if (!useCustomBm && selectedBm != null) {
                  bmId = selectedBm!.id;
                  elevation = selectedBm!.elevation;
                } else {
                  elevation = double.tryParse(elevationController.text.trim());
                  if (elevation == null) return;
                }

                final fb = FieldBook(
                  projectId: projectId,
                  title: title,
                  date: DateTime.now(),
                  startBmId: bmId,
                  startElevation: elevation,
                  surveyor: _blankToNull(surveyorController.text),
                  checker: _blankToNull(checkerController.text),
                  instrument: _blankToNull(instrumentController.text),
                  weather: _blankToNull(weatherController.text),
                  workSection: _blankToNull(workSectionController.text),
                  jobNumber: _blankToNull(jobNumberController.text),
                );
                final id = await ref
                    .read(fieldBookListProvider(projectId).notifier)
                    .addFieldBook(fb);
                if (context.mounted) {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FieldBookEditScreen(
                        fieldBook: fb.copyWith(id: id),
                        projectId: projectId,
                      ),
                    ),
                  );
                }
              },
              child: const Text('생성'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _duplicateFieldBook(
    BuildContext context,
    WidgetRef ref,
    FieldBook source,
  ) async {
    final measurements = await ref
        .read(measurementRepositoryProvider)
        .getByFieldBookId(source.id!);
    final duplicate = FieldBookTemplates.duplicateStructure(
      source: source,
      measurements: measurements,
      newDate: DateTime.now(),
    );
    final newId = await ref
        .read(fieldBookListProvider(projectId).notifier)
        .addFieldBook(duplicate.fieldBook);
    for (final row in duplicate.measurements) {
      await ref
          .read(measurementRepositoryProvider)
          .create(row.copyWith(fieldBookId: newId));
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('야장 구조를 복제했습니다')));
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, FieldBook fb) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('야장 삭제'),
        content: Text('"${fb.title}" 야장을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              ref
                  .read(fieldBookListProvider(projectId).notifier)
                  .deleteFieldBook(fb.id!);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  void _showCsvImportDialog(BuildContext context, WidgetRef ref) {
    final csvController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('CSV 가져오기'),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: csvController,
            maxLines: 10,
            decoration: const InputDecoration(
              hintText: 'Lv Book에서 내보낸 CSV 내용을 붙여넣으세요.',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () async {
              final result = CsvImporter.parse(
                csvController.text,
                projectId: projectId,
                fallbackDate: DateTime.now(),
              );
              if (result.fieldBook == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(result.errors.join('\n'))),
                );
                return;
              }
              final id = await ref
                  .read(fieldBookListProvider(projectId).notifier)
                  .addFieldBook(result.fieldBook!);
              for (final row in result.measurements) {
                await ref
                    .read(measurementRepositoryProvider)
                    .create(row.copyWith(fieldBookId: id));
              }
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('CSV를 가져왔습니다')));
            },
            child: const Text('가져오기'),
          ),
        ],
      ),
    );
  }

  String? _blankToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class _FieldBookListContent extends StatefulWidget {
  final int projectId;
  final List<FieldBook> fieldBooks;
  final ValueChanged<FieldBook> onDuplicate;
  final ValueChanged<FieldBook> onDelete;

  const _FieldBookListContent({
    required this.projectId,
    required this.fieldBooks,
    required this.onDuplicate,
    required this.onDelete,
  });

  @override
  State<_FieldBookListContent> createState() => _FieldBookListContentState();
}

class _FieldBookListContentState extends State<_FieldBookListContent> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    if (widget.fieldBooks.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            '야장이 없습니다.\n+ 버튼으로 새 야장 생성 또는 CSV 가져오기를 시작하세요.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    final filtered = FieldBookSearch.filter(widget.fieldBooks, query: _query);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: '야장 검색',
              hintText: '제목, 작업구간, 측량자, 날짜',
            ),
            onChanged: (value) => setState(() => _query = value),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BulkExportScreen(
                      projectId: widget.projectId,
                      fieldBooks: widget.fieldBooks,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.folder_copy_outlined),
              label: const Text('일괄 내보내기'),
            ),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('검색 결과가 없습니다'))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 96),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final fb = filtered[index];
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        leading: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppTheme.datumBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.description_outlined,
                            color: AppTheme.datumBlue,
                          ),
                        ),
                        title: Text(
                          fb.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            [
                              DateFormat('yyyy-MM-dd').format(fb.date),
                              if (fb.workSection?.trim().isNotEmpty == true)
                                fb.workSection!.trim(),
                              if (fb.surveyor?.trim().isNotEmpty == true)
                                '측량자 ${fb.surveyor!.trim()}',
                            ].join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'duplicate') {
                              widget.onDuplicate(fb);
                            } else if (value == 'delete') {
                              widget.onDelete(fb);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'duplicate',
                              child: Text('구조 복제'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('삭제'),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FieldBookEditScreen(
                                fieldBook: fb,
                                projectId: widget.projectId,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
