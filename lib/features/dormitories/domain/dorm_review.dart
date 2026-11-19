class DormReview {
  const DormReview({
    required this.id,
    required this.dormitoryId,
    required this.authorName,
    required this.authorSubtitle,
    required this.rating,
    required this.comment,
    required this.stayLabel,
    required this.createdAt,
  });

  final String id;
  final String dormitoryId;
  final String authorName;
  final String authorSubtitle;
  final int rating;
  final String comment;
  final String stayLabel;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'dormitoryId': dormitoryId,
    'authorName': authorName,
    'authorSubtitle': authorSubtitle,
    'rating': rating,
    'comment': comment,
    'stayLabel': stayLabel,
    'createdAt': createdAt.toIso8601String(),
  };
}
