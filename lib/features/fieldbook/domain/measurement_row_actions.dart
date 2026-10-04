import 'measurement.dart';

/// Default (Korean) name for a copy. UI passes `l10n.fieldbookCopyName`.
String koreanCopyName(String name) => '$name 복사';

class MeasurementRowActions {
  static List<Measurement> insertBelow(
    List<Measurement> rows, {
    required int index,
    required int fieldBookId,
    required String stationName,
  }) {
    final next = List<Measurement>.from(rows);
    next.insert(
      index + 1,
      Measurement(
        fieldBookId: fieldBookId,
        orderIndex: index + 1,
        stationName: stationName,
      ),
    );
    return _reindex(next);
  }

  static List<Measurement> duplicate(
    List<Measurement> rows, {
    required int index,
    required int fieldBookId,
    String Function(String name) copyName = koreanCopyName,
  }) {
    final next = List<Measurement>.from(rows);
    final source = next[index];
    next.insert(
      index + 1,
      Measurement(
        fieldBookId: fieldBookId,
        orderIndex: index + 1,
        stationName: copyName(source.stationName),
        type: source.type,
        bs: source.bs,
        fs: source.fs,
        ih: source.ih,
        gh: source.gh,
        manualTp: source.manualTp,
      ),
    );
    return _reindex(next);
  }

  static List<Measurement> _reindex(List<Measurement> rows) {
    return [
      for (var i = 0; i < rows.length; i++) rows[i].copyWith(orderIndex: i),
    ];
  }
}
