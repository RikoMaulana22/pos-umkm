// lib/features/settings/models/store_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class StoreModel {
  final String id;
  final String name;
  final String? address; // ✅ Tambahan: Untuk lokasi toko
  final String ownerId;
  final DateTime? subscriptionExpiry;
  final double subscriptionPrice;
  final bool isActive;
  final String subscriptionPackage;
  final DateTime? createdAt; // ✅ Tambahan: Untuk sorting tanggal pembuatan

  StoreModel({
    required this.id,
    required this.name,
    this.address, // ✅ Tambahan di constructor
    required this.ownerId,
    this.subscriptionExpiry,
    this.subscriptionPrice = 0.0,
    this.isActive = true,
    this.subscriptionPackage = 'bronze',
    this.createdAt, // ✅ Tambahan di constructor
  });

  factory StoreModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return StoreModel(
      id: doc.id,
      name: data['name'] ?? 'Tanpa Nama',
      address: data['address'], // ✅ Ambil data address
      ownerId: data['ownerId'] ?? '',
      subscriptionExpiry: (data['subscriptionExpiry'] as Timestamp?)?.toDate(),
      subscriptionPrice: (data['subscriptionPrice'] ?? 0).toDouble(),
      isActive: data['isActive'] ?? true,
      subscriptionPackage: data['subscriptionPackage'] ?? 'bronze',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate(), // ✅ Ambil data createdAt
    );
  }

  // ✅ Tambahan: Method untuk mengubah data menjadi Map (PENTING untuk simpan ke Firebase)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'ownerId': ownerId,
      'subscriptionExpiry': subscriptionExpiry != null
          ? Timestamp.fromDate(subscriptionExpiry!)
          : null,
      'subscriptionPrice': subscriptionPrice,
      'isActive': isActive,
      'subscriptionPackage': subscriptionPackage,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue
              .serverTimestamp(), // Otomatis isi tanggal sekarang jika kosong
    };
  }

  // Helper: Cek apakah toko BOLEH beroperasi
  bool get canOperate {
    if (!isActive) return false; // Jika dibekukan Super Admin
    if (subscriptionExpiry == null) return false; // Jika data tanggal rusak
    return subscriptionExpiry!.isAfter(DateTime.now()); // Jika belum expired
  }
}
