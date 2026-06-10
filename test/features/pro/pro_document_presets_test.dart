import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lv_book/features/pro/pro_pdf_settings.dart';
import 'package:lv_book/features/pro/pro_pdf_settings_screen.dart';
import 'package:lv_book/features/pro/pro_providers.dart';
import 'package:lv_book/features/pro/pro_settings_repository.dart';

void main() {
  test('default Pro presets include common document profiles', () {
    final presets = ProDocumentPresets.defaults();

    expect(presets.presets, hasLength(greaterThanOrEqualTo(3)));
    expect(presets.active.id, 'basic');
    expect(
      presets.presets.map((preset) => preset.settings.documentTemplate),
      containsAll([
        ProDocumentTemplate.basic,
        ProDocumentTemplate.submission,
        ProDocumentTemplate.inspection,
      ]),
    );
  });

  test('selected Pro preset is used by generated PDF settings', () {
    final presets = ProDocumentPresets(
      activePresetId: 'inspection',
      presets: [
        ProDocumentPreset(
          id: 'inspection',
          name: '검측 제출',
          settings: const ProPdfSettings(
            companyName: '대한토목',
            watermarkText: '검측용',
          ),
        ),
      ],
    );

    expect(presets.active.settings.companyName, '대한토목');
    expect(presets.active.settings.watermarkText, '검측용');
  });

  test('invalid active preset falls back to first preset', () {
    final presets = ProDocumentPresets(
      activePresetId: 'missing',
      presets: [
        ProDocumentPreset(
          id: 'default',
          name: '기본',
          settings: const ProPdfSettings(companyName: '기본회사'),
        ),
      ],
    );

    expect(presets.active.id, 'default');
  });

  test('repository persists active preset settings separately', () async {
    final repository = ProSettingsRepository(store: MemoryProSettingsStore());
    final presets = ProDocumentPresets.defaults();

    await repository.saveDocumentPresets(
      presets.copyWith(activePresetId: 'inspection'),
    );
    await repository.savePdfSettings(
      const ProPdfSettings(companyName: '대한토목', watermarkText: '검측용'),
    );

    final reloaded = await repository.getDocumentPresets();

    expect(reloaded.active.id, 'inspection');
    expect(reloaded.active.settings.companyName, '대한토목');
    expect(reloaded.active.settings.watermarkText, '검측용');
    expect(
      reloaded.presets
          .firstWhere((preset) => preset.id == 'basic')
          .settings
          .companyName,
      isNot('대한토목'),
    );
  });

  test(
    'repository delete keeps at least one preset and selects a fallback',
    () async {
      final repository = ProSettingsRepository(store: MemoryProSettingsStore());

      await repository.saveDocumentPresets(
        ProDocumentPresets.defaults().copyWith(activePresetId: 'inspection'),
      );
      await repository.deletePreset('inspection');
      await repository.deletePreset('submission');
      await repository.deletePreset('basic');

      final reloaded = await repository.getDocumentPresets();

      expect(reloaded.presets, hasLength(1));
      expect(reloaded.active.id, reloaded.presets.single.id);
    },
  );

  test('repository adds and renames a custom preset', () async {
    final repository = ProSettingsRepository(store: MemoryProSettingsStore());

    await repository.addPreset(
      '감리 제출',
      const ProPdfSettings(companyName: '대한토목'),
    );
    var presets = await repository.getDocumentPresets();
    final custom = presets.active;

    expect(custom.name, '감리 제출');
    expect(custom.settings.companyName, '대한토목');

    await repository.renamePreset(custom.id, '감리 최종 제출');
    presets = await repository.getDocumentPresets();

    expect(presets.active.name, '감리 최종 제출');
  });

  test(
    'repository migrates existing flat settings into default presets',
    () async {
      final store = MemoryProSettingsStore({
        'pro_company_name': '기존 회사',
        'pro_author_name': '기존 작성자',
        'pro_document_template': 'submission',
        'pro_file_name_pattern': 'siteDateTitle',
      });
      final repository = ProSettingsRepository(store: store);

      final presets = await repository.getDocumentPresets();

      expect(presets.presets, hasLength(greaterThanOrEqualTo(3)));
      expect(presets.active.settings.companyName, '기존 회사');
      expect(presets.active.settings.authorName, '기존 작성자');
      expect(
        presets.active.settings.documentTemplate,
        ProDocumentTemplate.submission,
      );
      expect(
        presets.active.settings.fileNamePattern,
        ProFileNamePattern.siteDateTitle,
      );
    },
  );

  testWidgets('settings screen shows presets and filename preview', (
    tester,
  ) async {
    final repository = ProSettingsRepository(store: MemoryProSettingsStore());
    await repository.savePdfSettings(
      const ProPdfSettings(fileNamePattern: ProFileNamePattern.siteDateTitle),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          proSettingsRepositoryProvider.overrideWith((ref) => repository),
        ],
        child: const MaterialApp(home: ProPdfSettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('문서 프리셋'), findsOneWidget);
    expect(find.text('기본 야장'), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('파일명 미리보기'),
      120,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('파일명 미리보기'), findsOneWidget);
    expect(find.text('강남 현장_2026-06-08_A구간 야장.pdf'), findsOneWidget);
  });
}
