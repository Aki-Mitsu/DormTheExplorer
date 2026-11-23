import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfileRepository {
  UserProfileRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchUserProfile(
    String userId,
  ) {
    return _users.doc(userId).snapshots();
  }

  Future<Map<String, dynamic>> fetchUserProfile(String userId) async {
    final profile = await _users.doc(userId).get();
    return profile.data() ?? const <String, dynamic>{};
  }

  Future<String?> syncLandlordPhoto({
    required String userId,
    required String photoUrl,
  }) async {
    if (_auth.currentUser?.uid != userId) {
      return 'No matching signed-in account.';
    }

    try {
      final snapshot = await _firestore
          .collection('dormitories')
          .where('landlordId', isEqualTo: userId)
          .get();
      final documents = snapshot.docs
          .where((document) => document.data()['landlordPhotoUrl'] != photoUrl)
          .toList(growable: false);

      for (var start = 0; start < documents.length; start += 450) {
        final batch = _firestore.batch();
        for (final document in documents.skip(start).take(450)) {
          batch.update(document.reference, {
            'landlordPhotoUrl': photoUrl,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
        await batch.commit();
      }
      return null;
    } catch (error) {
      return error is FirebaseException
          ? error.message ?? error.code
          : error.toString();
    }
  }
}
