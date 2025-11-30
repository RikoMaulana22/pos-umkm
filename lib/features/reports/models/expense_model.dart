import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseModel {
  final String id;
  final String storeId;
  final String userId; // Siapa yang mencatat
  final double amount;
  final String category; // Contoh: Listrik, Gaji, Sewa, Stok
  final String note;
  final Timestamp date;

  ExpenseModel({
    required this.id,
    required this.storeId,
    required this.userId,
    required this.amount,
    required this.category,
    required this.note,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'storeId': storeId,
      'userId': userId,
      'amount': amount,
      'category': category,
      'note': note,
      'date': date,
    };
  }

  factory ExpenseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ExpenseModel(
      id: doc.id,
      storeId: data['storeId'] ?? '',
      userId: data['userId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      category: data['category'] ?? 'Umum',
      note: data['note'] ?? '',
      date: data['date'] ?? Timestamp.now(),
    );
  }
}