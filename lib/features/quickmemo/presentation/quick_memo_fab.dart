import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../data/quick_memo_audio_paths.dart';
import '../data/quick_memo_providers.dart';

/// Opens the quick-memo composer sheet from any context below the Navigator.
Future<void> showQuickMemoComposer(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const QuickMemoComposer(),
  );
}

/// Tracks the navigator's route stack and decides whether the app-wide
/// quick-memo FAB may be shown.
///
/// Screens whose bottom edge carries dense, always-visible content (e.g. the
/// field book editor's validation chips and closure summary) opt out with
/// [HideQuickMemoFab]; the FAB is hidden while such a page is the topmost
/// page route. Popup routes (dialogs, menus, sheets) do not change the result.
class QuickMemoFabController extends NavigatorObserver with ChangeNotifier {
  final List<Route<dynamic>> _stack = [];
  final Set<Route<dynamic>> _suppressed = {};

  bool get visible {
    for (final route in _stack.reversed) {
      if (route is PageRoute) return !_suppressed.contains(route);
    }
    return true;
  }

  void suppress(Route<dynamic> route) {
    if (_suppressed.add(route)) _changed();
  }

  void release(Route<dynamic> route) {
    if (_suppressed.remove(route)) _changed();
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.add(route);
    _changed();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
    _changed();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
    _suppressed.remove(route);
    _changed();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final index = oldRoute == null ? -1 : _stack.indexOf(oldRoute);
    if (newRoute != null) {
      if (index >= 0) {
        _stack[index] = newRoute;
      } else {
        _stack.add(newRoute);
      }
    } else if (index >= 0) {
      _stack.removeAt(index);
    }
    if (oldRoute != null) _suppressed.remove(oldRoute);
    _changed();
  }

  bool _notifyScheduled = false;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  /// Navigator callbacks and [HideQuickMemoFab] registration can run during
  /// the build phase, where rebuilding the sibling FAB is not allowed; defer
  /// the notification to after the frame in that case.
  void _changed() {
    if (_disposed) return;
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase != SchedulerPhase.persistentCallbacks) {
      notifyListeners();
      return;
    }
    if (_notifyScheduled) return;
    _notifyScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _notifyScheduled = false;
      if (!_disposed) notifyListeners();
    });
  }
}

/// Makes a [QuickMemoFabController] reachable from routes below the app's
/// Navigator.
class QuickMemoFabScope extends InheritedWidget {
  final QuickMemoFabController controller;

  const QuickMemoFabScope({
    super.key,
    required this.controller,
    required super.child,
  });

  static QuickMemoFabController? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<QuickMemoFabScope>()?.controller;

  @override
  bool updateShouldNotify(QuickMemoFabScope oldWidget) =>
      controller != oldWidget.controller;
}

/// Hides the app-wide quick-memo FAB while the enclosing page route is the
/// topmost page. No-op when there is no [QuickMemoFabScope] (e.g. in tests).
class HideQuickMemoFab extends StatefulWidget {
  final Widget child;

  const HideQuickMemoFab({super.key, required this.child});

  @override
  State<HideQuickMemoFab> createState() => _HideQuickMemoFabState();
}

