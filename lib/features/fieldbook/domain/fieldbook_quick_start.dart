import '../../benchmark/domain/benchmark.dart';
import 'fieldbook.dart';

class FieldBookQuickStartSuggestion {
  final String? surveyor;
  final String? checker;
  final String? instrument;
  final String? weather;
  final String? workSection;
  final String? jobNumber;
  final BenchMark? startBm;
  final double? startElevation;

  const FieldBookQuickStartSuggestion({
    this.surveyor,
    this.checker,
    this.instrument,
    this.weather,
    this.workSection,
    this.jobNumber,
    this.startBm,
    this.startElevation,
  });

  bool get useCustomBm => startBm == null;
}

class FieldBookQuickStart {
  static FieldBookQuickStartSuggestion suggest({
    required List<FieldBook> fieldBooks,
    required List<BenchMark> benchmarks,
  }) {
    if (fieldBooks.isEmpty) return const FieldBookQuickStartSuggestion();

    final sorted = [...fieldBooks]
      ..sort((a, b) {
        final dateCompare = b.date.compareTo(a.date);
        if (dateCompare != 0) return dateCompare;
        return b.createdAt.compareTo(a.createdAt);
      });
    final latest = sorted.first;
    final startBm = latest.startBmId == null
        ? null
        : benchmarks.where((bm) => bm.id == latest.startBmId).firstOrNull;

    return FieldBookQuickStartSuggestion(
      surveyor: _blankToNull(latest.surveyor),
      checker: _blankToNull(latest.checker),
      instrument: _blankToNull(latest.instrument),
      weather: _blankToNull(latest.weather),
      workSection: _blankToNull(latest.workSection),
      jobNumber: _blankToNull(latest.jobNumber),
      startBm: startBm?.isSelectableForFieldBook == true ? startBm : null,
      startElevation: latest.startElevation,
    );
  }

  static String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}
