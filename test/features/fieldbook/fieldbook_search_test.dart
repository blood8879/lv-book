import 'package:flutter_test/flutter_test.dart';
import 'package:lv_book/features/fieldbook/domain/fieldbook.dart';
import 'package:lv_book/features/fieldbook/domain/fieldbook_search.dart';

void main() {
  test('field book search filters by title and work section', () {
    final result = FieldBookSearch.filter([
      FieldBook(
        projectId: 1,
        title: 'A구간 야장',
        date: DateTime(2026, 6, 1),
        workSection: 'STA.0+000',
      ),
      FieldBook(
        projectId: 1,
        title: 'B구간 야장',
        date: DateTime(2026, 6, 2),
        surveyor: '김측량',
      ),
    ], query: 'sta');

    expect(result.map((book) => book.title), ['A구간 야장']);
  });

  test('field book search shows empty state for no match', () {
    final result = FieldBookSearch.filter([
      FieldBook(projectId: 1, title: 'A구간 야장', date: DateTime(2026, 6, 1)),
    ], query: '없는구간');

    expect(result, isEmpty);
  });
}
