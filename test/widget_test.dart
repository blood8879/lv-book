import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lv_book/app.dart';

void main() {
  testWidgets('App should display app bar title', (tester) async {
    // The full app resolves its language from the device; pin Korean so this
    // test keeps asserting Korean text (English is covered in test/l10n/).
    tester.platformDispatcher.localesTestValue = const [Locale('ko', 'KR')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(const ProviderScope(child: LvBookApp()));

    expect(find.text('레벨 야장'), findsOneWidget);
  });
}
