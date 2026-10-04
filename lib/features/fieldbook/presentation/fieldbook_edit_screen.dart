import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/fieldbook_providers.dart';
import '../data/measurement_repository.dart';
import '../domain/fieldbook.dart';
import '../domain/measurement.dart';
import '../domain/measurement_validation.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/semantic_pill.dart';
import '../../benchmark/data/benchmark_repository.dart';
import '../../export/export_screen.dart';
import '../../quickmemo/presentation/quick_memo_fab.dart';
import '../../../core/utils/calculation.dart';

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
  String _saveStatus = '저장됨';
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
    setState(() => _saveStatus = '자동저장 대기');
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
          if (!_dirty) _saveStatus = silent ? '자동저장됨' : '저장됨';
        });
      },
      onError: (Object error, StackTrace stackTrace) {
        // Let the next flush (pop/dispose/pause) retry the failed edits.
        if (_queuedGeneration == generation) {
          _queuedGeneration = _savedGeneration;
        }
        if (mounted) setState(() => _saveStatus = '저장 실패');
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
      const SnackBar(
        content: Text('검토 정보를 저장했습니다'),
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
          title: const Text('행 삭제'),
          content: Text('${index + 1}번 행을 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('취소'),
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
              child: const Text('삭제'),
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
          stationName: row.stationName.isEmpty ? '' : '${row.stationName} 복사',
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
        title: const Text('측점명 수정'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: '측점명',
            hintText: '예: No.1, BM.1, TP.1',
            helperText: '비우면 행 번호(${index + 1})로 표시됩니다',
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
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              setState(() => _rows[index].stationName = controller.text.trim());
              _scheduleAutosave();
              Navigator.pop(ctx);
            },
            child: const Text('확인'),
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

  @override
  Widget build(BuildContext context) {
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
                tooltip: '빠른 메모',
                onPressed: () => showQuickMemoComposer(context),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: '10행 추가',
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
                tooltip: '저장',
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await _saveToDb();
                  if (mounted) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('저장 완료'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.ios_share),
                tooltip: '내보내기',
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
                    _buildValidationBar(),
                    _buildSummary(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildStartElevationBar() {
    final colors = context.appColors;
    const onDark = Colors.white;
    final onDarkMuted = Colors.white.withValues(alpha: 0.62);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: colors.darkSurface,
      child: Row(
        children: [
          Text(
            '시작 표고',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: onDarkMuted,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 140,
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
          const SizedBox(width: 8),
          Text('m', style: TextStyle(fontSize: 14, color: onDarkMuted)),
        ],
      ),
    );
  }

  Widget _buildReviewPanel() {
    final reviewedAt = _reviewedAt;
    final colors = context.appColors;
    return Material(
      color: colors.panel,
      shape: Border(bottom: BorderSide(color: colors.line)),
      child: ExpansionTile(
        controlAffinity: ListTileControlAffinity.leading,
        tilePadding: const EdgeInsets.fromLTRB(8, 0, 16, 0),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        title: Text('검토 정보', style: Theme.of(context).textTheme.titleSmall),
        trailing: Text(
          [
            _reviewStatus.label,
            if (reviewedAt != null) '검토일 ${_formatDate(reviewedAt)}',
          ].join(' · '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 13, color: colors.subtext),
        ),
        children: [
          DropdownButtonFormField<FieldBookReviewStatus>(
            initialValue: _reviewStatus,
            decoration: const InputDecoration(labelText: '검토 상태'),
            items: [
              for (final status in FieldBookReviewStatus.values)
                DropdownMenuItem(value: status, child: Text(status.label)),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _reviewStatus = value);
            },
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _reviewMemoController,
            decoration: const InputDecoration(
              labelText: '검토 메모',
              hintText: '예: 감리 확인 완료',
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
                        ? '오늘 검토일 적용'
                        : '검토일 ${_formatDate(reviewedAt)}',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _saveReviewMetadata,
                icon: const Icon(Icons.save_outlined),
                label: const Text('검토 정보 저장'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    final colors = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.soft,
        border: Border(bottom: BorderSide(color: colors.line, width: 1)),
      ),
      child: Row(
        children: [
          _headerCell('NO', flex: _flexNo),
          _headerCell('BS', flex: _flexValue),
          _headerCell('FS', flex: _flexValue),
          _headerCell('IH', flex: _flexValue),
          _headerCell('GH', flex: _flexValue),
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
                  tooltip: '행 작업',
                  onSelected: (value) {
                    if (value == 'insert') _insertRowBelow(index);
                    if (value == 'duplicate') _duplicateRow(index);
                    if (value == 'tp') _toggleManualTp(index);
                    if (value == 'delete') _deleteRow(index);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'insert',
                      child: Text('아래 행 삽입'),
                    ),
                    const PopupMenuItem(
                      value: 'duplicate',
                      child: Text('행 복제'),
                    ),
                    PopupMenuItem(
                      value: 'tp',
                      child: Text(row.manualTp ? '수동 TP 해제' : '수동 TP 지정'),
                    ),
                    const PopupMenuItem(value: 'delete', child: Text('삭제')),
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

  Widget _buildSummary() {
    double? firstGh, lastGh;
    for (final row in _rows) {
      if (row.gh != null) {
        firstGh ??= row.gh;
        lastGh = row.gh;
      }
    }

    final sums = LevelCheckSums.from(
      _toMeasurements(),
      startElevation: _startElevation,
    );
    final sumBs = sums.sumBs;
    final sumFs = sums.sumFs;
    final diff = sums.difference;
    final error = LevelClosure.error(
      _toMeasurements(),
      startElevation: _startElevation,
    );
    final colors = context.appColors;
    final errorColor = (firstGh != null && error.abs() < 0.001)
        ? colors.green
        : colors.err;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: colors.darkSurface,
      child: Column(
        children: [
          Row(
            children: [
              _summaryItem('ΣBS', sumBs.toStringAsFixed(3)),
              _summaryItem('ΣFS', sumFs.toStringAsFixed(3)),
              _summaryItem('차', diff.toStringAsFixed(3)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _summaryItem('시작', firstGh?.toStringAsFixed(3) ?? '-'),
              _summaryItem('최종', lastGh?.toStringAsFixed(3) ?? '-'),
              _summaryItem(
                '오차',
                error.toStringAsFixed(4),
                valueColor: errorColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildValidationBar() {
    final validation = MeasurementValidation.validate(
      measurements: _toMeasurements(),
      startElevation: _startElevation,
    );
    final isOk = validation.canExport;
    final colors = context.appColors;
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
                  isOk
                      ? '검산 ${validation.judgementLabel}'
                      : validation.messages.first,
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
                _saveStatus,
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
                  label: '${item.passed ? '✓' : '!'} ${item.label}',
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
          title: const Text('내보내기 전 확인'),
          content: Text(validation.messages.join('\n')),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
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
          title: const Text('허용오차 확인 필요'),
          content: Text(validation.messages.join('\n')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('계속'),
            ),
          ],
        ),
      );
      return proceed == true;
    }
    return true;
  }

  Widget _summaryItem(String label, String value, {Color? valueColor}) {
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
        ],
      ),
    );
  }

  Future<void> _export() async {
    await _saveToDb();
    final validation = MeasurementValidation.validate(
      measurements: _toMeasurements(),
      startElevation: _startElevation,
    );
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('내보낼 데이터가 없습니다')));
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
          ),
        ),
      );
    }
  }

  String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}
