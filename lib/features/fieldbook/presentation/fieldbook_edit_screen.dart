import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/fieldbook_providers.dart';
import '../data/measurement_repository.dart';
import '../domain/design_level.dart';
import '../domain/fieldbook.dart';
import '../domain/measurement.dart';
import '../domain/measurement_validation.dart';
import '../domain/misclosure.dart';
import '../domain/reduction.dart';
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
import 'reduction_method_selector.dart';
import '../../../core/utils/decimal_input.dart';

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

/// Design levels are full RLs (e.g. 100.187), wider than BS/FS readings, and
/// the cut/fill cell carries a C/F prefix. The target reading is a staff
/// reading ('2.065'; negative when design is above the HI).
const int _flexDesign = 26;
const int _flexCutFill = 23;
const int _flexTarget = 22;

/// Narrowest table that keeps the numeric columns at their usual ≈68 pt when
/// the Design / Cut-Fill / Target columns are shown (flex 171 instead of
/// 100, ≈3.7 pt per flex): '100.187', 'C 12.345' and the Spanish header
/// "Lect. obj." are never squeezed; on narrower screens the table scrolls
/// horizontally.
const double _designTableMinWidth = 640;

/// Cell column ids (focus/controller keys are `'<row>_<col>'`).
const String _colBs = 'bs';
const String _colFs = 'fs';
const String _colDesign = 'dl';
const List<String> _inputColumns = [_colBs, _colFs, _colDesign];

enum _SaveStatus { saved, pending, autosaved, error }

class _RowData {
  String stationName;
  String bsText;
  String fsText;

  /// Design level (계획고) as typed; '' when not set.
  String designText;
  double? ih;
  double? gh;

  /// Rise (+) / fall (−) for rise-and-fall books (see [LevelRun.riseFall]).
  double? riseFall;

  /// HI of the instrument setup in effect at this row ([setupHeightsOf]),
  /// also for rows with no reading yet and in rise-and-fall books.
  double? setupHi;
  bool isTP;
  bool manualTp;
  int? dbId;

  _RowData({
    this.stationName = '',
    this.bsText = '',
    this.fsText = '',
    this.designText = '',
    this.ih,
    this.gh,
    this.isTP = false,
    this.manualTp = false,
    this.dbId,
  });

  double? get bs => double.tryParse(bsText);
  double? get fs => double.tryParse(fsText);
  double? get design => double.tryParse(designText);
  bool get hasData => bs != null || fs != null;

  /// Rows worth persisting: a station name alone (e.g. from '구조 복제')
  /// or a design level entered ahead of the reading counts, fully empty
  /// rows do not.
  bool get hasContent =>
      stationName.trim().isNotEmpty || hasData || design != null;

  /// Cut (+) / fill (−) = RL − design; null without both.
  double? get cutFill => cutFillOf(rl: gh, design: design);

  /// Stakeout target staff reading = setup HI − design; null without both.
  double? get target => stakeoutTargetOf(hi: setupHi, design: design);

  String textOf(String col) => switch (col) {
    _colBs => bsText,
    _colFs => fsText,
    _ => designText,
  };

  void setText(String col, String text) {
    switch (col) {
      case _colBs:
        bsText = text;
      case _colFs:
        fsText = text;
      default:
        designText = text;
    }
  }
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

  /// HI / rise and fall (persisted on change, see [_applyReductionMethod]).
  late ReductionMethod _reductionMethod;

  /// Design / Cut-Fill columns shown (persisted on change, see
  /// [_applyShowDesignLevel]).
  late bool _showDesignLevel;

  /// Route length L (km / mi) of the K·√L tolerance (persisted on change,
  /// see [_applyRouteLength]).
  double? _routeLength;
  late final TextEditingController _routeLengthController;
  final int _initialRowCount = 20;
  final ScrollController _scrollController = ScrollController();

  /// "Row deleted · Undo" snack bar; closed on dispose so Undo never
  /// outlives the editor.
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? _undoSnackBar;
  final TextEditingController _reviewMemoController = TextEditingController();

