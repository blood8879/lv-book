import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/project_dashboard_providers.dart';
import '../data/project_providers.dart';
import '../domain/project.dart';
import '../../fieldbook/presentation/fieldbook_edit_screen.dart';
import 'project_detail_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../shared/widgets/banner_ad_widget.dart';
import '../../../shared/widgets/native_ad_card.dart';
import '../../ads/ad_manager.dart';
import '../../ads/ad_providers.dart';
import '../../backup/project_backup_providers.dart';
import '../../settings/settings_screen.dart';
import '../../quickmemo/presentation/quick_memo_list_screen.dart';
import '../../../core/constants/app_constants.dart';
import '../../../l10n/l10n.dart';

class ProjectListScreen extends ConsumerWidget {
  const ProjectListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectListProvider);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.coreAppName),
        actions: [
          IconButton(
            icon: const Icon(Icons.bolt),
            tooltip: l10n.projectListQuickMemoTooltip,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QuickMemoListScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: l10n.projectListSettingsTooltip,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const _ProEntryPanel(),
          Expanded(
            child: projectsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.only(top: 6),
                child: ListSkeleton(),
              ),
              error: (e, _) =>
                  Center(child: Text(l10n.coreErrorWithDetail('$e'))),
              data: (projects) => _ProjectOverview(projects: projects),
            ),
          ),
          BannerAdWidget(adUnitId: AdManager.banner1Id),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProjectDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Same flow as the FAB; also used by the empty-state primary action.
void _showAddProjectDialog(BuildContext context, WidgetRef ref) {
  final l10n = context.l10n;
  final nameController = TextEditingController();
  final descController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.projectNewDialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: InputDecoration(labelText: l10n.projectSiteNameLabel),
            autofocus: true,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: descController,
            decoration: InputDecoration(
              labelText: l10n.projectDescriptionLabel,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.coreCancel),
        ),
        FilledButton(
          onPressed: () {
            final name = nameController.text.trim();
            if (name.isNotEmpty) {
              ref
                  .read(projectListProvider.notifier)
                  .addProject(
                    name,
                    descController.text.trim().isEmpty
                        ? null
                        : descController.text.trim(),
                  );
              Navigator.pop(context);
            }
          },
          child: Text(l10n.coreAdd),
        ),
      ],
    ),
  );
}

class _ProEntryPanel extends ConsumerWidget {
  const _ProEntryPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final adsRemovedAsync = ref.watch(adsRemovedProvider);
    final adsRemoved = adsRemovedAsync.valueOrNull == true;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Material(
        color: colors.darkSurface,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.darkSurface2,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  adsRemoved ? Icons.verified : Icons.workspace_premium,
                  color: colors.orange,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      adsRemoved
                          ? l10n.projectProActiveTitle
                          : l10n.coreAppProName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      adsRemoved
                          ? l10n.projectProActiveMessage
                          : l10n.projectProPromoMessage,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.72),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (!adsRemoved) ...[
                const SizedBox(width: 8),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF101010),
                  ),
                  onPressed: adsRemovedAsync.isLoading
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SettingsScreen(),
                            ),
                          );
                        },
                  child: Text(l10n.projectProGetButton),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectOverview extends StatelessWidget {
  final List<Project> projects;

  const _ProjectOverview({required this.projects});

  @override
  Widget build(BuildContext context) {
    if (projects.isEmpty) {
      return const _EmptyProjectState();
    }

    final colors = context.appColors;
    // 저빈도 규칙: 화면당 네이티브 광고 1개. 프로젝트가 2개 이상이면 2번째 카드 뒤,
    // 1개면 그 카드 뒤에 삽입.
    final adAfterIndex = projects.length >= 2 ? 1 : 0;

    final children = <Widget>[
      const _BackupReminderBanner(),
      _ProjectSummary(projectCount: projects.length),
      _RecentFieldBookTile(projects: projects),
      Padding(
        padding: const EdgeInsets.fromLTRB(6, 10, 6, 4),
        child: Text(
          context.l10n.projectSitesHeader,
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colors.subtext,
          ),
        ),
      ),
    ];
    for (var i = 0; i < projects.length; i++) {
      children.add(_ProjectCard(project: projects[i]));
      if (i == adAfterIndex) {
        children.add(const NativeAdCard());
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        12,
        6,
        12,
        AppConstants.quickMemoFabClearance,
      ),
      children: children,
    );
  }
}

