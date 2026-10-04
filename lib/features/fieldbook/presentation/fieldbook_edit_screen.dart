import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/fieldbook_providers.dart';
import '../data/measurement_repository.dart';
import '../domain/fieldbook.dart';
import '../domain/measurement.dart';
import '../domain/measurement_validation.dart';
import '../domain/misclosure.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/semantic_pill.dart';
import '../../benchmark/data/benchmark_providers.dart';
import '../../benchmark/data/benchmark_repository.dart';
import '../../benchmark/domain/benchmark.dart';
import '../../benchmark/domain/benchmark_recheck.dart';
import '../../settings/misclosure_tolerance_repository.dart';
import '../../export/export_screen.dart';
import '../../quickmemo/presentation/quick_memo_fab.dart';
import '../../../core/utils/calculation.dart';
import '../../../l10n/l10n.dart';
import 'fieldbook_l10n.dart';

/// Display text for a BS/FS reading: 3 decimals (e.g. 1.94 → '1.940'), but
/// never rounds away entered precision (1.2345 stays '1.2345').
String formatReadingText(double value) {
  final fixed = value.toStringAsFixed(3);
  return double.parse(fixed) == value ? fixed : value.toString();
}

/// Column flex weights shared by the table header and rows. NO gets a wider
/// share than the numeric columns' tail so station names like 'BM-1 (폐합)'
/// stay legible on a 360pt viewport (≈50/68/68/68/68/36pt).
const int _flexNo = 14;
const int _flexValue = 19;
const int _flexAction = 10;

enum _SaveStatus { saved, pending, autosaved, error }

class _RowData {
  String stationName;
  String bsText;
  String fsText;
  double? ih;
  double? gh;
  bool isTP;
  bool manualTp;
  int? dbId;

  _RowData({
    this.stationName = '',
    this.bsText = '',
    this.fsText = '',
    this.ih,
    this.gh,
    this.isTP = false,
    this.manualTp = false,
    this.dbId,
  });

  double? get bs => double.tryParse(bsText);
  double? get fs => double.tryParse(fsText);
  bool get hasData => bs != null || fs != null;

  /// Rows worth persisting: a station name alone (e.g. from '구조 복제')
  /// counts, fully empty rows do not.
  bool get hasContent => stationName.trim().isNotEmpty || hasData;
}

class FieldBookEditScreen extends ConsumerStatefulWidget {
  final FieldBook fieldBook;
  final int projectId;

  const FieldBookEditScreen({
    super.key,
    required this.fieldBook,
    required this.projectId,
  });

  @override
  ConsumerState<FieldBookEditScreen> createState() =>
      _FieldBookEditScreenState();
}

