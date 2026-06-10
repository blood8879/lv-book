import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lv_book/app.dart';

void main() {
  testWidgets('App should display app bar title', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: LvBookApp()));

    expect(find.text('레벨 야장'), findsOneWidget);
  });
}
