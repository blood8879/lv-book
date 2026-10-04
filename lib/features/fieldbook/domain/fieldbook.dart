enum FieldBookReviewStatus { draft, reviewed, needsCheck }

extension FieldBookReviewStatusLabel on FieldBookReviewStatus {
  /// Korean label (legacy). UI and exports use `localizedLabel(l10n)` from
  /// `presentation/fieldbook_l10n.dart`. The persisted value is [name].
  String get label {
    switch (this) {
      case FieldBookReviewStatus.draft:
        return '작성중';
      case FieldBookReviewStatus.reviewed:
        return '검토완료';
      case FieldBookReviewStatus.needsCheck:
        return '확인필요';
    }
  }

  static FieldBookReviewStatus parse(Object? value) {
    final name = value as String?;
    if (name == 'approved') return FieldBookReviewStatus.reviewed;
    if (name == 'rejected' || name == 'inReview') {
      return FieldBookReviewStatus.needsCheck;
    }
    return FieldBookReviewStatus.values
            .where((status) => status.name == name)
            .firstOrNull ??
        FieldBookReviewStatus.draft;
  }
}

class FieldBook {
  static const _unset = Object();

  final int? id;
  final int projectId;
  final String title;
  final DateTime date;
  final int? startBmId;
  final double? startElevation;
  final String? memo;
  final String? surveyor;
  final String? checker;
  final String? instrument;
  final String? weather;
  final String? workSection;
  final String? jobNumber;
  final FieldBookReviewStatus reviewStatus;
  final String? reviewMemo;
  final DateTime? reviewedAt;
  final DateTime createdAt;

  FieldBook({
    this.id,
    required this.projectId,
    required this.title,
    required this.date,
    this.startBmId,
    this.startElevation,
    this.memo,
    this.surveyor,
    this.checker,
    this.instrument,
    this.weather,
    this.workSection,
    this.jobNumber,
    this.reviewStatus = FieldBookReviewStatus.draft,
    this.reviewMemo,
    this.reviewedAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'project_id': projectId,
      'title': title,
      'date': date.toIso8601String(),
      'start_bm_id': startBmId,
      'start_elevation': startElevation,
      'memo': memo,
      'surveyor': surveyor,
      'checker': checker,
      'instrument': instrument,
      'weather': weather,
      'work_section': workSection,
      'job_number': jobNumber,
      'review_status': reviewStatus.name,
      'review_memo': reviewMemo,
      'reviewed_at': reviewedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory FieldBook.fromMap(Map<String, dynamic> map) {
    return FieldBook(
      id: map['id'] as int?,
      projectId: map['project_id'] as int,
      title: map['title'] as String,
      date: DateTime.parse(map['date'] as String),
      startBmId: map['start_bm_id'] as int?,
      startElevation: (map['start_elevation'] as num?)?.toDouble(),
      memo: map['memo'] as String?,
      surveyor: map['surveyor'] as String?,
      checker: map['checker'] as String?,
      instrument: map['instrument'] as String?,
      weather: map['weather'] as String?,
      workSection: map['work_section'] as String?,
      jobNumber: map['job_number'] as String?,
      reviewStatus: FieldBookReviewStatusLabel.parse(map['review_status']),
      reviewMemo: map['review_memo'] as String?,
      reviewedAt: map['reviewed_at'] == null
          ? null
          : DateTime.parse(map['reviewed_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  FieldBook copyWith({
    int? id,
    int? projectId,
    String? title,
    DateTime? date,
    int? startBmId,
    double? startElevation,
    String? memo,
    String? surveyor,
    String? checker,
    String? instrument,
    String? weather,
    String? workSection,
    String? jobNumber,
    FieldBookReviewStatus? reviewStatus,
    Object? reviewMemo = _unset,
    Object? reviewedAt = _unset,
    DateTime? createdAt,
  }) {
    return FieldBook(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      date: date ?? this.date,
      startBmId: startBmId ?? this.startBmId,
      startElevation: startElevation ?? this.startElevation,
      memo: memo ?? this.memo,
      surveyor: surveyor ?? this.surveyor,
      checker: checker ?? this.checker,
      instrument: instrument ?? this.instrument,
      weather: weather ?? this.weather,
      workSection: workSection ?? this.workSection,
      jobNumber: jobNumber ?? this.jobNumber,
      reviewStatus: reviewStatus ?? this.reviewStatus,
      reviewMemo: identical(reviewMemo, _unset)
          ? this.reviewMemo
          : reviewMemo as String?,
      reviewedAt: identical(reviewedAt, _unset)
          ? this.reviewedAt
          : reviewedAt as DateTime?,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
