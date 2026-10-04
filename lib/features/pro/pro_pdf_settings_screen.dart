import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../l10n/l10n.dart';
import '../export/export_history_repository.dart';
import '../fieldbook/domain/fieldbook.dart';
import 'pro_pdf_settings.dart';
import 'pro_providers.dart';
import 'signature_pad_dialog.dart';
import '../../core/constants/app_constants.dart';

class ProPdfSettingsScreen extends ConsumerStatefulWidget {
  const ProPdfSettingsScreen({super.key});

  @override
  ConsumerState<ProPdfSettingsScreen> createState() =>
      _ProPdfSettingsScreenState();
}

class _ProPdfSettingsScreenState extends ConsumerState<ProPdfSettingsScreen> {
  final _companyController = TextEditingController();
  final _authorController = TextEditingController();
  final _watermarkController = TextEditingController();
  final _footerNoteController = TextEditingController();
  bool _includeCheckJudgement = true;
  bool _includeSignatureLines = true;
  ProDocumentTemplate _documentTemplate = ProDocumentTemplate.basic;
  ProFileNamePattern _fileNamePattern = ProFileNamePattern.titleOnly;
  String _signaturePng = '';
  String? _activePresetId;
  bool _loaded = false;

  @override
  void dispose() {
    _companyController.dispose();
    _authorController.dispose();
    _watermarkController.dispose();
    _footerNoteController.dispose();
    super.dispose();
  }

  void _applyPresets(ProDocumentPresets presets) {
    if (_loaded && _activePresetId == presets.activePresetId) return;
    _activePresetId = presets.activePresetId;
    _applySettings(presets.active.settings);
    _loaded = true;
  }

  void _applySettings(ProPdfSettings settings) {
    _companyController.text = settings.companyName;
    _authorController.text = settings.authorName;
    _watermarkController.text = settings.watermarkText;
    _footerNoteController.text = settings.footerNote;
    _includeCheckJudgement = settings.includeCheckJudgement;
    _includeSignatureLines = settings.includeSignatureLines;
    _documentTemplate = settings.documentTemplate;
    _fileNamePattern = settings.fileNamePattern;
    _signaturePng = settings.signaturePng;
  }

