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

    String? downloadUrl;

    // 1. LOGIKA UPLOAD GAMBAR
    if (imageBytes != null && imageBytes.isNotEmpty) {
      try {
        // Buat nama file unik (Timestamp)
        // Kita paksa ekstensi .jpg agar Android tidak bingung membaca format
        final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';

        // Pastikan folder aman (cegah error jika storeId kosong)
        final String safeStoreId = storeId.isEmpty ? 'common' : storeId;
        final String path = 'products/$safeStoreId/$fileName';

        // Buat referensi ke lokasi storage
        final Reference ref = _storage.ref().child(path);

        // Set metadata agar file dikenali sebagai gambar
        final metadata = SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {'uploaded_by': _userId!});

        // 🔥 INI KUNCINYA: KITA TAMPUNG TASK UPLOADNYA
        final UploadTask uploadTask = ref.putData(imageBytes, metadata);

        // ⏳ KITA TUNGGU (AWAIT) SAMPAI TASK SELESAI 100%
        // snapshot berisi bukti bahwa file sudah ada di server
        final TaskSnapshot snapshot = await uploadTask.whenComplete(() => null);

        // ✅ AMBIL URL DARI SNAPSHOT (BUKAN DARI REF MANUAL)
        // Ini menjamin file PASTI ADA sebelum kita minta URL-nya
        downloadUrl = await snapshot.ref.getDownloadURL();

        print("✅ Sukses Upload: $downloadUrl");
      } catch (e) {
        print("⚠️ Gagal Upload Gambar (Data produk tetap akan disimpan): $e");
        // Kita biarkan downloadUrl null, jangan throw error agar user tidak perlu mengetik ulang
      }
    }

    // 2. LOGIKA SIMPAN KE FIRESTORE (Tetap jalan meski gambar gagal)
    try {
      final product = Product(
        name: name.trim(),
        imageUrl: downloadUrl, // Akan null jika upload gagal/tidak ada gambar
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
      throw Exception("Gagal menyimpan data ke database: $e");
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
