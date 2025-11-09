// lib/features/inventory/services/category_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category_model.dart';

class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. Mengambil semua kategori untuk satu toko
  Stream<List<Category>> getCategories(String storeId) {
    return _firestore
        .collection('categories')
        .where('storeId', isEqualTo: storeId)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Category.fromFirestore(doc))
          .toList();
    });
  }

  // 2. Menambah kategori baru
  Future<void> addCategory(String name, String storeId) async {
    try {
      Category category = Category(name: name, storeId: storeId);
      await _firestore.collection('categories').add(category.toMap());
    } catch (e) {
      throw Exception("Gagal menambah kategori: ${e.toString()}");
    }
  }

  // 3. Menghapus kategori
  Future<void> deleteCategory(String categoryId) async {
    try {
      await _firestore.collection('categories').doc(categoryId).delete();
      // Catatan: Anda mungkin perlu update produk yang menggunakan kategori ini
    } catch (e) {
      throw Exception("Gagal menghapus kategori: ${e.toString()}");
    }
  }
}