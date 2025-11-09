// lib/features/reports/models/transaction_item_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionItemModel {
  final String productId;
  final String productName;
  final int quantity;
  final double price; // Harga Jual
  final double cost; // Harga Modal

  TransactionItemModel({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.cost,
  });

  // Untuk menyimpan ke Firestore
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'price': price,
      'cost': cost,
    };
  }

  // Untuk membaca dari Firestore
  factory TransactionItemModel.fromMap(Map<String, dynamic> data) {
    return TransactionItemModel(
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      quantity: data['quantity'] ?? 0,
      price: (data['price'] ?? 0).toDouble(),
      cost: (data['cost'] ?? 0).toDouble(), // Ambil harga modal
    );
  }
}