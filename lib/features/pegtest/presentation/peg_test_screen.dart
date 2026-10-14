import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/semantic_pill.dart';
import '../../../l10n/l10n.dart';
import '../../fieldbook/domain/misclosure.dart';
import '../../settings/misclosure_tolerance_repository.dart';
import '../data/peg_test_record_repository.dart';
import '../data/peg_test_settings_repository.dart';
import '../domain/peg_test_record.dart';
import '../domain/two_peg_test.dart';
import 'peg_test_history_screen.dart';

/// Two-peg test calculator: live result while typing, last inputs and the
/// allowance persisted in `app_settings`. A result can be saved as a record
/// (`peg_tests`) with optional instrument / observer / note.
class PegTestScreen extends ConsumerStatefulWidget {
  const PegTestScreen({super.key});

  @override
  ConsumerState<PegTestScreen> createState() => _PegTestScreenState();
}

class _PegTestScreenState extends ConsumerState<PegTestScreen> {
  static const _saveDelay = Duration(milliseconds: 600);

  final _controllers = {
    for (final field in PegTestField.values) field: TextEditingController(),
  };
  final _recordControllers = {
    for (final field in PegTestRecordField.values)
      field: TextEditingController(),
  };
  late final PegTestSettingsRepository _repository;
  bool _saving = false;
  PegTestSettings _settings = const PegTestSettings();
  Timer? _saveTimer;
  bool _inputsDirty = false;

  @override
  void initState() {
    super.initState();
    _repository = ref.read(pegTestSettingsRepositoryProvider);
    for (final controller in [
      ..._controllers.values,
      ..._recordControllers.values,
    ]) {
      controller.addListener(_onInputChanged);
    }
    _restore();
  }

  Future<void> _restore() async {
    final PegTestSettings settings;
    try {
      settings = await _repository.load();
    } catch (_) {
      return; // Defaults are fine; the screen works without storage.
    }
    if (!mounted) return;
    setState(() => _settings = settings);
    // Only fill fields the user has not started typing in.
    for (final field in PegTestField.values) {
      final saved = settings.inputs[field.name];
      final controller = _controllers[field]!;
      if (saved != null && controller.text.isEmpty) controller.text = saved;
    }
    for (final field in PegTestRecordField.values) {
      final saved = settings.inputs[field.name];
      final controller = _recordControllers[field]!;
      if (saved != null && controller.text.isEmpty) controller.text = saved;
    }
    _inputsDirty = false;
    _saveTimer?.cancel();
    await _prefillRecordDetails(settings);
  }

  /// Quick reuse: never-typed instrument / observer start from the latest
  /// saved test or field book.
  Future<void> _prefillRecordDetails(PegTestSettings settings) async {
    final missing = [
      PegTestRecordField.instrument,
      PegTestRecordField.observer,
    ].where((field) => settings.inputs[field.name] == null).toList();
    if (missing.isEmpty) return;
    final PegTestMetadata metadata;
    try {
      metadata = await ref.read(pegTestRecordRepositoryProvider).lastMetadata();
    } catch (_) {
      return;
    }
    if (!mounted) return;
    for (final field in missing) {
      final value = field == PegTestRecordField.instrument
          ? metadata.instrument
          : metadata.observer;
      final controller = _recordControllers[field]!;
      if (value != null && controller.text.isEmpty) controller.text = value;
    }
    _inputsDirty = false;
    _saveTimer?.cancel();
  }

  void _onInputChanged() {
    setState(() {});
    _inputsDirty = true;
    _saveTimer?.cancel();
    _saveTimer = Timer(_saveDelay, _saveInputs);
  }

