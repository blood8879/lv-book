import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../fieldbook/data/fieldbook_repository.dart';
import '../../fieldbook/domain/fieldbook.dart';

class DashboardStats {
  /// project_id → field-book counts.
  final Map<int, FieldBookProjectStats> byProject;

  /// Most recently dated field book across all projects.
  final FieldBook? recentFieldBook;

  const DashboardStats({required this.byProject, this.recentFieldBook});

  int get totalFieldBooks =>
      byProject.values.fold(0, (sum, stats) => sum + stats.total);

  int get totalOpen =>
      byProject.values.fold(0, (sum, stats) => sum + stats.openCount);

  FieldBookProjectStats statsFor(int? projectId) {
    return byProject[projectId] ??
        const FieldBookProjectStats(total: 0, openCount: 0);
  }
}

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final repository = FieldBookRepository();
  final byProject = await repository.getProjectStats();
  final recent = await repository.getMostRecent();
  return DashboardStats(byProject: byProject, recentFieldBook: recent);
});
