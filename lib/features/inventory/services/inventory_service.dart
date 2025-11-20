import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product_model.dart';
import '../models/product_variant_model.dart';

class InventoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  /// ========================================================
  /// ✅ TAMBAH PRODUK (Simpel / Varian)
  /// ========================================================
  Future<void> addProduct({
    required String name,
    required String storeId,
    required String categoryId,
    required String categoryName,
    Uint8List? imageBytes,
    String? imageName,
    required bool isVariantProduct,
    double? hargaModal,
    double? hargaJual,
    int? stok,
    double? hargaDiskon,
    String? sku,
    List<ProductVariant>? variants,
  }) async {
    if (_userId == null) throw Exception("User belum login");

    try {
      String? downloadUrl;
      // PATCH Handle Upload
      if (imageBytes != null && imageBytes.isNotEmpty && imageName != null) {
        final extension = imageName.split('.').last.toLowerCase();
        final validExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
        final ext = validExtensions.contains(extension) ? extension : 'jpg';

        final fileName =
            'products/$storeId/${DateTime.now().millisecondsSinceEpoch}.$ext';
        final metadata = SettableMetadata(contentType: 'image/$ext');

        final Reference ref = _storage.ref().child(fileName);
        final uploadTask = ref.putData(imageBytes, metadata);
        final snapshot = await uploadTask.whenComplete(() {});

        // PATCH: Pastikan upload sukses, baru ambil URL
        if (snapshot.state == TaskState.success) {
          downloadUrl = await ref.getDownloadURL();
        } else {
          throw Exception('Upload gambar ke storage gagal!');
        }
      }

      // PATCH: Jika tidak ada gambar, imageUrl biarkan null
      final product = Product(
        name: name.trim(),
        imageUrl: downloadUrl,
        createdBy: _userId!,
        categoryId: categoryId,
        categoryName: categoryName,
        isVariantProduct: isVariantProduct,
        variants: variants ?? [],
        hargaModal: hargaModal ?? 0,
        hargaJual: hargaJual ?? 0,
        stok: stok ?? 0,
        hargaDiskon: hargaDiskon,
        sku: sku,
      );

      final productData = product.toMap()
        ..addAll({
          'storeId': storeId,
        });

      await _firestore.collection('products').add(productData);
    } catch (e) {
      throw Exception("Gagal menambah produk: $e");
    }
  }

  Stream<List<Product>> getProducts(String storeId, {String? categoryId}) {
    if (_userId == null) return Stream.value([]);

    Query query =
        _firestore.collection('products').where('storeId', isEqualTo: storeId);

    if (categoryId != null && categoryId.isNotEmpty) {
      query = query.where('categoryId', isEqualTo: categoryId);
    }

    query = query.orderBy('name');

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) =>
            Product.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  Future<void> updateProduct({
    required Product product,
    Uint8List? newImageBytes,
    String? newImageName,
  }) async {
    if (_userId == null) throw Exception("User belum login");
    if (product.id == null) throw Exception("ID produk tidak valid");

    try {
      String? newImageUrl = product.imageUrl;

      // 🖼️ Ganti Gambar Jika Ada
      if (newImageBytes != null &&
          newImageBytes.isNotEmpty &&
          newImageName != null) {
        if (product.imageUrl != null && product.imageUrl!.isNotEmpty) {
          try {
            await _storage.refFromURL(product.imageUrl!).delete();
          } catch (_) {}
        }

        final fileExtension = newImageName.split('.').last.toLowerCase();
        final fileName =
            'products/${product.createdBy}/${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

        final uploadTask = _storage.ref(fileName).putData(newImageBytes,
            SettableMetadata(contentType: 'image/$fileExtension'));

        final snapshot = await uploadTask.whenComplete(() {});
        newImageUrl = await snapshot.ref.getDownloadURL();
      }

      // Data yang diperbarui
      final updatedData = {
        'name': product.name.trim(),
        'imageUrl': newImageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'categoryId': product.categoryId,
        'categoryName': product.categoryName,
        'isVariantProduct': product.isVariantProduct,
        'variants': product.variants.map((v) => v.toMap()).toList(),
        'hargaModal': product.hargaModal,
        'hargaJual': product.hargaJual,
        'stok': product.stok,
        'hargaDiskon': product.hargaDiskon,
        'sku': product.sku,
      };

      await _firestore
          .collection('products')
          .doc(product.id)
          .update(updatedData);
    } catch (e) {
      throw Exception("Gagal update produk: $e");
    }
  }

  Future<void> deleteProduct(String productId) async {
    if (_userId == null) throw Exception("User belum login");

    try {
      final doc = await _firestore.collection('products').doc(productId).get();
      if (!doc.exists) throw Exception("Produk tidak ditemukan");

      final data = doc.data()!;
      final imageUrl = data['imageUrl'];

      // Hapus gambar
      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          await _storage.refFromURL(imageUrl).delete();
        } catch (_) {}
      }

      await _firestore.collection('products').doc(productId).delete();
    } catch (e) {
      throw Exception("Gagal menghapus produk: $e");
    }
  }

  Future<void> adjustStock(String productId, int adjustmentAmount) async {
    if (_userId == null) throw Exception("User belum login");
    if (adjustmentAmount == 0) return;

    try {
      await _firestore.collection('products').doc(productId).update({
        'stok': FieldValue.increment(adjustmentAmount),
      });
    } catch (e) {
      throw Exception("Gagal update stok: $e");
    }
  }

  Future<Product?> getProductBySKU(String storeId, String sku) async {
    if (_userId == null) throw Exception("User belum login");

    try {
      final snap = await _firestore
          .collection('products')
          .where('storeId', isEqualTo: storeId)
          .where('sku', isEqualTo: sku)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) return null;

      return Product.fromMap(snap.docs.first.data(), snap.docs.first.id);
    } catch (e) {
      throw Exception("Gagal mencari produk: $e");
    }
  }
}