class _FieldBookEditScreenState extends ConsumerState<FieldBookEditScreen>
    with WidgetsBindingObserver {
  final List<_RowData> _rows = [];
  double _startElevation = 0;
  bool _loaded = false;
  bool _dirty = false;
  _SaveStatus _saveStatus = _SaveStatus.saved;
  Timer? _autosaveTimer;

  /// Captured in didChangeDependencies so saves that finish (or start) after
  /// dispose — pop-save, lifecycle flush — never touch `ref`.
  late ProviderContainer _container;

  /// Tail of the save queue; every save chains onto it so two saves never
  /// interleave their delete/insert.
  Future<void> _saveQueue = Future.value();

  /// Incremented on every edit; compared with the generation captured by the
  /// last queued save to know whether there are unsaved edits.
  int _editGeneration = 0;
  int _queuedGeneration = 0;
  int _savedGeneration = 0;
  double? _persistedStartElevation;
  late FieldBookReviewStatus _reviewStatus;
  DateTime? _reviewedAt;

  /// Closing reference (persisted on change, see [_applyClosingReference]).
  late ClosingReferenceMode _closingMode;
  int? _closingBmId;
  double? _closingElevation;
  String? _closingBmName;
  final int _initialRowCount = 20;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _reviewMemoController = TextEditingController();

  // Focus nodes for cell navigation
  final Map<String, FocusNode> _focusNodes = {};
  final Map<String, TextEditingController> _controllers = {};

  TextEditingController _getController(int row, String col) {
    final key = '${row}_$col';
    if (!_controllers.containsKey(key)) {
      final r = _rows[row];
      _controllers[key] = TextEditingController(
        text: col == 'bs' ? r.bsText : r.fsText,
      );
    }
    return _controllers[key]!;
  }

  FocusNode _getFocusNode(int row, String col) {
    final key = '${row}_$col';
    return _focusNodes.putIfAbsent(key, () => _createFocusNode(key));
  }

  /// Focus node that pads the cell's value to 3 decimals once the user leaves
  /// it, so the field is never reformatted while it is being typed in.
  FocusNode _createFocusNode(String key) {
    final node = FocusNode();
    node.addListener(() {
      if (!node.hasFocus) _formatCellOnBlur(key, node);
    });
    return node;
  }

  void _formatCellOnBlur(String key, FocusNode node) {
    if (!mounted || _focusNodes[key] != node) return;
    final controller = _controllers[key];
    if (controller == null) return;
    final sep = key.indexOf('_');
    final row = int.tryParse(key.substring(0, sep));
    final col = key.substring(sep + 1);
    if (row == null || row >= _rows.length) return;
    final value = double.tryParse(controller.text.trim());
    if (value == null) return;
    final formatted = formatReadingText(value);
    if (formatted == controller.text) return;
    // Same numeric value, so no recalculation or autosave is needed.
    controller.text = formatted;
    if (col == 'bs') {
      _rows[row].bsText = formatted;
    } else {
      _rows[row].fsText = formatted;
    }
  }

  void _moveToNextCell(int currentRow, String currentCol) {
    if (currentCol == 'bs') {
      // BS → FS of same row
      _getFocusNode(currentRow, 'fs').requestFocus();
    } else {
      // FS → BS of next row
      final nextRow = currentRow + 1;
      if (nextRow < _rows.length) {
        _getFocusNode(nextRow, 'bs').requestFocus();
        // Auto-scroll to make next row visible
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_scrollController.hasClients) {
            final targetOffset = (nextRow - 3) * 42.0;
            if (targetOffset > _scrollController.offset) {
              _scrollController.animateTo(
                targetOffset,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
              );
            }
          }
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _persistedStartElevation = widget.fieldBook.startElevation;
    _reviewStatus = widget.fieldBook.reviewStatus;
    _reviewedAt = widget.fieldBook.reviewedAt;
    _reviewMemoController.text = widget.fieldBook.reviewMemo ?? '';
    _closingMode = widget.fieldBook.closingMode;
    _closingBmId = widget.fieldBook.closingBmId;
    _closingElevation = widget.fieldBook.closingElevation;
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _container = ProviderScope.containerOf(context, listen: false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _flushPendingEdits();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _flushPendingEdits();
    _autosaveTimer?.cancel();
    _scrollController.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final f in _focusNodes.values) {
      f.dispose();
    }
    _reviewMemoController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    double elevation = widget.fieldBook.startElevation ?? 0;
    if (widget.fieldBook.startBmId != null && elevation == 0) {
      final bmRepo = BenchMarkRepository();
      final bm = await bmRepo.getById(widget.fieldBook.startBmId!);
      if (bm != null) elevation = bm.elevation;
    }

    final closingBmId = _closingBmId;
    if (_closingMode == ClosingReferenceMode.benchmark && closingBmId != null) {
      final bm = await BenchMarkRepository().getById(closingBmId);
      _closingBmName = bm?.name;
    }

    final measRepo = ref.read(measurementRepositoryProvider);
    final existing = await measRepo.getByFieldBookId(widget.fieldBook.id!);

    final rows = <_RowData>[];
    for (final m in existing) {
      rows.add(
        _RowData(
          stationName: m.stationName,
          bsText: m.bs == null ? '' : formatReadingText(m.bs!),
          fsText: m.fs == null ? '' : formatReadingText(m.fs!),
          ih: m.ih,
          gh: m.gh,
          isTP: m.type == MeasurementType.tp,
          manualTp: m.manualTp,
          dbId: m.id,
        ),
      );
    }

    while (rows.length < _initialRowCount) {
      rows.add(_RowData());
    }

    if (mounted) {
      setState(() {
        _startElevation = elevation;
        _rows.addAll(rows);
        _loaded = true;
      });
      _recalculate();
    }
  }

  void _recalculate() {
    final results = LevelRun.compute(_startElevation, [
      for (final row in _rows)
        LevelRunInput(bs: row.bs, fs: row.fs, manualTp: row.manualTp),
    ]);
    for (int i = 0; i < _rows.length; i++) {
      final row = _rows[i];
      final result = results[i];
      row.isTP = result.isTP;
      row.ih = result.ih;
      row.gh = result.gh;
    }
    setState(() {});
  }

  List<Measurement> _toMeasurements() {
    final measurements = <Measurement>[];
    var orderIndex = 0;
    for (final row in _rows) {
      if (!row.hasContent) continue;
      measurements.add(
        Measurement(
          id: row.dbId,
          fieldBookId: widget.fieldBook.id!,
          orderIndex: orderIndex,
          stationName: row.stationName.isEmpty
              ? '${orderIndex + 1}'
              : row.stationName,
          type: row.isTP ? MeasurementType.tp : MeasurementType.normal,
          bs: row.bs,
          fs: row.fs,
          ih: row.ih,
          gh: row.gh,
          manualTp: row.manualTp,
        ),
      );
      orderIndex++;
    }
    return measurements;
  }

  void _scheduleAutosave() {
    _dirty = true;
    _editGeneration++;
    _autosaveTimer?.cancel();
    setState(() => _saveStatus = _SaveStatus.pending);
    _autosaveTimer = Timer(const Duration(milliseconds: 900), () {
      _saveToDb(silent: true).catchError((Object _) {});
    });
  }

  bool get _hasUnqueuedEdits => _editGeneration != _queuedGeneration;

  /// Saves edits not yet queued (pop, dispose, app paused). Safe after
  /// dispose because the save only uses the captured container.
  void _flushPendingEdits() {
    if (!_loaded || !_hasUnqueuedEdits) return;
    try {
      _saveToDb(silent: true).catchError((Object _) {});
    } catch (_) {
      // Container already disposed (app teardown); nothing left to save into.
    }
  }

  Future<void> _saveToDb({bool silent = false}) {
    // A manual/export/pop save supersedes the pending autosave.
    _autosaveTimer?.cancel();
    _autosaveTimer = null;

    // Snapshot now so the queued save writes exactly the state at call time.
    final fieldBookId = widget.fieldBook.id!;
    final projectId = widget.projectId;
    final measurements = _toMeasurements();
    final startElevation = _startElevation;
    final generation = _editGeneration;
    _queuedGeneration = generation;
    final container = _container;
    final MeasurementRepository measRepo = container.read(
      measurementRepositoryProvider,
    );

    final save = _saveQueue.catchError((Object _) {}).then((_) async {
      await measRepo.replaceForFieldBook(
        fieldBookId,
        measurements,
        startElevation: startElevation,
      );
      container.invalidate(measurementListProvider(fieldBookId));
      if (_persistedStartElevation != startElevation) {
        _persistedStartElevation = startElevation;
        container.invalidate(fieldBookListProvider(projectId));
      }
    });
    _saveQueue = save;

    return save.then(
      (_) {
        if (generation > _savedGeneration) _savedGeneration = generation;
        if (!mounted) return;
        setState(() {
          _dirty = _savedGeneration != _editGeneration;
          if (!_dirty) {
            _saveStatus = silent ? _SaveStatus.autosaved : _SaveStatus.saved;
          }
        });
      },
      onError: (Object error, StackTrace stackTrace) {
        // Let the next flush (pop/dispose/pause) retry the failed edits.
        if (_queuedGeneration == generation) {
          _queuedGeneration = _savedGeneration;
        }
        if (mounted) setState(() => _saveStatus = _SaveStatus.error);
        Error.throwWithStackTrace(error, stackTrace);
      },
    );
  }

  Future<void> _saveReviewMetadata() async {
    await ref
        .read(fieldBookListProvider(widget.projectId).notifier)
        .updateFieldBook(_fieldBookWithReviewMetadata());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.fieldbookReviewSavedMessage),
        duration: Duration(seconds: 1),
      ),
    );
  }

  FieldBook _fieldBookWithReviewMetadata() {
    final memo = _reviewMemoController.text.trim();
    return FieldBook(
      id: widget.fieldBook.id,
      projectId: widget.fieldBook.projectId,
      title: widget.fieldBook.title,
      date: widget.fieldBook.date,
      startBmId: widget.fieldBook.startBmId,
      startElevation: _startElevation,
      closingMode: _closingMode,
      closingBmId: _closingBmId,
      closingElevation: _closingElevation,
      memo: widget.fieldBook.memo,
      surveyor: widget.fieldBook.surveyor,
      checker: widget.fieldBook.checker,
      instrument: widget.fieldBook.instrument,
      weather: widget.fieldBook.weather,
      workSection: widget.fieldBook.workSection,
      jobNumber: widget.fieldBook.jobNumber,
      reviewStatus: _reviewStatus,
      reviewMemo: memo.isEmpty ? null : memo,
      reviewedAt: _reviewedAt,
      createdAt: widget.fieldBook.createdAt,
    );
  }

  void _deleteRow(int index) {
    if (_rows[index].hasContent) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(ctx.l10n.fieldbookDeleteRowTitle),
          content: Text(ctx.l10n.fieldbookDeleteRowConfirm(index + 1)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(ctx.l10n.coreCancel),
            ),
            FilledButton(
              onPressed: () {
                // Remove controllers and focus nodes for this row
                _controllers.remove('${index}_bs')?.dispose();
                _controllers.remove('${index}_fs')?.dispose();
                _focusNodes.remove('${index}_bs')?.dispose();
                _focusNodes.remove('${index}_fs')?.dispose();
                setState(() => _rows.removeAt(index));
                // Rebuild controller/focus node keys
                _rebuildControllerKeys();
                _recalculate();
                _scheduleAutosave();
                Navigator.pop(ctx);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text(ctx.l10n.coreDelete),
            ),
          ],
        ),
      );
    } else {
      _controllers.remove('${index}_bs')?.dispose();
      _controllers.remove('${index}_fs')?.dispose();
      _focusNodes.remove('${index}_bs')?.dispose();
      _focusNodes.remove('${index}_fs')?.dispose();
      setState(() => _rows.removeAt(index));
      _rebuildControllerKeys();
      _recalculate();
      _scheduleAutosave();
    }
  }

  void _insertRowBelow(int index) {
    setState(() {
      _rows.insert(index + 1, _RowData());
    });
    _rebuildControllerKeys();
    _recalculate();
    _scheduleAutosave();
  }

  void _duplicateRow(int index) {
    final row = _rows[index];
    setState(() {
      _rows.insert(
        index + 1,
        _RowData(
          stationName: row.stationName.isEmpty
              ? ''
              : context.l10n.fieldbookCopyName(row.stationName),
          bsText: row.bsText,
          fsText: row.fsText,
          ih: row.ih,
          gh: row.gh,
          isTP: row.isTP,
          manualTp: row.manualTp,
        ),
      );
    });
    _rebuildControllerKeys();
    _recalculate();
    _scheduleAutosave();
  }

  void _toggleManualTp(int index) {
    setState(() {
      _rows[index].manualTp = !_rows[index].manualTp;
    });
    _recalculate();
    _scheduleAutosave();
  }

  void _editStationName(int index) {
    final controller = TextEditingController(text: _rows[index].stationName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.fieldbookEditStationTitle),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: ctx.l10n.fieldbookStationLabel,
            hintText: ctx.l10n.fieldbookStationHint,
            helperText: ctx.l10n.fieldbookStationHelper(index + 1),
          ),
          autofocus: true,
          onSubmitted: (_) {
            setState(() => _rows[index].stationName = controller.text.trim());
            _scheduleAutosave();
            Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ctx.l10n.coreCancel),
          ),
          FilledButton(
            onPressed: () {
              setState(() => _rows[index].stationName = controller.text.trim());
              _scheduleAutosave();
              Navigator.pop(ctx);
            },
            child: Text(ctx.l10n.coreConfirm),
          ),
        ],
      ),
    );
  }

  void _rebuildControllerKeys() {
    final oldControllers = Map<String, TextEditingController>.from(
      _controllers,
    );
    final oldFocusNodes = Map<String, FocusNode>.from(_focusNodes);
    _controllers.clear();
    _focusNodes.clear();

    for (int i = 0; i < _rows.length; i++) {
      for (final col in ['bs', 'fs']) {
        final key = '${i}_$col';
        final text = col == 'bs' ? _rows[i].bsText : _rows[i].fsText;
        _controllers[key] = TextEditingController(text: text);
        _focusNodes[key] = _createFocusNode(key);
      }
    }

    for (final c in oldControllers.values) {
      c.dispose();
    }
    for (final f in oldFocusNodes.values) {
      f.dispose();
    }
  }

  /// Known RL the run closes on (null: only the arithmetic check).
  double? get _closingRl => switch (_closingMode) {
    ClosingReferenceMode.none => null,
    ClosingReferenceMode.loop => _startElevation,
    ClosingReferenceMode.benchmark ||
    ClosingReferenceMode.manual => _closingElevation,
  };

  MisclosureTolerance get _tolerance =>
      _container.read(misclosureToleranceProvider).valueOrNull ??
      MisclosureTolerance.defaults;

  MeasurementValidationResult _validate(MisclosureTolerance tolerance) =>
      MeasurementValidation.validate(
        measurements: _toMeasurements(),
        startElevation: _startElevation,
        closingElevation: _closingRl,
        tolerance: tolerance,
      );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tolerance =
        ref.watch(misclosureToleranceProvider).valueOrNull ??
        MisclosureTolerance.defaults;
    // The app-wide quick-memo FAB would cover the validation chips and the
    // closure summary pinned to the bottom; it is offered from the app bar.
    return HideQuickMemoFab(
      child: PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) _flushPendingEdits();
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.fieldBook.title),
            actions: [
              IconButton(
                icon: const Icon(Icons.bolt),
                tooltip: l10n.quickMemoTitle,
                onPressed: () => showQuickMemoComposer(context),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: l10n.fieldbookAddTenRowsTooltip,
                onPressed: () {
                  setState(() {
                    for (int i = 0; i < 10; i++) {
                      _rows.add(_RowData());
                    }
                  });
                  _scheduleAutosave();
                },
              ),
              IconButton(
                icon: const Icon(Icons.save),
                tooltip: l10n.coreSave,
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await _saveToDb();
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(l10n.fieldbookSavedMessage),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.ios_share),
                tooltip: l10n.fieldbookExportTooltip,
                onPressed: _export,
              ),
            ],
          ),
          body: !_loaded
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    _buildStartElevationBar(),
                    _buildReviewPanel(),
                    _buildTableHeader(),
                    Expanded(child: _buildTableBody()),
                    _buildValidationBar(_validate(tolerance)),
                    _buildSummary(tolerance),
                  ],
                ),
        ),
      ),
    );
  }

  /// Start RL input and, on the right, the closing reference button (one
  /// row so the table keeps its height on small phones).
  Widget _buildStartElevationBar() {
    final colors = context.appColors;
    const onDark = Colors.white;
    final onDarkMuted = Colors.white.withValues(alpha: 0.62);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: colors.darkSurface,
      child: Row(
        children: [
          Text(
            context.l10n.fieldbookStartRlLabel,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: onDarkMuted,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 112,
            child: TextFormField(
              initialValue: _startElevation.toStringAsFixed(3),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: onDark,
                fontFeatures: AppTypography.tabularFeatures,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textAlign: TextAlign.center,
              cursorColor: onDark,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: onDark, width: 1.2),
                ),
                filled: true,
                fillColor: colors.darkSurface2,
              ),
              onChanged: (value) {
                final elev = double.tryParse(value);
                if (elev != null) {
                  _startElevation = elev;
                  _recalculate();
                  _scheduleAutosave();
                }
              },
            ),
          ),
          const SizedBox(width: 4),
          Text('m', style: TextStyle(fontSize: 14, color: onDarkMuted)),
          const SizedBox(width: 12),
          Expanded(
            child: _buildClosingButton(
              onDark: onDark,
              onDarkMuted: onDarkMuted,
            ),
          ),
        ],
      ),
    );
  }

  String _closingSummaryText(AppLocalizations l10n) {
    final rl = _closingRl;
    if (rl == null) return l10n.fieldbookClosingNotSet;
    final name = switch (_closingMode) {
      ClosingReferenceMode.loop => l10n.fieldbookClosingLoopShort,
      ClosingReferenceMode.benchmark => _closingBmName ?? 'BM',
      _ => l10n.fieldbookClosingManualShort,
    };
    return l10n.fieldbookClosingSummary(name, rl.toStringAsFixed(3));
  }

  /// Two-line button "Closing RL / Loop · 100.000 ▾" that opens
  /// [_editClosingReference].
  Widget _buildClosingButton({
    required Color onDark,
    required Color onDarkMuted,
  }) {
    final l10n = context.l10n;
    final isSet = _closingRl != null;
    return Align(
      alignment: Alignment.centerRight,
      child: InkWell(
        key: const ValueKey('closing-reference-button'),
        borderRadius: BorderRadius.circular(8),
        onTap: _editClosingReference,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
          child: Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        l10n.fieldbookClosingLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: onDarkMuted),
                      ),
                      Text(
                        _closingSummaryText(l10n),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSet ? FontWeight.w700 : FontWeight.w500,
                          color: isSet ? onDark : onDarkMuted,
                          fontFeatures: AppTypography.tabularFeatures,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.expand_more, size: 18, color: onDarkMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _editClosingReference() async {
    final l10n = context.l10n;
    List<BenchMark> benchmarks = const [];
    try {
      benchmarks = BenchMarkRecheck.selectableForFieldBook(
        await ref.read(benchmarkListProvider(widget.projectId).future),
      );
    } catch (_) {
      // Without the BM list only None / Loop / Manual can be chosen.
    }
    if (!mounted) return;
    final result = await showModalBottomSheet<_ClosingChoice>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ClosingReferenceSheet(
        initialMode: _closingMode,
        initialBmId: _closingBmId,
        initialElevation: _closingElevation,
        benchmarks: benchmarks,
      ),
    );
    if (result == null || !mounted) return;
    await _applyClosingReference(result, l10n);
  }

  Future<void> _applyClosingReference(
    _ClosingChoice choice,
    AppLocalizations l10n,
  ) async {
    setState(() {
      _closingMode = choice.mode;
      _closingBmId = choice.bmId;
      _closingElevation = choice.elevation;
      _closingBmName = choice.bmName;
    });
    try {
      await _container
          .read(fieldBookRepositoryProvider)
          .updateClosingReference(_fieldBookWithReviewMetadata());
      _container.invalidate(fieldBookListProvider(widget.projectId));
    } catch (error) {
      if (mounted) {
        AppSnackbar.error(context, l10n.coreErrorWithDetail('$error'));
      }
    }
  }

  Widget _buildReviewPanel() {
    final reviewedAt = _reviewedAt;
    final colors = context.appColors;
    final l10n = context.l10n;
    return Material(
      color: colors.panel,
      shape: Border(bottom: BorderSide(color: colors.line)),
      child: ExpansionTile(
        controlAffinity: ListTileControlAffinity.leading,
        tilePadding: const EdgeInsets.fromLTRB(8, 0, 16, 0),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        title: Text(
          l10n.fieldbookReviewPanelTitle,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        trailing: Text(
          [
            _reviewStatus.localizedLabel(l10n),
            if (reviewedAt != null)
              l10n.fieldbookReviewedOn(_formatDate(reviewedAt)),
          ].join(' · '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 13, color: colors.subtext),
        ),
        children: [
          DropdownButtonFormField<FieldBookReviewStatus>(
            initialValue: _reviewStatus,
            decoration: InputDecoration(
              labelText: l10n.fieldbookReviewStatusLabel,
            ),
            items: [
              for (final status in FieldBookReviewStatus.values)
                DropdownMenuItem(
                  value: status,
                  child: Text(status.localizedLabel(l10n)),
                ),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _reviewStatus = value);
            },
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _reviewMemoController,
            decoration: InputDecoration(
              labelText: l10n.fieldbookReviewMemoLabel,
              hintText: l10n.fieldbookReviewMemoHint,
            ),
            minLines: 1,
            maxLines: 3,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    final now = DateTime.now();
                    setState(() {
                      _reviewedAt = DateTime(now.year, now.month, now.day);
                    });
                  },
                  icon: const Icon(Icons.today_outlined),
                  label: Text(
                    reviewedAt == null
                        ? l10n.fieldbookReviewTodayButton
                        : l10n.fieldbookReviewedOn(_formatDate(reviewedAt)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _saveReviewMetadata,
                icon: const Icon(Icons.save_outlined),
                label: Text(l10n.fieldbookReviewSaveButton),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    final colors = context.appColors;
    final l10n = context.l10n;
    return Container(
      decoration: BoxDecoration(
        color: colors.soft,
        border: Border(bottom: BorderSide(color: colors.line, width: 1)),
      ),
      child: Row(
        children: [
          _headerCell(l10n.fieldbookColumnNo, flex: _flexNo),
          _headerCell('BS', flex: _flexValue),
          _headerCell('FS', flex: _flexValue),
          _headerCell(l10n.fieldbookColumnHi, flex: _flexValue),
          _headerCell(l10n.fieldbookColumnRl, flex: _flexValue),
          _headerCell('', flex: _flexAction), // TP/비고
        ],
      ),
    );
  }

  Widget _headerCell(String text, {int flex = 1}) {
    final colors = context.appColors;
    return Expanded(
      flex: flex,
      child: Container(
        height: 40,
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12.5,
            color: colors.subtext,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  Widget _buildTableBody() {
    return ListView.builder(
      controller: _scrollController,
      itemCount: _rows.length,
      itemExtent: 42,
      itemBuilder: (context, index) => _buildDataRow(index),
    );
  }

  Widget _buildDataRow(int index) {
    final row = _rows[index];
    final colors = context.appColors;
    final l10n = context.l10n;

    // TP rows tint the NO/BS/FS/action cells orange; IH/GH keep their
    // per-column tint so the two columns stay color-identifiable in the field.
    final rowBase = row.isTP ? colors.orangeSoft : colors.panel;

    return GestureDetector(
      onLongPress: () => _deleteRow(index),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: rowBase,
          border: Border(bottom: BorderSide(color: colors.zebra, width: 1)),
        ),
        child: Row(
          children: [
            // NO / 측점명
            // Names wrap to two smaller lines; the full name is always one
            // tap away in the edit dialog.
            Expanded(
              flex: _flexNo,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _editStationName(index),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Center(
                    child: Text(
                      row.stationName.isEmpty
                          ? '${index + 1}'
                          : row.stationName,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: row.stationName.length > 5 ? 11 : 13,
                        height: 1.15,
                        color: row.stationName.isEmpty
                            ? colors.placeholder
                            : colors.green,
                        fontWeight: row.stationName.isEmpty
                            ? FontWeight.normal
                            : FontWeight.w600,
                        fontFeatures: AppTypography.tabularFeatures,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // BS
            Expanded(flex: _flexValue, child: _editableCell(index, 'bs')),
            // FS
            Expanded(flex: _flexValue, child: _editableCell(index, 'fs')),
            // IH (read-only) — column-wide blue tint
            Expanded(
              flex: _flexValue,
              child: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 8),
                color: colors.blueSoft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    row.ih?.toStringAsFixed(3) ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.blue,
                      fontFeatures: AppTypography.tabularFeatures,
                    ),
                  ),
                ),
              ),
            ),
            // GH (read-only) — column-wide green tint
            Expanded(
              flex: _flexValue,
              child: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 8),
                color: colors.greenSoft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    row.gh?.toStringAsFixed(3) ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.green,
                      fontFeatures: AppTypography.tabularFeatures,
                    ),
                  ),
                ),
              ),
            ),
            // TP indicator and row actions
            Expanded(
              flex: _flexAction,
              child: Center(
                child: PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: row.isTP
                      ? Icon(Icons.flag, size: 18, color: colors.orange)
                      : Icon(Icons.more_vert, size: 18, color: colors.subtext),
                  tooltip: l10n.fieldbookRowActionsTooltip,
                  onSelected: (value) {
                    if (value == 'insert') _insertRowBelow(index);
                    if (value == 'duplicate') _duplicateRow(index);
                    if (value == 'tp') _toggleManualTp(index);
                    if (value == 'delete') _deleteRow(index);
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'insert',
                      child: Text(l10n.fieldbookRowInsertBelow),
                    ),
                    PopupMenuItem(
                      value: 'duplicate',
                      child: Text(l10n.fieldbookRowDuplicate),
                    ),
                    PopupMenuItem(
                      value: 'tp',
                      child: Text(
                        row.manualTp
                            ? l10n.fieldbookRowUnsetManualTp
                            : l10n.fieldbookRowSetManualTp,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(l10n.coreDelete),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _editableCell(int rowIndex, String col) {
    final colors = context.appColors;
    return Container(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: colors.zebra, width: 1)),
      ),
      child: TextField(
        controller: _getController(rowIndex, col),
        focusNode: _getFocusNode(rowIndex, col),
        style: TextStyle(
          fontSize: 14,
          color: colors.ink,
          fontFeatures: AppTypography.tabularFeatures,
        ),
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
          signed: true,
        ),
        textAlign: TextAlign.right,
        textInputAction: TextInputAction.next,
        decoration: const InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          border: InputBorder.none,
        ),
        onChanged: (v) {
          if (col == 'bs') {
            _rows[rowIndex].bsText = v;
          } else {
            _rows[rowIndex].fsText = v;
          }
          _recalculate();
          _scheduleAutosave();
        },
        onSubmitted: (_) => _moveToNextCell(rowIndex, col),
      ),
    );
  }

  Widget _buildSummary(MisclosureTolerance tolerance) {
    final closure = LevelClosureCheck.compute(
      _toMeasurements(),
      startElevation: _startElevation,
      closingElevation: _closingRl,
      tolerance: tolerance,
    );
    final sums = closure.sums;
    final hasData = _rows.any((row) => row.gh != null);
    final colors = context.appColors;
    final l10n = context.l10n;
    Color judged(bool ok) => hasData && ok ? colors.green : colors.err;
    final misclosure = closure.misclosure;

    // The dark panel runs to the screen edge; keep its text clear of the
    // home indicator / gesture bar.
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + bottomInset),
      color: colors.darkSurface,
      child: Column(
        children: [
          Row(
            children: [
              _summaryItem('ΣBS', sums.sumBs.toStringAsFixed(3)),
              _summaryItem('ΣFS', sums.sumFs.toStringAsFixed(3)),
              _summaryItem(
                l10n.fieldbookSummaryDiff,
                sums.difference.toStringAsFixed(3),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _summaryItem(
                l10n.fieldbookSummaryStart,
                hasData ? sums.firstGh.toStringAsFixed(3) : '-',
              ),
              _summaryItem(
                l10n.fieldbookSummaryFinal,
                hasData ? sums.lastGh.toStringAsFixed(3) : '-',
              ),
              // With a closing RL: the real misclosure (Final − closing RL).
              // Without one: only the arithmetic check, labelled as such.
              if (misclosure != null)
                _summaryItem(
                  l10n.fieldbookSummaryMisclosure,
                  formatMisclosure(misclosure),
                  valueColor: judged(closure.withinTolerance ?? false),
                  caption: l10n.fieldbookSummaryAllowed(
                    formatAllowedMisclosure(closure.allowed),
                  ),
                )
              else
                _summaryItem(
                  l10n.fieldbookSummaryArithmetic,
                  closure.arithmeticError.toStringAsFixed(4),
                  valueColor: judged(closure.arithmeticOk),
                  caption: l10n.fieldbookSummaryNoClosing,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildValidationBar(MeasurementValidationResult validation) {
    final isOk = validation.canExport;
    final colors = context.appColors;
    final l10n = context.l10n;
    final accent = isOk ? colors.green : colors.err;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: isOk ? colors.greenSoft : colors.errSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isOk ? Icons.check_circle_outline : Icons.error_outline,
                size: 18,
                color: accent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  !isOk
                      ? validation.issues.first.localizedMessage(l10n)
                      : validation.misclosure != null
                      ? l10n.fieldbookMisclosureCheckResult(
                          validation.localizedJudgement(l10n),
                        )
                      : l10n.fieldbookArithmeticCheckResult(
                          validation.localizedJudgement(l10n),
                        ),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: accent,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _saveStatusText(l10n),
                style: TextStyle(fontSize: 12, color: colors.subtext),
              ),
              if (_dirty) ...[
                const SizedBox(width: 8),
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final item in validation.checklist)
                SemanticPill(
                  label:
                      '${item.passed ? '✓' : '!'} ${item.check.localizedLabel(l10n)}',
                  variant: item.passed
                      ? SemanticPillVariant.green
                      : SemanticPillVariant.err,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmExportValidation(
    MeasurementValidationResult validation,
  ) async {
    if (validation.hasBlockingFailures) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.l10n.fieldbookExportCheckTitle),
          content: Text(validation.localizedMessages(context.l10n).join('\n')),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.coreConfirm),
            ),
          ],
        ),
      );
      return false;
    }

    if (!validation.canExport) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.l10n.fieldbookToleranceCheckTitle),
          content: Text(validation.localizedMessages(context.l10n).join('\n')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.l10n.coreCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.l10n.fieldbookContinueButton),
            ),
          ],
        ),
      );
      return proceed == true;
    }
    return true;
  }

  Widget _summaryItem(
    String label,
    String value, {
    Color? valueColor,
    String? caption,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.white,
              fontFeatures: AppTypography.tabularFeatures,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          if (caption != null)
            Text(
              caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                height: 1.1,
                color: Colors.white.withValues(alpha: 0.55),
                fontFeatures: AppTypography.tabularFeatures,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _export() async {
    await _saveToDb();
    final validation = _validate(_tolerance);
    if (!validation.canExport && mounted) {
      final proceed = await _confirmExportValidation(validation);
      if (!proceed) return;
    }
    final measRepo = _container.read(measurementRepositoryProvider);
    final measurements = MeasurementValidation.trimTrailingUnmeasured(
      await measRepo.getByFieldBookId(widget.fieldBook.id!),
    );

    if (measurements.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.fieldbookNoDataToExport)),
        );
      }
      return;
    }

    String bmName = 'BM';
    if (widget.fieldBook.startBmId != null) {
      final bmRepo = BenchMarkRepository();
      final bm = await bmRepo.getById(widget.fieldBook.startBmId!);
      if (bm != null) bmName = bm.name;
    }

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ExportScreen(
            fieldBook: _fieldBookWithReviewMetadata(),
            measurements: measurements,
            bmName: bmName,
            startElevation: _startElevation,
            closingBmName: _closingMode == ClosingReferenceMode.benchmark
                ? _closingBmName
                : null,
          ),
        ),
      );
    }
  }

  String _saveStatusText(AppLocalizations l10n) => switch (_saveStatus) {
    _SaveStatus.saved => l10n.fieldbookSaveStatusSaved,
    _SaveStatus.pending => l10n.fieldbookSaveStatusPending,
    _SaveStatus.autosaved => l10n.fieldbookSaveStatusAutosaved,
    _SaveStatus.error => l10n.fieldbookSaveStatusError,
  };

  String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}

