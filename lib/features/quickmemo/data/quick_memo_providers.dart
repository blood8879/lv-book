import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/quick_memo.dart';
import 'quick_memo_audio_paths.dart';
import 'quick_memo_repository.dart';

final quickMemoRepositoryProvider = Provider<QuickMemoRepository>((ref) {
  return QuickMemoRepository();
});

/// Loads and mutates the standalone quick-memo list (newest first).
class QuickMemoListNotifier extends AsyncNotifier<List<QuickMemo>> {
  QuickMemoRepository get _repository => ref.read(quickMemoRepositoryProvider);

  @override
  Future<List<QuickMemo>> build() {
    return _repository.list();
  }

  /// [audioPath] is the recording's absolute path; it is persisted relative to
  /// the app documents directory (see [QuickMemoAudioPaths]).
  Future<void> addMemo({String? text, String? audioPath}) async {
    final storedAudioPath = audioPath == null
        ? null
        : await QuickMemoAudioPaths.toStoredOnDevice(audioPath);
    final memo = QuickMemo(text: text, audioPath: storedAudioPath);
    await _repository.create(memo);
    state = AsyncData(await _repository.list());
  }

  Future<void> delete(QuickMemo memo) async {
    if (memo.id != null) {
      await _repository.delete(memo.id!);
    }
    // Best-effort cleanup of the orphaned recording; never block deletion.
    if (memo.hasAudio) {
      try {
        final file = File(
          await QuickMemoAudioPaths.resolveOnDevice(memo.audioPath!),
        );
        if (await file.exists()) await file.delete();
      } catch (_) {
        // Ignore filesystem errors; the DB row is already gone.
      }
    }
    state = AsyncData(await _repository.list());
  }
}

final quickMemoListProvider =
    AsyncNotifierProvider<QuickMemoListNotifier, List<QuickMemo>>(
      QuickMemoListNotifier.new,
    );
