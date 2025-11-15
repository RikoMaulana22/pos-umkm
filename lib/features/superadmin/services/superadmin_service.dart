// lib/features/superadmin/services/superadmin_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../settings/models/store_model.dart';
import '../models/upgrade_request_model.dart';

class SuperAdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ============================================================
  // GET ALL STORES
  // ============================================================
  Stream<List<StoreModel>> getAllStores() {
    return _firestore
        .collection('stores')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => StoreModel.fromFirestore(doc)).toList();
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
  }) async {
    try {
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
        'subscriptionPrice': subscriptionPrice,
        'subscriptionPackage': subscriptionPackage,
        'isActive': true,
      });

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': adminEmail,
        'username': adminUsername,
        'role': 'admin',
        'storeId': storeDoc.id,
      });
    } on FirebaseAuthException catch (e) {
      throw Exception("Gagal membuat user Auth: ${e.message}");
    } catch (e) {
      throw Exception("Gagal membuat toko: ${e.toString()}");
    }
  }

  // ============================================================
  // GET REVENUE DATA (DASHBOARD)
  // ============================================================
  Future<Map<String, dynamic>> getRevenueData() async {
    double totalRevenue = 0.0;
    int activeSubscriptions = 0;
    int expiredSubscriptions = 0;

    QuerySnapshot storeSnapshot = await _firestore.collection('stores').get();

    for (var doc in storeSnapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      totalRevenue += (data['subscriptionPrice'] ?? 0.0).toDouble();

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
        'subscriptionPrice': newPrice,
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
      await _firestore.collection('users').doc(ownerId).delete();
    } catch (e) {
      throw Exception("Gagal menghapus toko: ${e.toString()}");
    }
  }

  // ============================================================
  // UPDATE STORE DETAILS
  // ============================================================
  Future<void> updateStoreDetails({
    required String storeId,
    bool? isActive,
    DateTime? expiryDate,
    double? price,
  }) async {
    Map<String, dynamic> data = {};

    if (isActive != null) data['isActive'] = isActive;
    if (expiryDate != null)
      data['subscriptionExpiry'] = Timestamp.fromDate(expiryDate);
    if (price != null) data['subscriptionPrice'] = price;

    await _firestore.collection('stores').doc(storeId).update(data);
  }

  // ============================================================
  // GET REVENUE STATS
  // ============================================================
  Future<Map<String, dynamic>> getRevenueStats() async {
    double totalRevenue = 0;
    int activeStores = 0;
    int expiredOrSuspended = 0;

    final snapshot = await _firestore.collection('stores').get();

    for (var doc in snapshot.docs) {
      final store = StoreModel.fromFirestore(doc);

      totalRevenue += store.subscriptionPrice;

      if (store.canOperate) {
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
        .collection('upgradeRequests')
        .where('status', isEqualTo: 'pending')
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => UpgradeRequestModel.fromFirestore(doc))
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
        'subscriptionPrice': request.price,
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
}
