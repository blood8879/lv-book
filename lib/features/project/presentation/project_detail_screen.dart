import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
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
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.description_outlined), text: '야장'),
              Tab(icon: Icon(Icons.pin_drop_outlined), text: 'BM 관리'),
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
