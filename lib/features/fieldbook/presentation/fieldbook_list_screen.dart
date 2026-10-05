import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/text_file_picker.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../shared/widgets/native_ad_card.dart';
import '../data/fieldbook_providers.dart';
import '../domain/fieldbook.dart';
import '../domain/fieldbook_quick_start.dart';
import '../domain/fieldbook_search.dart';
import '../domain/fieldbook_templates.dart';
import '../domain/measurement.dart';
import '../../benchmark/data/benchmark_providers.dart';
import '../../benchmark/domain/benchmark.dart';
import '../../benchmark/domain/benchmark_recheck.dart';
import '../../backup/project_backup_providers.dart';
import '../../backup/project_backup_service.dart';
import '../../export/bulk_export_screen.dart';
import '../../import/csv_importer.dart';
import '../../project/data/project_providers.dart';
import 'fieldbook_edit_screen.dart';
import 'reduction_method_selector.dart';
import '../../settings/misclosure_tolerance_repository.dart';
import '../../../core/constants/app_constants.dart';
import '../../../l10n/l10n.dart';

class FieldBookListScreen extends ConsumerWidget {
  final int projectId;

  const FieldBookListScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fieldBooksAsync = ref.watch(fieldBookListProvider(projectId));

    return Scaffold(
      body: fieldBooksAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.only(top: 8),
          child: ListSkeleton(),
        ),
        error: (e, _) =>
            Center(child: Text(context.l10n.coreErrorWithDetail('$e'))),
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
        label: Text(context.l10n.fieldbookFabLabel),
      ),
    );
  }

  void _showActionSheet(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.note_add_outlined),
              title: Text(l10n.fieldbookNewTitle),
              onTap: () {
                Navigator.pop(sheetContext);
                _showCreateDialog(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload_file_outlined),
              title: Text(l10n.fieldbookImportCsv),
              onTap: () {
                Navigator.pop(sheetContext);
                _showCsvImportDialog(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.backup_outlined),
              title: Text(l10n.fieldbookShareBackup),
              onTap: () {
                Navigator.pop(sheetContext);
                _shareProjectBackup(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.restore_page_outlined),
              title: Text(l10n.fieldbookRestoreBackupJson),
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
    final l10n = context.l10n;
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
      if (context.mounted) {
        AppSnackbar.error(
          context,
          l10n.fieldbookShareBackupError(_backupErrorDetail(l10n, error)),
        );
      }
    }
  }

  Future<void> _showBackupRestoreDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final controller = TextEditingController();
    final l10n = context.l10n;
    try {
      final source = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.fieldbookRestoreBackupJson),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  try {
                    final content = await TextFilePicker.pick(
                      extensions: const ['json'],
                    );
                    if (content != null) controller.text = content;
                  } on TextFileEncodingException catch (error) {
                    if (context.mounted) {
                      AppSnackbar.error(context, error.localizedMessage(l10n));
                    }
                  }
                },
                icon: const Icon(Icons.folder_open_outlined, size: 18),
                label: Text(l10n.fieldbookChooseBackupFile),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                minLines: 6,
                maxLines: 10,
                decoration: InputDecoration(
                  hintText: l10n.fieldbookBackupPasteHint,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.coreCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: Text(l10n.fieldbookRestoreButton),
            ),
          ],
        ),
      );
      if (source == null || source.trim().isEmpty) return;

      await ref.read(projectBackupServiceProvider).restoreAsNewProject(source);
      ref.invalidate(fieldBookListProvider(projectId));
      ref.invalidate(projectListProvider);
      if (context.mounted) {
        AppSnackbar.success(context, l10n.fieldbookBackupRestoredMessage);
      }
    } catch (error) {
      if (context.mounted) {
        AppSnackbar.error(
          context,
          l10n.fieldbookRestoreBackupError(_backupErrorDetail(l10n, error)),
        );
      }
    }
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
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
    var reductionMethod = quickStart.reductionMethod;
    final unit = ref.read(lengthUnitProvider).symbol;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final colors = sheetContext.appColors;
        return Padding(
          // Keyboard height when it is up, otherwise the navigation-bar
          // inset (padding drops to 0 while the keyboard covers it).
          padding: EdgeInsets.only(
            bottom:
                MediaQuery.viewInsetsOf(sheetContext).bottom +
                MediaQuery.paddingOf(sheetContext).bottom,
          ),
          child: StatefulBuilder(
            builder: (sheetContext, setState) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l10n.fieldbookNewTitle,
                      style: Theme.of(sheetContext).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: l10n.fieldbookTitleLabel,
                      hintText: l10n.fieldbookTitleHint,
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 12),
                  // Toggle between BM selection and custom input
                  if (benchmarks.isNotEmpty)
                    SegmentedButton<bool>(
                      segments: [
                        ButtonSegment(
                          value: false,
                          label: Text(l10n.fieldbookSelectBm),
                        ),
                        ButtonSegment(
                          value: true,
                          label: Text(l10n.fieldbookEnterManually),
                        ),
                      ],
                      selected: {useCustomBm},
                      showSelectedIcon: false,
                      onSelectionChanged: (selection) =>
                          setState(() => useCustomBm = selection.first),
                    ),
                  const SizedBox(height: 12),
                  if (!useCustomBm && benchmarks.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<BenchMark>(
                          initialValue: selectedBm,
                          decoration: InputDecoration(
                            labelText: l10n.fieldbookStartBmLabel,
                          ),
                          items: benchmarks.map((bm) {
                            return DropdownMenuItem(
                              value: bm,
                              child: Text(
                                '${bm.name} (${bm.elevation.toStringAsFixed(3)}$unit)',
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
                                l10n: l10n,
                              )!,
                              style: TextStyle(
                                color: colors.err,
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
                      decoration: InputDecoration(
                        labelText: l10n.fieldbookBmNameLabel,
                        hintText: l10n.fieldbookBmNameHint,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: elevationController,
                      decoration: InputDecoration(
                        labelText: l10n.fieldbookStartElevationLabel(unit),
                        hintText: l10n.fieldbookStartElevationHint,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  ReductionMethodSelector(
                    value: reductionMethod,
                    onChanged: (value) =>
                        setState(() => reductionMethod = value),
                  ),
                  const SizedBox(height: 4),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(l10n.fieldbookSiteDetailsTitle),
                    trailing: Text(
                      l10n.fieldbookSiteDetailsSummary,
                      style: TextStyle(fontSize: 12.5, color: colors.subtext),
                    ),
                    children: [
                      TextField(
                        controller: surveyorController,
                        decoration: InputDecoration(
                          labelText: l10n.fieldbookSurveyorLabel,
                        ),
                      ),
                      TextField(
                        controller: checkerController,
                        decoration: InputDecoration(
                          labelText: l10n.fieldbookCheckerLabel,
                        ),
                      ),
                      TextField(
                        controller: instrumentController,
                        decoration: InputDecoration(
                          labelText: l10n.fieldbookInstrumentLabel,
                        ),
                      ),
                      TextField(
                        controller: weatherController,
                        decoration: InputDecoration(
                          labelText: l10n.fieldbookWeatherLabel,
                        ),
                      ),
                      TextField(
                        controller: workSectionController,
                        decoration: InputDecoration(
                          labelText: l10n.fieldbookWorkSectionLabel,
                        ),
                      ),
                      TextField(
                        controller: jobNumberController,
                        decoration: InputDecoration(
                          labelText: l10n.fieldbookJobNumberLabel,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          child: Text(l10n.coreCancel),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () async {
                            final title = titleController.text.trim();
                            if (title.isEmpty) return;

                            double? elevation;
                            int? bmId;

                            if (!useCustomBm && selectedBm != null) {
                              bmId = selectedBm!.id;
                              elevation = selectedBm!.elevation;
                            } else {
                              elevation = double.tryParse(
                                elevationController.text.trim(),
                              );
                              if (elevation == null) return;
                            }

                            final fb = FieldBook(
                              projectId: projectId,
                              title: title,
                              date: DateTime.now(),
                              startBmId: bmId,
                              startElevation: elevation,
                              reductionMethod: reductionMethod,
                              surveyor: _blankToNull(surveyorController.text),
                              checker: _blankToNull(checkerController.text),
                              instrument: _blankToNull(
                                instrumentController.text,
                              ),
                              weather: _blankToNull(weatherController.text),
                              workSection: _blankToNull(
                                workSectionController.text,
                              ),
                              jobNumber: _blankToNull(jobNumberController.text),
                            );
                            final id = await ref
                                .read(fieldBookListProvider(projectId).notifier)
                                .addFieldBook(fb);
                            if (!sheetContext.mounted) return;
                            Navigator.pop(sheetContext);
                            if (!context.mounted) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FieldBookEditScreen(
                                  fieldBook: fb.copyWith(id: id),
                                  projectId: projectId,
                                ),
                              ),
                            );
                          },
                          child: Text(l10n.fieldbookCreateButton),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Inserts a field book and its rows atomically so a failure midway does
  /// not leave a half-filled field book behind.
  static Future<int> _insertFieldBookWithMeasurements(
    FieldBook fieldBook,
    List<Measurement> measurements,
  ) async {
    final db = await DatabaseHelper.instance.database;
    return db.transaction((txn) async {
      final fieldBookMap = fieldBook.toMap()..remove('id');
      final id = await txn.insert('field_books', fieldBookMap);
      for (final row in measurements) {
        final rowMap = row.copyWith(fieldBookId: id).toMap()..remove('id');
        await txn.insert('measurements', rowMap);
      }
      return id;
    });
  }

  static bool _duplicating = false;

  Future<void> _duplicateFieldBook(
    BuildContext context,
    WidgetRef ref,
    FieldBook source,
  ) async {
    if (_duplicating) return;
    _duplicating = true;
    final l10n = context.l10n;
    try {
      await _duplicateFieldBookUnguarded(context, ref, source);
    } catch (error) {
      if (context.mounted) {
        AppSnackbar.error(context, l10n.fieldbookDuplicateError('$error'));
      }
    } finally {
      _duplicating = false;
    }
  }

  Future<void> _duplicateFieldBookUnguarded(
    BuildContext context,
    WidgetRef ref,
    FieldBook source,
  ) async {
    final l10n = context.l10n;
    final measurements = await ref
        .read(measurementRepositoryProvider)
        .getByFieldBookId(source.id!);
    final duplicate = FieldBookTemplates.duplicateStructure(
      source: source,
      measurements: measurements,
      newDate: DateTime.now(),
      copyName: l10n.fieldbookCopyName,
    );
    await _insertFieldBookWithMeasurements(
      duplicate.fieldBook,
      duplicate.measurements,
    );
    ref.invalidate(fieldBookListProvider(projectId));
    if (!context.mounted) return;
    AppSnackbar.success(context, l10n.fieldbookDuplicatedMessage);
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, FieldBook fb) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.fieldbookDeleteTitle),
        content: Text(context.l10n.fieldbookDeleteConfirm(fb.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.coreCancel),
          ),
          FilledButton(
            onPressed: () {
              ref
                  .read(fieldBookListProvider(projectId).notifier)
                  .deleteFieldBook(fb.id!);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: context.appColors.err,
              foregroundColor: Colors.white,
            ),
            child: Text(context.l10n.coreDelete),
          ),
        ],
      ),
    );
  }

  void _showCsvImportDialog(BuildContext context, WidgetRef ref) {
    final csvController = TextEditingController();
    var importing = false;
    final l10n = context.l10n;
    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n.fieldbookImportCsv),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: importing
                      ? null
                      : () async {
                          try {
                            final content = await TextFilePicker.pick(
                              extensions: const ['csv'],
                            );
                            if (content != null) csvController.text = content;
                          } on TextFileEncodingException catch (error) {
                            if (context.mounted) {
                              AppSnackbar.error(
                                context,
                                error.localizedMessage(l10n),
                              );
                            }
                          }
                        },
                  icon: const Icon(Icons.folder_open_outlined, size: 18),
                  label: Text(l10n.fieldbookChooseCsvFile),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: csvController,
                  maxLines: 10,
                  decoration: InputDecoration(
                    hintText: l10n.fieldbookCsvPasteHint,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: importing ? null : () => Navigator.pop(context),
              child: Text(l10n.coreCancel),
            ),
            FilledButton(
              onPressed: importing
                  ? null
                  : () async {
                      final result = CsvImporter.parse(
                        csvController.text,
                        projectId: projectId,
                        fallbackDate: DateTime.now(),
                        l10n: l10n,
                        appUnit: ref.read(lengthUnitProvider),
                      );
                      if (result.fieldBook == null) {
                        AppSnackbar.error(context, result.errors.join('\n'));
                        return;
                      }
                      setDialogState(() => importing = true);
                      try {
                        await _insertFieldBookWithMeasurements(
                          result.fieldBook!,
                          result.measurements,
                        );
                        ref.invalidate(fieldBookListProvider(projectId));
                      } catch (error) {
                        if (context.mounted) {
                          setDialogState(() => importing = false);
                          AppSnackbar.error(
                            context,
                            l10n.fieldbookCsvImportError('$error'),
                          );
                        }
                        return;
                      }
                      if (!context.mounted) return;
                      if (result.warnings.isEmpty) {
                        AppSnackbar.success(context, l10n.fieldbookCsvImported);
                      } else {
                        AppSnackbar.error(
                          context,
                          l10n.fieldbookCsvImportedWithWarnings(
                            result.warnings.join('\n'),
                          ),
                        );
                      }
                      Navigator.pop(context);
                    },
              child: Text(l10n.fieldbookImportButton),
            ),
          ],
        ),
      ),
    );
  }

  /// Backup errors carry a code; anything else is shown as-is.
  static String _backupErrorDetail(AppLocalizations l10n, Object error) =>
      error is ProjectBackupException ? error.localizedMessage(l10n) : '$error';

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
      final colors = context.appColors;
      return EmptyState(
        icon: Icons.menu_book_outlined,
        title: context.l10n.fieldbookEmptyTitle,
        message: context.l10n.fieldbookEmptyMessage,
        accent: colors.orange,
        accentSoft: colors.orangeSoft,
      );
    }

    final filtered = FieldBookSearch.filter(widget.fieldBooks, query: _query);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              labelText: context.l10n.fieldbookSearchLabel,
              hintText: context.l10n.fieldbookSearchHint,
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
              label: Text(context.l10n.fieldbookBulkExportButton),
            ),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(child: Text(context.l10n.fieldbookNoSearchResults))
              : _buildList(filtered),
        ),
      ],
    );
  }

  Widget _buildList(List<FieldBook> filtered) {
    // One native ad per screen: after the 3rd card when there are 3+ cards,
    // otherwise at the end of the list. (NativeAdCard collapses to zero space
    // when ads are removed/unsupported/not yet loaded.)
    final adPosition = filtered.length >= 3 ? 3 : filtered.length;
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        8,
        4,
        8,
        AppConstants.quickMemoFabListBottomPadding(context),
      ),
      itemCount: filtered.length + 1,
      itemBuilder: (context, index) {
        if (index == adPosition) return const NativeAdCard();
        final fbIndex = index > adPosition ? index - 1 : index;
        return _buildCard(filtered[fbIndex]);
      },
    );
  }

  Widget _buildCard(FieldBook fb) {
    final colors = context.appColors;
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
            color: colors.blueSoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.description_outlined, color: colors.blue),
        ),
        title: Text(fb.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            [
              DateFormat('yyyy-MM-dd').format(fb.date),
              if (fb.workSection?.trim().isNotEmpty == true)
                fb.workSection!.trim(),
              if (fb.surveyor?.trim().isNotEmpty == true)
                context.l10n.fieldbookSurveyorSubtitle(fb.surveyor!.trim()),
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
            PopupMenuItem(
              value: 'duplicate',
              child: Text(context.l10n.fieldbookDuplicateStructure),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Text(context.l10n.coreDelete),
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
  }
}
