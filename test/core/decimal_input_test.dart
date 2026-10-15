import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lv_book/core/utils/decimal_input.dart';

void main() {
  test('converts a typed decimal comma to a point', () {
    const formatter = DecimalCommaFormatter();
    final result = formatter.formatEditUpdate(
      const TextEditingValue(text: '1'),
      const TextEditingValue(
        text: '1,',
        selection: TextSelection.collapsed(offset: 2),
      ),
    );
    expect(result.text, '1.');
    expect(result.selection.baseOffset, 2);
  });

  test('leaves text without a comma untouched', () {
    const formatter = DecimalCommaFormatter();
    const value = TextEditingValue(text: '-1.425');
    expect(formatter.formatEditUpdate(TextEditingValue.empty, value), value);
  });

  testWidgets('a field with the formatter stores a parseable value', (
    tester,
  ) async {
    final controller = TextEditingController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TextField(
            controller: controller,
            inputFormatters: const [DecimalCommaFormatter()],
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), '100,187');
    expect(controller.text, '100.187');
    expect(double.tryParse(controller.text), 100.187);
  });
}
