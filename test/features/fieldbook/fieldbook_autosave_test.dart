import 'package:flutter_test/flutter_test.dart';
import 'package:lv_book/features/fieldbook/domain/measurement.dart';
import 'package:lv_book/features/fieldbook/domain/measurement_draft.dart';

void main() {
  test('autosaves edited measurement rows after debounce', () async {
    final store = MemoryMeasurementDraftStore();

    await store.save(
      fieldBookId: 1,
      rows: [
        Measurement(fieldBookId: 1, orderIndex: 0, stationName: 'BM.1', bs: 1),
      ],
    );

    final rows = await store.load(fieldBookId: 1);
    expect(rows, hasLength(1));
    expect(rows.single.bs, 1);
  });

  test('recovers latest draft after reopening field book', () async {
    final store = MemoryMeasurementDraftStore();
    await store.save(
      fieldBookId: 1,
      rows: [
        Measurement(fieldBookId: 1, orderIndex: 0, stationName: 'No.1', fs: 1),
      ],
    );

    final reopened = await store.load(fieldBookId: 1);

    expect(reopened.single.stationName, 'No.1');
    expect(reopened.single.fs, 1);
  });
}