/// Result of the closing reference sheet.
class _ClosingChoice {
  final ClosingReferenceMode mode;
  final int? bmId;
  final double? elevation;
  final String? bmName;

  const _ClosingChoice(this.mode, {this.bmId, this.elevation, this.bmName});
}

/// None / Start BM (loop) / Other BM / Manual RL.
class _ClosingReferenceSheet extends StatefulWidget {
  final ClosingReferenceMode initialMode;
  final int? initialBmId;
  final double? initialElevation;
  final List<BenchMark> benchmarks;

  const _ClosingReferenceSheet({
    required this.initialMode,
    required this.initialBmId,
    required this.initialElevation,
    required this.benchmarks,
  });

  @override
  State<_ClosingReferenceSheet> createState() => _ClosingReferenceSheetState();
}

class _ClosingReferenceSheetState extends State<_ClosingReferenceSheet> {
  late ClosingReferenceMode _mode = widget.initialMode;
  late BenchMark? _bm = widget.benchmarks
      .where((bm) => bm.id == widget.initialBmId)
      .firstOrNull;
  late final _elevationController = TextEditingController(
    text: widget.initialMode == ClosingReferenceMode.manual
        ? widget.initialElevation?.toStringAsFixed(3) ?? ''
        : '',
  );
  bool _showError = false;

