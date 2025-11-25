import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Request upgrade method matching the screen call
  Future<void> requestUpgrade(
      String storeId, String packageId, String proofUrl) async {
    await _firestore.collection('upgradeRequests').add({
      'storeId': storeId,
      'packageId': packageId, // or 'packageName' if you prefer passing name
      'paymentProofUrl': proofUrl,
      'status': 'pending',
      'requestedAt': FieldValue.serverTimestamp(),
      'createdAt':
          FieldValue.serverTimestamp(), // Redundant timestamp for safety
    });
  }
}
