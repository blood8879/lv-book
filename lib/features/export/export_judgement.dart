class ExportJudgement {
  static const defaultTolerance = 0.001;

  static bool isSuitable(
    double closureError, {
    double tolerance = defaultTolerance,
  }) {
    return closureError.abs() <= tolerance + 1e-9;
  }

  static String label(
    double closureError, {
    double tolerance = defaultTolerance,
  }) {
    return isSuitable(closureError, tolerance: tolerance) ? '적합' : '확인 필요';
  }
}
