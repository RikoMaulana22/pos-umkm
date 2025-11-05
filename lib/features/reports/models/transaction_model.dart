// lib/features/reports/models/transaction_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String storeId;
  final String cashierId;
  final double totalPrice;
  final int totalItems;
  final String paymentMethod;
  final Timestamp timestamp;
  final List<dynamic> items; // Daftar item yang dibeli

  TransactionModel({
    required this.id,
    required this.storeId,
    required this.cashierId,
    required this.totalPrice,
    required this.totalItems,
    required this.paymentMethod,
    required this.timestamp,
    required this.items,
  });

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      storeId: data['storeId'] ?? '',
      cashierId: data['cashierId'] ?? '',
      totalPrice: (data['totalPrice'] ?? 0).toDouble(),
      totalItems: data['totalItems'] ?? 0,
      paymentMethod: data['paymentMethod'] ?? 'N/A',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      items: data['items'] ?? [],
    );
  }
}