  void _saveInputs() {
    if (!_inputsDirty) return;
    _inputsDirty = false;
    _repository
        .saveInputs({
          for (final entry in _controllers.entries)
            entry.key.name: entry.value.text,
          for (final entry in _recordControllers.entries)
            entry.key.name: entry.value.text,
        })
        .catchError((_) {});
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _saveInputs();
    for (final controller in [
      ..._controllers.values,
      ..._recordControllers.values,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String _text(PegTestField field) => _controllers[field]!.text;

  String _recordText(PegTestRecordField field) =>
      _recordControllers[field]!.text;

  TwoPegTest? _compute(LengthUnit unit) => TwoPegTest.tryParse(
    a1: _text(PegTestField.a1),
    b1: _text(PegTestField.b1),
    a2: _text(PegTestField.a2),
    b2: _text(PegTestField.b2),
    pegDistance: _text(PegTestField.distance),
    unit: unit,
    toleranceEntry: _settings.toleranceFor(unit),
  );

  Future<void> _editTolerance(LengthUnit unit) async {
    final l10n = context.l10n;
    final value = await showDialog<double>(
      context: context,
      builder: (_) => PegTestToleranceDialog(
        unit: unit,
        initial: _settings.toleranceFor(unit),
      ),
    );
    if (value == null || !mounted) return;
    try {
      await _repository.saveTolerance(unit, value);
      if (!mounted) return;
      setState(() {
        _settings = PegTestSettings(
          toleranceMm: unit == LengthUnit.metres
              ? value
              : _settings.toleranceMm,
          toleranceFt: unit == LengthUnit.feet ? value : _settings.toleranceFt,
          inputs: _settings.inputs,
        );
      });
      AppSnackbar.success(context, l10n.coreSaved);
    } catch (error) {
      if (mounted) {
        AppSnackbar.error(context, l10n.coreErrorWithDetail('$error'));
      }
    }
  }

  Future<void> _copyResult(TwoPegTest test) async {
    final l10n = context.l10n;
    await Clipboard.setData(
      ClipboardData(text: buildPegTestSummary(l10n, test, DateTime.now())),
    );
    if (mounted) AppSnackbar.success(context, l10n.pegTestCopied);
  }

  Future<void> _saveRecord(TwoPegTest test) async {
    if (_saving) return;
    final l10n = context.l10n;
    setState(() => _saving = true);
    try {
      await ref
          .read(pegTestRecordListProvider.notifier)
          .add(
            PegTestRecord.fromTest(
              test,
              instrument: _recordText(PegTestRecordField.instrument),
              observer: _recordText(PegTestRecordField.observer),
              note: _recordText(PegTestRecordField.note),
            ),
          );
      if (!mounted) return;
      // The note belongs to this record; instrument / observer carry over.
      _recordControllers[PegTestRecordField.note]!.clear();
      AppSnackbar.success(context, l10n.pegTestRecordSaved);
    } catch (error) {
      if (mounted) {
        AppSnackbar.error(context, l10n.coreErrorWithDetail('$error'));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PegTestHistoryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final unit = ref.watch(lengthUnitProvider);
    final test = _compute(unit);
    final distance = TwoPegTest.parseNumber(_text(PegTestField.distance));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.pegTestTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: l10n.pegTestHistoryTooltip,
            onPressed: _openHistory,
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
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text(
              l10n.pegTestSubtitle,
              style: TextStyle(fontSize: 13.5, color: colors.subtext),
            ),
          ),
          const _HowToCard(),
          const SizedBox(height: 12),
          _InputGroup(
            title: l10n.pegTestSetup1Title,
            children: [
              _ReadingRow(
                a: _NumberField(
                  key: const ValueKey('peg-test-a1'),
                  controller: _controllers[PegTestField.a1]!,
                  label: l10n.pegTestReadingALabel(unit.symbol),
                ),
                b: _NumberField(
                  key: const ValueKey('peg-test-b1'),
                  controller: _controllers[PegTestField.b1]!,
                  label: l10n.pegTestReadingBLabel(unit.symbol),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InputGroup(
            title: l10n.pegTestSetup2Title,
            children: [
              _ReadingRow(
                a: _NumberField(
                  key: const ValueKey('peg-test-a2'),
                  controller: _controllers[PegTestField.a2]!,
                  label: l10n.pegTestReadingALabel(unit.symbol),
                ),
                b: _NumberField(
                  key: const ValueKey('peg-test-b2'),
                  controller: _controllers[PegTestField.b2]!,
                  label: l10n.pegTestReadingBLabel(unit.symbol),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _InputGroup(
            children: [
              _NumberField(
                key: const ValueKey('peg-test-distance'),
                controller: _controllers[PegTestField.distance]!,
                label: l10n.pegTestDistanceLabel(unit.symbol),
                errorText: distance != null && distance <= 0
                    ? l10n.pegTestDistanceInvalid
                    : null,
                last: true,
              ),
              const SizedBox(height: 4),
              ListTile(
                key: const ValueKey('peg-test-tolerance'),
                contentPadding: const EdgeInsets.only(left: 4),
                leading: const Icon(Icons.straighten),
                title: Text(l10n.pegTestToleranceLabel),
                subtitle: Text(
                  l10n.pegTestToleranceValue(
                    formatToleranceValue(_settings.toleranceFor(unit)),
                    unit.toleranceSymbol,
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: l10n.pegTestToleranceEditTooltip,
                  onPressed: () => _editTolerance(unit),
                ),
                onTap: () => _editTolerance(unit),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _RecordDetailsCard(controllers: _recordControllers),
          const SizedBox(height: 12),
          PegTestResultCard(
            test: test,
            unit: unit,
            onCopy: test == null ? null : () => _copyResult(test),
            showSave: true,
            onSave: test == null || _saving ? null : () => _saveRecord(test),
          ),
        ],
      ),
    );
  }
}

/// Signed text with [decimals] decimals; never '-0.0'. Not locale-formatted.
String formatSigned(double value, int decimals) {
  final fixed = value.toStringAsFixed(decimals);
  if (double.parse(fixed) == 0) return 0.toStringAsFixed(decimals);
  return value > 0 ? '+$fixed' : fixed;
}

/// Collimation error (reading unit) as shown: mm with 1 decimal for metres
/// ('+5.0 mm'), ft with 4 decimals for feet ('+0.0150 ft', like
/// [formatMisclosure]).
String formatPegTestError(double error, LengthUnit unit) =>
    unit == LengthUnit.metres
    ? '${formatSigned(error * 1000, 1)} mm'
    : '${formatMisclosure(error)} ft';

/// Reading with its unit: '1.115 m'.
String formatPegTestReading(double value, LengthUnit unit) =>
    '${value.toStringAsFixed(3)} ${unit.symbol}';

/// Angle in arc-seconds: '+25.8″'.
String formatArcSeconds(double seconds) => '${formatSigned(seconds, 1)}″';

String pegTestVerdict(AppLocalizations l10n, TwoPegTest test) =>
    test.withinTolerance
    ? l10n.coreJudgementWithinTolerance
    : l10n.pegTestAdjustmentRequired;

/// Plain-text summary for the clipboard (date, inputs, results, verdict).
String buildPegTestSummary(
  AppLocalizations l10n,
  TwoPegTest test,
  DateTime now,
) {
  final unit = test.unit;
  String reading(double value) => formatPegTestReading(value, unit);
  String line(String label, String value) =>
      l10n.pegTestSummaryLine(label, value);
  return [
    '${l10n.pegTestTitle} · ${DateFormat('yyyy-MM-dd HH:mm').format(now)}',
    l10n.pegTestSummarySetup1(reading(test.a1), reading(test.b1)),
    l10n.pegTestSummarySetup2(reading(test.a2), reading(test.b2)),
    line(
      l10n.pegTestDistanceLabel(unit.symbol),
      test.pegDistance.toStringAsFixed(3),
    ),
    line(
      l10n.pegTestTrueDifference,
      '${formatSigned(test.trueDifference, 3)} ${unit.symbol}',
    ),
    line(l10n.pegTestCollimationError, formatPegTestError(test.error, unit)),
    line(
      l10n.pegTestErrorPer100(unit.symbol),
      formatPegTestError(test.errorPer100, unit),
    ),
    line(l10n.pegTestAngle, formatArcSeconds(test.arcSeconds)),
    line(
      l10n.pegTestToleranceLabel,
      '±${formatToleranceValue(test.toleranceEntry)} ${unit.toleranceSymbol}',
    ),
    line(l10n.pegTestSummaryResult, pegTestVerdict(l10n, test)),
    line(l10n.pegTestCorrectReading, reading(test.expectedB2)),
  ].join('\n');
}

/// Edits the allowance in mm (metres) or ft (feet); pops the value.
class PegTestToleranceDialog extends StatefulWidget {
  final LengthUnit unit;
  final double initial;

  const PegTestToleranceDialog({
    super.key,
    required this.unit,
    required this.initial,
  });

  @override
  State<PegTestToleranceDialog> createState() => _PegTestToleranceDialogState();
}

class _PegTestToleranceDialogState extends State<PegTestToleranceDialog> {
  late final _controller = TextEditingController(
    text: formatToleranceValue(widget.initial),
  );
  bool _showErrors = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double? get _value =>
      MisclosureTolerance.parseEntry(_controller.text, widget.unit);

  void _submit() {
    final value = _value;
    if (value == null) {
      setState(() => _showErrors = true);
      return;
    }
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final symbol = widget.unit.toleranceSymbol;
    return AlertDialog(
      title: Text(l10n.pegTestToleranceDialogTitle),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: l10n.pegTestToleranceFieldLabel(symbol),
          errorText: _showErrors && _value == null
              ? l10n.settingsToleranceInvalid(
                  formatToleranceValue(
                    MisclosureTolerance.minEntry(widget.unit),
                  ),
                  formatToleranceValue(
                    MisclosureTolerance.maxEntry(widget.unit),
                  ),
                  symbol,
                )
              : null,
        ),
        onChanged: (_) {
          if (_showErrors) setState(() {});
        },
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.coreCancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.coreSave)),
      ],
    );
  }
}

class _HowToCard extends StatelessWidget {
  const _HowToCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final steps = [
      l10n.pegTestHowToStep1,
      l10n.pegTestHowToStep2,
      l10n.pegTestHowToStep3,
      l10n.pegTestHowToStep4,
    ];
    return Material(
      color: colors.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: const Icon(Icons.help_outline),
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(
          l10n.pegTestHowToTitle,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          for (final (index, step) in steps.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 22,
                    child: Text(
                      '${index + 1}.',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: colors.blue,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(step, style: TextStyle(color: colors.body)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Collapsed instrument / observer / note fields for a saved record.
class _RecordDetailsCard extends StatelessWidget {
  final Map<PegTestRecordField, TextEditingController> controllers;

  const _RecordDetailsCard({required this.controllers});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final filled = [PegTestRecordField.instrument, PegTestRecordField.observer]
        .map((field) => controllers[field]!.text.trim())
        .where((t) => t.isNotEmpty);
    Widget field(PegTestRecordField field, String label, {bool last = false}) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: TextField(
            key: ValueKey('peg-test-${field.name}'),
            controller: controllers[field],
            textInputAction: last ? TextInputAction.done : TextInputAction.next,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        );
    return Material(
      color: colors.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        key: const ValueKey('peg-test-record-details'),
        leading: const Icon(Icons.badge_outlined),
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(
          l10n.pegTestRecordDetailsTitle,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        subtitle: Text(
          filled.isEmpty ? l10n.pegTestRecordDetailsHint : filled.join(' · '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12.5, color: colors.subtext),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
        children: [
          field(PegTestRecordField.instrument, l10n.pegTestInstrumentLabel),
          field(PegTestRecordField.observer, l10n.pegTestObserverLabel),
          field(PegTestRecordField.note, l10n.pegTestNoteLabel, last: true),
        ],
      ),
    );
  }
}

class _InputGroup extends StatelessWidget {
  final String? title;
  final List<Widget> children;

  const _InputGroup({this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    // Material (not a decorated Container) so the tolerance ListTile's ink
    // shows on the panel.
    return Material(
      color: colors.panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colors.subtext,
                ),
              ),
              const SizedBox(height: 10),
            ],
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ReadingRow extends StatelessWidget {
  final Widget a;
  final Widget b;

  const _ReadingRow({required this.a, required this.b});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: a),
        const SizedBox(width: 10),
        Expanded(child: b),
      ],
    );
  }
}

/// Large numeric field for gloved / outdoor use.
class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? errorText;
  final bool last;

  const _NumberField({
    super.key,
    required this.controller,
    required this.label,
    this.errorText,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: last ? TextInputAction.done : TextInputAction.next,
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: colors.ink,
        fontFeatures: AppTypography.tabularFeatures,
      ),
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
    );
  }
}

/// Result of a two-peg test (live on the calculator, read-only on a saved
/// record). [showSave] adds the "Save record" button, enabled by [onSave].
class PegTestResultCard extends StatelessWidget {
  final TwoPegTest? test;
  final LengthUnit unit;
  final VoidCallback? onCopy;
  final bool showSave;
  final VoidCallback? onSave;

  const PegTestResultCard({
    super.key,
    required this.test,
    required this.unit,
    required this.onCopy,
    this.showSave = false,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final test = this.test;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: test == null
              ? colors.line
              : test.withinTolerance
              ? colors.green
              : colors.orange,
          width: test == null ? 1 : 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.pegTestResultTitle,
                  style: textTheme.titleMedium,
                ),
              ),
              if (test != null)
                SemanticPill(
                  key: const ValueKey('peg-test-verdict'),
                  label: pegTestVerdict(l10n, test),
                  variant: test.withinTolerance
                      ? SemanticPillVariant.green
                      : SemanticPillVariant.orange,
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (test == null)
            Text(
              l10n.pegTestResultEmpty,
              style: TextStyle(color: colors.subtext),
            )
          else ...[
            _ResultRow(
              label: l10n.pegTestTrueDifference,
              value: '${formatSigned(test.trueDifference, 3)} ${unit.symbol}',
            ),
            _ResultRow(
              label: l10n.pegTestCollimationError,
              value: formatPegTestError(test.error, unit),
              emphasized: true,
            ),
            _ResultRow(
              label: l10n.pegTestErrorPer100(unit.symbol),
              value: formatPegTestError(test.errorPer100, unit),
            ),
            _ResultRow(
              label: l10n.pegTestAngle,
              value: formatArcSeconds(test.arcSeconds),
            ),
            if (test.error.abs() > toleranceEpsilon)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  test.error > 0
                      ? l10n.pegTestInclinedUp
                      : l10n.pegTestInclinedDown,
                  style: TextStyle(fontSize: 12.5, color: colors.subtext),
                ),
              ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: test.withinTolerance
                    ? colors.greenSoft
                    : colors.orangeSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.pegTestCorrectReading,
                    style: TextStyle(fontSize: 13, color: colors.subtext),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatPegTestReading(test.expectedB2, unit),
                    key: const ValueKey('peg-test-correct-reading'),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: colors.ink,
                      fontFeatures: AppTypography.tabularFeatures,
                    ),
                  ),
                  if (!test.withinTolerance) ...[
                    const SizedBox(height: 4),
                    Text(
                      l10n.pegTestAdjustInstruction(
                        test.expectedB2.toStringAsFixed(3),
                        unit.symbol,
                      ),
                      style: TextStyle(color: colors.body),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (showSave)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCopy,
                    icon: const Icon(Icons.copy),
                    label: Text(l10n.pegTestCopyResult),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    key: const ValueKey('peg-test-save-record'),
                    onPressed: onSave,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(l10n.pegTestSaveRecord),
                  ),
                ),
              ],
            )
          else
            OutlinedButton.icon(
              onPressed: onCopy,
              icon: const Icon(Icons.copy),
              label: Text(l10n.pegTestCopyResult),
            ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasized;

  const _ResultRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label, style: TextStyle(color: colors.body)),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: emphasized ? 18 : 15,
              fontWeight: emphasized ? FontWeight.w700 : FontWeight.w600,
              color: colors.ink,
              fontFeatures: AppTypography.tabularFeatures,
            ),
          ),
        ],
      ),
    );
  }
}
