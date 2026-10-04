import '../../../core/database/database_helper.dart';
import '../../../core/utils/calculation.dart';
import '../../../l10n/l10n.dart';
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
///
/// Names and notes are written in the app language ([AppLocalizations]) at
/// creation time; afterwards they are ordinary user data.
class SampleProjectService {
  static const benchmarkName = 'BM-1';
  static const benchmarkElevation = 100.000;

  /// BM-1 → TP-1 → No.1(중간점) → TP-2 → No.2(중간점) → BM-1 폐합.
  /// ΣBS 4.375, ΣFS(전진) 4.374 → 폐합 GH 100.001 (오차 1mm 이내, 적합).
  static List<SampleObservation> observations(AppLocalizations l10n) => [
    const SampleObservation(benchmarkName, bs: 1.425),
    const SampleObservation('TP-1', bs: 1.612, fs: 0.873),
    const SampleObservation('No.1', fs: 1.940),
    const SampleObservation('TP-2', bs: 1.338, fs: 2.105),
    const SampleObservation('No.2', fs: 1.250),
    SampleObservation(
      l10n.projectSampleClosingStation(benchmarkName),
      fs: 1.396,
    ),
  ];

  final DatabaseHelper _dbHelper;
  Future<Project>? _inFlight;

  SampleProjectService({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  /// Builds the sample measurements with IH/GH from the app's own [LevelRun].
  /// Station names follow [l10n] (Korean when omitted).
  static List<Measurement> buildMeasurements({
    required int fieldBookId,
    double startElevation = benchmarkElevation,
    AppLocalizations? l10n,
  }) {
    final observations = SampleProjectService.observations(l10n ?? l10nKo);
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
  /// returns the created project, written in [l10n] (pass `context.l10n`).
  /// Concurrent calls share one creation.
  Future<Project> createSampleProject({required AppLocalizations l10n}) {
    return _inFlight ??= _create(l10n).whenComplete(() => _inFlight = null);
  }

  Future<Project> _create(AppLocalizations l10n) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return db.transaction((txn) async {
      final project = Project(
        name: l10n.projectSampleName,
        description: l10n.projectSampleDescription,
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
          description: l10n.projectSampleBenchmarkDescription,
          locationHint: l10n.projectSampleBenchmarkLocation,
          status: BenchMarkStatus.available,
        ).toMap(),
      );

      final fieldBookId = await txn.insert(
        'field_books',
        FieldBook(
          projectId: projectId,
          title: l10n.projectSampleLevelBookTitle,
          date: today,
          startBmId: bmId,
          startElevation: benchmarkElevation,
          memo: l10n.projectSampleMemo,
          surveyor: l10n.projectSampleSurveyor,
          instrument: l10n.projectSampleInstrument,
          weather: l10n.projectSampleWeather,
          workSection: l10n.projectSampleSection,
          createdAt: now,
        ).toMap(),
      );

      final batch = txn.batch();
      for (final m in buildMeasurements(fieldBookId: fieldBookId, l10n: l10n)) {
        batch.insert('measurements', m.toMap());
      }
      await batch.commit(noResult: true);

      return project.copyWith(id: projectId);
    });
  }
}
