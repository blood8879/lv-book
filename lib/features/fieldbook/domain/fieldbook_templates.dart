import 'fieldbook.dart';
import 'measurement.dart';

class DuplicatedFieldBook {
  final FieldBook fieldBook;
  final List<Measurement> measurements;

  const DuplicatedFieldBook({
    required this.fieldBook,
    required this.measurements,
  });
}

class FieldBookTemplates {
  static DuplicatedFieldBook duplicateStructure({
    required FieldBook source,
    required List<Measurement> measurements,
    required DateTime newDate,
  }) {
    final fieldBook = FieldBook(
      projectId: source.projectId,
      title: '${source.title} 복사',
      date: newDate,
      startBmId: source.startBmId,
      startElevation: source.startElevation,
      memo: source.memo,
      surveyor: source.surveyor,
      checker: source.checker,
      instrument: source.instrument,
      weather: source.weather,
      workSection: source.workSection,
      jobNumber: source.jobNumber,
    );

    return DuplicatedFieldBook(
      fieldBook: fieldBook,
      measurements: [
        for (var i = 0; i < measurements.length; i++)
          Measurement(
            fieldBookId: 0,
            orderIndex: i,
            stationName: measurements[i].stationName,
            type: measurements[i].type,
            manualTp: measurements[i].manualTp,
          ),
      ],
    );
  }

  static List<Measurement> noPrefixRows({
    required int fieldBookId,
    required int count,
  }) {
    return [
      for (var i = 0; i < count; i++)
        Measurement(
          fieldBookId: fieldBookId,
          orderIndex: i,
          stationName: 'No.${i + 1}',
        ),
    ];
  }
}
