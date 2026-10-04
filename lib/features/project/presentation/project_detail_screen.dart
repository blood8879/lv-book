import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/l10n.dart';
import '../domain/project.dart';
import '../../benchmark/presentation/benchmark_list_screen.dart';
import '../../fieldbook/presentation/fieldbook_list_screen.dart';

class ProjectDetailScreen extends StatelessWidget {
  final Project project;

  const ProjectDetailScreen({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(project.name),
          bottom: TabBar(
            tabs: [
              Tab(
                icon: const Icon(Icons.description_outlined),
                text: context.l10n.projectDetailTabLevelBooks,
              ),
              Tab(
                icon: const Icon(Icons.pin_drop_outlined),
                text: context.l10n.projectDetailTabBenchmarks,
              ),
            ],
          ),
        ),
        body: Container(
          color: colors.paper,
          child: TabBarView(
            children: [
              FieldBookListScreen(projectId: project.id!),
              BenchmarkListScreen(projectId: project.id!),
            ],
          ),
        ),
      ),
    );
  }
}
