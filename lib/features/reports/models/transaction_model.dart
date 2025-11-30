import 'package:cloud_firestore/cloud_firestore.dart';
import 'transaction_item_model.dart';

class TransactionModel {
  final String id;
  final String storeId;
  final String cashierId;
  final double totalPrice;
  final int totalItems;
  final String paymentMethod;
  final Timestamp timestamp;
  final List<TransactionItemModel> items;

  // Field baru untuk fitur Hutang & Split
  final double amountPaid; // Jumlah yang sudah dibayar
  final double remainingDebt; // Sisa hutang
  final String? customerName; // Nama pelanggan (wajib jika hutang)
  final String paymentStatus; // 'Lunas', 'Belum Lunas', 'Sebagian'
  final double? cashReceived; // Uang fisik yang diterima kasir
  final double? change;
  double get totalCost {
    return items.fold(0.0, (sum, item) => sum + (item.cost * item.quantity));
  }

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
    this.amountPaid = 0,
    this.remainingDebt = 0,
    this.customerName,
    this.paymentStatus = 'Lunas',
    this.cashReceived, // Tambahkan ini
    this.change,
  });

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final parsedItems = (data['items'] is List)
        ? (data['items'] as List)
            .map((item) =>
                TransactionItemModel.fromMap(item as Map<String, dynamic>))
            .toList()
        : <TransactionItemModel>[];

    return TransactionModel(
      id: doc.id,
      storeId: data['storeId'] ?? '',
      cashierId: data['cashierId'] ?? '',
      totalPrice: (data['totalPrice'] ?? 0).toDouble(),
      totalItems: data['totalItems'] ?? 0,
      paymentMethod: data['paymentMethod'] ?? 'N/A',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      items: parsedItems,
      // Mapping field baru dengan fallback value untuk data lama
      amountPaid: (data['paid'] ?? data['totalPrice'] ?? 0).toDouble(),
      remainingDebt: (data['debt'] ?? 0).toDouble(),
      customerName: data['customerName'],
      paymentStatus: data['paymentStatus'] ?? 'Lunas',
      cashReceived: (data['cashReceived'] ?? 0).toDouble(),
      change: (data['change'] ?? 0).toDouble(),
    );
  }
}
