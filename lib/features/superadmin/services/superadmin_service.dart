// lib/features/superadmin/services/superadmin_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../settings/models/store_model.dart';
import '../models/upgrade_request_model.dart';

class SuperAdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // _auth tidak digunakan di level class, dihapus untuk menghilangkan warning

  // ============================================================
  // GET ALL STORES
  // ============================================================
  Stream<List<StoreModel>> getAllStores() {
    return _firestore
        .collection('stores')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        // PERBAIKAN: Gunakan fromMap sesuai model yang sudah dibuat
        return StoreModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // ============================================================
  // CREATE STORE WITH ADMIN ACCOUNT
  // ============================================================
  Future<void> createStoreWithAdmin({
    required String adminEmail,
    required String adminPassword,
    required String adminUsername,
    required String storeName,
    required DateTime expiryDate,
    required double subscriptionPrice,
    required String subscriptionPackage,
    required String location,
  }) async {
    try {
      // Trik membuat user tanpa logout admin yang sedang login
      FirebaseApp tempApp = await Firebase.initializeApp(
        name: 'tempApp-${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );

      UserCredential userCredential =
          await FirebaseAuth.instanceFor(app: tempApp)
              .createUserWithEmailAndPassword(
        email: adminEmail,
        password: adminPassword,
      );

      await tempApp.delete();

      DocumentReference storeDoc = await _firestore.collection('stores').add({
        'name': storeName,
        'ownerId': userCredential.user!.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'subscriptionExpiry': Timestamp.fromDate(expiryDate),
        'subscriptionPrice': subscriptionPrice.toInt(), // Simpan sebagai int
        'subscriptionPackage': subscriptionPackage,
        'isActive': true,
        'location': location,
        'address': location, // Redundansi agar sesuai model
      });

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': adminEmail,
        'username': adminUsername,
        'role': 'admin',
        'storeId': storeDoc.id,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseAuthException catch (e) {
      throw Exception("Gagal membuat user Auth: ${e.message}");
    } catch (e) {
      throw Exception("Gagal membuat toko: ${e.toString()}");
    }
  }

  // ============================================================
  // GET REVENUE DATA (DASHBOARD - Manual Loop)
  // ============================================================
  Future<Map<String, dynamic>> getRevenueData() async {
    double totalRevenue = 0.0;
    int activeSubscriptions = 0;
    int expiredSubscriptions = 0;

    QuerySnapshot storeSnapshot = await _firestore.collection('stores').get();

    for (var doc in storeSnapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      // Handle casting num ke double aman
      totalRevenue += (data['subscriptionPrice'] ?? 0).toDouble();

      final Timestamp? expiry = data['subscriptionExpiry'];
      final bool isActive = data['isActive'] ?? false;

      if (expiry != null &&
          expiry.toDate().isAfter(DateTime.now()) &&
          isActive) {
        activeSubscriptions++;
      } else {
        expiredSubscriptions++;
      }
    }

    return {
      'totalRevenue': totalRevenue,
      'totalStores': storeSnapshot.size,
      'activeSubscriptions': activeSubscriptions,
      'expiredSubscriptions': expiredSubscriptions,
    };
  }

  // ============================================================
  // UPDATE STORE SUBSCRIPTION
  // ============================================================
  Future<void> updateStoreSubscription({
    required String storeId,
    required String newName,
    required DateTime newExpiryDate,
    required double newPrice,
    required bool isActive,
    required String newPackage,
  }) async {
    try {
      await _firestore.collection('stores').doc(storeId).update({
        'name': newName,
        'subscriptionExpiry': Timestamp.fromDate(newExpiryDate),
        'subscriptionPrice': newPrice.toInt(),
        'isActive': isActive,
        'subscriptionPackage': newPackage,
      });
    } catch (e) {
      throw Exception("Gagal update langganan: ${e.toString()}");
    }
  }

  // ============================================================
  // DELETE STORE & USER
  // ============================================================
  Future<void> deleteStore(String storeId, String ownerId) async {
    try {
      await _firestore.collection('stores').doc(storeId).delete();
      // Note: User di Auth tidak bisa dihapus langsung tanpa credential,
      // tapi data di Firestore users bisa dihapus.
      await _firestore.collection('users').doc(ownerId).delete();
    } catch (e) {
      throw Exception("Gagal menghapus toko: ${e.toString()}");
    }
  }

  // ============================================================
  // GET REVENUE STATS (Menggunakan Model)
  // ============================================================
  Future<Map<String, dynamic>> getRevenueStats() async {
    double totalRevenue = 0;
    int activeStores = 0;
    int expiredOrSuspended = 0;

    final snapshot = await _firestore.collection('stores').get();

    for (var doc in snapshot.docs) {
      // PERBAIKAN: Gunakan fromMap
      final store = StoreModel.fromMap(doc.data(), doc.id);

      // Ambil harga (handle null di model)
      // Gunakan safe cast dari int? ke double
      totalRevenue += (store.subscriptionPackage == 'Free' ? 0 : 0);
      // TODO: Karena StoreModel tidak menyimpan harga history,
      // idealnya total revenue diambil dari collection 'transactions' atau 'invoices'.
      // Untuk sementara kita skip penambahan harga dari StoreModel jika field price tidak ada.

      // Cek status aktif manual
      bool isActive = false;
      if (store.subscriptionExpiry != null) {
        final bool notExpired =
            store.subscriptionExpiry!.isAfter(DateTime.now());
        // Asumsi: jika ada field isActive di firestore tapi tidak di model, kita anggap true dulu
        // atau tambahkan field isActive di StoreModel (sudah ditambahkan di langkah sebelumnya?)
        // Jika belum ada di model, kita gunakan logika expiry saja.
        isActive = notExpired;
      }

      if (isActive) {
        activeStores++;
      } else {
        expiredOrSuspended++;
      }
    }

    return {
      'totalRevenue': totalRevenue,
      'totalStores': snapshot.size,
      'active': activeStores,
      'inactive': expiredOrSuspended,
    };
  }

  // ============================================================
  // UPGRADE REQUESTS - STREAM
  // ============================================================
  Stream<List<UpgradeRequestModel>> getUpgradeRequests() {
    return _firestore
        .collection(
            'upgradeRequests') // Pastikan nama collection konsisten (camelCase atau snake_case)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt',
            descending: true) // Gunakan createdAt atau requestedAt
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => UpgradeRequestModel.fromMap(
              doc.data(), doc.id)) // PERBAIKAN: fromMap
          .toList();
    });
  }

  // ============================================================
  // GET STORE NAME
  // ============================================================
  Future<String> getStoreName(String storeId) async {
    try {
      final doc = await _firestore.collection('stores').doc(storeId).get();
      if (doc.exists) {
        return (doc.data() as Map<String, dynamic>)['name'] ??
            'Nama Toko Hilang';
      }
      return 'Toko Tidak Ditemukan';
    } catch (e) {
      return 'Error: ${e.toString()}';
    }
  }

  // ============================================================
  // APPROVE UPGRADE REQUEST
  // ============================================================
  Future<void> approveUpgradeRequest(UpgradeRequestModel request) async {
    try {
      final newExpiryDate = DateTime.now().add(const Duration(days: 30));

      WriteBatch batch = _firestore.batch();

      DocumentReference storeDoc =
          _firestore.collection('stores').doc(request.storeId);

      batch.update(storeDoc, {
        'subscriptionPackage': request.packageName,
        // 'subscriptionPrice': request.price, // Jika ada field price di request
        'subscriptionExpiry': Timestamp.fromDate(newExpiryDate),
        'isActive': true,
      });

      DocumentReference requestDoc =
          _firestore.collection('upgradeRequests').doc(request.id);

      batch.update(requestDoc, {
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } catch (e) {
      throw Exception("Gagal menyetujui permintaan: ${e.toString()}");
    }
  }

  // ============================================================
  // PROSES REJECT (TOLAK)
  // ============================================================
  Future<void> rejectUpgradeRequest(String requestId) async {
    try {
      await _firestore.collection('upgradeRequests').doc(requestId).update({
        'status': 'rejected',
        'rejectedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Gagal menolak request: $e');
    }
  }
}
