import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lv_book/main.dart' as app;

/// End-to-end smoke run on a device/simulator: empty home → sample project →
/// field book editor. Each `STEP:` marker pauses so an external
/// `simctl io screenshot` can capture the screen.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> step(WidgetTester tester, String name) async {
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    // ignore: avoid_print
    print('STEP:$name');
    await Future<void>.delayed(const Duration(seconds: 4));
  }

  testWidgets('sample project flow', (tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await step(tester, 'home');

    final sample = find.text('예제 프로젝트로 둘러보기');
    if (sample.evaluate().isNotEmpty) {
      await tester.tap(sample);
      await tester.pumpAndSettle(const Duration(seconds: 2));
    } else {
      await tester.tap(find.textContaining('예제 현장').first);
      await tester.pumpAndSettle();
    }
    await step(tester, 'project_detail');

    await tester.tap(find.byType(Card).first);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await step(tester, 'fieldbook_edit');

    await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
    await step(tester, 'fieldbook_summary');

    expect(find.textContaining('적합'), findsWidgets);
  });
}
