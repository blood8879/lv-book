import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../data/benchmark_media_services.dart';
import '../data/benchmark_providers.dart';
import '../domain/benchmark.dart';
import '../../../shared/widgets/banner_ad_widget.dart';
import '../../ads/ad_manager.dart';
import '../../ads/ad_providers.dart';

class BenchmarkListScreen extends ConsumerWidget {
  final int projectId;

  const BenchmarkListScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final benchmarksAsync = ref.watch(benchmarkListProvider(projectId));
    final isPro = ref.watch(adsRemovedProvider).valueOrNull ?? false;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: benchmarksAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('오류: $e')),
              data: (benchmarks) {
                if (benchmarks.isEmpty) {
                  return const Center(
                    child: Text(
                      'BM(기준점)이 없습니다.\n+ 버튼을 눌러 추가하세요.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 96),
                  itemCount: benchmarks.length,
                  itemBuilder: (context, index) {
                    final bm = benchmarks[index];
                    return Card(
                      child: ListTile(
                        onTap: () =>
                            _showLocationPanel(context, ref, bm, isPro: isPro),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        leading: Container(
                          width: 42,
                          height: 42,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: bm.isSelectableForFieldBook
                                ? AppTheme.fieldGreen.withValues(alpha: 0.1)
                                : Theme.of(context).colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            bm.kind.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: bm.isSelectableForFieldBook
                                  ? AppTheme.fieldGreen
                                  : Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                        title: Text(
                          bm.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('표고 ${bm.elevation.toStringAsFixed(3)} m'),
                            Text(
                              '종류: ${bm.kind.label}',
                              style: const TextStyle(color: Color(0xFF6D665B)),
                            ),
                            Text(
                              '상태: ${bm.status.label}',
                              style: TextStyle(
                                color: bm.isSelectableForFieldBook
                                    ? const Color(0xFF6D665B)
                                    : Theme.of(context).colorScheme.error,
                              ),
                            ),
                            if (bm.locationHint != null &&
                                bm.locationHint!.isNotEmpty)
                              Text(
                                '위치: ${bm.locationHint!}',
                                style: const TextStyle(
                                  color: Color(0xFF6D665B),
                                ),
                              ),
                            if (bm.description != null &&
                                bm.description!.isNotEmpty)
                              Text(
                                bm.description!,
                                style: const TextStyle(
                                  color: Color(0xFF6D665B),
                                ),
                              ),
                            if (bm.protectionNote != null &&
                                bm.protectionNote!.isNotEmpty)
                              Text(
                                '보호: ${bm.protectionNote!}',
                                style: const TextStyle(
                                  color: Color(0xFF6D665B),
                                ),
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
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('수정'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('삭제'),
                            ),
                          ],
                        ),
                      ),
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

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final elevationController = TextEditingController();
    final descController = TextEditingController();
    final locationController = TextEditingController();
    final protectionController = TextEditingController();
    var status = BenchMarkStatus.available;
    var kind = BenchMarkKind.bm;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('새 BM 추가'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'BM 이름 *',
                    hintText: '예: BM.1',
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: elevationController,
                  decoration: const InputDecoration(
                    labelText: '표고 (m) *',
                    hintText: '예: 100.000',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: '설명 (선택)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(labelText: '현장 위치 힌트'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: protectionController,
                  decoration: const InputDecoration(labelText: '보호/확인 메모'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<BenchMarkStatus>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: '상태'),
                  items: BenchMarkStatus.values
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value.label),
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
                  decoration: const InputDecoration(labelText: '종류'),
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
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                final elevation = double.tryParse(
                  elevationController.text.trim(),
                );
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
              child: const Text('추가'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, BenchMark bm) {
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

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('BM 수정'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'BM 이름 *'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: elevationController,
                  decoration: const InputDecoration(labelText: '표고 (m) *'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: '설명 (선택)'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(labelText: '현장 위치 힌트'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: protectionController,
                  decoration: const InputDecoration(labelText: '보호/확인 메모'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<BenchMarkStatus>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: '상태'),
                  items: BenchMarkStatus.values
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value.label),
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
                  decoration: const InputDecoration(labelText: '종류'),
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
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                final elevation = double.tryParse(
                  elevationController.text.trim(),
                );
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
              child: const Text('저장'),
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
                            color: AppTheme.fieldGreen.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            current.kind.label,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: AppTheme.fieldGreen,
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
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Pro 위치 기록',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (!isPro) ...[
                      if (current.hasPhoto || current.hasCoordinate)
                        const Text(
                          'Pro 위치 정보 저장됨',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        )
                      else
                        const Text('Pro에서 TBM/BM 사진과 좌표를 저장할 수 있습니다.'),
                    ] else ...[
                      if (coordinate != null) ...[
                        Text(
                          coordinate,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        if (current.coordinateAccuracyM != null)
                          Text(
                            '정확도 ${current.coordinateAccuracyM!.toStringAsFixed(1)}m',
                          ),
                      ] else
                        const Text('저장된 좌표가 없습니다.'),
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
                                      errorMessage = error.message;
                                    });
                                  } on BenchmarkProActionException catch (
                                    error
                                  ) {
                                    setModalState(() {
                                      errorMessage = error.message;
                                    });
                                  } finally {
                                    setModalState(() {
                                      isCapturing = false;
                                    });
                                  }
                                },
                          icon: const Icon(Icons.my_location),
                          label: Text(isCapturing ? '좌표 저장 중' : '현재 좌표 저장'),
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
                                        .copyCoordinate(current);
                                  } on BenchmarkMapLaunchException catch (
                                    error
                                  ) {
                                    setModalState(() {
                                      errorMessage = error.message;
                                    });
                                  } on BenchmarkProActionException catch (
                                    error
                                  ) {
                                    setModalState(() {
                                      errorMessage = error.message;
                                    });
                                  }
                                },
                                icon: const Icon(Icons.copy),
                                label: const Text('좌표 복사'),
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
                                      errorMessage = error.message;
                                    });
                                  } on BenchmarkProActionException catch (
                                    error
                                  ) {
                                    setModalState(() {
                                      errorMessage = error.message;
                                    });
                                  }
                                },
                                icon: const Icon(Icons.map),
                                label: const Text('지도 열기'),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 14),
                      Text(
                        current.hasPhoto ? '사진 저장됨' : '저장된 사진이 없습니다.',
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
                              return const Text('사진 파일을 찾을 수 없습니다.');
                            }
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                file,
                                key: const Key('benchmark-photo-preview'),
                                height: 160,
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
                                setModalState: setModalState,
                                onUpdated: (updated) => current = updated,
                                onError: (message) => errorMessage = message,
                              ),
                              icon: const Icon(Icons.photo_camera),
                              label: const Text('사진 촬영'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _attachBenchmarkPhoto(
                                ref,
                                current,
                                ImageSource.gallery,
                                setModalState: setModalState,
                                onUpdated: (updated) => current = updated,
                                onError: (message) => errorMessage = message,
                              ),
                              icon: const Icon(Icons.photo_library),
                              label: const Text('사진 선택'),
                            ),
                          ),
                        ],
                      ),
                      if (current.hasPhoto) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
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
                                  errorMessage = error.message;
                                });
                              }
                            },
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('사진 제거'),
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
    required StateSetter setModalState,
    required ValueChanged<BenchMark> onUpdated,
    required ValueChanged<String> onError,
  }) async {
    final benchmarkId = current.id;
    if (benchmarkId == null) {
      setModalState(() => onError('저장된 BM만 사진을 추가할 수 있습니다.'));
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
      setModalState(() => onError(error.message));
    } catch (_) {
      setModalState(() => onError('사진을 저장하지 못했습니다.'));
    }
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, BenchMark bm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('BM 삭제'),
        content: Text('"${bm.name}" (표고: ${bm.elevation})을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              ref
                  .read(benchmarkListProvider(projectId).notifier)
                  .deleteBenchmark(bm.id!);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('삭제'),
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
