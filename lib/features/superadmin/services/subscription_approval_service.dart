import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/upgrade_request_model.dart';

class SubscriptionApprovalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream daftar request yang masih PENDING
  Stream<List<UpgradeRequestModel>> getPendingRequests() {
    return _firestore
        .collection('upgradeRequests')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UpgradeRequestModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // LOGIKA UTAMA: Setujui & Perpanjang Toko
  Future<void> approveRequest(UpgradeRequestModel request) async {
    final storeRef = _firestore.collection('stores').doc(request.storeId);
    final requestRef = _firestore.collection('upgradeRequests').doc(request.id);

    return _firestore.runTransaction((transaction) async {
      DocumentSnapshot storeDoc = await transaction.get(storeRef);

      if (!storeDoc.exists) {
        throw Exception("Data toko tidak ditemukan!");
      }

      // Hitung Tanggal Expired Baru
      DateTime currentExpiry = (storeDoc.get('subscriptionExpiry') as Timestamp?)?.toDate() ?? DateTime.now();
      DateTime newExpiry;

      // Jika masih aktif, tambah dari tanggal expired lama. 
      // Jika sudah mati (expired), tambah dari hari ini.
      if (currentExpiry.isAfter(DateTime.now())) {
        newExpiry = currentExpiry.add(Duration(days: request.durationInDays));
      } else {
        newExpiry = DateTime.now().add(Duration(days: request.durationInDays));
      }

      // 1. Update status Request
      transaction.update(requestRef, {'status': 'approved'});

      // 2. Update data Toko
      transaction.update(storeRef, {
        'subscriptionExpiry': newExpiry,
        'subscriptionStatus': 'active', // Pastikan status jadi aktif
        'currentPackage': request.packageName,
      });
    });
  }

  // Tolak Request
  Future<void> rejectRequest(String requestId) async {
    await _firestore.collection('upgradeRequests').doc(requestId).update({
      'status': 'rejected',
    });
  }
}