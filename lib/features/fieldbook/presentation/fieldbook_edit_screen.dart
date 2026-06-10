import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/fieldbook_providers.dart';
import '../domain/fieldbook.dart';
import '../domain/measurement.dart';
import '../domain/measurement_validation.dart';
import '../../../core/theme/app_theme.dart';
import '../../benchmark/data/benchmark_repository.dart';
import '../../export/export_screen.dart';
import '../../../core/utils/calculation.dart';

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

class _FieldBookEditScreenState extends ConsumerState<FieldBookEditScreen> {
  final List<_RowData> _rows = [];
  double _startElevation = 0;
  bool _loaded = false;
  bool _dirty = false;
  String _saveStatus = '저장됨';
  Timer? _autosaveTimer;
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
    if (!_focusNodes.containsKey(key)) {
      _focusNodes[key] = FocusNode();
    }
    return _focusNodes[key]!;
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
    _reviewStatus = widget.fieldBook.reviewStatus;
    _reviewedAt = widget.fieldBook.reviewedAt;
    _reviewMemoController.text = widget.fieldBook.reviewMemo ?? '';
    _loadData();
  }

  @override
  void dispose() {
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
          bsText: m.bs?.toString() ?? '',
          fsText: m.fs?.toString() ?? '',
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
    double currentIH = 0;
    bool firstBsFound = false;

    for (int i = 0; i < _rows.length; i++) {
      final row = _rows[i];
      final bs = row.bs;
      final fs = row.fs;

      final isTP = firstBsFound && bs != null && fs != null;
      row.isTP = row.manualTp || isTP;

      if (!firstBsFound && bs == null && fs == null && i == 0) {
        // First row before any input: show start elevation as GH
        row.gh = _startElevation;
        row.ih = null;
      } else if (!firstBsFound && bs != null) {
        currentIH = LevelCalculation.calculateIH(_startElevation, bs);
        row.ih = currentIH;
        row.gh = _startElevation;
        firstBsFound = true;
      } else if (isTP) {
        row.gh = LevelCalculation.calculateGH(currentIH, fs);
        row.ih = LevelCalculation.calculateIH(row.gh!, bs);
        currentIH = row.ih!;
      } else if (firstBsFound && fs != null) {
        row.gh = LevelCalculation.calculateGH(currentIH, fs);
        row.ih = null;
      } else {
        row.ih = null;
        row.gh = null;
      }
    }
    setState(() {});
  }

  List<Measurement> _toMeasurements() {
    final measurements = <Measurement>[];
    var orderIndex = 0;
    for (final row in _rows) {
      if (!row.hasData) continue;
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
    _autosaveTimer?.cancel();
    setState(() => _saveStatus = '자동저장 대기');
    _autosaveTimer = Timer(const Duration(milliseconds: 900), () async {
      await _saveToDb(silent: true);
    });
  }

  Future<void> _saveToDb({bool silent = false}) async {
    final measRepo = ref.read(measurementRepositoryProvider);
    await measRepo.deleteByFieldBookId(widget.fieldBook.id!);

    for (final measurement in _toMeasurements()) {
      await measRepo.create(
        Measurement(
          fieldBookId: measurement.fieldBookId,
          orderIndex: measurement.orderIndex,
          stationName: measurement.stationName,
          type: measurement.type,
          bs: measurement.bs,
          fs: measurement.fs,
          ih: measurement.ih,
          gh: measurement.gh,
          manualTp: measurement.manualTp,
        ),
      );
    }
    _dirty = false;
    if (mounted) {
      setState(() => _saveStatus = silent ? '자동저장됨' : '저장됨');
    }
    ref.invalidate(measurementListProvider(widget.fieldBook.id!));
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
      startElevation: widget.fieldBook.startElevation,
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
    if (_rows[index].hasData) {
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
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
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
        _focusNodes[key] = FocusNode();
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
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _saveToDb();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.fieldBook.title),
          actions: [
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
    );
  }

  Widget _buildStartElevationBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: AppTheme.ink,
      child: Row(
        children: [
          Icon(Icons.straighten, size: 18, color: AppTheme.paper),
          const SizedBox(width: 8),
          Text(
            '시작 표고',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.paper.withValues(alpha: 0.78),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: TextFormField(
              initialValue: _startElevation.toStringAsFixed(3),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.paper,
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 4,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.5),
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
            'm',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.paper.withValues(alpha: 0.78),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewPanel() {
    final reviewedAt = _reviewedAt;
    return Material(
      color: AppTheme.panel,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        leading: const Icon(Icons.fact_check_outlined, size: 20),
        title: Text('검토 정보', style: Theme.of(context).textTheme.titleSmall),
        subtitle: Text(
          [
            _reviewStatus.label,
            if (reviewedAt != null) '검토일 ${_formatDate(reviewedAt)}',
          ].join(' · '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.panel,
        border: Border(bottom: BorderSide(color: AppTheme.line, width: 1.5)),
      ),
      child: Row(
        children: [
          _headerCell('NO', flex: 1),
          _headerCell('BS', flex: 2),
          _headerCell('FS', flex: 2),
          _headerCell('IH', flex: 2),
          _headerCell('GH', flex: 2),
          _headerCell('', flex: 1), // TP/비고
        ],
      ),
    );
  }

  Widget _headerCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Container(
        height: 36,
        alignment: Alignment.center,
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
    final isEven = index % 2 == 0;

    Color? bgColor;
    if (row.isTP) {
      bgColor = AppTheme.surveyOrange.withValues(alpha: 0.1);
    } else if (row.hasData) {
      bgColor = isEven ? AppTheme.panel : const Color(0xFFFCFBF7);
    } else {
      bgColor = isEven ? AppTheme.panel : AppTheme.paper;
    }

    return GestureDetector(
      onLongPress: () => _deleteRow(index),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(
            bottom: BorderSide(
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            // NO / 측점명
            Expanded(
              flex: 1,
              child: GestureDetector(
                onTap: () => _editStationName(index),
                child: Center(
                  child: Text(
                    row.stationName.isEmpty ? '${index + 1}' : row.stationName,
                    style: TextStyle(
                      fontSize: 13,
                      color: row.stationName.isEmpty
                          ? const Color(0xFF8A8276)
                          : AppTheme.fieldGreen,
                      fontWeight: row.stationName.isEmpty
                          ? FontWeight.normal
                          : FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            // BS
            Expanded(flex: 2, child: _editableCell(index, 'bs')),
            // FS
            Expanded(flex: 2, child: _editableCell(index, 'fs')),
            // IH (read-only)
            Expanded(
              flex: 2,
              child: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  row.ih?.toStringAsFixed(3) ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.datumBlue,
                  ),
                ),
              ),
            ),
            // GH (read-only)
            Expanded(
              flex: 2,
              child: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  row.gh?.toStringAsFixed(3) ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.fieldGreen,
                  ),
                ),
              ),
            ),
            // TP indicator and row actions
            Expanded(
              flex: 1,
              child: Center(
                child: PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: row.isTP
                      ? const Icon(
                          Icons.flag,
                          size: 18,
                          color: AppTheme.surveyOrange,
                        )
                      : const Icon(Icons.more_vert, size: 18),
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
    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
      ),
      child: TextField(
        controller: _getController(rowIndex, col),
        focusNode: _getFocusNode(rowIndex, col),
        style: const TextStyle(fontSize: 14),
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
    double sumBs = 0, sumFs = 0;
    double? firstGh, lastGh;

    for (final row in _rows) {
      if (row.bs != null) sumBs += row.bs!;
      if (row.fs != null) sumFs += row.fs!;
      if (row.gh != null) {
        firstGh ??= row.gh;
        lastGh = row.gh;
      }
    }

    final diff = sumBs - sumFs;
    final ghDiff = (firstGh != null && lastGh != null) ? lastGh - firstGh : 0.0;
    final error = diff - ghDiff;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.panel,
        border: Border(top: BorderSide(color: AppTheme.line, width: 1.5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _summaryChip('ΣBS', sumBs.toStringAsFixed(3)),
              _summaryChip('ΣFS', sumFs.toStringAsFixed(3)),
              _summaryChip('차', diff.toStringAsFixed(3)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              _summaryChip('시작', firstGh?.toStringAsFixed(3) ?? '-'),
              _summaryChip('최종', lastGh?.toStringAsFixed(3) ?? '-'),
              _summaryChip(
                '오차',
                error.toStringAsFixed(4),
                color: (firstGh != null && error.abs() < 0.001)
                    ? AppTheme.fieldGreen
                    : Theme.of(context).colorScheme.error,
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      color: isOk
          ? AppTheme.fieldGreen.withValues(alpha: 0.1)
          : Theme.of(context).colorScheme.errorContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isOk ? Icons.check_circle_outline : Icons.error_outline,
                size: 18,
                color: isOk
                    ? AppTheme.fieldGreen
                    : Theme.of(context).colorScheme.onErrorContainer,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isOk
                      ? '검산 ${validation.judgementLabel} · $_saveStatus'
                      : '${validation.messages.first} · $_saveStatus',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: isOk
                        ? AppTheme.fieldGreen
                        : Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
              if (_dirty)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 2,
            children: [
              for (final item in validation.checklist)
                Text(
                  '${item.passed ? '✓' : '!'} ${item.label}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: item.passed
                        ? AppTheme.fieldGreen
                        : Theme.of(context).colorScheme.onErrorContainer,
                  ),
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

  Widget _summaryChip(String label, String value, {Color? color}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label ',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
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
    final measRepo = ref.read(measurementRepositoryProvider);
    final measurements = await measRepo.getByFieldBookId(widget.fieldBook.id!);

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
