import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../core/database/database_helper.dart';
import 'pro_pdf_settings.dart';

class ProSettingsRepository {
  static const _presetsKey = 'pro_document_presets';
  static const _companyNameKey = 'pro_company_name';
  static const _authorNameKey = 'pro_author_name';
  static const _includeCheckJudgementKey = 'pro_include_check_judgement';
  static const _includeSignatureLinesKey = 'pro_include_signature_lines';
  static const _documentTemplateKey = 'pro_document_template';
  static const _watermarkTextKey = 'pro_watermark_text';
  static const _footerNoteKey = 'pro_footer_note';
  static const _fileNamePatternKey = 'pro_file_name_pattern';

  final ProSettingsStore _store;

  ProSettingsRepository({ProSettingsStore? store})
    : _store = store ?? DatabaseProSettingsStore();

  Future<ProPdfSettings> getPdfSettings() async {
    return (await getDocumentPresets()).active.settings;
  }

  Future<ProDocumentPresets> getDocumentPresets() async {
    final stored = await _getValue(_presetsKey);
    if (stored != null) {
      return ProDocumentPresets.fromJson(
        jsonDecode(stored) as Map<String, dynamic>,
      );
    }

    final migrated = ProDocumentPresets.defaults(
      migratedSettings: await _getFlatPdfSettings(),
    );
    await saveDocumentPresets(migrated);
    return migrated;
  }

  Future<void> saveDocumentPresets(ProDocumentPresets presets) async {
    await _setValue(_presetsKey, jsonEncode(presets.toJson()));
  }

  Future<void> setActivePreset(String presetId) async {
    final presets = await getDocumentPresets();
    await saveDocumentPresets(presets.copyWith(activePresetId: presetId));
  }

  Future<void> deletePreset(String presetId) async {
    final presets = await getDocumentPresets();
    await saveDocumentPresets(presets.deletePreset(presetId));
  }

  Future<void> addPreset(String name, ProPdfSettings settings) async {
    final presets = await getDocumentPresets();
    await saveDocumentPresets(presets.addPreset(name, settings));
  }

  Future<void> renamePreset(String presetId, String name) async {
    final presets = await getDocumentPresets();
    await saveDocumentPresets(presets.renamePreset(presetId, name));
  }

  Future<ProPdfSettings> _getFlatPdfSettings() async {
    return ProPdfSettings(
      companyName: await _getValue(_companyNameKey) ?? '',
      authorName: await _getValue(_authorNameKey) ?? '',
      includeCheckJudgement: await _getBool(
        _includeCheckJudgementKey,
        defaultValue: true,
      ),
      includeSignatureLines: await _getBool(
        _includeSignatureLinesKey,
        defaultValue: true,
      ),
      documentTemplate: ProDocumentTemplate.values.byName(
        await _getValue(_documentTemplateKey) ?? ProDocumentTemplate.basic.name,
      ),
      watermarkText: await _getValue(_watermarkTextKey) ?? '',
      footerNote: await _getValue(_footerNoteKey) ?? '',
      fileNamePattern: ProFileNamePattern.values.byName(
        await _getValue(_fileNamePatternKey) ??
            ProFileNamePattern.titleOnly.name,
      ),
    );
  }

  Future<void> savePdfSettings(ProPdfSettings settings) async {
    final presets = await getDocumentPresets();
    await saveDocumentPresets(presets.updateActiveSettings(settings));

    // Keep legacy flat keys current for older call sites or downgraded builds.
    await _setValue(_companyNameKey, settings.companyName.trim());
    await _setValue(_authorNameKey, settings.authorName.trim());
    await _setValue(
      _includeCheckJudgementKey,
      settings.includeCheckJudgement.toString(),
    );
    await _setValue(
      _includeSignatureLinesKey,
      settings.includeSignatureLines.toString(),
    );
    await _setValue(_documentTemplateKey, settings.documentTemplate.name);
    await _setValue(_watermarkTextKey, settings.watermarkText.trim());
    await _setValue(_footerNoteKey, settings.footerNote.trim());
    await _setValue(_fileNamePatternKey, settings.fileNamePattern.name);
  }

  Future<bool> _getBool(String key, {required bool defaultValue}) async {
    final value = await _getValue(key);
    if (value == null) return defaultValue;
    return value == 'true';
  }

  Future<String?> _getValue(String key) async {
    return _store.getValue(key);
  }

  Future<void> _setValue(String key, String value) async {
    return _store.setValue(key, value);
  }
}

abstract class ProSettingsStore {
  Future<String?> getValue(String key);

  Future<void> setValue(String key, String value);
}

class DatabaseProSettingsStore implements ProSettingsStore {
  @override
  Future<String?> getValue(String key) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'app_settings',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['value'] as String;
  }

  @override
  Future<void> setValue(String key, String value) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert('app_settings', {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}

class MemoryProSettingsStore implements ProSettingsStore {
  final Map<String, String> _values;

  MemoryProSettingsStore([Map<String, String>? values])
    : _values = Map<String, String>.from(values ?? const {});

  @override
  Future<String?> getValue(String key) async {
    return _values[key];
  }

  @override
  Future<void> setValue(String key, String value) async {
    _values[key] = value;
  }
}