  // Focus nodes for cell navigation
  final Map<String, FocusNode> _focusNodes = {};
  final Map<String, TextEditingController> _controllers = {};

  TextEditingController _getController(int row, String col) {
    final key = '${row}_$col';
    if (!_controllers.containsKey(key)) {
      final r = _rows[row];
      _controllers[key] = TextEditingController(text: r.textOf(col));
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
    _rows[row].setText(col, formatted);
  }

  void _moveToNextCell(int currentRow, String currentCol) {
    if (currentCol == _colBs) {
      // BS → FS of same row
      _getFocusNode(currentRow, _colFs).requestFocus();
    } else if (currentCol == _colFs && _showDesignLevel) {
      // FS → Design of same row (when the design column is shown)
      _getFocusNode(currentRow, _colDesign).requestFocus();
    } else {
      // FS (or Design) → BS of next row
      final nextRow = currentRow + 1;
      if (nextRow < _rows.length) {
        _getFocusNode(nextRow, _colBs).requestFocus();
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
    _reductionMethod = widget.fieldBook.reductionMethod;
    _showDesignLevel = widget.fieldBook.showDesignLevel;
    _routeLength = widget.fieldBook.routeLength;
    _routeLengthController = TextEditingController(
      text: _routeLength == null ? '' : formatReadingText(_routeLength!),
    );
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
    _undoSnackBar?.close();
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
    _routeLengthController.dispose();
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
          designText: m.designLevel == null
              ? ''
              : formatReadingText(m.designLevel!),
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
    final inputs = [
      for (final row in _rows)
        LevelRunInput(bs: row.bs, fs: row.fs, manualTp: row.manualTp),
    ];
    final results = LevelRun.compute(_startElevation, inputs);
    final riseFall = LevelRun.riseFall(inputs);
    final setupHeights = setupHeightsOf([
      for (var i = 0; i < _rows.length; i++)
        (bs: _rows[i].bs, rl: results[i].gh),
    ]);
    for (int i = 0; i < _rows.length; i++) {
      final row = _rows[i];
      final result = results[i];
      row.isTP = result.isTP;
      row.ih = result.ih;
      row.gh = result.gh;
      row.riseFall = riseFall[i];
      row.setupHi = setupHeights[i];
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
          designLevel: row.design,
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
      reductionMethod: _reductionMethod,
      showDesignLevel: _showDesignLevel,
      routeLength: _routeLength,
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
                Navigator.pop(ctx);
                _removeRow(index);
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
      _removeRow(index);
    }
  }

  /// Removes the row and, when it had content, offers Undo in a snack bar.
  /// The deletion is autosaved like any edit, so undo re-inserts the same
  /// row object (texts, manual TP, design level) at the same position and
  /// saves again through the serialized save queue.
  void _removeRow(int index) {
    final removed = _rows[index];
    // Remove controllers and focus nodes for this row
    _disposeRowCells(index);
    setState(() => _rows.removeAt(index));
    // Rebuild controller/focus node keys
    _rebuildControllerKeys();
    _recalculate();
    _scheduleAutosave();
    if (removed.hasContent) _offerUndoDelete(index, removed);
  }

  void _offerUndoDelete(int index, _RowData row) {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    final controller = messenger.showSnackBar(
      SnackBar(
        key: const ValueKey('row-deleted-snackbar'),
        content: Text(l10n.fieldbookRowDeletedMessage),
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: l10n.fieldbookUndoAction,
          onPressed: () => _undoDelete(index, row),
        ),
      ),
    );
    _undoSnackBar = controller;
    controller.closed.then((_) {
      if (identical(_undoSnackBar, controller)) _undoSnackBar = null;
    });
  }

  void _undoDelete(int index, _RowData row) {
    if (!mounted) return;
    setState(() => _rows.insert(index.clamp(0, _rows.length), row));
    _rebuildControllerKeys();
    _recalculate();
    _scheduleAutosave();
    // Persist now rather than after the debounce: the deletion is already
    // saved, and the user may leave right after undoing.
    _saveToDb(silent: true).catchError((Object _) {});
  }

  void _disposeRowCells(int index) {
    for (final col in _inputColumns) {
      _controllers.remove('${index}_$col')?.dispose();
      _focusNodes.remove('${index}_$col')?.dispose();
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
          designText: row.designText,
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
      for (final col in _inputColumns) {
        final key = '${i}_$col';
        _controllers[key] = TextEditingController(text: _rows[i].textOf(col));
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
        method: _reductionMethod,
        routeLength: _routeLength,
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
                    Expanded(child: _buildTable()),
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
          // Flexible: longer labels (e.g. Spanish "Cota inicial") ellipsize
          // instead of squeezing the closing button off a narrow phone.
          Flexible(
            child: Text(
              context.l10n.fieldbookStartRlLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: onDarkMuted,
              ),
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
              inputFormatters: const [DecimalCommaFormatter()],
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
          Text(
            _tolerance.unit.symbol,
            style: TextStyle(fontSize: 14, color: onDarkMuted),
          ),
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
        unit: _tolerance.unit,
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

  Future<void> _applyReductionMethod(ReductionMethod method) async {
    if (method == _reductionMethod) return;
    final l10n = context.l10n;
    setState(() => _reductionMethod = method);
    try {
      await _container
          .read(fieldBookRepositoryProvider)
          .updateReductionMethod(_fieldBookWithReviewMetadata());
      _container.invalidate(fieldBookListProvider(widget.projectId));
    } catch (error) {
      if (mounted) {
        AppSnackbar.error(context, l10n.coreErrorWithDetail('$error'));
      }
    }
  }

  /// Shows/hides the Design / Cut-Fill columns. Only the flag is written
  /// (like the reduction method); design levels themselves are part of the
  /// rows and go through the serialized save queue. Hiding keeps them.
  Future<void> _applyShowDesignLevel(bool show) async {
    if (show == _showDesignLevel) return;
    final l10n = context.l10n;
    setState(() => _showDesignLevel = show);
    try {
      await _container
          .read(fieldBookRepositoryProvider)
          .updateShowDesignLevel(_fieldBookWithReviewMetadata());
      _container.invalidate(fieldBookListProvider(widget.projectId));
    } catch (error) {
      if (mounted) {
        AppSnackbar.error(context, l10n.coreErrorWithDetail('$error'));
      }
    }
  }

  /// Saves a typed route length (empty clears it); invalid text is ignored
  /// until it parses. Only the column is written, like the method/flag.
  Future<void> _applyRouteLength(String text) async {
    final trimmed = text.trim();
    final value = trimmed.isEmpty
        ? null
        : double.tryParse(trimmed.replaceAll(',', '.'));
    if (trimmed.isNotEmpty && !MisclosureTolerance.isValidRouteLength(value)) {
      return;
    }
    if (value == _routeLength) return;
    final l10n = context.l10n;
    setState(() => _routeLength = value);
    try {
      await _container
          .read(fieldBookRepositoryProvider)
          .updateRouteLength(_fieldBookWithReviewMetadata());
      _container.invalidate(fieldBookListProvider(widget.projectId));
    } catch (error) {
      if (mounted) {
        AppSnackbar.error(context, l10n.coreErrorWithDetail('$error'));
      }
    }
  }

  /// Route length input and, below it, the allowance with its numbers
  /// ('Tolerance ±10 mm·√2.40 km = ±15.5 mm') or the prompt to enter it.
  List<Widget> _toleranceFields() {
    final l10n = context.l10n;
    final colors = context.appColors;
    final tolerance = _tolerance;
    final closure = LevelClosureCheck.compute(
      _toMeasurements(),
      startElevation: _startElevation,
      closingElevation: _closingRl,
      tolerance: tolerance,
      method: _reductionMethod,
      routeLength: _routeLength,
    );
    final formula = closure.allowedFormula;
    final unavailable = tolerance.needsRouteLength && _routeLength == null;
    return [
      TextField(
        key: const ValueKey('route-length-field'),
        controller: _routeLengthController,
        inputFormatters: const [DecimalCommaFormatter()],
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: l10n.fieldbookRouteLengthLabel(tolerance.unit.routeSymbol),
          helperText: l10n.fieldbookRouteLengthHelper,
          helperMaxLines: 2,
        ),
        onChanged: _applyRouteLength,
      ),
      if (formula != null || unavailable) ...[
        const SizedBox(height: 6),
        Text(
          unavailable
              ? l10n.fieldbookIssueRouteLengthMissing
              : l10n.fieldbookToleranceFormula(formula!),
          key: const ValueKey('tolerance-formula'),
          style: TextStyle(
            fontSize: 12.5,
            color: unavailable ? colors.err : colors.subtext,
            fontFeatures: AppTypography.tabularFeatures,
          ),
        ),
      ],
    ];
  }

  bool get _isRiseFall => _reductionMethod == ReductionMethod.riseAndFall;

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
        // Capped so a long summary (large text, rise and fall) never
        // squeezes the title into a narrow column.
        trailing: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.5,
          ),
          child: Text(
            [
              if (_isRiseFall) _reductionMethod.localizedLabel(l10n),
              _reviewStatus.localizedLabel(l10n),
              if (reviewedAt != null)
                l10n.fieldbookReviewedOn(_formatDate(reviewedAt)),
            ].join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: TextStyle(fontSize: 13, color: colors.subtext),
          ),
        ),
        children: [
          // Capped and scrollable so the open panel never pushes the table
          // and the summary off a small screen.
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.3,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _reviewPanelFields(reviewedAt),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _reviewPanelFields(DateTime? reviewedAt) {
    final l10n = context.l10n;
    return [
      DropdownButtonFormField<FieldBookReviewStatus>(
        initialValue: _reviewStatus,
        decoration: InputDecoration(labelText: l10n.fieldbookReviewStatusLabel),
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
      const SizedBox(height: 12),
      ..._toleranceFields(),
      // Set once per book; changing it only changes the presentation.
      const SizedBox(height: 12),
      ReductionMethodSelector(
        value: _reductionMethod,
        onChanged: _applyReductionMethod,
        showHelp: true,
      ),
      const SizedBox(height: 4),
      SwitchListTile(
        key: const ValueKey('design-level-switch'),
        contentPadding: EdgeInsets.zero,
        value: _showDesignLevel,
        onChanged: _applyShowDesignLevel,
        title: Text(
          l10n.fieldbookDesignToggleLabel,
          style: const TextStyle(fontSize: 14),
        ),
        subtitle: Text(
          l10n.fieldbookDesignToggleHelp,
          style: TextStyle(fontSize: 12, color: context.appColors.subtext),
        ),
      ),
    ];
  }

  /// Header + rows. With the Design / Cut-Fill columns the table keeps at
  /// least [_designTableMinWidth] and scrolls horizontally on narrow phones;
  /// without them it fills the width exactly as before.
  Widget _buildTable() {
    Widget table() => Column(
      children: [
        _buildTableHeader(),
        Expanded(child: _buildTableBody()),
      ],
    );
    if (!_showDesignLevel) return table();
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= _designTableMinWidth) return table();
        return SingleChildScrollView(
          key: const ValueKey('design-table-scroll'),
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: _designTableMinWidth,
            height: constraints.maxHeight,
            child: table(),
          ),
        );
      },
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
          _headerCell(l10n.fieldbookColumnBs, flex: _flexValue),
          _headerCell(l10n.fieldbookColumnFs, flex: _flexValue),
          _headerCell(
            _isRiseFall ? l10n.fieldbookColumnRiseFall : l10n.fieldbookColumnHi,
            flex: _flexValue,
          ),
          _headerCell(l10n.fieldbookColumnRl, flex: _flexValue),
          if (_showDesignLevel) ...[
            _headerCell(l10n.fieldbookColumnDesign, flex: _flexDesign),
            _headerCell(l10n.fieldbookColumnCutFill, flex: _flexCutFill),
            _headerCell(l10n.fieldbookColumnTarget, flex: _flexTarget),
          ],
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
        padding: const EdgeInsets.symmetric(horizontal: 2),
        // Scales down instead of overflowing with large text settings.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            maxLines: 1,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
              color: colors.subtext,
              letterSpacing: 0.2,
            ),
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
            Expanded(flex: _flexValue, child: _editableCell(index, _colBs)),
            // FS
            Expanded(flex: _flexValue, child: _editableCell(index, _colFs)),
            // IH or rise(+)/fall(−) (read-only) — column-wide blue tint
            Expanded(
              flex: _flexValue,
              child: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 8),
                color: colors.blueSoft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: _isRiseFall
                      ? Text(
                          row.riseFall == null
                              ? ''
                              : formatRiseFall(row.riseFall!),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: (row.riseFall ?? 0) > 0
                                ? colors.green
                                : colors.blue,
                            fontFeatures: AppTypography.tabularFeatures,
                          ),
                        )
                      : Text(
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
            if (_showDesignLevel) ...[
              // Design level (editable, same input as BS/FS)
              Expanded(
                flex: _flexDesign,
                child: _editableCell(index, _colDesign),
              ),
              // Cut/fill (read-only)
              Expanded(flex: _flexCutFill, child: _cutFillCell(row)),
              // Stakeout target reading (read-only)
              Expanded(flex: _flexTarget, child: _targetCell(index, row)),
            ],
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
        key: ValueKey('cell-$rowIndex-$col'),
        controller: _getController(rowIndex, col),
        focusNode: _getFocusNode(rowIndex, col),
        style: TextStyle(
          fontSize: 14,
          color: colors.ink,
          fontFeatures: AppTypography.tabularFeatures,
        ),
        inputFormatters: const [DecimalCommaFormatter()],
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
          _rows[rowIndex].setText(col, v);
          // A design level never changes RLs; the cut/fill cell is redrawn
          // by the autosave's setState.
          if (col != _colDesign) _recalculate();
          _scheduleAutosave();
        },
        onSubmitted: (_) => _moveToNextCell(rowIndex, col),
      ),
    );
  }

  /// 'C 0.125' (cut, orange) / 'F 0.040' (fill, blue) / '0.000' (on grade).
  /// The letter carries the meaning; the colour only reinforces it.
  Widget _cutFillCell(_RowData row) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final value = row.cutFill;
    final kind = value == null ? null : cutFillKindOf(value);
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 8),
      color: colors.soft,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: Text(
          value == null
              ? ''
              : formatCutFill(
                  value,
                  cutLetter: l10n.fieldbookCutLetter,
                  fillLetter: l10n.fieldbookFillLetter,
                ),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: switch (kind) {
              CutFillKind.cut => colors.orange,
              CutFillKind.fill => colors.blue,
              _ => colors.subtext,
            },
            fontFeatures: AppTypography.tabularFeatures,
          ),
        ),
      ),
    );
  }

  /// Staff reading that puts the staff on design (HI in effect − design);
  /// blank before the first setup or without a design level.
  Widget _targetCell(int index, _RowData row) {
    final colors = context.appColors;
    final value = row.target;
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 8),
      color: colors.blueSoft,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: Text(
          value?.toStringAsFixed(3) ?? '',
          key: ValueKey('cell-$index-target'),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colors.blue,
            fontFeatures: AppTypography.tabularFeatures,
          ),
        ),
      ),
    );
  }

  Widget _buildSummary(MisclosureTolerance tolerance) {
    final closure = LevelClosureCheck.compute(
      _toMeasurements(),
      startElevation: _startElevation,
      closingElevation: _closingRl,
      tolerance: tolerance,
      method: _reductionMethod,
      routeLength: _routeLength,
    );
    final sums = closure.sums;
    final hasData = _rows.any((row) => row.gh != null);
    final colors = context.appColors;
    final l10n = context.l10n;
    Color judged(bool ok) => hasData && ok ? colors.green : colors.err;
    final misclosure = closure.misclosure;
    final riseFall = _isRiseFall ? closure.riseFall : null;

    // The dark panel runs to the screen edge (edge-to-edge); keep its text
    // clear of the navigation / gesture bar. paddingOf (not viewPadding) is
    // 0 while the keyboard is up, so the summary sitting on the keyboard gets
    // no extra gap.
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + bottomInset),
      color: colors.darkSurface,
      child: Column(
        children: [
          // Rise and fall: ΣRise / ΣFall / ΣRise − ΣFall as captions, so
          // the three-way check (ΣBS − ΣFS = ΣRise − ΣFall = Final − Start)
          // reads down the Diff column without taking another line.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _summaryItem(
                l10n.fieldbookSummarySumBs,
                sums.sumBs.toStringAsFixed(3),
                caption: riseFall == null
                    ? null
                    : l10n.fieldbookSummarySumRise(
                        riseFall.sumRise.toStringAsFixed(3),
                      ),
              ),
              _summaryItem(
                l10n.fieldbookSummarySumFs,
                sums.sumFs.toStringAsFixed(3),
                caption: riseFall == null
                    ? null
                    : l10n.fieldbookSummarySumFall(
                        riseFall.sumFall.toStringAsFixed(3),
                      ),
              ),
              _summaryItem(
                l10n.fieldbookSummaryDiff,
                sums.difference.toStringAsFixed(3),
                caption: riseFall == null
                    ? null
                    : l10n.fieldbookSummaryRiseMinusFall(
                        riseFall.difference.toStringAsFixed(3),
                      ),
                captionColor: riseFall == null
                    ? null
                    : judged(closure.riseFallOk),
                captionKey: const ValueKey('rise-fall-summary'),
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
                  caption: closure.allowed == null
                      ? l10n.fieldbookSummaryAllowedUnavailable
                      : l10n.fieldbookSummaryAllowed(
                          formatAllowedMisclosure(closure.allowed!),
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
          // One scrollable line (items needing attention first), so more
          // checks or large text never take rows away from the table.
          SingleChildScrollView(
            key: const ValueKey('validation-checklist'),
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final item in [
                  ...validation.checklist.where((item) => !item.passed),
                  ...validation.checklist.where((item) => item.passed),
                ]) ...[
                  SemanticPill(
                    label:
                        '${item.passed ? '✓' : '!'} ${item.check.localizedLabel(l10n)}',
                    variant: item.passed
                        ? SemanticPillVariant.green
                        : SemanticPillVariant.err,
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
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
    Color? captionColor,
    Key? captionKey,
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
              key: captionKey,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                height: 1.1,
                fontWeight: captionColor == null ? null : FontWeight.w700,
                color: captionColor ?? Colors.white.withValues(alpha: 0.55),
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
  final LengthUnit unit;

  const _ClosingReferenceSheet({
    required this.initialMode,
    required this.initialBmId,
    required this.initialElevation,
    required this.benchmarks,
    required this.unit,
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
      // Keyboard height when it is up, otherwise the navigation-bar inset
      // (padding drops to 0 while the keyboard covers it).
      padding: EdgeInsets.only(
        bottom:
            MediaQuery.viewInsetsOf(context).bottom +
            MediaQuery.paddingOf(context).bottom,
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
                              '${bm.name} (${bm.elevation.toStringAsFixed(3)}${widget.unit.symbol})',
                            ),
                          ),
                      ],
                      onChanged: (value) => setState(() => _bm = value),
                    ),
            if (_mode == ClosingReferenceMode.manual)
              TextField(
                controller: _elevationController,
                autofocus: true,
                inputFormatters: const [DecimalCommaFormatter()],
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                decoration: InputDecoration(
                  labelText: l10n.fieldbookClosingElevationLabel(
                    widget.unit.symbol,
                  ),
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
