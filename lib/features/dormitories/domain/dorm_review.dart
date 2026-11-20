class DormReview {
  const DormReview({
    required this.id,
    required this.dormitoryId,
    required this.authorName,
    this.authorPhotoUrl,
    required this.authorSubtitle,
    required this.rating,
    required this.comment,
    required this.stayLabel,
    required this.createdAt,
  });

  final String id;
  final String dormitoryId;
  final String authorName;
  final String? authorPhotoUrl;
  final String authorSubtitle;
  final int rating;
  final String comment;
  final String stayLabel;
  final DateTime createdAt;

  factory DormReview.fromJson(Map<String, dynamic> json, {required String id}) {
    final createdAtValue = json['createdAt'];
    final createdAt = createdAtValue is String
        ? DateTime.tryParse(createdAtValue)
        : null;

    return DormReview(
      id: id,
      dormitoryId: json['dormitoryId'] as String? ?? '',
      authorName: json['authorName'] as String? ?? 'Dorm Seeker',
      authorPhotoUrl: json['authorPhotoUrl'] as String?,
      authorSubtitle: json['authorSubtitle'] as String? ?? 'Student seeker',
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment'] as String? ?? '',
      stayLabel: json['stayLabel'] as String? ?? 'Review',
      createdAt: createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() => {
    'dormitoryId': dormitoryId,
    'authorName': authorName,
    if (authorPhotoUrl != null) 'authorPhotoUrl': authorPhotoUrl,
    'authorSubtitle': authorSubtitle,
    'rating': rating,
    'comment': comment,
    'stayLabel': stayLabel,
    'createdAt': createdAt.toIso8601String(),
  };
}
