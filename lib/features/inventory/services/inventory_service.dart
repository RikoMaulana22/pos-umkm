import 'dart:convert'; // Untuk memproses respon JSON dari Cloudinary
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart'
    as http; // Paket HTTP untuk upload ke Cloudinary
import '../models/product_model.dart';
import '../models/product_variant_model.dart';

class InventoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // =======================================================================
  // ⚙️ KONFIGURASI CLOUDINARY (WAJIB DIISI)
  // =======================================================================
  // 1. Masuk ke Dashboard Cloudinary -> Copy "Cloud Name"
  final String _cloudName = "dnw2t61ne";

  // 2. Masuk ke Settings -> Upload -> Upload presets -> Copy nama preset (Mode: Unsigned)
  final String _uploadPreset = "pos_umkm_preset";

  String? get _userId => _auth.currentUser?.uid;

  /// ======================================================================
  /// ☁️ HELPER: FUNGSI UPLOAD KE CLOUDINARY
  /// ======================================================================
  Future<String?> _uploadToCloudinary(Uint8List imageBytes) async {
    try {
      var uri =
          Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');

      var request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = _uploadPreset
        ..files.add(http.MultipartFile.fromBytes('file', imageBytes,
            filename:
                'product_image.jpg' // Nama dummy, Cloudinary akan otomatis rename
            ));

      var response = await request.send();

      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final jsonMap = jsonDecode(respStr);
        // Mengembalikan URL gambar yang aman (https)
        return jsonMap['secure_url'];
      } else {
        print('⚠️ Gagal Upload ke Cloudinary. Status: ${response.statusCode}');
        // Opsional: Baca body error untuk debugging
        final errStr = await response.stream.bytesToString();
        print('⚠️ Detail Error: $errStr');
        return null;
      }
    } catch (e) {
      print('⚠️ Error Koneksi Cloudinary: $e');
      return null;
    }
  }

  /// ======================================================================
  /// ✅ TAMBAH PRODUK (MENGGUNAKAN CLOUDINARY)
  /// ======================================================================
  Future<void> addProduct({
    required String name,
    required String storeId,
    required String categoryId,
    required String categoryName,
    Uint8List? imageBytes,
    String?
        imageName, // Tidak dipakai lagi, kita generate otomatis di Cloudinary
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

    // 1. LOGIKA UPLOAD GAMBAR (KE CLOUDINARY)
    if (imageBytes != null && imageBytes.isNotEmpty) {
      print("🔄 Memulai upload ke Cloudinary...");
      downloadUrl = await _uploadToCloudinary(imageBytes);

      if (downloadUrl != null) {
        print("✅ Sukses Upload: $downloadUrl");
      } else {
        print("⚠️ Upload gagal, produk akan disimpan tanpa gambar.");
      }
    }

    // 2. LOGIKA SIMPAN DATA KE FIRESTORE
    try {
      final product = Product(
        name: name.trim(),
        imageUrl: downloadUrl, // URL dari Cloudinary
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

  /// ======================================================================
  /// 📦 AMBIL DAFTAR PRODUK
  /// ======================================================================
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

  /// ======================================================================
  /// 🔄 UPDATE PRODUK (MENGGUNAKAN CLOUDINARY)
  /// ======================================================================
  Future<void> updateProduct({
    required Product product,
    Uint8List? newImageBytes,
    String? newImageName,
  }) async {
    if (_userId == null) throw Exception("User belum login");
    if (product.id == null || product.id!.isEmpty)
      throw Exception("ID produk tidak valid");

    try {
      String? newImageUrl = product.imageUrl;

      // Jika ada gambar baru, upload ke Cloudinary
      if (newImageBytes != null && newImageBytes.isNotEmpty) {
        print("🔄 Mengupload gambar baru ke Cloudinary...");
        String? cloudUrl = await _uploadToCloudinary(newImageBytes);
        if (cloudUrl != null) {
          newImageUrl = cloudUrl;
        }
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

  /// ======================================================================
  /// 🗑️ HAPUS PRODUK
  /// ======================================================================
  Future<void> deleteProduct(String productId) async {
    if (_userId == null) throw Exception("User belum login");

    try {
      // Cek apakah produk ada
      final doc = await _firestore.collection('products').doc(productId).get();
      if (!doc.exists) throw Exception("Produk tidak ditemukan");

      // CATATAN: Kita tidak menghapus gambar dari Cloudinary secara otomatis
      // karena mode "Unsigned Upload" biasanya tidak mengizinkan delete via API
      // demi keamanan. Gambar lama akan tetap ada di Cloud (tidak masalah,
      // kapasitas Cloudinary besar). Fokus kita hanya hapus data di Database.

      await _firestore.collection('products').doc(productId).delete();
    } catch (e) {
      throw Exception("Gagal menghapus produk: $e");
    }
  }

  // ... (Fungsi adjustStock & getProductBySKU tetap sama, tidak perlu diubah) ...

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