  @override
  Widget build(BuildContext context) {
    final presetsAsync = ref.watch(proDocumentPresetsProvider);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.proPdfSettingsTitle)),
      bottomNavigationBar: _buildFooter(),
      body: presetsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text(l10n.proPdfLoadError('$error'))),
        data: (presets) {
          _applyPresets(presets);

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              AppConstants.quickMemoFabClearance,
            ),
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: presets.active.id,
                      decoration: InputDecoration(
                        labelText: l10n.proPdfPresetLabel,
                        prefixIcon: const Icon(Icons.tune_outlined),
                      ),
                      items: presets.presets
                          .map(
                            (preset) => DropdownMenuItem(
                              value: preset.id,
                              child: Text(preset.displayName(l10n)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          _selectPreset(value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: () => _createPreset(presets.active.settings),
                    tooltip: l10n.proPdfPresetAdd,
                    icon: const Icon(Icons.add),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: () => _renamePreset(presets.active),
                    tooltip: l10n.proPdfPresetRename,
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: presets.presets.length > 1
                        ? () => _deletePreset(presets.active.id)
                        : null,
                    tooltip: l10n.proPdfPresetDeleteTooltip,
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _companyController,
                decoration: InputDecoration(
                  labelText: l10n.proPdfCompanyLabel,
                  hintText: l10n.proPdfCompanyHint,
                  prefixIcon: const Icon(Icons.business),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _authorController,
                decoration: InputDecoration(
                  labelText: l10n.proPdfAuthorLabel,
                  hintText: l10n.proPdfAuthorHint,
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ProDocumentTemplate>(
                initialValue: _documentTemplate,
                decoration: InputDecoration(
                  labelText: l10n.proPdfTemplateLabel,
                  prefixIcon: const Icon(Icons.description_outlined),
                ),
                items: ProDocumentTemplate.values
                    .map(
                      (template) => DropdownMenuItem(
                        value: template,
                        child: Text(template.label(l10n)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _documentTemplate = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ProFileNamePattern>(
                initialValue: _fileNamePattern,
                decoration: InputDecoration(
                  labelText: l10n.proPdfFileNameRuleLabel,
                  prefixIcon: const Icon(Icons.drive_file_rename_outline),
                ),
                items: ProFileNamePattern.values
                    .map(
                      (pattern) => DropdownMenuItem(
                        value: pattern,
                        child: Text(pattern.label(l10n)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _fileNamePattern = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _watermarkController,
                decoration: InputDecoration(
                  labelText: l10n.proPdfWatermarkLabel,
                  hintText: l10n.proPdfWatermarkHint,
                  prefixIcon: const Icon(Icons.water_drop_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _footerNoteController,
                decoration: InputDecoration(
                  labelText: l10n.proPdfFooterNoteLabel,
                  hintText: l10n.proPdfFooterNoteHint,
                  prefixIcon: const Icon(Icons.notes_outlined),
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.fact_check_outlined),
                title: Text(l10n.proPdfShowJudgementTitle),
                subtitle: Text(l10n.proPdfShowJudgementSubtitle),
                value: _includeCheckJudgement,
                onChanged: (value) =>
                    setState(() => _includeCheckJudgement = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.draw_outlined),
                title: Text(l10n.proPdfSignatureLinesTitle),
                subtitle: Text(l10n.proPdfSignatureLinesSubtitle),
                value: _includeSignatureLines,
                onChanged: (value) =>
                    setState(() => _includeSignatureLines = value),
              ),
              if (_includeSignatureLines) _buildSignatureCard(),
              const SizedBox(height: 12),
              _FilenamePreview(settings: _currentSettings()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFooter() {
    final colors = context.appColors;
    final l10n = context.l10n;
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: OutlinedButton.icon(
                  onPressed: _showExportHistory,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                  ),
                  icon: const Icon(Icons.history),
                  label: Text(l10n.proPdfExportHistory),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: FilledButton.icon(
                  onPressed: _save,
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                  icon: const Icon(Icons.save),
                  label: Text(l10n.coreSave),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignatureCard() {
    final colors = context.appColors;
    final l10n = context.l10n;
    final hasSignature = _signaturePng.trim().isNotEmpty;
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.gesture, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.proPdfSignatureTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l10n.proPdfSignatureDescription,
              style: TextStyle(fontSize: 12, color: colors.subtext),
            ),
            const SizedBox(height: 8),
            if (hasSignature)
              Container(
                height: 80,
                width: double.infinity,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Image.memory(
                  base64Decode(_signaturePng),
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) =>
                      Center(child: Text(l10n.proPdfSignatureDisplayError)),
                ),
              )
            else
              Container(
                height: 80,
                width: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  l10n.proPdfSignatureEmpty,
                  style: TextStyle(color: colors.subtext),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _captureSignature,
                    icon: const Icon(Icons.edit, size: 18),
                    label: Text(
                      hasSignature
                          ? l10n.proPdfSignatureRedo
                          : l10n.proPdfSignatureRegister,
                    ),
                  ),
                ),
                if (hasSignature) ...[
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _signaturePng = ''),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.err,
                      side: BorderSide(color: colors.err),
                    ),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: Text(l10n.coreDelete),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _captureSignature() async {
    final result = await SignaturePadDialog.show(context);
    if (result == null || !mounted) return;
    setState(() => _signaturePng = result);
  }

  Future<void> _save() async {
    final settings = _currentSettings();

    await ref.read(proSettingsRepositoryProvider).savePdfSettings(settings);
    ref.invalidate(proDocumentPresetsProvider);
    ref.invalidate(proPdfSettingsProvider);

    if (!mounted) return;
    AppSnackbar.success(context, context.l10n.proPdfSavedMessage);
  }

  ProPdfSettings _currentSettings() {
    return ProPdfSettings(
      companyName: _companyController.text,
      authorName: _authorController.text,
      includeCheckJudgement: _includeCheckJudgement,
      includeSignatureLines: _includeSignatureLines,
      documentTemplate: _documentTemplate,
      watermarkText: _watermarkController.text,
      footerNote: _footerNoteController.text,
      fileNamePattern: _fileNamePattern,
      signaturePng: _signaturePng,
    );
  }

  Future<void> _selectPreset(String presetId) async {
    await ref.read(proSettingsRepositoryProvider).setActivePreset(presetId);
    _loaded = false;
    ref.invalidate(proDocumentPresetsProvider);
    ref.invalidate(proPdfSettingsProvider);
  }

  Future<void> _deletePreset(String presetId) async {
    await ref.read(proSettingsRepositoryProvider).deletePreset(presetId);
    _loaded = false;
    ref.invalidate(proDocumentPresetsProvider);
    ref.invalidate(proPdfSettingsProvider);
    if (!mounted) return;
    AppSnackbar.success(context, context.l10n.proPdfPresetDeletedMessage);
  }

  Future<void> _createPreset(ProPdfSettings settings) async {
    final l10n = context.l10n;
    final name = await _askPresetName(
      title: l10n.proPdfPresetAdd,
      initialValue: l10n.proPdfPresetNewName,
    );
    if (name == null) return;
    await ref.read(proSettingsRepositoryProvider).addPreset(name, settings);
    _loaded = false;
    ref.invalidate(proDocumentPresetsProvider);
    ref.invalidate(proPdfSettingsProvider);
  }

  Future<void> _renamePreset(ProDocumentPreset preset) async {
    final l10n = context.l10n;
    final name = await _askPresetName(
      title: l10n.proPdfPresetRename,
      initialValue: preset.displayName(l10n),
    );
    if (name == null) return;
    await ref.read(proSettingsRepositoryProvider).renamePreset(preset.id, name);
    ref.invalidate(proDocumentPresetsProvider);
  }

  Future<String?> _askPresetName({
    required String title,
    required String initialValue,
  }) {
    // The dialog owns its TextEditingController so it is disposed only after
    // the route (including its exit animation) is fully torn down.
    return showDialog<String>(
      context: context,
      builder: (context) =>
          _PresetNameDialog(title: title, initialValue: initialValue),
    );
  }

  Future<void> _showExportHistory() async {
    final l10n = context.l10n;
    final repository = ExportHistoryRepository();
    final records = await repository.all();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.proPdfExportHistory),
        content: SizedBox(
          width: double.maxFinite,
          child: records.isEmpty
              ? Text(l10n.proPdfExportHistoryEmpty)
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: records.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final record = records[index];
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(record.fieldBookTitle),
                      subtitle: Text(
                        '${record.format.toUpperCase()} · ${DateFormat('yyyy-MM-dd HH:mm').format(record.exportedAt)}',
                      ),
                      trailing: Text(record.fileName),
                    );
                  },
                ),
        ),
        actions: [
          if (records.isNotEmpty)
            TextButton(
              onPressed: () async {
                await repository.clear();
                if (context.mounted) Navigator.pop(context);
              },
              child: Text(l10n.proPdfExportHistoryClearAll),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.coreClose),
          ),
        ],
      ),
    );
  }
}

class _FilenamePreview extends StatelessWidget {
  final ProPdfSettings settings;

  const _FilenamePreview({required this.settings});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final preview = settings.formatFileName(
      projectName: l10n.proPdfPreviewSampleSite,
      fieldBook: FieldBook(
        projectId: 1,
        title: l10n.proPdfPreviewSampleTitle,
        date: DateTime(2026, 6, 8),
        workSection: 'STA.0+000',
      ),
      extension: 'pdf',
    );

    return InputDecorator(
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.insert_drive_file_outlined),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.proPdfFileNamePreviewLabel,
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 4),
          Text(preview),
        ],
      ),
    );
  }
}

class _PresetNameDialog extends StatefulWidget {
  final String title;
  final String initialValue;

  const _PresetNameDialog({required this.title, required this.initialValue});

  @override
  State<_PresetNameDialog> createState() => _PresetNameDialogState();
}

class _PresetNameDialogState extends State<_PresetNameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          labelText: context.l10n.proPdfPresetNameLabel,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.coreCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: Text(context.l10n.coreSave),
        ),
      ],
    );
  }
}
