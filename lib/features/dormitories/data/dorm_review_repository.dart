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
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final seenUids = <String>{};
      final seenUidProfiles = <String>{};
      final seenLegacyProfiles = <String>{};
      final uniqueReviews = reviews.where((review) {
        final profileKey =
            '${review.authorName.trim().toLowerCase()}|${review.authorPhotoUrl ?? ''}';
        final authorUid = review.authorUid;
        if (authorUid?.isNotEmpty == true) {
          if (seenUids.contains(authorUid) ||
              seenLegacyProfiles.contains(profileKey)) {
            return false;
          }
          seenUids.add(authorUid!);
          seenUidProfiles.add(profileKey);
          return true;
        }
        if (seenLegacyProfiles.contains(profileKey) ||
            seenUidProfiles.contains(profileKey)) {
          return false;
        }
        seenLegacyProfiles.add(profileKey);
        return true;
      });
      return List.unmodifiable(uniqueReviews);
    });
  }

  @override
  Future<void> addReview(DormReview review) async {
    final reviews = _reviews(review.dormitoryId);
    final reviewReference = reviews.doc(review.id);
    await _firestore.runTransaction((transaction) async {
      final existingReview = await transaction.get(reviewReference);
      if (existingReview.exists) {
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'already-exists',
          message: 'You have already reviewed this dormitory.',
        );
      }
      transaction.set(reviewReference, review.toJson());
    });

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
