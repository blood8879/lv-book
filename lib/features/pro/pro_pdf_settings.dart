import '../fieldbook/domain/fieldbook.dart';

enum ProDocumentTemplate { basic, submission, inspection }

enum ProFileNamePattern { titleOnly, siteDateTitle, siteSectionDateTitle }

extension ProDocumentTemplateTitle on ProDocumentTemplate {
  String get title {
    switch (this) {
      case ProDocumentTemplate.basic:
        return '기본 야장';
      case ProDocumentTemplate.submission:
        return '제출용';
      case ProDocumentTemplate.inspection:
        return '검측용';
    }
  }
}

class ProPdfSettings {
  final String companyName;
  final String authorName;
  final bool includeCheckJudgement;
  final bool includeSignatureLines;
  final ProDocumentTemplate documentTemplate;
  final String watermarkText;
  final String footerNote;
  final ProFileNamePattern fileNamePattern;

  /// Base64-encoded PNG of the author's handwritten signature. Empty when
  /// no signature has been registered.
  final String signaturePng;

  const ProPdfSettings({
    this.companyName = '',
    this.authorName = '',
    this.includeCheckJudgement = true,
    this.includeSignatureLines = true,
    this.documentTemplate = ProDocumentTemplate.basic,
    this.watermarkText = '',
    this.footerNote = '',
    this.fileNamePattern = ProFileNamePattern.titleOnly,
    this.signaturePng = '',
  });

  factory ProPdfSettings.fromJson(Map<String, dynamic> json) {
    return ProPdfSettings(
      companyName: json['companyName'] as String? ?? '',
      authorName: json['authorName'] as String? ?? '',
      includeCheckJudgement: json['includeCheckJudgement'] as bool? ?? true,
      includeSignatureLines: json['includeSignatureLines'] as bool? ?? true,
      documentTemplate: _enumByName(
        ProDocumentTemplate.values,
        json['documentTemplate'] as String?,
        ProDocumentTemplate.basic,
      ),
      watermarkText: json['watermarkText'] as String? ?? '',
      footerNote: json['footerNote'] as String? ?? '',
      fileNamePattern: _enumByName(
        ProFileNamePattern.values,
        json['fileNamePattern'] as String?,
        ProFileNamePattern.titleOnly,
      ),
      signaturePng: json['signaturePng'] as String? ?? '',
    );
  }

  bool get hasSignature => signaturePng.trim().isNotEmpty;

  bool get hasBranding =>
      companyName.trim().isNotEmpty || authorName.trim().isNotEmpty;

  ProPdfSettings copyWith({
    String? companyName,
    String? authorName,
    bool? includeCheckJudgement,
    bool? includeSignatureLines,
    ProDocumentTemplate? documentTemplate,
    String? watermarkText,
    String? footerNote,
    ProFileNamePattern? fileNamePattern,
    String? signaturePng,
  }) {
    return ProPdfSettings(
      companyName: companyName ?? this.companyName,
      authorName: authorName ?? this.authorName,
      includeCheckJudgement:
          includeCheckJudgement ?? this.includeCheckJudgement,
      includeSignatureLines:
          includeSignatureLines ?? this.includeSignatureLines,
      documentTemplate: documentTemplate ?? this.documentTemplate,
      watermarkText: watermarkText ?? this.watermarkText,
      footerNote: footerNote ?? this.footerNote,
      fileNamePattern: fileNamePattern ?? this.fileNamePattern,
      signaturePng: signaturePng ?? this.signaturePng,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'companyName': companyName,
      'authorName': authorName,
      'includeCheckJudgement': includeCheckJudgement,
      'includeSignatureLines': includeSignatureLines,
      'documentTemplate': documentTemplate.name,
      'watermarkText': watermarkText,
      'footerNote': footerNote,
      'fileNamePattern': fileNamePattern.name,
      'signaturePng': signaturePng,
    };
  }

  String formatFileName({
    required String projectName,
    required FieldBook fieldBook,
    required String extension,
  }) {
    final date = _dateToken(fieldBook.date);
    final tokens = switch (fileNamePattern) {
      ProFileNamePattern.titleOnly => [fieldBook.title],
      ProFileNamePattern.siteDateTitle => [projectName, date, fieldBook.title],
      ProFileNamePattern.siteSectionDateTitle => [
        projectName,
        fieldBook.workSection,
        date,
        fieldBook.title,
      ],
    };
    final base = tokens
        .whereType<String>()
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .join('_');
    final safeBase = _safeFileName(base.isEmpty ? fieldBook.title : base);
    final safeExtension = extension.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    return '$safeBase.$safeExtension';
  }

  static String _dateToken(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  static String _safeFileName(String value) {
    final sanitized = value.trim().replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    return sanitized.isEmpty ? 'fieldbook' : sanitized;
  }

  static T _enumByName<T extends Enum>(
    List<T> values,
    String? name,
    T fallback,
  ) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return fallback;
  }
}

