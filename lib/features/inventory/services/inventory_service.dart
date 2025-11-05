// lib/features/inventory/services/inventory_service.dart
import 'dart:io'; // Untuk 'File' gambar
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product_model.dart';

class InventoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Mendapatkan ID user yang sedang login
  String? get _userId => _auth.currentUser?.uid;

  // 1. Tambah Produk Baru
  Future<void> addProduct({
    required String name,
    required double hargaModal,
    required double hargaJual,
    required int stok,
    required File imageFile, // File gambar dari image_picker
  }) async {
    if (_userId == null) throw Exception("User tidak login");

    try {
      // 1. Upload Gambar ke Firebase Storage
      // Membuat nama file yang unik berdasarkan waktu
      String fileName = 'products/${_userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      UploadTask uploadTask = _storage.ref().child(fileName).putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // 2. Buat objek Product
      Product product = Product(
        name: name,
        hargaModal: hargaModal,
        hargaJual: hargaJual,
        stok: stok,
        imageUrl: downloadUrl,
        createdBy: _userId!,
      );

      // 3. Simpan data Product ke Firestore
      await _firestore.collection('products').add(product.toMap());
      
    } catch (e) {
      throw Exception("Gagal menambah produk: $e");
    }
  }

  // 2. Mengambil SEMUA produk (untuk ditampilkan di daftar)
  Stream<List<Product>> getProducts() {
    if (_userId == null) return Stream.value([]); // Kembalikan list kosong jika user out

    return _firestore
        .collection('products')
        // .where('createdBy', isEqualTo: _userId) // Opsional: jika ingin produk per user
        .orderBy('timestamp', descending: true) // Tampilkan yang terbaru di atas
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Product.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // 3. Update Produk (Nanti dipakai di Halaman Edit)
  Future<void> updateProduct(Product product) async {
    if (product.id == null) throw Exception("ID Produk tidak valid");
    try {
      await _firestore
          .collection('products')
          .doc(product.id)
          .update(product.toMap());
    } catch (e) {
      throw Exception("Gagal update produk: $e");
    }
  }

  // 4. Hapus Produk (Nanti dipakai di Halaman Edit)
  Future<void> deleteProduct(String productId) async {
    try {
      // TODO: Hapus juga gambar di Firebase Storage
      await _firestore.collection('products').doc(productId).delete();
    } catch (e) {
      throw Exception("Gagal menghapus produk: $e");
    }
  }
}