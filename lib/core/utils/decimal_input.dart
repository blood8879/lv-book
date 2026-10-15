import 'package:flutter/services.dart';

/// Turns a typed decimal comma into a point, so numeric fields accept the
/// comma key of keyboards in decimal-comma locales (e.g. Spanish) while the
/// stored text stays parseable by `double.tryParse`.
class DecimalCommaFormatter extends TextInputFormatter {
  const DecimalCommaFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (!newValue.text.contains(',')) return newValue;
    return newValue.copyWith(text: newValue.text.replaceAll(',', '.'));
  }
}
