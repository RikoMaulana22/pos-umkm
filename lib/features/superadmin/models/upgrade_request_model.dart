// lib/features/superadmin/models/upgrade_request_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class UpgradeRequestModel {
  final String id; // ID dokumen permintaan
  final String storeId;
  final String packageName;
  final double price;
  final String status;
  final Timestamp requestedAt;
  final String? proofOfPaymentURL; // <-- 1. TAMBAHKAN FIELD INI

  // Tambahan untuk UI
  String? storeName;

  UpgradeRequestModel({
    required this.id,
    required this.storeId,
    required this.packageName,
    required this.price,
    required this.status,
    required this.requestedAt,
    this.proofOfPaymentURL, // <-- 2. TAMBAHKAN DI CONSTRUCTOR
    this.storeName,
  });

  factory UpgradeRequestModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UpgradeRequestModel(
      id: doc.id,
      storeId: data['storeId'] ?? '',
      packageName: data['packageName'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      status: data['status'] ?? 'pending',
      requestedAt: data['requestedAt'] ?? Timestamp.now(),
      proofOfPaymentURL: data['proofOfPaymentURL'], // <-- 3. AMBIL DATANYA
    );
  }
}
