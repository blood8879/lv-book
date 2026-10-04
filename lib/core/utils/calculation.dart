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
}
