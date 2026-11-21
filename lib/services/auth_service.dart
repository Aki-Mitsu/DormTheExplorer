import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmailNotVerifiedException implements Exception {
  const EmailNotVerifiedException(this.email);

  final String email;

  @override
  String toString() => 'Verify $email before signing in.';
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> signUp({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    if (role != 'seeker' && role != 'landlord') {
      throw ArgumentError('Invalid account type.');
    }

    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    try {
      await credential.user!.sendEmailVerification();
      await _db.collection('users').doc(credential.user!.uid).set({
        'fullName': fullName.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'role': role,
        'verificationStatus': role == 'landlord' ? 'pending' : null,
        'notificationsOn': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Avoid leaving an Auth account without its corresponding role profile.
      await credential.user?.delete();
      rethrow;
    }
  }

  String? get currentUserId => _auth.currentUser?.uid;

  Future<String?> logIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) return null;

    await user.reload();
    final refreshedUser = _auth.currentUser;
    if (refreshedUser != null &&
        refreshedUser.email != null &&
        !refreshedUser.emailVerified) {
      throw EmailNotVerifiedException(refreshedUser.email!);
    }

    return getRole(user.uid);
  }

  Future<void> resendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Sign in to request another verification email.');
    }
    await user.sendEmailVerification();
  }

  Future<bool> refreshEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    await _auth.currentUser?.getIdToken(true);
    return _auth.currentUser?.emailVerified ?? false;
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  Future<String?> getRole(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data()?['role'] as String?;
  }

  static String messageFor(Object error) {
    if (error is EmailNotVerifiedException) {
      return 'Verify your email address before signing in.';
    }
    if (error is FirebaseAuthException) {
      return switch (error.code) {
        'email-already-in-use' => 'An account already exists for this email.',
        'invalid-email' => 'Enter a valid email address.',
        'weak-password' => 'Choose a stronger password.',
        'user-not-found' ||
        'wrong-password' ||
        'invalid-credential' => 'Email or password is incorrect.',
        'user-disabled' => 'This account has been disabled.',
        'too-many-requests' => 'Too many attempts. Please try again later.',
        'network-request-failed' =>
          'Check your internet connection and try again.',
        'operation-not-allowed' =>
          'Email and password sign-in is not enabled in Firebase.',
        _ => error.message ?? 'Authentication failed. Please try again.',
      };
    }
    if (error is FirebaseException) {
      if (error.code == 'permission-denied') {
        return 'Firebase denied the profile write. Check your Firestore rules.';
      }
      if (error.code == 'unavailable' ||
          error.code == 'network-request-failed') {
        return 'Could not reach Firebase. Check your internet connection.';
      }
      return error.message ?? 'Could not save your account profile.';
    }
    if (error is ArgumentError) {
      return error.message?.toString() ?? 'Invalid account type.';
    }
    return 'Something went wrong. Please try again.';
  }
}
