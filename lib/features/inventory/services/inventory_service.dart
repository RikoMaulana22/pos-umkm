import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product_model.dart';

class InventoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  /// ✅ Tambah produk baru ke Firestore
  Future<void> addProduct({
    required String name,
    required double hargaModal,
    required double hargaJual,
    required int stok,
    Uint8List? imageBytes,
    String? imageName,
    required String storeId,
  }) async {
    if (_userId == null) throw Exception("User belum login");

    try {
      String? downloadUrl;

      // 🔹 Upload gambar hanya jika user memilih gambar
      if (imageBytes != null && imageBytes.isNotEmpty && imageName != null) {
        final String fileExtension =
            imageName.contains('.') ? imageName.split('.').last.toLowerCase() : 'jpg';

        final String fileName =
            'products/$storeId/${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

        final metadata = SettableMetadata(contentType: 'image/$fileExtension');

        final uploadTask = _storage.ref(fileName).putData(imageBytes, metadata);
        final snapshot = await uploadTask.whenComplete(() {});
        downloadUrl = await snapshot.ref.getDownloadURL();
      }

      // 🔹 Buat data produk
      final product = Product(
        name: name.trim(),
        hargaModal: hargaModal,
        hargaJual: hargaJual,
        stok: stok,
        imageUrl: downloadUrl ?? '', // kosong jika tanpa gambar
        createdBy: _userId!,
      );

      final productData = product.toMap()
        ..addAll({
          'storeId': storeId,
          'timestamp': FieldValue.serverTimestamp(),
        });

      // 🔹 Simpan ke Firestore
      await _firestore.collection('products').add(productData);
    } on FirebaseException catch (e) {
      throw Exception("Firebase Error: ${e.message}");
    } catch (e) {
      throw Exception("Gagal menambah produk: $e");
    }
  }

  /// ✅ Ambil daftar produk berdasarkan storeId
  Stream<List<Product>> getProducts(String storeId) {
    if (_userId == null) return Stream.value([]);

    return _firestore
        .collection('products')
        .where('storeId', isEqualTo: storeId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Product.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// ✅ Update data produk (dengan/ tanpa ganti gambar)
  Future<void> updateProduct({
    required Product product,
    Uint8List? newImageBytes,
    String? newImageName,
  }) async {
    if (_userId == null) throw Exception("User belum login");
    if (product.id == null) throw Exception("ID produk tidak valid");

    try {
      String? newImageUrl = product.imageUrl;

      // 🔹 Upload gambar baru jika ada
      if (newImageBytes != null && newImageBytes.isNotEmpty && newImageName != null) {
        // Hapus gambar lama jika ada
        if (product.imageUrl != null && product.imageUrl!.isNotEmpty) {
          try {
            await _storage.refFromURL(product.imageUrl!).delete();
          } catch (e) {
            print("⚠️ Gagal hapus gambar lama: $e");
          }
        }

        final fileExtension = newImageName.split('.').last.toLowerCase();
        final fileName =
            'products/${product.createdBy}/${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

        final metadata = SettableMetadata(contentType: 'image/$fileExtension');
        final uploadTask = _storage.ref(fileName).putData(newImageBytes, metadata);
        final snapshot = await uploadTask.whenComplete(() {});
        newImageUrl = await snapshot.ref.getDownloadURL();
      }

      final updatedData = {
        'name': product.name.trim(),
        'hargaModal': product.hargaModal,
        'hargaJual': product.hargaJual,
        'stok': product.stok,
        'imageUrl': newImageUrl ?? '',
        'timestamp': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('products').doc(product.id).update(updatedData);
    } on FirebaseException catch (e) {
      throw Exception("Firebase Error: ${e.message}");
    } catch (e) {
      throw Exception("Gagal update produk: $e");
    }
  }

  /// ✅ Hapus produk (beserta gambar)
  Future<void> deleteProduct(String productId) async {
    if (_userId == null) throw Exception("User belum login");

    try {
      final doc = await _firestore.collection('products').doc(productId).get();
      if (!doc.exists) throw Exception("Produk tidak ditemukan");

      final data = doc.data() as Map<String, dynamic>;
      final imageUrl = data['imageUrl'] as String?;

      // 🔹 Hapus gambar jika ada
      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          await _storage.refFromURL(imageUrl).delete();
        } catch (e) {
          print("⚠️ Gagal hapus gambar dari Storage: $e");
        }
      }

      await _firestore.collection('products').doc(productId).delete();
    } on FirebaseException catch (e) {
      throw Exception("Firebase Error: ${e.message}");
    } catch (e) {
      throw Exception("Gagal menghapus produk: $e");
    }
  }
}