class _RecentFieldBookTile extends ConsumerWidget {
  final List<Project> projects;

  const _RecentFieldBookTile({required this.projects});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider).valueOrNull;
    final recent = stats?.recentFieldBook;
    if (recent == null) return const SizedBox.shrink();

    final project = projects
        .where((item) => item.id == recent.projectId)
        .firstOrNull;
    if (project == null) return const SizedBox.shrink();

    final colors = context.appColors;
    // Material (not a decorated Container) owns the fill so the ListTile's
    // ink splash paints on it instead of being hidden underneath.
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: colors.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colors.orangeSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.edit_note_outlined, color: colors.orange),
          ),
          title: Text(
            recent.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            context.l10n.projectRecentWorkSubtitle(
              project.name,
              DateFormat('yyyy-MM-dd').format(recent.date),
            ),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FieldBookEditScreen(
                  fieldBook: recent,
                  projectId: recent.projectId,
                ),
              ),
            ).then((_) => ref.invalidate(dashboardStatsProvider));
          },
        ),
      ),
    );
  }
}

class _BackupReminderBanner extends ConsumerWidget {
  const _BackupReminderBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reminderAsync = ref.watch(backupReminderProvider);
    final reminder = reminderAsync.valueOrNull;
    if (reminder == null) return const SizedBox.shrink();

