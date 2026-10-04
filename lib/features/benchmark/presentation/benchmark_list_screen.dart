import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/semantic_pill.dart';
import '../../../core/widgets/skeleton.dart';
import '../data/benchmark_media_services.dart';
import '../data/benchmark_providers.dart';
import '../domain/benchmark.dart';
import '../../../shared/widgets/banner_ad_widget.dart';
import '../../ads/ad_manager.dart';
import '../../ads/ad_providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../l10n/l10n.dart';

class BenchmarkListScreen extends ConsumerWidget {
  final int projectId;

  const BenchmarkListScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final benchmarksAsync = ref.watch(benchmarkListProvider(projectId));
    final isPro = ref.watch(adsRemovedProvider).valueOrNull ?? false;
    final colors = context.appColors;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: benchmarksAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.only(top: 8),
                child: ListSkeleton(),
              ),
              error: (e, _) =>
                  Center(child: Text(context.l10n.coreErrorWithDetail('$e'))),
              data: (benchmarks) {
                if (benchmarks.isEmpty) {
                  return EmptyState(
                    icon: Icons.flag_outlined,
                    title: context.l10n.benchmarkEmptyTitle,
                    message: context.l10n.benchmarkEmptyMessage,
                    accent: colors.blue,
                    accentSoft: colors.blueSoft,
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    8,
                    8,
                    8,
                    AppConstants.quickMemoFabClearance,
                  ),
                  itemCount: benchmarks.length,
                  itemBuilder: (context, index) {
                    return _buildBenchmarkCard(
                      context,
                      ref,
                      benchmarks[index],
                      isPro: isPro,
                    );
                  },
                );
              },
            ),
          ),
          BannerAdWidget(adUnitId: AdManager.banner2Id),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBenchmarkCard(
    BuildContext context,
    WidgetRef ref,
    BenchMark bm, {
    required bool isPro,
  }) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final (
      Color badgeFg,
      Color badgeBg,
      SemanticPillVariant variant,
    ) = switch (bm.status) {
      BenchMarkStatus.available => (
        colors.green,
        colors.greenSoft,
        SemanticPillVariant.green,
      ),
      BenchMarkStatus.damagedSuspected => (
        colors.orange,
        colors.orangeSoft,
        SemanticPillVariant.orange,
      ),
      BenchMarkStatus.stopped => (
        colors.err,
        colors.errSoft,
        SemanticPillVariant.err,
      ),
    };
    final isStopped = bm.status == BenchMarkStatus.stopped;
    final lineColor = isStopped ? colors.err : colors.subtext;

    return Card(
      color: isStopped ? colors.errSoft : null,
      shape: isStopped
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: colors.err),
            )
          : null,
      child: ListTile(
        onTap: () => _showLocationPanel(context, ref, bm, isPro: isPro),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        leading: Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: badgeBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            bm.kind.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: badgeFg,
            ),
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                bm.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            SemanticPill(
              label: bm.status.localizedLabel(l10n),
              variant: variant,
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.benchmarkElevationLine(bm.elevation.toStringAsFixed(3)),
              style: TextStyle(
                color: isStopped ? colors.err : null,
                fontFeatures: AppTypography.tabularFeatures,
              ),
            ),
            Text(
              l10n.benchmarkKindLine(bm.kind.label),
              style: TextStyle(color: lineColor),
            ),
            if (bm.locationHint != null && bm.locationHint!.isNotEmpty)
              Text(
                l10n.benchmarkLocationLine(bm.locationHint!),
                style: TextStyle(color: lineColor),
              ),
            if (bm.description != null && bm.description!.isNotEmpty)
              Text(bm.description!, style: TextStyle(color: lineColor)),
            if (bm.protectionNote != null && bm.protectionNote!.isNotEmpty)
              Text(
                l10n.benchmarkProtectionLine(bm.protectionNote!),
                style: TextStyle(color: lineColor),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              _showEditDialog(context, ref, bm);
            } else if (value == 'delete') {
              _showDeleteDialog(context, ref, bm);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(value: 'edit', child: Text(l10n.coreEdit)),
            PopupMenuItem(value: 'delete', child: Text(l10n.coreDelete)),
          ],
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final nameController = TextEditingController();
    final elevationController = TextEditingController();
    final descController = TextEditingController();
    final locationController = TextEditingController();
    final protectionController = TextEditingController();
    var status = BenchMarkStatus.available;
    var kind = BenchMarkKind.bm;
    String? nameError;
    String? elevationError;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.benchmarkAddDialogTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: l10n.benchmarkNameLabel,
                    hintText: l10n.benchmarkNameHint,
                    errorText: nameError,
                  ),
                  autofocus: true,
                  onChanged: (value) {
                    if (nameError != null && value.trim().isNotEmpty) {
                      setState(() => nameError = null);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: elevationController,
                  decoration: InputDecoration(
                    labelText: l10n.benchmarkElevationLabel,
                    hintText: l10n.benchmarkElevationHint,
                    errorText: elevationError,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (value) {
                    if (elevationError != null &&
                        double.tryParse(value.trim()) != null) {
                      setState(() => elevationError = null);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: InputDecoration(
                    labelText: l10n.benchmarkDescriptionLabel,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locationController,
                  decoration: InputDecoration(
                    labelText: l10n.benchmarkLocationHintLabel,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: protectionController,
                  decoration: InputDecoration(
                    labelText: l10n.benchmarkProtectionLabel,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<BenchMarkStatus>(
                  initialValue: status,
                  decoration: InputDecoration(
                    labelText: l10n.benchmarkStatusLabel,
                  ),
                  items: BenchMarkStatus.values
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value.localizedLabel(l10n)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => status = value);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<BenchMarkKind>(
                  initialValue: kind,
                  decoration: InputDecoration(
                    labelText: l10n.benchmarkKindLabel,
                  ),
                  items: BenchMarkKind.values
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => kind = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.coreCancel),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                final elevation = double.tryParse(
                  elevationController.text.trim(),
                );
                setState(() {
                  nameError = name.isEmpty
                      ? l10n.benchmarkNameRequiredError
                      : null;
                  elevationError = elevation == null
                      ? l10n.benchmarkElevationInvalidError
                      : null;
                });
                if (name.isNotEmpty && elevation != null) {
                  ref
                      .read(benchmarkListProvider(projectId).notifier)
                      .addBenchmark(
                        name,
                        elevation,
                        descController.text.trim().isEmpty
                            ? null
                            : descController.text.trim(),
                        locationHint: _blankToNull(locationController.text),
                        protectionNote: _blankToNull(protectionController.text),
                        lastVerifiedAt: DateTime.now(),
                        status: status,
                        kind: kind,
                      );
                  Navigator.pop(context);
                }
              },
              child: Text(l10n.coreAdd),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, BenchMark bm) {
    final l10n = context.l10n;
    final nameController = TextEditingController(text: bm.name);
    final elevationController = TextEditingController(
      text: bm.elevation.toString(),
    );
    final descController = TextEditingController(text: bm.description ?? '');
    final locationController = TextEditingController(
      text: bm.locationHint ?? '',
    );
    final protectionController = TextEditingController(
      text: bm.protectionNote ?? '',
    );
    var status = bm.status;
    var kind = bm.kind;
    String? nameError;
    String? elevationError;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.benchmarkEditDialogTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: l10n.benchmarkNameLabel,
                    errorText: nameError,
                  ),
                  onChanged: (value) {
                    if (nameError != null && value.trim().isNotEmpty) {
                      setState(() => nameError = null);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: elevationController,
                  decoration: InputDecoration(
                    labelText: l10n.benchmarkElevationLabel,
                    errorText: elevationError,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (value) {
                    if (elevationError != null &&
                        double.tryParse(value.trim()) != null) {
                      setState(() => elevationError = null);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: InputDecoration(
                    labelText: l10n.benchmarkDescriptionLabel,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locationController,
                  decoration: InputDecoration(
                    labelText: l10n.benchmarkLocationHintLabel,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: protectionController,
                  decoration: InputDecoration(
                    labelText: l10n.benchmarkProtectionLabel,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<BenchMarkStatus>(
                  initialValue: status,
                  decoration: InputDecoration(
                    labelText: l10n.benchmarkStatusLabel,
                  ),
                  items: BenchMarkStatus.values
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value.localizedLabel(l10n)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => status = value);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<BenchMarkKind>(
                  initialValue: kind,
                  decoration: InputDecoration(
                    labelText: l10n.benchmarkKindLabel,
                  ),
                  items: BenchMarkKind.values
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => kind = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.coreCancel),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                final elevation = double.tryParse(
                  elevationController.text.trim(),
                );
                setState(() {
                  nameError = name.isEmpty
                      ? l10n.benchmarkNameRequiredError
                      : null;
                  elevationError = elevation == null
                      ? l10n.benchmarkElevationInvalidError
                      : null;
                });
                if (name.isNotEmpty && elevation != null) {
                  ref
                      .read(benchmarkListProvider(projectId).notifier)
                      .updateBenchmark(
                        bm.copyWith(
                          name: name,
                          elevation: elevation,
                          description: descController.text.trim().isEmpty
                              ? null
                              : descController.text.trim(),
                          locationHint: _blankToNull(locationController.text),
                          protectionNote: _blankToNull(
                            protectionController.text,
                          ),
                          lastVerifiedAt: DateTime.now(),
                          status: status,
                          kind: kind,
                        ),
                      );
                  Navigator.pop(context);
                }
              },
              child: Text(l10n.coreSave),
            ),
          ],
        ),
      ),
    );
  }

  void _showLocationPanel(
    BuildContext context,
    WidgetRef ref,
    BenchMark benchmark, {
    required bool isPro,
  }) {
    var current = benchmark;
    var isCapturing = false;
    String? errorMessage;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final colors = context.appColors;
          final l10n = context.l10n;
          final coordinate = current.formattedCoordinate;
          return SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: colors.greenSoft,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            current.kind.label,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: colors.green,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            current.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      l10n.benchmarkProLocationTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (!isPro) ...[
                      if (current.hasPhoto || current.hasCoordinate)
                        Text(
                          l10n.benchmarkProLocationSaved,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        )
                      else
                        Text(l10n.benchmarkProLocationPromo),
                    ] else ...[
                      if (coordinate != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: colors.soft,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                coordinate,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: AppTypography.tabularFeatures,
                                ),
                              ),
                              if (current.coordinateAccuracyM != null)
                                Text(
                                  l10n.benchmarkAccuracy(
                                    current.coordinateAccuracyM!
                                        .toStringAsFixed(1),
                                  ),
                                  style: TextStyle(
                                    color: colors.subtext,
                                    fontFeatures: AppTypography.tabularFeatures,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ] else
                        Text(l10n.benchmarkNoSavedCoordinate),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: isCapturing
                              ? null
                              : () async {
                                  setModalState(() {
                                    isCapturing = true;
                                    errorMessage = null;
                                  });
                                  try {
                                    final updated = await ref
                                        .read(benchmarkProActionServiceProvider)
                                        .captureCoordinate(
                                          benchmark: current,
                                          updateBenchmark: ref
                                              .read(
                                                benchmarkListProvider(
                                                  projectId,
                                                ).notifier,
                                              )
                                              .updateBenchmark,
                                        );
                                    setModalState(() {
                                      current = updated;
                                    });
                                  } on BenchmarkLocationException catch (
                                    error
                                  ) {
                                    setModalState(() {
                                      errorMessage = error.localizedMessage(
                                        l10n,
                                      );
                                    });
                                  } on BenchmarkProActionException catch (
                                    error
                                  ) {
                                    setModalState(() {
                                      errorMessage = error.localizedMessage(
                                        l10n,
                                      );
                                    });
                                  } finally {
                                    setModalState(() {
                                      isCapturing = false;
                                    });
                                  }
                                },
                          icon: const Icon(Icons.my_location),
                          label: Text(
                            isCapturing
                                ? l10n.benchmarkSavingCoordinate
                                : l10n.benchmarkSaveCurrentCoordinate,
                          ),
                        ),
                      ),
                      if (current.hasCoordinate) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  try {
                                    await ref
                                        .read(benchmarkProActionServiceProvider)
                                        .copyCoordinate(current, l10n: l10n);
                                  } on BenchmarkMapLaunchException catch (
                                    error
                                  ) {
                                    setModalState(() {
                                      errorMessage = error.localizedMessage(
                                        l10n,
                                      );
                                    });
                                  } on BenchmarkProActionException catch (
                                    error
                                  ) {
                                    setModalState(() {
                                      errorMessage = error.localizedMessage(
                                        l10n,
                                      );
                                    });
                                  }
                                },
                                icon: const Icon(Icons.copy),
                                label: Text(l10n.benchmarkCopyCoordinateButton),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  try {
                                    await ref
                                        .read(benchmarkProActionServiceProvider)
                                        .openMap(current);
                                  } on BenchmarkMapLaunchException catch (
                                    error
                                  ) {
                                    setModalState(() {
                                      errorMessage = error.localizedMessage(
                                        l10n,
                                      );
                                    });
                                  } on BenchmarkProActionException catch (
                                    error
                                  ) {
                                    setModalState(() {
                                      errorMessage = error.localizedMessage(
                                        l10n,
                                      );
                                    });
                                  }
                                },
                                icon: const Icon(Icons.map),
                                label: Text(l10n.benchmarkOpenMapButton),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 14),
                      Text(
                        current.hasPhoto
                            ? l10n.benchmarkPhotoSaved
                            : l10n.benchmarkNoSavedPhoto,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      if (current.hasPhoto) ...[
                        const SizedBox(height: 8),
                        FutureBuilder<File?>(
                          future: ref
                              .read(benchmarkPhotoStorageProvider)
                              .photoFile(current.photoPath),
                          builder: (context, snapshot) {
                            final file = snapshot.data;
                            if (snapshot.connectionState !=
                                ConnectionState.done) {
                              return const SizedBox(
                                height: 120,
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            if (file == null) {
                              return Text(l10n.benchmarkPhotoFileMissing);
                            }
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                file,
                                key: const Key('benchmark-photo-preview'),
                                height: 120,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            );
                          },
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _attachBenchmarkPhoto(
                                ref,
                                current,
                                ImageSource.camera,
                                l10n: l10n,
                                setModalState: setModalState,
                                onUpdated: (updated) => current = updated,
                                onError: (message) => errorMessage = message,
                              ),
                              icon: const Icon(Icons.photo_camera),
                              label: Text(l10n.benchmarkTakePhotoButton),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _attachBenchmarkPhoto(
                                ref,
                                current,
                                ImageSource.gallery,
                                l10n: l10n,
                                setModalState: setModalState,
                                onUpdated: (updated) => current = updated,
                                onError: (message) => errorMessage = message,
                              ),
                              icon: const Icon(Icons.photo_library),
                              label: Text(l10n.benchmarkPickPhotoButton),
                            ),
                          ),
                        ],
                      ),
                      if (current.hasPhoto) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colors.err,
                              side: BorderSide(color: colors.err),
                            ),
                            onPressed: () async {
                              try {
                                final updated = await ref
                                    .read(benchmarkProActionServiceProvider)
                                    .removePhoto(
                                      benchmark: current,
                                      updateBenchmark: ref
                                          .read(
                                            benchmarkListProvider(
                                              projectId,
                                            ).notifier,
                                          )
                                          .updateBenchmark,
                                    );
                                setModalState(() {
                                  current = updated;
                                });
                              } on BenchmarkProActionException catch (error) {
                                setModalState(() {
                                  errorMessage = error.localizedMessage(l10n);
                                });
                              }
                            },
                            icon: const Icon(Icons.delete_outline),
                            label: Text(l10n.benchmarkRemovePhotoButton),
                          ),
                        ),
                      ],
                      if (errorMessage != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _attachBenchmarkPhoto(
    WidgetRef ref,
    BenchMark current,
    ImageSource source, {
    required AppLocalizations l10n,
    required StateSetter setModalState,
    required ValueChanged<BenchMark> onUpdated,
    required ValueChanged<String> onError,
  }) async {
    final benchmarkId = current.id;
    if (benchmarkId == null) {
      setModalState(() => onError(l10n.benchmarkPhotoNeedsSavedBm));
      return;
    }

    try {
      final updated = await ref
          .read(benchmarkProActionServiceProvider)
          .attachPhoto(
            benchmark: current,
            source: source,
            updateBenchmark: ref
                .read(benchmarkListProvider(projectId).notifier)
                .updateBenchmark,
          );
      if (updated == null) return;
      setModalState(() {
        onUpdated(updated);
      });
    } on BenchmarkProActionException catch (error) {
      setModalState(() => onError(error.localizedMessage(l10n)));
    } catch (_) {
      setModalState(() => onError(l10n.benchmarkPhotoSaveError));
    }
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, BenchMark bm) {
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.benchmarkDeleteDialogTitle),
        content: Text(
          l10n.benchmarkDeleteConfirm(bm.name, bm.elevation.toString()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.coreCancel),
          ),
          FilledButton(
            onPressed: () {
              ref
                  .read(benchmarkListProvider(projectId).notifier)
                  .deleteBenchmark(bm.id!);
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

  String? _blankToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
