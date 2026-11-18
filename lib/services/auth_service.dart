import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Future<void> signUp({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String role, // 'seeker' or 'landlord' only
  }) async {
    if (role != 'seeker' && role != 'landlord') {
      throw ArgumentError('Invalid role');
    }
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(), password: password);

    await _db.collection('users').doc(cred.user!.uid).set({
      'fullName': fullName.trim(),
      'email': email.trim(),
      'phone': phone.trim(),
      'role': role,
      'verificationStatus': role == 'landlord' ? 'pending' : null,
      'notificationsOn': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> logIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(
          email: email.trim(), password: password);

  Future<void> signOut() => _auth.signOut();

  Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  Future<String?> getRole(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data()?['role'] as String?;
  }
}