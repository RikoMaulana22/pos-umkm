import 'package:cloud_firestore/cloud_firestore.dart';

class UpgradeRequestModel {
  final String id;
  final String storeId;
  final String? userId; // Opsional, karena mungkin tidak dikirim saat upload
  final String packageName;
  final int price;
  final int durationInDays;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime createdAt;
  final String paymentMethod;
  final String? proofOfPaymentURL; // ✅ Field Baru Ditambahkan

  UpgradeRequestModel({
    required this.id,
    required this.storeId,
    this.userId,
    required this.packageName,
    required this.price,
    required this.durationInDays,
    required this.status,
    required this.createdAt,
    required this.paymentMethod,
    this.proofOfPaymentURL, // ✅ Masukkan di constructor
  });

  factory UpgradeRequestModel.fromMap(Map<String, dynamic> map, String id) {
    // Helper untuk handle Timestamp atau String tanggal
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return UpgradeRequestModel(
      id: id,
      storeId: map['storeId'] ?? '',
      userId: map['userId'], // Bisa null
      packageName: map['packageName'] ?? '',
      price: (map['price'] ?? 0).toInt(),
      durationInDays: (map['durationInDays'] ?? 30).toInt(), // Default 30 hari
      status: map['status'] ?? 'pending',
      // Handle field 'requestedAt' atau 'createdAt'
      createdAt: parseDate(map['requestedAt'] ?? map['createdAt']),
      paymentMethod: map['paymentMethod'] ?? 'Manual Transfer',
      proofOfPaymentURL: map['proofOfPaymentURL'], // ✅ Mapping dari Firestore
    );
  }
}
