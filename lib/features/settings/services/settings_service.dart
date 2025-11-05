// lib/features/settings/services/settings_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/store_model.dart';

class SettingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. Mengambil detail toko
  Future<StoreModel> getStoreDetails(String storeId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('stores').doc(storeId).get();
      if (!doc.exists) {
        throw Exception("Toko tidak ditemukan");
      }
      return StoreModel.fromFirestore(doc);
    } catch (e) {
      throw Exception("Gagal mengambil data toko: ${e.toString()}");
    }
  }

  // 2. Update nama toko
  Future<void> updateStoreName(String storeId, String newName) async {
    try {
      await _firestore.collection('stores').doc(storeId).update({
        'name': newName,
      });
    } catch (e) {
      throw Exception("Gagal update nama toko: ${e.toString()}");
    }
  }

  // TODO: Nanti kita tambahkan fungsi untuk pengaturan printer
  // TODO: Nanti kita tambahkan fungsi untuk pengaturan pajak
}