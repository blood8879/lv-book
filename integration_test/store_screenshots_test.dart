import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lv_book/l10n/l10n.dart';
import 'package:lv_book/main.dart' as app;

/// Walks the app through the screens used for store screenshots. Each
/// `SHOT:<name>` marker pauses so an external `simctl io screenshot` can
/// capture it (see docs/store/graphics/generate_en.sh for the names).
///
/// Run on a fresh simulator whose language matches the listing, e.g.
///   flutter test integration_test/store_screenshots_test.dart -d SIM_ID
/// Pass `--dart-define=SHOT_ONLY=editor --dart-define=SHOT_SUFFIX=_dark` with
/// the simulator in dark appearance to capture just the dark editor.
const _only = String.fromEnvironment('SHOT_ONLY');
const _suffix = String.fromEnvironment('SHOT_SUFFIX');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> shot(WidgetTester tester, String name) async {
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    if (_only.isNotEmpty && _only != name) return;
    // ignore: avoid_print
    print('SHOT:$name$_suffix');
    await Future<void>.delayed(const Duration(seconds: 4));
  }

  testWidgets('store screenshot walk', (tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 2));
    final l10n = l10nForPlatform();

    final sample = find.text(l10n.projectEmptySampleButton);
    if (sample.evaluate().isNotEmpty) {
      await tester.tap(sample);
      await tester.pumpAndSettle(const Duration(seconds: 2));
    } else {
      await tester.tap(find.byType(Card).first);
      await tester.pumpAndSettle();
    }
    await Future<void>.delayed(const Duration(seconds: 4)); // snackbar fades
    await shot(tester, 'levelbooks');

    await tester.tap(find.text(l10n.projectDetailTabBenchmarks));
    await tester.pumpAndSettle();
    await shot(tester, 'benchmarks');
    await tester.tap(find.text(l10n.projectDetailTabLevelBooks));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Card).first);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await shot(tester, 'editor');

    await tester.tap(find.byIcon(Icons.ios_share));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await Future<void>.delayed(const Duration(seconds: 4)); // PDF raster
    await shot(tester, 'export');

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await shot(tester, 'home');

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.settingsPdfSettingsTitle));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await shot(tester, 'pdfsettings');
  });
}
