import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/dorm_review.dart';

abstract interface class DormReviewRepository {
  Stream<List<DormReview>> watchReviews(String dormitoryId);

  Future<void> addReview(DormReview review);
}

class FirestoreDormReviewRepository implements DormReviewRepository {
  FirestoreDormReviewRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _reviews(String dormitoryId) =>
      _firestore
          .collection('dormitories')
          .doc(dormitoryId)
          .collection('reviews');

  @override
  Stream<List<DormReview>> watchReviews(String dormitoryId) {
    return _reviews(dormitoryId).snapshots().map((snapshot) {
      final reviews = snapshot.docs
          .map((document) => DormReview.fromJson(document.data(), id: document.id))
          .toList();
      reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return List.unmodifiable(reviews);
    });
  }

  @override
  Future<void> addReview(DormReview review) async {
    final reviews = _reviews(review.dormitoryId);
    await reviews.doc(review.id).set(review.toJson());

    final savedReviews = await reviews.get();
    if (savedReviews.docs.isEmpty) return;

    final totalRating = savedReviews.docs.fold<int>(
      0,
      (total, document) =>
          total + ((document.data()['rating'] as num?)?.toInt() ?? 0),
    );
    final averageRating = totalRating / savedReviews.docs.length;

    await _firestore.collection('dormitories').doc(review.dormitoryId).update({
      'averageRating': averageRating,
    });
  }
}
