import 'package:cloud_firestore/cloud_firestore.dart';

abstract interface class DormListingReportRepository {
  Future<void> submitReport({
    required String dormitoryId,
    required String reporterId,
    required String reason,
    required String details,
  });
}

class FirestoreDormListingReportRepository
    implements DormListingReportRepository {
  FirestoreDormListingReportRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<void> submitReport({
    required String dormitoryId,
    required String reporterId,
    required String reason,
    required String details,
  }) async {
    final normalizedDetails = details.trim();
    if (normalizedDetails.length > 1000) {
      throw ArgumentError.value(
        normalizedDetails.length,
        'details',
        'Must be 1000 characters or fewer.',
      );
    }

    final report = _firestore
        .collection('dormitories')
        .doc(dormitoryId)
        .collection('reports')
        .doc(reporterId);
    final existingReport = await report.get();
    if (existingReport.exists) {
      throw StateError('You have already reported this listing.');
    }

    await report.set({
      'reporterId': reporterId,
      'reason': reason,
      'details': normalizedDetails,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
