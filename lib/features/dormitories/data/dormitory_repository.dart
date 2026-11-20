import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/dormitory.dart';

class DormitoryRepository {
  DormitoryRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _dormitories =>
      _firestore.collection('dormitories');

  Future<String> addDormitory(Dormitory dormitory) async {
    final document = await _dormitories.add({
      ...dormitory.toJson(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return document.id;
  }

  Future<void> updateDormitory(Dormitory dormitory) async {
    final reference = _dormitories.doc(dormitory.id);
    final snapshot = await reference.get();
    if (snapshot.data()?['landlordId'] != dormitory.landlordId) {
      throw StateError('This listing does not belong to the signed-in landlord.');
    }

    final data = dormitory.toJson()..remove('landlordId');
    await reference.update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setAvailability({
    required String dormitoryId,
    required String landlordId,
    required int availableSlots,
  }) async {
    final reference = _dormitories.doc(dormitoryId);
    final snapshot = await reference.get();
    final data = snapshot.data();
    if (data?['landlordId'] != landlordId) {
      throw StateError('This listing does not belong to the signed-in landlord.');
    }

    final totalSlots = (data?['totalSlots'] as num?)?.toInt() ?? 0;
    if (availableSlots < 0 || availableSlots > totalSlots) {
      throw ArgumentError.value(
        availableSlots,
        'availableSlots',
        'Must be between zero and total capacity.',
      );
    }

    await reference.update({
      'availableSlots': availableSlots,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteDormitory({
    required String dormitoryId,
    required String landlordId,
  }) async {
    final reference = _dormitories.doc(dormitoryId);
    final snapshot = await reference.get();
    if (snapshot.data()?['landlordId'] != landlordId) {
      throw StateError('This listing does not belong to the signed-in landlord.');
    }
    final reviews = await reference.collection('reviews').get();
    for (var start = 0; start < reviews.docs.length; start += 450) {
      final batch = _firestore.batch();
      for (final review in reviews.docs.skip(start).take(450)) {
        batch.delete(review.reference);
      }
      await batch.commit();
    }
    await reference.delete();
  }

  Stream<Dormitory?> watchDormitory(String dormitoryId) {
    return _dormitories.doc(dormitoryId).snapshots().map((document) {
      final data = document.data();
      if (!document.exists || data == null) return null;
      return Dormitory.fromJson(data, id: document.id);
    });
  }

  Stream<List<Dormitory>> watchApprovedDormitories() {
    return _dormitories
        .where('status', isEqualTo: 'approved')
        .snapshots()
        .map(_mapDocuments);
  }

  Stream<List<Dormitory>> watchLandlordDormitories(String landlordId) {
    return _dormitories
        .where('landlordId', isEqualTo: landlordId)
        .snapshots()
        .map(_mapDocuments);
  }

  List<Dormitory> _mapDocuments(QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs
        .map((document) => Dormitory.fromJson(document.data(), id: document.id))
        .toList(growable: false);
  }
}
