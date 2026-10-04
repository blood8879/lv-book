import '../../../core/database/database_helper.dart';
import '../../../core/utils/calculation.dart';
import '../../benchmark/domain/benchmark.dart';
import '../../fieldbook/domain/fieldbook.dart';
import '../../fieldbook/domain/measurement.dart';
import '../domain/project.dart';

/// One observed row of the sample run (BS/FS as a surveyor would enter them).
class SampleObservation {
  final String stationName;
  final double? bs;
  final double? fs;

  const SampleObservation(this.stationName, {this.bs, this.fs});
}

/// Creates a ready-to-browse example project so first-run users can see the
/// automatic IH/GH calculation and closure check without typing anything.
class SampleProjectService {
  static const projectName = '예제 현장 (삭제 가능)';
  static const benchmarkName = 'BM-1';
  static const benchmarkElevation = 100.000;
  static const fieldBookTitle = '예제 야장 (BM-1 왕복)';

  /// BM-1 → TP-1 → No.1(중간점) → TP-2 → No.2(중간점) → BM-1 폐합.
  /// ΣBS 4.375, ΣFS(전진) 4.374 → 폐합 GH 100.001 (오차 1mm 이내, 적합).
  static const observations = <SampleObservation>[
    SampleObservation(benchmarkName, bs: 1.425),
    SampleObservation('TP-1', bs: 1.612, fs: 0.873),
    SampleObservation('No.1', fs: 1.940),
    SampleObservation('TP-2', bs: 1.338, fs: 2.105),
    SampleObservation('No.2', fs: 1.250),
    SampleObservation('$benchmarkName (폐합)', fs: 1.396),
  ];

  final DatabaseHelper _dbHelper;
  Future<Project>? _inFlight;

  SampleProjectService({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  /// Builds the sample measurements with IH/GH from the app's own [LevelRun].
  static List<Measurement> buildMeasurements({
    required int fieldBookId,
    double startElevation = benchmarkElevation,
  }) {
    final results = LevelRun.compute(startElevation, [
      for (final o in observations) LevelRunInput(bs: o.bs, fs: o.fs),
    ]);
    return [
      for (var i = 0; i < observations.length; i++)
        Measurement(
          fieldBookId: fieldBookId,
          orderIndex: i,
          stationName: observations[i].stationName,
          type: results[i].isTP ? MeasurementType.tp : MeasurementType.normal,
          bs: observations[i].bs,
          fs: observations[i].fs,
          ih: results[i].ih,
          gh: results[i].gh,
        ),
    ];
  }

  /// Inserts project → BM → field book → measurements in one transaction and
  /// returns the created project. Concurrent calls share one creation.
  Future<Project> createSampleProject() {
    return _inFlight ??= _create().whenComplete(() => _inFlight = null);
  }

  Future<Project> _create() async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return db.transaction((txn) async {
      final project = Project(
        name: projectName,
        description: '자동 계산·폐합 확인용 예제입니다. 필요 없으면 삭제하세요.',
        createdAt: now,
        updatedAt: now,
      );
      final projectId = await txn.insert('projects', project.toMap());

      final bmId = await txn.insert(
        'benchmarks',
        BenchMark(
          projectId: projectId,
          name: benchmarkName,
          elevation: benchmarkElevation,
          description: '예제 기준점',
          locationHint: '현장 사무소 앞 경계석',
          status: BenchMarkStatus.available,
        ).toMap(),
      );

      final fieldBookId = await txn.insert(
        'field_books',
        FieldBook(
          projectId: projectId,
          title: fieldBookTitle,
          date: today,
          startBmId: bmId,
          startElevation: benchmarkElevation,
          memo: '예제 데이터입니다. 값을 바꾸면 IH/GH가 자동으로 다시 계산됩니다.',
          surveyor: '홍길동',
          instrument: '자동 레벨',
          weather: '맑음',
          workSection: '예제 구간',
          createdAt: now,
        ).toMap(),
      );

      final batch = txn.batch();
      for (final m in buildMeasurements(fieldBookId: fieldBookId)) {
        batch.insert('measurements', m.toMap());
      }
      await batch.commit(noResult: true);

      return project.copyWith(id: projectId);
    });
  }
}
