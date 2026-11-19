import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/dormitory.dart';

class DormitoryRepository {
  DormitoryRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _dormitories =>
      _firestore.collection('dormitories');

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
