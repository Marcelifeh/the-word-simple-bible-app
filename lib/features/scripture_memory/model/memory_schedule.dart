enum MemoryStatus {
  newVerse,
  learning,
  reviewing,
  established,
  archived,
}

class MemorySchedule {
  const MemorySchedule({
    required this.status,
    required this.stage,
    required this.dueLocalDate,
    this.lastReviewedLocalDate,
    this.reviewCount = 0,
    this.lapseCount = 0,
    this.hasReachedEstablished = false,
  });

  final MemoryStatus status;
  final int stage;
  final String dueLocalDate;
  final String? lastReviewedLocalDate;
  final int reviewCount;
  final int lapseCount;
  final bool hasReachedEstablished;

  MemorySchedule copyWith({
    MemoryStatus? status,
    int? stage,
    String? dueLocalDate,
    String? lastReviewedLocalDate,
    int? reviewCount,
    int? lapseCount,
    bool? hasReachedEstablished,
  }) {
    return MemorySchedule(
      status: status ?? this.status,
      stage: stage ?? this.stage,
      dueLocalDate: dueLocalDate ?? this.dueLocalDate,
      lastReviewedLocalDate:
          lastReviewedLocalDate ?? this.lastReviewedLocalDate,
      reviewCount: reviewCount ?? this.reviewCount,
      lapseCount: lapseCount ?? this.lapseCount,
      hasReachedEstablished:
          hasReachedEstablished ?? this.hasReachedEstablished,
    );
  }

  Map<String, dynamic> toJson() => {
        'status': status.name,
        'stage': stage,
        'dueLocalDate': dueLocalDate,
        'lastReviewedLocalDate': lastReviewedLocalDate,
        'reviewCount': reviewCount,
        'lapseCount': lapseCount,
        'hasReachedEstablished': hasReachedEstablished,
      };

  factory MemorySchedule.fromJson(Map<String, dynamic> json) {
    return MemorySchedule(
      status: MemoryStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => MemoryStatus.newVerse,
      ),
      stage: (json['stage'] as num?)?.toInt() ?? 0,
      dueLocalDate: json['dueLocalDate']?.toString() ?? '',
      lastReviewedLocalDate: json['lastReviewedLocalDate']?.toString(),
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      lapseCount: (json['lapseCount'] as num?)?.toInt() ?? 0,
      hasReachedEstablished: json['hasReachedEstablished'] == true ||
          ((json['stage'] as num?)?.toInt() ?? 0) >= 5,
    );
  }
}