class _HideQuickMemoFabState extends State<HideQuickMemoFab> {
  QuickMemoFabController? _controller;
  Route<dynamic>? _route;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = QuickMemoFabScope.maybeOf(context);
    final route = ModalRoute.of(context);
    if (controller == _controller && route == _route) return;
    if (_route != null) _controller?.release(_route!);
    _controller = controller;
    _route = route;
    if (route != null) controller?.suppress(route);
  }

  @override
  void dispose() {
    if (_route != null) _controller?.release(_route!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// App-wide floating action button for capturing a quick field note.
///
/// Mounted once via [MaterialApp.builder] so it overlays every screen. It sits
/// bottom-left so it never collides with per-screen bottom-right FABs. Lists
/// reserve [AppConstants.quickMemoFabClearance] of bottom padding so their
/// last item can scroll clear of it; screens with fixed bottom bars opt out
/// via [HideQuickMemoFab].
class QuickMemoFab extends StatefulWidget {
  /// Navigator key of the root [MaterialApp]; used to obtain an overlay-backed
  /// context for the modal bottom sheet (the FAB lives above the Navigator).
  final GlobalKey<NavigatorState> navigatorKey;

  /// Route-aware visibility; when null the FAB is always shown.
  final QuickMemoFabController? controller;

  const QuickMemoFab({super.key, required this.navigatorKey, this.controller});

  @override
  State<QuickMemoFab> createState() => _QuickMemoFabState();
}

class _QuickMemoFabState extends State<QuickMemoFab> {
  /// True while the composer sheet is open. While open the FAB removes itself
  /// from the tree so it can neither draw over nor intercept taps meant for the
  /// sheet (the FAB shares the bottom-left screen area with the sheet's record
  /// toggle button — see bug: FAB stealing the stop-recording tap and closing
  /// the sheet, losing the in-progress note and audio).
  bool _sheetOpen = false;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    if (controller == null) return _buildFab(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) =>
          controller.visible ? _buildFab(context) : const SizedBox.shrink(),
    );
  }

  Widget _buildFab(BuildContext context) {
    // Fully remove the FAB from the tree while the sheet is open: it is both
    // invisible and excluded from hit-testing, so taps pass to the sheet.
    if (_sheetOpen) return const SizedBox.shrink();

    final colors = AppColors.of(context);
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 80),
          child: Material(
            color: colors.orange,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _open(context),
              child: SizedBox(
                width: 52,
                height: 52,
                child: Icon(Icons.bolt, color: colors.paper, size: 26),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    // The FAB is a sibling of the Navigator, so use the Navigator's overlay
    // context (a descendant) to host the modal sheet.
    final overlayContext = widget.navigatorKey.currentState?.overlay?.context;
    if (overlayContext == null) return;

    setState(() => _sheetOpen = true);
    try {
      await showQuickMemoComposer(overlayContext);
    } finally {
      if (mounted) setState(() => _sheetOpen = false);
    }
  }
}

/// Bottom-sheet composer: type a note and/or tap-toggle a voice recording.
class QuickMemoComposer extends ConsumerStatefulWidget {
  const QuickMemoComposer({super.key});

  @override
  ConsumerState<QuickMemoComposer> createState() => _QuickMemoComposerState();
}

class _QuickMemoComposerState extends ConsumerState<QuickMemoComposer> {
  final _textController = TextEditingController();
  final _recorder = AudioRecorder();

  bool _isRecording = false;
  bool _saving = false;
  String? _recordedPath;
  Duration _elapsed = Duration.zero;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _textController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _recorder.stop();
      _timer?.cancel();
      if (!mounted) return;
      setState(() {
        _isRecording = false;
        _recordedPath = path;
      });
      return;
    }

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      if (mounted) AppSnackbar.error(context, '마이크 권한이 필요합니다.');
      return;
    }

    // Drop any previous take before starting a new one.
    await _discardRecording();

    // Recorded at an absolute path; addMemo persists it relative to the
    // documents directory so it survives iOS container path changes.
    final dir = await getApplicationDocumentsDirectory();
    final memoDir = Directory(p.join(dir.path, QuickMemoAudioPaths.dirName));
    if (!await memoDir.exists()) {
      await memoDir.create(recursive: true);
    }
    final path = p.join(
      memoDir.path,
      'memo_${DateTime.now().millisecondsSinceEpoch}.m4a',
    );

    await _recorder.start(const RecordConfig(), path: path);
    if (!mounted) return;
    setState(() {
      _isRecording = true;
      _elapsed = Duration.zero;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _elapsed += const Duration(seconds: 1));
      }
    });
  }

  Future<void> _discardRecording() async {
    final path = _recordedPath;
    if (path == null) return;
    setState(() => _recordedPath = null);
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Ignore cleanup failures.
    }
  }

  Future<void> _save() async {
    if (_isRecording) {
      _recordedPath = await _recorder.stop();
      _timer?.cancel();
      _isRecording = false;
    }
    final text = _textController.text.trim();
    if (text.isEmpty && _recordedPath == null) return;

    setState(() => _saving = true);
    try {
      await ref
          .read(quickMemoListProvider.notifier)
          .addMemo(text: text.isEmpty ? null : text, audioPath: _recordedPath);
      if (!mounted) return;
      Navigator.pop(context);
      AppSnackbar.success(context, '메모를 저장했습니다.');
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppSnackbar.error(context, '저장 실패: $error');
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final hasRecording = _recordedPath != null;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 16 + bottomInset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt, color: colors.orange, size: 20),
              const SizedBox(width: 6),
              Text('빠른 현장 메모', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _textController,
            minLines: 2,
            maxLines: 4,
            textInputAction: TextInputAction.newline,
            decoration: const InputDecoration(hintText: '메모를 입력하세요 (선택)'),
          ),
          const SizedBox(height: 12),
          _RecordingRow(
            isRecording: _isRecording,
            hasRecording: hasRecording,
            label: _isRecording
                ? '녹음 중 · ${_formatDuration(_elapsed)}'
                : hasRecording
                ? '음성 녹음됨 · 다시 녹음하려면 마이크를 누르세요'
                : '마이크를 눌러 음성 메모를 녹음하세요',
            colors: colors,
            onToggle: _toggleRecording,
            onDiscard: hasRecording && !_isRecording ? _discardRecording : null,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check, size: 18),
              label: const Text('저장'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordingRow extends StatelessWidget {
  final bool isRecording;
  final bool hasRecording;
  final String label;
  final AppColors colors;
  final VoidCallback onToggle;
  final VoidCallback? onDiscard;

  const _RecordingRow({
    required this.isRecording,
    required this.hasRecording,
    required this.label,
    required this.colors,
    required this.onToggle,
    required this.onDiscard,
  });

  @override
  Widget build(BuildContext context) {
    final active = isRecording ? colors.err : colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.soft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.line),
      ),
      child: Row(
        children: [
          Material(
            color: active,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onToggle,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  isRecording ? Icons.stop : Icons.mic,
                  color: colors.paper,
                  size: 22,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colors.subtext),
            ),
          ),
          if (onDiscard != null)
            IconButton(
              tooltip: '녹음 삭제',
              onPressed: onDiscard,
              icon: Icon(Icons.delete_outline, color: colors.subtext),
            ),
        ],
      ),
    );
  }
}
