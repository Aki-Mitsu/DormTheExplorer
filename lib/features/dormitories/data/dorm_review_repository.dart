import '../domain/dorm_review.dart';

abstract interface class DormReviewRepository {
  List<DormReview> reviewsFor(String dormitoryId);

  Future<void> addReview(DormReview review);
}

/// In-memory sample source until reviews are connected to Firestore.
class SampleDormReviewRepository implements DormReviewRepository {
  static final Map<String, List<DormReview>> _reviewsByDormitory = {};

  @override
  List<DormReview> reviewsFor(String dormitoryId) {
    return List.unmodifiable(
      _reviewsByDormitory.putIfAbsent(
        dormitoryId,
        () => _sampleReviews(dormitoryId),
      ),
    );
  }

  @override
  Future<void> addReview(DormReview review) async {
    _reviewsByDormitory
        .putIfAbsent(review.dormitoryId, () => _sampleReviews(review.dormitoryId))
        .insert(0, review);
  }

  List<DormReview> _sampleReviews(String dormitoryId) => [
    DormReview(
      id: 'sample-review-1',
      dormitoryId: dormitoryId,
      authorName: 'Jamie R.',
      authorSubtitle: 'Student seeker',
      rating: 5,
      comment: 'The location is convenient and the rooms feel comfortable.',
      stayLabel: 'Stayed 10 months • Shared room',
      createdAt: DateTime(2026, 3, 18),
    ),
    DormReview(
      id: 'sample-review-2',
      dormitoryId: dormitoryId,
      authorName: 'Alex M.',
      authorSubtitle: 'Student seeker',
      rating: 5,
      comment: 'A peaceful place to study, with helpful management.',
      stayLabel: 'Stayed 1 year • Single room',
      createdAt: DateTime(2026, 2, 5),
    ),
    DormReview(
      id: 'sample-review-3',
      dormitoryId: dormitoryId,
      authorName: 'Sam C.',
      authorSubtitle: 'Student seeker',
      rating: 4,
      comment: 'Good value and close to campus.',
      stayLabel: 'Stayed 6 months • Shared room',
      createdAt: DateTime(2026, 1, 22),
    ),
  ];
}
