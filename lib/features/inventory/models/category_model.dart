// lib/features/inventory/models/category_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Category {
  final String? id;
  final String name;
  final String storeId;

  Category({
    this.id,
    required this.name,
    required this.storeId,
  });

  // Mengubah Map (dari Firestore) menjadi objek Category
  factory Category.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Category(
      id: doc.id,
      name: data['name'] ?? '',
      storeId: data['storeId'] ?? '',
    );
  }

  // Mengubah objek Category menjadi Map (untuk dikirim ke Firestore)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'storeId': storeId,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}