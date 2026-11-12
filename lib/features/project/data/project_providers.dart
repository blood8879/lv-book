import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../analytics/analytics_events.dart';
import '../../analytics/analytics_providers.dart';
import 'project_repository.dart';
import 'sample_project_service.dart';
import '../domain/project.dart';

final projectRepositoryProvider = Provider((ref) => ProjectRepository());

final sampleProjectServiceProvider = Provider((ref) => SampleProjectService());

final projectListProvider =
    AsyncNotifierProvider<ProjectListNotifier, List<Project>>(
      ProjectListNotifier.new,
    );

class ProjectListNotifier extends AsyncNotifier<List<Project>> {
  @override
  Future<List<Project>> build() async {
    final repo = ref.read(projectRepositoryProvider);
    return repo.getAll();
  }

  Future<void> addProject(String name, String? description) async {
    final repo = ref.read(projectRepositoryProvider);
    await repo.create(Project(name: name, description: description));
    ref.read(analyticsServiceProvider).logEvent(
      AnalyticsEvents.projectCreated,
      {AnalyticsParams.method: AnalyticsValues.manual},
    );
    ref.invalidateSelf();
  }

  Future<void> updateProject(Project project) async {
    final repo = ref.read(projectRepositoryProvider);
    await repo.update(project);
    ref.invalidateSelf();
  }

  Future<void> deleteProject(int id) async {
    final repo = ref.read(projectRepositoryProvider);
    await repo.delete(id);
    ref.invalidateSelf();
  }
}
