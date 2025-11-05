// lib/features/superadmin/services/superadmin_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
// Kita gunakan ulang model data Store yang sudah ada
import '../../settings/models/store_model.dart';

class SuperAdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Mengambil daftar SEMUA toko yang ada di database
  Stream<List<StoreModel>> getAllStores() {
    return _firestore
        .collection('stores')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => StoreModel.fromFirestore(doc))
          .toList();
    });
  }

  // Nanti kita bisa tambahkan fungsi lain di sini, seperti:
  // Future<void> createStore(String storeName, String adminEmail, ...)
  // Future<void> disableStore(String storeId)
}