  @override
  void dispose() {
    _elevationController.dispose();
    super.dispose();
  }

  double? get _manualElevation {
    final value = double.tryParse(_elevationController.text.trim());
    return value != null && value.isFinite ? value : null;
  }

  _ClosingChoice? get _choice => switch (_mode) {
    ClosingReferenceMode.none => const _ClosingChoice(
      ClosingReferenceMode.none,
    ),
    ClosingReferenceMode.loop => const _ClosingChoice(
      ClosingReferenceMode.loop,
    ),
    // Snapshot the BM elevation now (like the start RL), so later BM edits
    // never silently change this book.
    ClosingReferenceMode.benchmark =>
      _bm == null
          ? null
          : _ClosingChoice(
              ClosingReferenceMode.benchmark,
              bmId: _bm!.id,
              elevation: _bm!.elevation,
              bmName: _bm!.name,
            ),
    ClosingReferenceMode.manual =>
      _manualElevation == null
          ? null
          : _ClosingChoice(
              ClosingReferenceMode.manual,
              elevation: _manualElevation,
            ),
  };

  void _apply() {
    final choice = _choice;
    if (choice == null) {
      setState(() => _showError = true);
      return;
    }
    Navigator.pop(context, choice);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final options = [
      (ClosingReferenceMode.none, l10n.fieldbookClosingNone),
      (ClosingReferenceMode.loop, l10n.fieldbookClosingLoop),
      (ClosingReferenceMode.benchmark, l10n.fieldbookClosingOtherBm),
      (ClosingReferenceMode.manual, l10n.fieldbookClosingManual),
    ];
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.fieldbookClosingSheetTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              l10n.fieldbookClosingSheetHelp,
              style: TextStyle(fontSize: 12.5, color: colors.subtext),
            ),
            const SizedBox(height: 8),
            RadioGroup<ClosingReferenceMode>(
              groupValue: _mode,
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _mode = value;
                  _showError = false;
                });
              },
              child: Column(
                children: [
                  for (final (mode, label) in options)
                    RadioListTile<ClosingReferenceMode>(
                      value: mode,
                      title: Text(label),
                      contentPadding: EdgeInsets.zero,
                      dense: false,
                    ),
                ],
              ),
            ),
            if (_mode == ClosingReferenceMode.benchmark)
              widget.benchmarks.isEmpty
                  ? Text(
                      l10n.fieldbookClosingNoBm,
                      style: TextStyle(color: colors.err, fontSize: 13),
                    )
                  : DropdownButtonFormField<BenchMark>(
                      initialValue: _bm,
                      decoration: InputDecoration(
                        labelText: l10n.fieldbookClosingBmLabel,
                        errorText: _showError && _bm == null
                            ? l10n.fieldbookClosingInvalid
                            : null,
                      ),
                      items: [
                        for (final bm in widget.benchmarks)
                          DropdownMenuItem(
                            value: bm,
                            child: Text(
                              '${bm.name} (${bm.elevation.toStringAsFixed(3)}m)',
                            ),
                          ),
                      ],
                      onChanged: (value) => setState(() => _bm = value),
                    ),
            if (_mode == ClosingReferenceMode.manual)
              TextField(
                controller: _elevationController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: InputDecoration(
                  labelText: l10n.fieldbookClosingElevationLabel,
                  errorText: _showError && _manualElevation == null
                      ? l10n.fieldbookClosingInvalid
                      : null,
                ),
                onChanged: (_) {
                  if (_showError) setState(() {});
                },
                onSubmitted: (_) => _apply(),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.coreCancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _apply,
                    child: Text(l10n.fieldbookClosingApply),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