class ProDocumentPreset {
  final String id;
  final String name;
  final ProPdfSettings settings;

  const ProDocumentPreset({
    required this.id,
    required this.name,
    required this.settings,
  });

  factory ProDocumentPreset.fromJson(Map<String, dynamic> json) {
    return ProDocumentPreset(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      settings: ProPdfSettings.fromJson(
        json['settings'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  ProDocumentPreset copyWith({
    String? id,
    String? name,
    ProPdfSettings? settings,
  }) {
    return ProDocumentPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      settings: settings ?? this.settings,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'settings': settings.toJson()};
  }
}

class ProDocumentPresets {
  final String activePresetId;
  final List<ProDocumentPreset> presets;

  const ProDocumentPresets({
    required this.activePresetId,
    required this.presets,
  });

  factory ProDocumentPresets.defaults({ProPdfSettings? migratedSettings}) {
    return ProDocumentPresets(
      activePresetId: 'basic',
      presets: [
        ProDocumentPreset(
          id: 'basic',
          name: '기본 야장',
          settings: migratedSettings ?? const ProPdfSettings(),
        ),
        const ProDocumentPreset(
          id: 'submission',
          name: '제출용',
          settings: ProPdfSettings(
            documentTemplate: ProDocumentTemplate.submission,
            includeSignatureLines: true,
          ),
        ),
        const ProDocumentPreset(
          id: 'inspection',
          name: '검측용',
          settings: ProPdfSettings(
            documentTemplate: ProDocumentTemplate.inspection,
            watermarkText: '검측용',
            includeSignatureLines: true,
          ),
        ),
      ],
    );
  }

  factory ProDocumentPresets.fromJson(Map<String, dynamic> json) {
    final decodedPresets = (json['presets'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(ProDocumentPreset.fromJson)
        .where((preset) => preset.id.trim().isNotEmpty)
        .toList();
    if (decodedPresets.isEmpty) {
      return ProDocumentPresets.defaults();
    }
    final activePresetId = json['activePresetId'] as String? ?? '';
    return ProDocumentPresets(
      activePresetId:
          decodedPresets.any((preset) => preset.id == activePresetId)
          ? activePresetId
          : decodedPresets.first.id,
      presets: List<ProDocumentPreset>.unmodifiable(decodedPresets),
    );
  }

  ProDocumentPreset get active {
    return presets.where((preset) => preset.id == activePresetId).firstOrNull ??
        presets.first;
  }

  ProDocumentPresets copyWith({
    String? activePresetId,
    List<ProDocumentPreset>? presets,
  }) {
    final nextPresets = presets ?? this.presets;
    final requestedActiveId = activePresetId ?? this.activePresetId;
    final nextActiveId =
        nextPresets.any((preset) => preset.id == requestedActiveId)
        ? requestedActiveId
        : nextPresets.first.id;
    return ProDocumentPresets(
      activePresetId: nextActiveId,
      presets: List<ProDocumentPreset>.unmodifiable(nextPresets),
    );
  }

  ProDocumentPresets updateActiveSettings(ProPdfSettings settings) {
    return copyWith(
      presets: presets
          .map(
            (preset) => preset.id == active.id
                ? preset.copyWith(settings: settings)
                : preset,
          )
          .toList(),
    );
  }

  ProDocumentPresets deletePreset(String presetId) {
    if (presets.length == 1) return this;
    final nextPresets = presets
        .where((preset) => preset.id != presetId)
        .toList(growable: false);
    if (nextPresets.isEmpty) return this;
    return copyWith(
      activePresetId: activePresetId == presetId
          ? nextPresets.first.id
          : activePresetId,
      presets: nextPresets,
    );
  }

  ProDocumentPresets addPreset(String name, ProPdfSettings settings) {
    final trimmedName = name.trim().isEmpty ? '새 프리셋' : name.trim();
    final id = _nextPresetId(trimmedName);
    return copyWith(
      activePresetId: id,
      presets: [
        ...presets,
        ProDocumentPreset(id: id, name: trimmedName, settings: settings),
      ],
    );
  }

  ProDocumentPresets renamePreset(String presetId, String name) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return this;
    return copyWith(
      presets: presets
          .map(
            (preset) => preset.id == presetId
                ? preset.copyWith(name: trimmedName)
                : preset,
          )
          .toList(),
    );
  }

  String _nextPresetId(String name) {
    final safeName = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9가-힣]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final base = safeName.isEmpty ? 'preset' : safeName;
    if (!presets.any((preset) => preset.id == base)) return base;
    var index = 2;
    while (presets.any((preset) => preset.id == '$base-$index')) {
      index += 1;
    }
    return '$base-$index';
  }

  Map<String, dynamic> toJson() {
    return {
      'activePresetId': activePresetId,
      'presets': presets.map((preset) => preset.toJson()).toList(),
    };
  }
}
