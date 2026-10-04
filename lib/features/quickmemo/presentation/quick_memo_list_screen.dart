import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/skeleton.dart';
import '../data/quick_memo_audio_paths.dart';
import '../data/quick_memo_providers.dart';
import '../domain/quick_memo.dart';
import '../../../core/constants/app_constants.dart';

class QuickMemoListScreen extends ConsumerWidget {
  const QuickMemoListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memosAsync = ref.watch(quickMemoListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('빠른 메모')),
      body: memosAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.only(top: 6),
          child: ListSkeleton(),
        ),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (memos) {
          if (memos.isEmpty) {
            return const EmptyState(
              icon: Icons.bolt,
              title: '저장된 메모가 없어요',
              message: '화면 왼쪽 아래 번개 버튼으로 어디서든 텍스트·음성 메모를 남겨보세요.',
              accent: AppTheme.surveyOrange,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              12,
              8,
              12,
              AppConstants.quickMemoFabClearance,
            ),
            itemCount: memos.length,
            itemBuilder: (context, index) => _QuickMemoCard(memo: memos[index]),
          );
        },
      ),
    );
  }
}

class _QuickMemoCard extends ConsumerWidget {
  final QuickMemo memo;

  const _QuickMemoCard({required this.memo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    return Dismissible(
      key: ValueKey('quick_memo_${memo.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: colors.errSoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.delete_outline, color: colors.err),
      ),
      confirmDismiss: (_) => _confirmDelete(context, colors),
      onDismissed: (_) => ref.read(quickMemoListProvider.notifier).delete(memo),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.panel,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('yyyy-MM-dd HH:mm').format(memo.createdAt),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.subtext),
            ),
            if (memo.hasText) ...[
              const SizedBox(height: 8),
              Text(
                memo.text!.trim(),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
            if (memo.hasAudio) ...[
              const SizedBox(height: 10),
              _AudioPlayerTile(path: memo.audioPath!),
            ],
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, AppColors colors) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('메모 삭제'),
        content: const Text('이 메모를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: colors.err),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

/// Simple play/pause tile for a recorded memo (no waveform), with elapsed and
/// total time.
class _AudioPlayerTile extends StatefulWidget {
  final String path;

  const _AudioPlayerTile({required this.path});

  @override
  State<_AudioPlayerTile> createState() => _AudioPlayerTileState();
}

class _AudioPlayerTileState extends State<_AudioPlayerTile> {
  final _player = AudioPlayer();
  bool _isPlaying = false;
  bool _missing = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _init();
  }

  /// Absolute path of the recording under the current documents directory.
  String? _resolvedPath;

  Future<void> _init() async {
    final String resolved;
    try {
      resolved = await QuickMemoAudioPaths.resolveOnDevice(widget.path);
    } catch (_) {
      if (mounted) setState(() => _missing = true);
      return;
    }
    if (!mounted) return;
    if (!File(resolved).existsSync()) {
      setState(() => _missing = true);
      return;
    }
    _resolvedPath = resolved;
    _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    });
    try {
      await _player.setSource(DeviceFileSource(resolved));
      final d = await _player.getDuration();
      if (d != null && mounted) setState(() => _duration = d);
    } catch (_) {
      if (mounted) setState(() => _missing = true);
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_isPlaying) {
      await _player.pause();
      if (mounted) setState(() => _isPlaying = false);
    } else {
      final path = _resolvedPath;
      if (path == null) return;
      await _player.play(DeviceFileSource(path));
      if (mounted) setState(() => _isPlaying = true);
    }
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    if (_missing) {
      return Row(
        children: [
          Icon(Icons.mic_off, size: 18, color: colors.subtext),
          const SizedBox(width: 8),
          Text(
            '음성 파일을 찾을 수 없습니다.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.subtext),
          ),
        ],
      );
    }

    final total = _duration.inMilliseconds == 0 ? null : _duration;
    final progress = total == null || total.inMilliseconds == 0
        ? 0.0
        : (_position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colors.soft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.line),
      ),
      child: Row(
        children: [
          Material(
            color: colors.orange,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _toggle,
              child: SizedBox(
                width: 40,
                height: 40,
                child: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  color: colors.paper,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: colors.line,
                    color: colors.orange,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  total == null
                      ? _format(_position)
                      : '${_format(_position)} / ${_format(total)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.subtext,
                    fontFeatures: AppTypography.tabularFeatures,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
