// lib/features/settings/models/store_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class StoreModel {
  final String id;
  final String name;
  final String ownerId;
  final DateTime? subscriptionExpiry;
  final double subscriptionPrice;
  final bool isActive; // <-- FIELD BARU UNTUK KONTROL
  final String subscriptionPackage;

  StoreModel({
    required this.id,
    required this.name,
    required this.ownerId,
    this.subscriptionExpiry,
    this.subscriptionPrice = 0.0,
    this.isActive = true, // Default aktif saat dibuat
    this.subscriptionPackage = 'bronze',
  });

  factory StoreModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return StoreModel(
      id: doc.id,
      name: data['name'] ?? 'Tanpa Nama',
      ownerId: data['ownerId'] ?? '',
      subscriptionExpiry: (data['subscriptionExpiry'] as Timestamp?)?.toDate(),
      subscriptionPrice: (data['subscriptionPrice'] ?? 0).toDouble(),
      isActive: data['isActive'] ?? true,
      subscriptionPackage:
          data['subscriptionPackage'] ?? 'bronze', // <-- 3. AMBIL DARI FIRESTORE
    );
  }

  // Helper: Cek apakah toko BOLEH beroperasi
  bool get canOperate {
    if (!isActive) return false; // Jika dibekukan Super Admin
    if (subscriptionExpiry == null) return false; // Jika data tanggal rusak
    return subscriptionExpiry!.isAfter(DateTime.now()); // Jika belum expired
  }
}