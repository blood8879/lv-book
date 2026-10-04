import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_snackbar.dart';
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

    return Scaffold(
      appBar: AppBar(title: const Text('Pro PDF 설정')),
      bottomNavigationBar: _buildFooter(),
      body: presetsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('설정을 불러오지 못했습니다: $error')),
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
                      decoration: const InputDecoration(
                        labelText: '문서 프리셋',
                        prefixIcon: Icon(Icons.tune_outlined),
                      ),
                      items: presets.presets
                          .map(
                            (preset) => DropdownMenuItem(
                              value: preset.id,
                              child: Text(preset.name),
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
                    tooltip: '프리셋 추가',
                    icon: const Icon(Icons.add),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: () => _renamePreset(presets.active),
                    tooltip: '프리셋 이름 변경',
                    icon: const Icon(Icons.edit_outlined),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: presets.presets.length > 1
                        ? () => _deletePreset(presets.active.id)
                        : null,
                    tooltip: '프리셋 삭제',
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _companyController,
                decoration: const InputDecoration(
                  labelText: '회사명',
                  hintText: '예: 주식회사 레벨측량',
                  prefixIcon: Icon(Icons.business),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _authorController,
                decoration: const InputDecoration(
                  labelText: '작성자',
                  hintText: '예: 홍길동',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ProDocumentTemplate>(
                initialValue: _documentTemplate,
                decoration: const InputDecoration(
                  labelText: '문서 템플릿',
                  prefixIcon: Icon(Icons.description_outlined),
                ),
                items: ProDocumentTemplate.values
                    .map(
                      (template) => DropdownMenuItem(
                        value: template,
                        child: Text(template.title),
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
                decoration: const InputDecoration(
                  labelText: '파일명 규칙',
                  prefixIcon: Icon(Icons.drive_file_rename_outline),
                ),
                items: const [
                  DropdownMenuItem(
                    value: ProFileNamePattern.titleOnly,
                    child: Text('야장명'),
                  ),
                  DropdownMenuItem(
                    value: ProFileNamePattern.siteDateTitle,
                    child: Text('현장_날짜_야장명'),
                  ),
                  DropdownMenuItem(
                    value: ProFileNamePattern.siteSectionDateTitle,
                    child: Text('현장_작업구간_날짜_야장명'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _fileNamePattern = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _watermarkController,
                decoration: const InputDecoration(
                  labelText: '워터마크',
                  hintText: '예: 검측용',
                  prefixIcon: Icon(Icons.water_drop_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _footerNoteController,
                decoration: const InputDecoration(
                  labelText: '하단 메모',
                  hintText: '예: 현장대리인 확인',
                  prefixIcon: Icon(Icons.notes_outlined),
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.fact_check_outlined),
                title: const Text('검산 판정 표시'),
                subtitle: const Text('PDF/CSV에 적합 또는 확인 필요 판정을 포함합니다.'),
                value: _includeCheckJudgement,
                onChanged: (value) =>
                    setState(() => _includeCheckJudgement = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.draw_outlined),
                title: const Text('확인 서명란 표시'),
                subtitle: const Text('제출용 PDF 하단에 작성/검토/승인란을 추가합니다.'),
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
                  label: const Text('내보내기 이력'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 4,
                child: FilledButton.icon(
                  onPressed: _save,
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                  icon: const Icon(Icons.save),
                  label: const Text('저장'),
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
                const Expanded(
                  child: Text(
                    '작성자 서명',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              "PDF '작성'란에 들어갈 손글씨 서명을 등록합니다.",
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
                      const Center(child: Text('서명을 표시할 수 없습니다')),
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
                  '등록된 서명이 없습니다',
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
                    label: Text(hasSignature ? '다시 서명' : '서명 등록'),
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
                    label: const Text('삭제'),
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
    AppSnackbar.success(context, 'Pro PDF 설정을 저장했습니다');
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
    AppSnackbar.success(context, '프리셋을 삭제했습니다');
  }

  Future<void> _createPreset(ProPdfSettings settings) async {
    final name = await _askPresetName(title: '프리셋 추가', initialValue: '새 프리셋');
    if (name == null) return;
    await ref.read(proSettingsRepositoryProvider).addPreset(name, settings);
    _loaded = false;
    ref.invalidate(proDocumentPresetsProvider);
    ref.invalidate(proPdfSettingsProvider);
  }

  Future<void> _renamePreset(ProDocumentPreset preset) async {
    final name = await _askPresetName(
      title: '프리셋 이름 변경',
      initialValue: preset.name,
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
    final repository = ExportHistoryRepository();
    final records = await repository.all();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('내보내기 이력'),
        content: SizedBox(
          width: double.maxFinite,
          child: records.isEmpty
              ? const Text('내보내기 이력이 없습니다.')
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
              child: const Text('전체 삭제'),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
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
    final preview = settings.formatFileName(
      projectName: '강남 현장',
      fieldBook: FieldBook(
        projectId: 1,
        title: 'A구간 야장',
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
          Text('파일명 미리보기', style: Theme.of(context).textTheme.labelMedium),
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
        decoration: const InputDecoration(labelText: '프리셋 이름'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: const Text('저장'),
        ),
      ],
    );
  }
}
