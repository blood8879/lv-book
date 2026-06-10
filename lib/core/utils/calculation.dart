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
