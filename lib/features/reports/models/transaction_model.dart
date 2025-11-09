// lib/features/reports/models/transaction_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
// 1. IMPOR MODEL BARU
import 'transaction_item_model.dart';

class TransactionModel {
  final String id;
  final String storeId;
  final String cashierId;
  final double totalPrice;
  final int totalItems;
  final String paymentMethod;
  final Timestamp timestamp;
  // 2. UBAH TIPE DATA
  final List<TransactionItemModel> items; 
  // 3. TAMBAHKAN FIELD BARU
  final double? cashReceived;
  final double? change;

  // 4. Hitung total modal dari items
  double get totalCost {
    return items.fold(0.0, (sum, item) => sum + (item.cost * item.quantity));
  }
  // 5. Hitung total profit
  double get totalProfit {
    return totalPrice - totalCost;
  }

  TransactionModel({
    required this.id,
    required this.storeId,
    required this.cashierId,
    required this.totalPrice,
    required this.totalItems,
    required this.paymentMethod,
    required this.timestamp,
    required this.items,
    this.cashReceived, // 6. TAMBAH DI CONSTRUCTOR
    this.change, // 7. TAMBAH DI CONSTRUCTOR
  });

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // 8. UBAH CARA PARSING ITEMS
    List<TransactionItemModel> parsedItems = [];
    if (data['items'] != null && data['items'] is List) {
      parsedItems = (data['items'] as List)
          .map((itemData) => TransactionItemModel.fromMap(itemData as Map<String, dynamic>))
          .toList();
    }

    return TransactionModel(
      id: doc.id,
      storeId: data['storeId'] ?? '',
      cashierId: data['cashierId'] ?? '',
      totalPrice: (data['totalPrice'] ?? 0).toDouble(),
      totalItems: data['totalItems'] ?? 0,
      paymentMethod: data['paymentMethod'] ?? 'N/A',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      items: parsedItems, // 9. Masukkan item yang sudah diparsing
      cashReceived: (data['cashReceived'] ?? 0).toDouble(), // 10. Ambil data
      change: (data['change'] ?? 0).toDouble(), // 11. Ambil data
    );
  }
}