    final colors = context.appColors;
    final days = reminder.daysSinceLastShare;
    final l10n = context.l10n;
    final title = days == null
        ? l10n.projectBackupNeverSharedTitle
        : l10n.projectBackupLastSharedTitle(days);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: colors.orangeSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.orange),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.arrow_upward, color: colors.orange, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: colors.orange),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.projectBackupReminderMessage,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.subtext, height: 1.3),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.orange,
                    side: BorderSide(color: colors.orange),
                  ),
                  onPressed: () async {
                    await ref
                        .read(backupSettingsRepositoryProvider)
                        .setReminderSnoozedAt(DateTime.now());
                    ref.invalidate(backupReminderProvider);
                  },
                  child: Text(l10n.projectBackupLaterButton),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.orange,
                    foregroundColor: colors.paper,
                  ),
                  onPressed: () async {
                    try {
                      final count = await ref.read(
                        allProjectsBackupShareProvider,
                      )();
                      if (count > 0 && context.mounted) {
                        AppSnackbar.success(
                          context,
                          l10n.projectBackupSharedMessage(count),
                        );
                      }
                    } catch (error) {
                      if (context.mounted) {
                        AppSnackbar.error(
                          context,
                          l10n.projectBackupShareError('$error'),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.ios_share, size: 18),
                  label: Text(l10n.projectBackupShareButton),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProjectSummary extends ConsumerWidget {
  final int projectCount;

  const _ProjectSummary({required this.projectCount});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider).valueOrNull;
    final colors = context.appColors;
    final l10n = context.l10n;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colors.greenSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.map_outlined, color: colors.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.projectSummaryTitle(projectCount),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  stats == null
                      ? l10n.projectSummaryLoading
                      : stats.totalOpen > 0
                      ? l10n.projectSummaryStatsOpen(
                          stats.totalFieldBooks,
                          stats.totalOpen,
                        )
                      : l10n.projectSummaryStatsAllReviewed(
                          stats.totalFieldBooks,
                        ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyProjectState extends ConsumerStatefulWidget {
  const _EmptyProjectState();

  @override
  ConsumerState<_EmptyProjectState> createState() => _EmptyProjectStateState();
}

class _EmptyProjectStateState extends ConsumerState<_EmptyProjectState> {
  bool _creatingSample = false;

  Future<void> _openSampleProject() async {
    if (_creatingSample) return;
    setState(() => _creatingSample = true);

    // Captured up front: refreshing the list replaces this empty state.
    final container = ProviderScope.containerOf(context, listen: false);
    final navigator = Navigator.of(context);
    final l10n = context.l10n;
    try {
      final project = await ref
          .read(sampleProjectServiceProvider)
          .createSampleProject(l10n: l10n);
      if (!mounted) return;
      AppSnackbar.success(context, l10n.projectSampleCreatedMessage);
      container.invalidate(projectListProvider);
      container.invalidate(dashboardStatsProvider);
      navigator
          .push(
            MaterialPageRoute(
              builder: (_) => ProjectDetailScreen(project: project),
            ),
          )
          .then((_) => container.invalidate(dashboardStatsProvider));
    } catch (_) {
      if (!mounted) return;
      setState(() => _creatingSample = false);
      AppSnackbar.error(context, l10n.projectSampleCreateError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return EmptyState(
      icon: Icons.construction,
      title: l10n.projectEmptyTitle,
      message: l10n.projectEmptyMessage,
      primaryAction: EmptyStateAction(
        label: l10n.projectEmptyNewButton,
        icon: Icons.add,
        onPressed: _creatingSample
            ? null
            : () => _showAddProjectDialog(context, ref),
      ),
      secondaryAction: EmptyStateAction(
        label: l10n.projectEmptySampleButton,
        icon: Icons.menu_book_outlined,
        busy: _creatingSample,
        onPressed: _openSampleProject,
      ),
    );
  }
}

class _ProjectCard extends ConsumerWidget {
  final Project project;

  const _ProjectCard({required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final description = project.description?.trim();
    final stats = ref
        .watch(dashboardStatsProvider)
        .valueOrNull
        ?.statsFor(project.id);
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: colors.greenSoft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.business_outlined, color: colors.green, size: 22),
        ),
        title: Text(project.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (description != null && description.isNotEmpty)
                Text(description, maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(
                l10n.projectCardUpdated(
                  DateFormat('yyyy-MM-dd').format(project.updatedAt),
                ),
              ),
              if (stats != null && stats.total > 0)
                Text(
                  stats.openCount > 0
                      ? l10n.projectCardStatsOpen(stats.total, stats.openCount)
                      : l10n.projectCardStats(stats.total),
                ),
            ],
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _showEditDialog(context, ref);
            } else if (value == 'delete') {
              _showDeleteDialog(context, ref);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(value: 'edit', child: Text(l10n.coreEdit)),
            PopupMenuItem(value: 'delete', child: Text(l10n.coreDelete)),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProjectDetailScreen(project: project),
            ),
          ).then((_) => ref.invalidate(dashboardStatsProvider));
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final nameController = TextEditingController(text: project.name);
    final descController = TextEditingController(
      text: project.description ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.projectEditDialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: l10n.projectSiteNameLabel),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: InputDecoration(
                labelText: l10n.projectDescriptionLabel,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.coreCancel),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                ref
                    .read(projectListProvider.notifier)
                    .updateProject(
                      project.copyWith(
                        name: name,
                        description: descController.text.trim().isEmpty
                            ? null
                            : descController.text.trim(),
                      ),
                    );
                Navigator.pop(context);
              }
            },
            child: Text(l10n.coreSave),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.projectDeleteDialogTitle),
        content: Text(l10n.projectDeleteConfirm(project.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.coreCancel),
          ),
          FilledButton(
            onPressed: () {
              ref.read(projectListProvider.notifier).deleteProject(project.id!);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.coreDelete),
          ),
        ],
      ),
    );
  }
}
