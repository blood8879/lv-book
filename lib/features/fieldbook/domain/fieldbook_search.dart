import 'fieldbook.dart';

class FieldBookSearch {
  static List<FieldBook> filter(List<FieldBook> fieldBooks, {String? query}) {
    final normalized = query?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return fieldBooks;

    return fieldBooks.where((fieldBook) {
      final haystack = [
        fieldBook.title,
        fieldBook.workSection,
        fieldBook.surveyor,
        fieldBook.checker,
        fieldBook.instrument,
        fieldBook.weather,
        fieldBook.jobNumber,
        _dateToken(fieldBook.date),
      ].whereType<String>().join(' ').toLowerCase();
      return haystack.contains(normalized);
    }).toList();
  }

  static String _dateToken(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}
