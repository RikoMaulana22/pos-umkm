import 'package:cloud_firestore/cloud_firestore.dart';

class UpgradeRequestModel {
  final String id;
  final String storeId;
  final String userId;
  final String packageName;
  final int price;
  final int durationInDays;
  final String status; // 'pending', 'approved', 'rejected'
  final DateTime createdAt;
  final String paymentMethod;

  UpgradeRequestModel({
    required this.id,
    required this.storeId,
    required this.userId,
    required this.packageName,
    required this.price,
    required this.durationInDays,
    required this.status,
    required this.createdAt,
    required this.paymentMethod,
  });

  factory UpgradeRequestModel.fromMap(Map<String, dynamic> map, String id) {
    return UpgradeRequestModel(
      id: id,
      storeId: map['storeId'] ?? '',
      userId: map['userId'] ?? '',
      packageName: map['packageName'] ?? '',
      price: map['price']?.toInt() ?? 0,
      durationInDays: map['durationInDays']?.toInt() ?? 0,
      status: map['status'] ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      paymentMethod: map['paymentMethod'] ?? '',
    );
  }
}
