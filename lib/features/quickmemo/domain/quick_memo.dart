/// A standalone quick field note — text and/or a voice recording.
///
/// Not tied to any project or station; captured from anywhere in the app via
/// the global quick-memo FAB and reviewed later in the quick-memo list.
class QuickMemo {
  final int? id;

  /// Optional typed note. Either [text] or [audioPath] (or both) is present.
  final String? text;

  /// Optional recorded audio file, stored relative to the app documents
  /// directory (e.g. `quick_memos/memo_123.m4a`). Legacy rows may still hold an
  /// absolute path. Resolve with `QuickMemoAudioPaths.resolveOnDevice` before
  /// touching the file.
  final String? audioPath;

  final DateTime createdAt;

  QuickMemo({this.id, this.text, this.audioPath, DateTime? createdAt})
    : createdAt = createdAt ?? DateTime.now();

  bool get hasText => text != null && text!.trim().isNotEmpty;

  bool get hasAudio => audioPath != null && audioPath!.isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'text': text,
      'audio_path': audioPath,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory QuickMemo.fromMap(Map<String, dynamic> map) {
    return QuickMemo(
      id: map['id'] as int?,
      text: map['text'] as String?,
      audioPath: map['audio_path'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  QuickMemo copyWith({
    int? id,
    String? text,
    String? audioPath,
    DateTime? createdAt,
  }) {
    return QuickMemo(
      id: id ?? this.id,
      text: text ?? this.text,
      audioPath: audioPath ?? this.audioPath,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
