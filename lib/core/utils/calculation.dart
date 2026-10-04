class LevelCalculation {
  /// Calculate Instrument Height (IH)
  /// IH = known elevation + BS
  static double calculateIH(double elevation, double bs) {
    return elevation + bs;
  }

  /// Calculate Ground Height (GH)
  /// GH = IH - FS
  static double calculateGH(double ih, double fs) {
    return ih - fs;
  }

  /// Calculate error check
  /// Error = ΣBS - ΣFS - (final GH - initial GH)
  static double calculateError({
    required double sumBs,
    required double sumFs,
    required double startElevation,
    required double endElevation,
  }) {
    return sumBs - sumFs - (endElevation - startElevation);
  }
}

/// One observed row of a leveling run (BS/FS as entered).
class LevelRunInput {
  final double? bs;
  final double? fs;
  final bool manualTp;

  const LevelRunInput({this.bs, this.fs, this.manualTp = false});
}

/// Computed IH/GH for one row, plus whether it acts as a turning point.
class LevelRunResult {
  final double? ih;
  final double? gh;
  final bool isTP;

  const LevelRunResult({this.ih, this.gh, this.isTP = false});
}

/// Height-of-instrument run computation shared by the field book editor and
/// any code that generates measurements (e.g. the sample project).
class LevelRun {
  const LevelRun._();

  /// - The first row with a BS sits on the start elevation (IH = start + BS).
  /// - A later row with both BS and FS is a turning point: GH = IH − FS and a
  ///   new IH = GH + BS.
  /// - A later row with FS only is an intermediate/final point: GH = IH − FS.
  /// - An empty first row shows the start elevation as GH.
  static List<LevelRunResult> compute(
    double startElevation,
    List<LevelRunInput> rows,
  ) {
    final results = <LevelRunResult>[];
    double currentIH = 0;
    bool firstBsFound = false;

    for (int i = 0; i < rows.length; i++) {
      final row = rows[i];
      final bs = row.bs;
      final fs = row.fs;

      final autoTp = firstBsFound && bs != null && fs != null;
      final isTP = row.manualTp || autoTp;

      if (!firstBsFound && bs == null && fs == null && i == 0) {
        results.add(LevelRunResult(gh: startElevation, isTP: isTP));
      } else if (!firstBsFound && bs != null) {
        currentIH = LevelCalculation.calculateIH(startElevation, bs);
        firstBsFound = true;
        results.add(
          LevelRunResult(ih: currentIH, gh: startElevation, isTP: isTP),
        );
      } else if (autoTp) {
        final gh = LevelCalculation.calculateGH(currentIH, fs);
        currentIH = LevelCalculation.calculateIH(gh, bs);
        results.add(LevelRunResult(ih: currentIH, gh: gh, isTP: isTP));
      } else if (firstBsFound && fs != null) {
        results.add(
          LevelRunResult(
            gh: LevelCalculation.calculateGH(currentIH, fs),
            isTP: isTP,
          ),
        );
      } else {
        results.add(LevelRunResult(isTP: isTP));
      }
    }
    return results;
  }

  /// Rise (+) / fall (−) of each row for the rise-and-fall presentation;
  /// null where the row has no reduced foresight (rows before and including
  /// the first BS, BS-only rows, empty rows).
  ///
  /// difference = previous reading − this row's FS, where the previous
  /// reading is the last staff reading on the same instrument setup: the BS
  /// of the setup (first BS or a turning point's BS) or the preceding IS/FS.
  /// Follows [compute]: the result equals the change in RL from the previous
  /// reduced row, so ΣRise − ΣFall = ΣBS − ΣFS = Final RL − Start RL.
  static List<double?> riseFall(List<LevelRunInput> rows) {
    final results = <double?>[];
    double? previous;
    for (final row in rows) {
      final bs = row.bs;
      final fs = row.fs;
      if (previous == null) {
        // Before the first setup: a BS starts it, anything else is ignored
        // (an FS on the first BS row is ignored by [compute] as well).
        if (bs != null) previous = bs;
        results.add(null);
      } else if (fs == null) {
        results.add(null);
      } else {
        results.add(previous - fs);
        // A turning point's BS starts the next setup.
        previous = bs ?? fs;
      }
    }
    return results;
  }
}
